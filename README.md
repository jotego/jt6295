# JT6295
4 channel ADPCM decoder compatible with OKI 6295, by Jose Tejada (aka jotego)

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation

JT6295 is an ADPCM sound source written in Verilog, fully compatible with OKI MSM6295.

## Architecture

This design uses a pipeline in order to save FPGA resources and power. In that
sense, it would be very similar to the original design.

The behaviour of the original chip if a phrase command is send twice before the
end of it, has not been verified. The current JT6295 is to ignore commands to
the same channel as long as the playback has not ended.

## Port Description

Name     | Direction | Width | Purpose
---------|-----------|-------|--------------------------------------
rst      | input     |       | active-high asynchronous reset signal
clk      | input     |       | clock
cen      | input     |       | clock enable (positive edge).
ss       | input     | 1     | selects the data rate
din      | input     | 8     | input data from CPU
dout     | output    | 8     | output data to CPU
rom_addr | output    | 18    | Memory address to be read
rom_data | input     | 8     | Data read
rom_ok   | input     | 1     | high when rom_data is valid and matches rom_addr
sound    | output    | 14    | signed sound output

## Usage

This is a pin-to-pin compatible module with OKI MSM6295. If you are just going to use it on a retro core you don't need to know the internals of it just hook it up and be sure that the effective clock rate, i.e. clk&cen signal, is the intended frequency.

rom_ok signal should go down in one clock cycle (regardless of cen) if rom_data
is not valid after a change to rom_addr.

CPU and ROM interfaces do not follow the clock enable and operate at full speed.

The output data rate is 4x the expected from the ss pin as there is a 4x
interpolator built in, which eases most of the high frequency aliasing of the
signal.

## FPGA arcade cores using this module:

* [Double Dragon 2](https://github.com/jotego/jtdd), by the same author