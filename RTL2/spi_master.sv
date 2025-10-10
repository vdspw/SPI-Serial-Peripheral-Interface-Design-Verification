// SPI master 
module spi(
  input clk,newd,rst, // global signals clk and reset and new data bit.
  input [11:0] din,  // data bus 12 bit wide
  output reg sclk,cs,mosi //sclk,chip select and mosi

);
  
  typedef enum bit[1:0]
  { idle = 2'b00,enable = 2'b01, send = 2'b10, comp = 2'b11} //state od operation.
  state_type;
  
  state_type state = idle; // initialized to IDLE state.
  
  int countc = 0;
  int count = 0;
  
////generation of sclk//////////// 4x slower than the surce clk.
  always@(posedge clk) begin
    if(rst == 1'b1)begin
      countc <=0;
      sclk <= 1'b0;
    end
    else begin
      if(count < 10) begin
        countc <= countc+1;
      end
      else begin
        countc <= 0;
        sclk <= ~sclk;
      end
    end
    
  end
  
  //state machine logic///////////////
  reg [11:0] temp;
  
  always@(posedge sclk)begin
    if(rst ==1'b1)begin
      cs <= 1'b1;  //this disbale the operation 
      mosi <= 1'b0; // hence the O/P is zero.
    end
    else begin
      case(state)
        idle: begin
          		if(newd == 1'b1)begin
                  state <= send;
                  cs <= 1'b0;
                  temp <= din; // data in fills the temp.
          		end
          		else begin
                  state <= idle;
                  temp <= 8'h00; // should have all zeros 
                end
        	  end
        
        send :begin
          if(count <= 11) begin //count less than or equal to 11.
            mosi <= temp[count]; // LSB is sent first.
            count = count +1; // increment
          		 end
          else begin
            count <= 0;		// refersh the count register.
            state <= idle; // go back to IDLE state.
            cs <= 1'b1;	  // chip select is made HIGH diabling further transactions
            mosi <= 1'b0; // output is made zero 
          end
        	  end
        default : state <= idle;
      endcase
    end
  end
  
endmodule
  
