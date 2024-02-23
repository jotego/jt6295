#!/bin/bash

set -e

if [ ! -e ../../src/jt6295 ]; then
    echo "Missing jt6295 executable to generate test files. Trying to compile it"
    cd ../../src
    go build -o jt6295 .
    cd -
fi

../../src/jt6295 sine sine100.yaml

FILES="test.v ../../hdl/jt6295_adpcm.v ../../hdl/jt6295_sh_rst.v"

# use -DSINESIM to simulate a short built-in sine wave
iverilog $FILES -DSIMULATION  -o sim
sim -lxt
rm -f sim