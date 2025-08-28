# SPI-Serial-Peripheral-Interface-Design-Verification
CONTENTS:
1.Designing the SPI by using Verilog HDL .
2.Verification by a regular testbench -- Simulation based functional verification.
3.UVM Based testbench .

DESIGN SPECIFICATIONS:
Different modes of operation :

CPOLARITY  CPHASE    SCLK   EDGE
0          0          0      1st edge (posedge) ---MODE 0
0          1          0      2nd edge (negedge) ---MODE 1
1          0          1      1st edge (negedge) ---MODE 2
1          1          1      2nd edge (posedge) ---MODE 3

Master -- New data transmotted on the postive edge.
          Data length is varialbe ( 8 bit to 32 bit) 
