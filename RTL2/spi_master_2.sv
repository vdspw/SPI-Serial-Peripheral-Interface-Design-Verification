// SPI master 
module spi(
  input clk, newd, rst,
  input [11:0] din,
  output reg sclk, cs, mosi
);
  
  typedef enum bit[1:0] {
    idle = 2'b00,
    enable = 2'b01,
    send = 2'b10,
    comp = 2'b11
  } state_type;
  
  state_type state = idle;
  
  int countc = 0;
  int count = 0;
  
  //// Generation of sclk - 4x slower than source clk
  always @(posedge clk) begin
    if (rst == 1'b1) begin
      countc <= 0;
      sclk <= 1'b0;
    end
    else begin
      if (countc < 10) begin      // BUG FIX: was "count < 10", should be "countc < 10"
        countc <= countc + 1;
      end
      else begin
        countc <= 0;
        sclk <= ~sclk;
      end
    end
  end
  
  //// State machine logic
  reg [11:0] temp;
  
  always @(posedge sclk) begin
    if (rst == 1'b1) begin
      cs <= 1'b1;
      mosi <= 1'b0;
      state <= idle;              // BUG FIX: Reset state
      count <= 0;                 // BUG FIX: Reset count
      temp <= 12'h000;            // BUG FIX: Reset temp
    end
    else begin
      case(state)
        idle: begin
          if (newd == 1'b1) begin
            state <= send;
            cs <= 1'b0;
            temp <= din;
          end
          else begin
            state <= idle;
            temp <= 12'h000;      // BUG FIX: was 8'h00, should be 12'h000
          end
        end
        
        send: begin
          if (count <= 11) begin
            mosi <= temp[count];
            count <= count + 1;   // BUG FIX: was "count = count + 1" (blocking), should be "<=" (non-blocking)
          end
          else begin
            count <= 0;
            state <= idle;
            cs <= 1'b1;
            mosi <= 1'b0;
          end
        end
        
        default: state <= idle;
      endcase
    end
  end
  
endmodule
