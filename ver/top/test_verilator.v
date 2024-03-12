`timescale 1ns / 1ps

module test;

reg  rst;
wire irq;
reg  clk, cen=1'b0;


wire ss = 1;
wire sample;
wire [17:0] rom_addr;
reg  [17:0] rom_last;
reg  [ 7:0] rom_data;
wire        rom_ok = rom_last === rom_addr;
wire signed [13:0] sound;
reg         wrn=1'b1;
reg  [ 7:0] din=0;
wire [ 7:0] dout;
reg  [ 7:0] rom[0:262143];

always @(posedge clk) begin
    rom_last <= rom_addr;
    rom_data <= rom[rom_addr];
end

jt6295 uut(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),
    .ss         ( ss        ),
    // CPU interface
    .wrn        ( wrn       ),  // active low
    .din        ( din       ),
    .dout       ( dout      ),
    // ROM interface
    .rom_addr   ( rom_addr  ),
    .rom_data   ( rom_data  ),
    .rom_ok     ( rom_ok    ),
    // Sound output
    .sample     ( sample    ),
    .sound      ( sound     )
);

wire signed [13:0] pcm_butter;

// jtframe_iir2 #(.WA(8), .WS(14)) u_butter(
//     .rst        ( rst       ),
//     .clk        ( clk       ),
//     .sample     ( sample    ),
//     .a1         ( 22'd328   ),
//     .a2         (-22'd122   ),
//     .b0         ( 22'd13    ),
//     .b1         ( 22'd25    ),
//     .b2         ( 22'd13    ),
//     .sin        ( sound     ),
//     .sout       ( pcm_butter)
// );

iir_filter u_butter(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .sample ( sample    ),
    .x_in   ( sound     ),
    .y_out  ( pcm_butter)
);

initial begin
    clk=1'b0;
    forever #118.371 clk=~clk;
end

integer f, fcnt;

initial begin
    f=$fopen("rom.bin","rb");
    fcnt=$fread(rom,f);
    $display("%d bytes read from rom.bin",fcnt);
    $fclose(f);
end

initial begin
    rst = 1;
    #1250 rst=1'b0;
end

localparam TIMEOUT=48000*2;
integer sample_cnt=0;

always @(posedge sample) begin
    sample_cnt <= sample_cnt+1;
    if(sample_cnt==TIMEOUT) $finish;
end

initial begin
    @(negedge rst);
    #10000;
    @(posedge sample) begin
        wrn = 0;
        din = 8'h82; // start phrase 1, change bits 6:0 for different phrases
    end
    @(posedge sample) wrn = 1;
    @(posedge sample) begin
        wrn = 0;
        din = 8'h10; // ch 1, att 0
    end
    @(posedge sample) wrn = 1;
end


integer cen_cnt=0;

always @(posedge clk) begin
    cen <= 1'b0;
    if(cen_cnt==0) cen<=1'b1;
    cen_cnt <= cen_cnt==0 ? 3 : (cen_cnt-1);
end

`ifdef DUMP
`ifdef VERILATOR
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0,test);
        $dumpon;
    end
`else
    initial begin
        $dumpfile("test.lxt");
        $dumpvars(0,test);
        $dumpon;
    end
`endif
`endif

endmodule

module iir_filter(
    input rst,
    input clk,
    input sample,
    input signed [13:0] x_in, // 14-bit signed input
    output signed [13:0] y_out // 14-bit signed output
);

// Fixed-point coefficients in Q1.13 format
parameter signed [13:0] b0 = 14'd405,
                        b1 = 14'd811,
                        b2 = 14'd405,
                        a1 = -14'd10483,
                        a2 = 14'd3912;

// Internal registers for delay elements
reg signed [13:0] x_1 = 0, x_2 = 0; // Input delay registers
reg signed [13:0] y_1 = 0, y_2 = 0; // Output delay registers

// Intermediate values for the filter calculations
wire signed [27:0] mul_b0, mul_b1, mul_b2, mul_a1, mul_a2;

// Calculating the product of coefficients and inputs/outputs
assign mul_b0 = b0 * x_in;
assign mul_b1 = b1 * x_1;
assign mul_b2 = b2 * x_2;
assign mul_a1 = a1 * y_1;
assign mul_a2 = a2 * y_2;

// Summation of products, scaled back to Q1.13 format
wire signed [27:0] y_sum = mul_b0 + mul_b1 + mul_b2 - mul_a1 - mul_a2;
assign y_out = y_sum[23-:14]; // Adjusting the fixed-point result to fit in 14 bits

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset the delay elements
        x_1 <= 0;
        x_2 <= 0;
        y_1 <= 0;
        y_2 <= 0;
    end else if(sample) begin
        // Update delay elements
        x_1 <= x_in;
        x_2 <= x_1;
        y_1 <= y_sum[27:14];
        y_2 <= y_1;
    end
end

endmodule
