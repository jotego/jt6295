`timescale 1ns / 1ps

module test;

reg  rst;
wire irq;
reg  clk, cen=1'b0;
wire [3:0] din;
wire signed [11:0] sound;
wire adpcm_en;

assign adpcm_en = cnt>=0 && !rst;

jt6295_adpcm uut(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( 1'b1      ),
    .en         ( adpcm_en  ),
    .att        ( 4'd0      ),
    .data       ( din       ),
    .sound      ( sound     )
);

reg [7:0] data[0:1024*32-1];

integer f,fcnt;

initial begin
    f=$fopen("patch00.bin","rb");
    fcnt=$fread(data,f);
    $display("%d samples read",fcnt*2);
    $fclose(f);

    clk=1'b0;
    forever #325.521 clk=~clk;
end

initial begin
    rst = 1'b0;
    #150 rst=1'b1;
    #750 rst=1'b0;
    #10_000_000 $finish;
end

integer cnt, cen_cnt;
assign din = cnt<0 ? 4'd0 : data[cnt>>1] >> (cnt[0]?0:4);

always @(posedge clk,posedge rst) begin
    if( rst ) begin
        cnt     <= -10;
        cen     <= 0;
        cen_cnt <= 0;
    end else begin
        cen <=cen_cnt==0;
        cen_cnt <= cen_cnt==0 ? 3 : (cen_cnt-1);
        if(cen) begin
            cnt <= cnt+1;
            if( cnt==fcnt ) $finish;
        end
    end
end

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

endmodule