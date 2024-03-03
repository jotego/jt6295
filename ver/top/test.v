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

initial begin
    @(negedge rst);
    #10000;
    @(posedge sample) begin
        wrn = 0;
        din = 8'h81; // start phrase 1, change bits 6:0 for different phrases
    end
    @(posedge sample) wrn = 1;
    @(posedge sample) begin
        wrn = 0;
        din = 8'h10; // ch 1, att 0
    end
    @(posedge sample) wrn = 1;
    // time out
    #1000_000_000 $finish;
end


integer cen_cnt=0;

always @(posedge clk) begin
    cen <= 1'b0;
    if(cen_cnt==0) cen<=1'b1;
    cen_cnt <= cen_cnt==0 ? 3 : (cen_cnt-1);
end

`ifdef DUMP
`ifndef NCVERILOG
    initial begin
        $dumpfile("test.lxt");
        $dumpvars(0,test);
        $dumpon;
    end
`else
    initial begin
        $shm_open("test.shm");
        $shm_probe(test,"AS");
    end
`endif
`endif

endmodule