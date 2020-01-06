/*  This file is part of JT6295.
    JT6295 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT6295 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT6295.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 6-1-2020 */

module jt6295_ctrl(
    input                  rst,
    input                  clk,
    // CPU
    input                  wrn,
    input      [ 7:0]      din,
    // Channel address
    output reg [17:0]      start_addr0,
    output reg [17:0]      end_addr0,  
    output reg [17:0]      start_addr1,
    output reg [17:0]      end_addr1,  
    output reg [17:0]      start_addr2,
    output reg [17:0]      end_addr2,  
    output reg [17:0]      start_addr3,
    output reg [17:0]      end_addr3,  
    // Attenuation
    output reg [ 3:0]      att0,
    output reg [ 3:0]      att1,
    output reg [ 3:0]      att2,
    output reg [ 3:0]      att3,
    // ROM interface
    output     [ 9:0]      rom_addr,
    input      [ 7:0]      rom_data,
    input                  rom_ok,
    // flow control
    output     [ 3:0]      start,
    output     [ 3:0]      stop,
    input      [ 3:0]      busy
);

reg  last_wrn;
wire negedge_wrn = !wrn && last_wrn;

// new request
reg [6:0] phrase;
reg       pull;
reg [3:0] ch, att;
reg       cmd;

always @(posedge clk) begin
    last_wrn <= wrn;
end

// Bus interface
always @(posedge clk) begin
    if( rst ) begin
        cmd <= 1'b0;
    end else begin
        pull <= 1'b0;
        if( negedge_wrn ) begin // new write
            if( cmd ) begin // 2nd byte
                ch   <= din[7:4];
                att  <= din[3:0];
                cmd  <= 1'b0;
                pull <= 1'b1;
            end
            else if( din[7] ) begin // channel start
                phrase <= din[6:0];
                cmd    <= 1'b1; // wait for second byte
            end else begin // stop data
                stop   <= din[7:4];
            end
        end
    end
end

reg [17:0] new_start, new_end;
reg [ 2:0] st;

assign rom_addr = { phrase, st };

// Request phrase address
always @(posedge clk) begin
    if( rst ) begin
        st <= 3'd7;
    end else begin
        if(st!=3'd7) begin
            wrom <= 1'b0;
            if( !wrom && rom_ok ) begin
                st   <= st+3'd1;
                wrom <= 1'b1;
            end
        end
        case(st)
            3'd7: if(pull) begin
                st       <= 3'd0;
                wrom     <= 1'b1;
                start    <= 4'd0;
            end
            3'd0: new_start[17:16] <= rom_data[1:0];
            3'd1: new_start[15: 8] <= rom_data;
            3'd2: new_start[ 7: 0] <= rom_data;
            3'd3: new_end  [17:16] <= rom_data[1:0];
            3'd4: new_end  [15: 8] <= rom_data;
            3'd5: new_end  [ 7: 0] <= rom_data;
            3'd6: begin
                start <= ch;
                if( ch[0] ) begin
                    start_addr0 <= new_start;
                    end_addr0   <= new_end;
                    att0        <= att;
                end
                if( ch[1] ) begin
                    start_addr1 <= new_start;
                    end_addr1   <= new_end;
                    att1        <= att;
                end
                if( ch[2] ) begin
                    start_addr2 <= new_start;
                    end_addr2   <= new_end;
                    att2        <= att;
                end
                if( ch[3] ) begin
                    start_addr3 <= new_start;
                    end_addr3   <= new_end;
                    att3        <= att;
                end
            end
            end
        endcase
    end
end

endmodule