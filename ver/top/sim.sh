#!/bin/bash

set -e

if which verilator; then
    rm -f test.vcd
    mkfifo test.vcd
    vcd2fst -p test.vcd test.fst&
    verilator ../../hdl/*.v test_verilator.v --binary --top test \
        --timescale 1ns/1ps +define+SIMULATION  --trace +define+DUMP
    obj_dir/Vtest
    wait
    rm -f test.vcd
else
    iverilog -f test.f -DSIMULATION -o sim || exit 1
    sim -lxt
    rm -f sim
fi

if [ -e jt6295.raw ]; then
    ffmpeg -y -f s16le -ar 44100 -ac 1 -i jt6295.raw -ar 8000 output.wav
fi