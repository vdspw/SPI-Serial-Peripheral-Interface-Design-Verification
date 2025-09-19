module tb;
  
  reg clk = 0;
  reg rst = 0;
  reg tx_enable =0;
  wire mosi;
  wire cs;
  wire sclk;
  
  always #5 clk = ~clk;
  
  initial begin
    rst = 1;
    repeat(5) @(posedge clk);
    rst =0;
    
  end
  
  initial begin
    tx_enable =0;
    repeat(5) @(posedge clk);
    tx_enable = 1;
  end
  
  fsm_spi dut(clk,rst,tx_enable,mosi,cs,sclk);
  
/*   initial begin
      $dumpfile("dump.vcd");
      $dumpvars;
    end
  
  initial begin
    #100;
    $display(" Simulation completed !"); */
  
  end
endmodule
