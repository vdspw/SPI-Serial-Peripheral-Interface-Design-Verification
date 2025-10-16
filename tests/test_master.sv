// Testbench
interface spi_if;
  logic clk;
  logic newd;
  logic rst;
  logic [11:0] din;
  logic sclk;
  logic cs;
  logic mosi;
endinterface : spi_if
// transaction class///////////////

class transaction;
  rand bit newd; // new data bit can be randomized.
  rand bit [11:0] din; // 12 bit data can be randomized.
  bit cs; // output chip select.
  bit mosi; // output Master out Slave In.
  
  function void display(input string tag);
    $display(" [%0s] : DATA_NEW : %0b DIN : %0d CS : %0b MOSI : %0b", tag, newd,din,cs,mosi );
  endfunction
  
  function transaction copy(); // creating a copy.(deep copy)
    copy = new();
    copy.newd = this.newd;
    copy.din = this.din;
    copy.cs = this.cs;
    copy.mosi = this.mosi;
  endfunction
  
endclass : transaction

///////////////////////////////////////
//generator class///////////////////

class generator;
  
  transaction tr;
  mailbox #(transaction) mbx; 
  event done;
  int count = 0;
  event drvnext; // drive next --driver work done
  event sconext; // scoreboard work done.
  
  function new(mailbox #(transaction) mbx);
    this.mbx=mbx;
    tr = new();
  endfunction
  
  task run();
    repeat(count) begin
      assert(tr.randomize) else $error("[GEN] : Randomization Failed");
      mbx.put(tr.copy); // placing the copy of data in the mailbox.
      tr.display("GEN"); // Gen is the string which is passed 
      @(drvnext);
      @(sconext);
    end
    ->done;
  endtask
   
endclass

////////////////////////////////////////////////
//driver class////////////////////

class driver;
  
  virtual spi_if vif;
  transaction tr;  // this transaction instace is required to store the data //recived from gen and 2 mbx's.
  mailbox #(transaction) mbx;// recive data from generator.
  mailbox #(bit[11:0])mbxds; // transmit data from driver to SB for //comparision.
  event drvnext; // inicates the driver work is complete.
  bit[11:0] din;
  
  //constructor
  function new(mailbox #(bit[11:0]) mbxds, mailbox #(transaction) mbx);
    this.mbx = mbx;
    this.mbxds = mbxds;
  endfunction
  
  task reset();
    vif.rst <= 1'b1; // reset is high.
    vif.cs <= 1'b1; // chip slect is high.
    vif.newd <= 1'b0; // new data is low.
    vif.din <= 1'b0; // data on the bus is zero.
    vif.mosi <= 1'b0; // the o/p is zero.
    repeat(10) @(posedge vif.clk);
    vif.rst <= 1'b0; // deassert the reset.
    repeat(5) @(posedge vif.clk); // wait for 5 clk cycles.
    
    $display("[DRV] : RESET DONE");
    $display("------------------------------");
  endtask
  
  // task to drive transactions.
  task run();
    forever begin
      mbx.get(tr); // fetching transaction
      @(posedge vif.sclk);
      vif.newd <= 1'b1; // new data is high.
      vif.din <= tr.din; // din of the transaction is put in vif.din.
      mbxds.put(tr.din); // put the transaction in mbx (driv to SB) .
      @(posedge vif.sclk);
      vif.newd <= 1'b0; // deassert the new data signal.
      wait(vif.cs == 1'b1) ; 
      
      $display("[DRV] : DATA SENT TO DAC : %0d ",tr.din);
      ->drvnext;
    end
  endtask
endclass
        
//////////////////////////////////////////////////
/// monitor ////////////////////
class monitor;
  transaction tr; 
  mailbox #(bit[11:0] ) mbx;
  bit[11:0] srx; // recieved data
  
  virtual spi_if vif; // virtual interface
  
  //contructor
  function new(mailbox #(bit[11:0]) mbx);
    this.mbx = mbx;
  endfunction
  
  //task to monitor the bus
  task run();
    forever begin
      @(posedge vif.sclk);
      wait(vif.cs == 1'b0); // cs=0 is start of transaction
      @(posedge vif.sclk);
      
      for(int i=0;i<11;i++)begin
        @(posedge vif.sclk);
        srx[i] = vif.mosi; // the o/P
      end
      
      wait(vif.cs == 1'b1) ; //end of transaction
      
      $display("[MON] : DATA SENT : %0d",srx);
      mbx.put(srx);
    end
  endtask
endclass:monitor
  
////////////////////////////////////////////////////////
/// scoreboard ////////////////////////
  
class scoreboard;
  mailbox #(bit[11:0]) mbxds, mbxms;
  bit [11:0] ds; // data from driver
  bit [11:0] ms; // data from monitor
  event sconext;
//constructor
  function new(mailbox #(bit[11:0]) mbxds, mailbox #(bit[11:0]) mbxms);
    this.mbxds = mbxds;
    this.mbxms = mbxms;
  endfunction
  
  //task comparing data from driver and monitor.
  task run();
    forever begin
      mbxds.get(ds); // fetch data from DS 11 bit
      mbxms.get(ms); // fetch data from MS 11 bit
      $display("[SCO] :  DRV : %0d   MON : %0d", ds,ms);
      
      if(ds == ms)
        $display("[SCO] : DATA MATCHED");
      else
        $display("[SCO] : DATA MISMATCHED");
      $display("-------------------------------------");
      ->sconext;
    end
  endtask
  
endclass:scoreboard
  
///////////////////////////////////////////////////////////
// environment////////////
class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  
  event nextgd ; // gen to drv
  event nextgs ; // gen to sb.
  
  mailbox #(transaction) mbxgd; // gen to drv
  mailbox #(bit[11:0]) mbxds; //drv to SB
  mailbox #(bit[11:0]) mbxms ; // mon to sb.
  
  virtual spi_if vif;
  
  //constructor
  function new(virtual spi_if vif);
    mbxgd = new();
    mbxms = new();
    mbxds = new();
    gen = new(mbxgd);
    drv = new(mbxds, mbxgd);
    mon = new(mbxms);
    sco = new(mbxds, mbxms);
    
    this.vif = vif;
    drv.vif = this.vif;
    mon.vif = this.vif;
    
    gen.sconext = nextgs;
    sco.sconext = nextgs;
    
    gen.drvnext = nextgd;
    drv.drvnext = nextgd;
  endfunction
  
    task pre_test();
      drv.reset();
    endtask
    
    task test();
      fork 
        gen.run();
        drv.run();
        mon.run();
        sco.run();
      join_any
    endtask
    
    //post test actions
    task post_test();
      wait(gen.done.triggered);
      $finish();
    endtask
    
    //start the env
    task run();
      pre_test();
      test();
      post_test();
    endtask

endclass
  
  //////////////////////////////////////////////
/// testbench top////////////
  
module tb;
  
  spi_if vif();
  spi dut (vif.clk, vif.newd, vif.rst, vif.din, vif.sclk, vif.cs, vif.mosi);
  
  initial begin
    vif.clk <= 0;
  end
  
  always #10 vif.clk = ~vif.clk;
  environment env;
  
  initial begin
    env = new(vif);
    env.gen.count = 20;
    env.run();
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule
