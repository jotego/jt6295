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

// slot 0 has priority over slot1

module jt6295_rom(
    input             rst,
    input             clk,

    input             slot0_cs,
    input             slot1_cs,

    input      [17:0] slot0_addr,
    input      [17:0] slot1_addr,

    output reg [ 7:0] slot0_dout,
    output reg [ 7:0] slot1_dout,

    output reg        slot0_ok,
    output reg        slot1_ok,
    // ROM interface
    output reg [17:0] rom_addr,
    input      [ 7:0] rom_data,
    input             rom_ok
);

reg [1:0] datasel;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rom_addr <= 18'd0;
        datasel  <= 2'b0;
    end else begin
        if( (datasel && rom_ok) || !datasel ) begin
            datasel <= 2'b0;

            if( slot0_cs ) slot0_ok <= 1'b0;
            if( slot1_cs ) slot1_ok <= 1'b0;

            if(rom_ok && datasel[0]) begin
                slot0_dout <= rom_data;
                slot0_ok   <= 1'b1;
            end
            
            if(rom_ok && datasel[1]) begin
                slot1_dout <= rom_data;
                slot1_ok   <= 1'b1;
            end

            if( slot0_cs ) begin
                rom_addr     <= slot0_addr;
                datasel[1:0] <= 2'b01;
            end else
            if( slot1_cs ) begin
                rom_addr     <= slot1_addr;
                datasel[1:0] <= 2'b10;
            end
        end
    end
end



endmodule