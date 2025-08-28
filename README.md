# SPI-Serial-Peripheral-Interface-Design-Verification
Designing the SPI by using Verilog HDL .
Verification by a regular testbench -- Simulation based functional verification.
UVM Based testbench .

Different modes of operation :

CPOLARITY  CPHASE    SCLK   EDGE
0          0          0      1st edge (posedge) ---MODE 0
0          1          0      2nd edge (negedge) ---MODE 1
1          0          1      1st edge (negedge)----MODE 2
1          1          1      2nd edge (posedge)----MODE3
