// SERIAL PERIPHERAL INTERFACE
module fsm_spi(
  input wire clk,	//system clock (FPGA)
  input wire rst, 	//system reset
  input wire tx_enable, //transaction enable
  output reg mosi,		//Master Out Slave In--Data transmitted
  output reg cs,		// Chip select
  output reg sclk		// Serial clock
);

typedef enum logic [1:0] 
{
  idle = 0,     //IDLE STATE
  start_tx = 1, //WHEN TRANSACTION IS ENABLED
  tx_data =2,   //TRANSACTION STARTED
  end_tx =3		//END OF TRANSACTION
}state_type;

state_type state,next_state; 

reg[7:0] din = 8'b10101010; //the data to be transmitted.

reg spi_clk =0;
reg [2:0] count =0; // 0-7
integer bit_count = 0; 

//////////////////////////////////////////////////////////////////
//generation of sclk
always@(posedge clk)
  begin
    case(next_state)  //wait for 2 counts
      idle:
        begin
          spi_clk <=0; // in IDLE clk is not started
        end
      
      start_tx:   
        begin
          if(count <3'b011 || count == 3'b111) //counter value lesser than 3 or equal to 7
            spi_clk <=1'b1;					// clk ops start.
          else
            spi_clk <=1'b0;
        end
      
      tx_data:
        begin
          if(count <3'b011 || count == 3'b111) // clk op is same as above state. 
            spi_clk <=1'b1;// SPI mode 0 requirements.
          else
            spi_clk <=1'b0;
        end
      
      end_tx:
        begin
          if(count< 3'b011)
            spi_clk <= 1'b1;
          else
            spi_clk <= 1'b0;
          
        end
      
      	default: spi_clk <= 1'b0;
    endcase
      
   end
/////////////////////////////////////////////////////////////////////////
//reset 
always@(posedge clk)
  begin
    if(rst)
      state <= idle;
    else
      state <= next_state;
  end

/////////////////////////////////////////////////////////////////////////
// next state
always@(*)
  begin
    case (state)
      idle:
        begin
          mosi = 1'b0; //masrtoer out slave in is 0
          cs = 1'b1;   // active low signal is HIGH indicates not operational
          if(tx_enable)
            next_state = start_tx; //once transmisttion is enabled
          else
            next_state = idle;
        end
      
      start_tx:
        begin
          cs = 1'b0;	// operation strarts when chip select is 0.(active low)
          if(count == 3'b111)
            next_state = tx_data;
          else 
            next_state = start_tx;
        end
      
      tx_data:
        begin
          mosi = din[7-bit_count]; // transmit the current bit of Din.
          if(bit_count !=8)begin
            next_state = tx_data;
          end
          else begin
            next_state = end_tx;
            mosi = 1'b0;
          end
        end
      
      default: next_state = idle;
      
    endcase
  end

//////////////////////////////////counter////////
always@(posedge clk)
  begin
    case(state)
      
		idle:
          begin
            count <=0;
            bit_count <= 0;
          end
      
      start_tx :
        count <= count+1;
      
      tx_data:
        begin
          if(bit_count !=8)
            begin
              if(count < 3'b111)
                count <= count +1;
              else
                begin
                  count <= 0;
                  bit_count <= bit_count + 1;
                end
            end
        end
      
      end_tx:
        begin
          count <= count +1;
          bit_count <=0;
        end
      
      default:
        begin
          count <= 0;
          bit_count <= 0;
        end
    endcase
  end
/////////////////////////////////////////////////
  assign sclk = spi_clk;
  
endmodule


