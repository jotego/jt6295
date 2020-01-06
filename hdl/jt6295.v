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

module jt6295(
    input                  rst,
    input                  clk,
    input                  cen /* direct_enable */,        
    input                  ss,        // ss pin: selects sample rate
    // CPU interface
    input                  wrn,  // active low
    input         [ 7:0]   din,
    output        [ 7:0]   dout,
    // ROM interface
    output        [17:0]   rom_addr,
    input         [ 7:0]   rom_data,
    input                  rom_ok,
    // Sound output
    output signed [11:0]   sound
);

wire        cen_sr;  // sampling rate
wire        cen_sr4; // 4x sampling rate 

wire [ 3:0] busy, start, stop;
wire [17:0] start_addr0, end_addr0,
            start_addr1, end_addr1,
            start_addr2, end_addr2,
            start_addr3, end_addr3,
            ch_addr0, ch_addr1, ch_addr2, ch_addr3;
wire [ 9:0] ctrl_addr;
wire [ 7:0] ch_data0, ch_data1, ch_data2, ch_data3, ctrl_data;
wire [ 3:0] data0, data1, data2, data3, pipe_data;
wire [ 3:0] att0, att1, att2, att3, pipe_att;
wire        ctrl_ok;

assign      dout = { 4'hf, busy };

jt6295_timing u_timing(
    .clk    ( clk       ),
    .cen    ( cen       ),
    .ss     ( ss        ),
    .cen_sr ( cen_sr    ),
    .cen_sr4( cen_sr4   )
);

// ROM interface
jt6295_rom u_rom(
    .rst        ( rst           ),
    .clk        ( clk           ),
    // Each parallel accessing device
    .slot0_addr ( ch_addr       ),
    .slot1_addr ( { 8'd0, ctrl_addr } ),
    // Data
    .slot0_dout ( ch_data       ),
    .slot1_addr ( ctrl_data     ),
    // Ok
    .slot0_ok   (               ),
    .slot1_ok   ( ctrl_ok       ),
    // 
);

// CPU interface

jt6295_ctrl u_ctrl(
    .rst        ( rst           ),
    .clk        ( clk           ),
    // CPU
    .wrn        ( wrn           ),
    .din        ( din           ),
    // Channel address
    .start_addr0( start_addr0   ),
    .end_addr0  ( end_addr0     ),
    .start_addr1( start_addr1   ),
    .end_addr1  ( end_addr1     ),
    .start_addr2( start_addr2   ),
    .end_addr2  ( end_addr2     ),
    .start_addr3( start_addr3   ),
    .end_addr3  ( end_addr3     ),
    // Attenuation
    .att0       ( att0          ),
    .att1       ( att1          ),
    .att2       ( att2          ),
    .att3       ( att3          ),
    // ROM interface
    .rom_addr   ( ctrl_addr     ),
    .rom_data   ( ctrl_data     ),
    .rom_ok     ( ctrl_ok       ),

    .start      ( start         ),
    .stop       ( stop          ),
    .busy       ( busy          )
);

jt6295_serial u_serial(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cen_sr4       ), 
    // Flow
    .start_addr ( start_addr    ),
    .stop_addr  ( stop_addr     ),
    .att_in     ( att           ),
    .start      ( start         ),
    .stop       ( stop          ),    
    .busy       ( busy          ),
    // ADPCM data feed    
    .ch_addr    ( ch_addr       ),
    .ch_data    ( ch_data       ),
    // serialized data
    .pipe_en    ( pipe_en       ),
    .pipe_att   ( pip_att       ),
    .pipe_data  ( pipe_data     )
);

jt6295_adpcm u_adpcm(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cen_sr4       ), 
    // serialized data
    .en         ( pipe_en       ),
    .att        ( pip_att       ),
    .data       ( pipe_data     ),
    .sound      ( pipe_snd      )
);

jt6295_acc u_acc(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cen_sr4       ), 
    // serialized data
    .sound_in   ( pipe_snd      ),
    .sound_out  ( sound         )
);

endmodule