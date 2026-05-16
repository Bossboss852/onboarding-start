`default_nettype none

module spi (
  input [2:0] ui_in,
  input clk, rst_n,
  output reg [7:0] en_reg_out_7_0,
  output reg [15:8] en_reg_out_15_8,
  output reg [7:0] en_reg_pwm_7_0,
  output reg [15:8] en_reg_pwm_15_8,
  output reg [7:0] pwm_duty_cycle
);

//data is ui_in[1], chip select is ui_in[2], sclk is ui_in[0]
reg [2:0] clockstore;
reg [1:0] copistore;
reg [1:0] ncsstore;
parameter IDLE=0, ADDRESS = 1, BITINGEST = 2, IGNORE = 3, MODE = 4;
reg [3:0] state;
reg [3:0] next;
reg [3:0] counter;
reg [6:0] address;
reg [7:0] data;
always @(*) begin
    if (~ncsstore[1]) begin
      if (state == IDLE) begin
        next = MODE;
      end else if (state == MODE) begin
        if (copistore[1]) begin
          next = ADDRESS;
        end else begin
          next = IGNORE;
        end
      end else if (state == ADDRESS) begin
        if (counter == 7) begin
          next = BITINGEST;
        end else begin
          next = ADDRESS;
        end
      end else if (state == BITINGEST) begin
        if (counter == 15) begin
          next = IDLE;
        end else begin
          next = BITINGEST;
        end
      end else if (state == IGNORE) begin
        if(counter == 15) begin
          next = IDLE;
        end else begin
          next = IGNORE;
        end
      end else begin
        next = MODE;
      end
    end else begin
      next = IDLE;
    end
end

always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    counter <= '0;
    state <= IDLE;
    en_reg_out_7_0 <= '0;
    en_reg_out_15_8 <= '0;
    en_reg_pwm_7_0 <= '0;
    en_reg_pwm_15_8 <= '0;
    pwm_duty_cycle <= '0;
  end else begin
    state <= next;
    clockstore <= {clockstore[1:0], ui_in[0]};
    // the current sysclock is clockstore[1], last clock cycle is clockstore[2]
    copistore <= {copistore[0], ui_in[1]};
    ncsstore <= {ncsstore[0], ui_in[2]};
    // current cycle is any[1]
    if (clockstore[1]&~clockstore[2]) begin
      if ((state == ADDRESS)|(state == BITINGEST)|(state == IGNORE)) begin
        counter <= counter + 1;
      end
      if (state == MODE) begin
        write <= copistore[1];
      end else if (state == ADDRESS) begin
        address[counter] <= copistore[1];
      end else if (state == BITINGEST) begin
        data[(counter-7)] <= copistore[1];
        if (counter == 15) begin
          if (address == 0) begin
            en_reg_out_7_0 <= {data[6:0],copistore[1]};
          end else if (address == 1) begin
            en_reg_out_15_8 <= {data[6:0],copistore[1]};
          end else if (address == 2) begin
            en_reg_pwm_7_0 <= {data[6:0],copistore[1]};
          end else if (address == 3) begin
            en_reg_pwm_15_8 <= {data[6:0],copistore[1]};
          end else if (address == 4) begin
            pwm_duty_cycle <= {data[6:0],copistore[1]};
          end
        end
      end else if (state == IDLE) begin
        counter <= 0;
      end
    end
  end
end

endmodule

