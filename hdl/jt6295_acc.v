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



module jt6295_acc(
    input                rst,
    input                clk,
    input                cen,
    input                cen4,
    input  signed [11:0] sound_in,
    output signed [13:0] sound_out
);

reg signed [13:0] acc, sum;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        acc <= 14'd0;
    end else if(cen4) begin
        acc <= cen ? sound_in : acc + sound_in;        
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        sum <= 14'd0;
    end else if(cen) begin
        sum <= acc;
    end
end

// If N is set to 2 there is too much filtering and 
// some instruments won't be heard
jt12_interpol #(.calcw(14+1), .inw(14), 
    .n(1),    // number of stages
    .m(2),    // depth of comb filter
    .rate(4)  // it will stuff with as many as (rate-1) zeros
) u_interpol(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen_in     ( cen       ),
    .cen_out    ( cen4      ),
    .snd_in     ( sum       ),
    .snd_out    ( sound_out )
);

//assign sound_out = sum;
endmodule