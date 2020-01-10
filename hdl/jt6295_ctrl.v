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
    input                  cen4,
    // CPU
    input                  wrn,
    input      [ 7:0]      din,
    // Channel address
    output reg [17:0]      start_addr,
    output reg [17:0]      stop_addr,   
    // Attenuation
    output reg [ 3:0]      att,
    // ROM interface
    output     [ 9:0]      rom_addr,
    output reg             rom_cs,
    input      [ 7:0]      rom_data,    
    input                  rom_ok,
    // flow control
    output reg [ 3:0]      start,
    output reg [ 3:0]      stop,
    input      [ 3:0]      busy
);

reg  last_wrn;
wire posedge_wrn  = wrn && !last_wrn;

// new request
reg [6:0] phrase;
reg       pull;
reg [3:0] ch, new_att;
reg       cmd;

always @(posedge clk) begin
    last_wrn <= wrn;
end

// Bus interface
always @(posedge clk) begin
    if( rst ) begin
        cmd  <= 1'b0;
        stop <= 4'd0;
        ch   <= 4'd0;
    end else begin
        pull <= 1'b0;
        if( posedge_wrn  ) begin // new write
            if( cmd ) begin // 2nd byte
                ch      <= din[7:4];
                new_att <= din[3:0];
                cmd     <= 1'b0;
                pull    <= 1'b1;
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

reg [17:0] new_start;
reg [17:8] new_stop;
reg [ 2:0] st;
reg        wrom;

assign rom_addr = { phrase, st };

// Request phrase address
always @(posedge clk) begin
    if( rst ) begin
        st <= 3'd7;
        att <= 4'd0;
        start_addr <= 18'd0;
        stop_addr  <= 18'd0;
        rom_cs <= 1'b0;
        start  <= 4'd0;
    end else begin
        if(st!=3'd7) begin
            wrom <= 1'b0;
            if( !wrom && rom_ok ) begin
                st   <= st+3'd1;
                wrom <= 1'b1;
            end
        end
        case(st)
            3'd7: begin
                if(pull) begin
                    st       <= 3'd0;
                    wrom     <= 1'b1;
                    start    <= 4'd0;
                    rom_cs   <= 1'b1;
                end
                if(cen4) start <= start & busy;
            end
            3'd1: new_start[17:16] <= rom_data[1:0];
            3'd2: new_start[15: 8] <= rom_data;
            3'd3: new_start[ 7: 0] <= rom_data;
            3'd4: new_stop [17:16] <= rom_data[1:0];
            3'd5: new_stop [15: 8] <= rom_data;
            3'd6: begin
                start       <= start | ch;
                start_addr  <= new_start;
                stop_addr   <= {new_stop[17:8], rom_data} ;
                att         <= new_att;
                rom_cs      <= 1'b0;
            end
        endcase
    end
end

endmodule