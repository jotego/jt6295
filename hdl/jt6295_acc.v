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
    output signed [13:0] sound_out,
    output               sample
);

parameter INTERPOL=1;

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

generate
    if( INTERPOL) begin
        // This module is in the JTFRAME repository https://github.com/jotego/jtframe

        // Zero padding
        reg  signed [15:0] fir_din;
        wire signed [15:0] fir_dout;

        assign sample    = cen4;
        assign sound_out = fir_dout[14:1]; // gain the signal back up

        always @(posedge clk) begin
            if( cen4 ) fir_din <= cen ? { {2{sum[13]}}, sum } : 16'd0;
        end


        jtframe_fir_mono #(.COEFFS("jt6295_up4.hex"),.KMAX(69)) u_upfilter(
            .rst        ( rst       ),
            .clk        ( clk       ),
            .sample     ( cen4      ),
            .din        ( fir_din   ),
            .dout       ( fir_out   )
        );
    end else begin
        assign sound_out = sum;
        assign sample    = cen;
    end
endgenerate

endmodule