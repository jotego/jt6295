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

module jt6295_serial(
    input               rst,
    input               clk,
    input               cen,
    input               cen4,
    // Flow
    input      [17:0]   start_addr,
    input      [17:0]   stop_addr,
    input      [ 3:0]   att,
    input      [ 3:0]   start,
    input      [ 3:0]   stop,
    output reg [ 3:0]   busy,
    // ADPCM data feed    
    output     [17:0]   rom_addr,
    input      [ 7:0]   rom_data,
    // serialized data
    output reg          pipe_en,
    output reg [ 3:0]   pipe_att,
    output reg [ 3:0]   pipe_data
);

(*keep*) reg  [ 3:0] ch, start_latch, start_csr;
wire [ 3:0] att_in, att_out;
wire [18:0] cnt, cnt_next, cnt_in;
wire [17:0] ch_end, stop_in, stop_out;
(*keep*) wire        update = start_latch[0] & ~start_csr[0];
(*keep*) wire        over, busy_in, busy_out;
assign      cnt_next = busy_out ? cnt+19'd1 : cnt;

// Busy
always @(posedge clk, posedge rst) begin
    if(rst)
        busy <= 4'b0;
    else if(cen4) begin
        if( ch[0] ) busy[0] <= busy_in;
        if( ch[1] ) busy[1] <= busy_in;
        if( ch[2] ) busy[2] <= busy_in;
        if( ch[3] ) busy[3] <= busy_in;
    end
end

// current channel
always @(posedge clk, posedge rst) begin
    if(rst)
        ch <= 4'b1;
    else begin
        if(cen4) ch <= { ch[0], ch[3:1]  };
        if(cen)  ch <= 4'b0001; // keep it sync'ed with the start_latch
    end
end

// 

always @(posedge clk, posedge rst) begin
    if(rst) begin
        start_latch <= 4'b0;
        start_csr   <= 4'b0;
    end else begin        
        if(cen4) begin
            start_csr   <= { start_latch[0], start_csr[3:1] };
            start_latch <= start_latch >> 1;
        end
        if(cen) begin
            start_latch <= start;
        end
    end
end

assign stop_in = update ? stop_addr : stop_out;
assign cnt_in  = update ? {start_addr, 1'b0} : cnt_next;
assign att_in  = update ? att : att_out;

localparam CSRW = 18+19+4+1;

wire [CSRW-1:0] csr_in, csr_out;

assign csr_in = { stop_in, cnt_in, att_in, busy_in };
assign {stop_out, cnt, att_out, busy_out } = csr_out;
assign rom_addr = cnt[18:1];
assign over     = rom_addr >= stop_out;
assign busy_in  = update | ( busy_out & ~over );

jt6295_sh_rst #(.WIDTH(CSRW), .STAGES(4) ) u_cnt
(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .clk_en ( cen4       ),
    .din    ( csr_in    ),
    .drop   ( csr_out   )
);

// Channel data is latched for a clock cycle to wait for ROM data
reg       sel, en;
reg [3:0] attx;

always @(posedge clk, posedge rst) begin
    if(rst) begin
        en       <= 1'b0;
        sel      <= 1'b0;
        pipe_data<= 4'd0;
        pipe_en  <= 1'b0;
        attx     <= 4'd0;
        pipe_att <= 4'd0;
    end else if(cen4) begin
        // data
        sel       <= cnt[0];
        pipe_data <= !sel ? rom_data[7:4] : rom_data[3:0];
        // attenuation
        attx      <= att_out;
        pipe_att  <= attx;
        // busy / enable
        en        <= busy_in;
        pipe_en   <= en;
    end
end

endmodule
