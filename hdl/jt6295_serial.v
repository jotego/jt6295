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
    output reg [ 7:0]   pipe_data
);

reg  [ 3:0] ch, start_latch;
wire [ 3:0] att_in, att_out;
wire [17:0] cnt, ch_end;
wire [17:0] cnt_next = cnt+18'd1;
wire [17:0] cnt_in, stop_in;
wire        update = start_latch==ch;
wire        over, busy_in, busy_out;

// Busy
always @(posedge clk, posedge rst) begin
    if(rst)
        busy <= 4'b0;
    else if(cen) begin
        if( ch[0] ) busy[0] <= busy_out;
        if( ch[1] ) busy[1] <= busy_out;
        if( ch[2] ) busy[2] <= busy_out;
        if( ch[3] ) busy[3] <= busy_out;
    end
end

// current channel
always @(posedge clk, posedge rst) begin
    if(rst)
        ch <= 4'b1;
    else if(cen)
        ch <= { ch[2:0], ch[3] };
end

// 

always @(posedge clk, posedge rst) begin
    if(rst)
        start_latch <= 4'b0;
    else begin
        if(cen) 
            start_latch <= 4'b0;
        else
            start_latch |= start;        
    end
end

assign stop_in = update ? stop_addr : stop ;
assign cnt_in  = update ? start_addr : cnt_next;
assign att_in  = update ? att : att_out;

wire [18+18+4-1:0] csr_in, csr_out;

assign csr_in = { stop_in, cnt_in, att_in, busy_in };
assign {stop, cnt, att_out, busy_out } = csr_out;
assign rom_addr = cnt;
assign over = stop == cnt;
assign busy_in = update | ( busy_out & ~over );

jt6295_sh_rst #(.WIDTH(18+18+4), .STAGES(4) ) u_cnt
(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .clk_en ( cen       ),
    .din    ( csr_in    ),
    .drop   ( csr_out   )
);

// Channel data is latched for a clock cycle to wait for ROM data
reg       sel, en;
reg [3:0] attx;

always @(posedge clk, posedge rst) begin
    if(rst) begin
    end else if(cen) begin
        // data
        sel       <= cnt[0];
        pipe_data <= sel ? rom_data[7:4] : rom_data[3:0];
        // attenuation
        attx      <= att_out;
        pipe_att  <= attx;
        // busy / enable
        en        <= busy_in;
        pipe_en   <= en;
    end
end

endmodule
