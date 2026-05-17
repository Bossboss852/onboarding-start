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
reg [2:0] copistore;
reg [1:0] ncsstore;
parameter IDLE = 4'd0, BITINGEST = 4'd2, IGNORE = 4'd3, LAST = 4'd4;
reg [3:0] state;
reg [3:0] next;
reg [3:0] counter;
reg [14:0] ingested;
always @(*) begin
    if ((~ncsstore[1])) begin
      if (state == IDLE) begin
        if (copistore[1]) begin
          next = BITINGEST;
        end else begin
          next = IGNORE;
        end
      end else if (state == BITINGEST) begin
        if (counter == 4'd14) begin
          next = LAST;
        end else begin
          next = BITINGEST;
        end
      end else if (state == IGNORE) begin
        if(counter == 4'd14) begin
          next = IDLE;
        end else begin
          next = IGNORE;
        end
      end else if (state == LAST) begin
        next = IDLE;
      end else begin
        next = IDLE;
      end
    end else begin
      next = IDLE;
    end
end

always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    counter <= 4'd0;
    state <= IDLE;
    clockstore <= 3'd0;
    copistore <= 3'd0;
    ncsstore <= 2'd0;
    ingested <= 15'd0;
    en_reg_out_7_0 <= 8'd0;
    en_reg_out_15_8 <= 8'd0;
    en_reg_pwm_7_0 <= 8'd0;
    en_reg_pwm_15_8 <= 8'd0;
    pwm_duty_cycle <= 8'd0;
  end else begin
    clockstore <= {clockstore[1:0], ui_in[0]};
    // the current sysclock is clockstore[1], last clock cycle is clockstore[2]
    copistore <= {copistore[1:0], ui_in[1]};
    ncsstore <= {ncsstore[0], ui_in[2]};
    // current cycle is any[1]
    if (clockstore[1]&~clockstore[2]) begin
      state <= next;
      if ((state == BITINGEST)|(state == IGNORE)) begin
        counter <= counter + 4'd1;
        ingested <= {ingested[13:0], copistore[1]};
      end else if (state == IDLE) begin
        counter <= 4'd0;
      end else if ((state == IGNORE) & (counter == 4'd14)) begin
        counter <= 4'd0;
      end
    end
    if (state == LAST) begin
        if (ingested[14:8] == 7'd0) begin
            en_reg_out_7_0 <= ingested[7:0];
          end else if (ingested[14:8] == 7'd1) begin
            en_reg_out_15_8 <= ingested[7:0];
          end else if (ingested[14:8] == 7'd2) begin
            en_reg_pwm_7_0 <= ingested[7:0];
          end else if (ingested[14:8] == 7'd3) begin
            en_reg_pwm_15_8 <= ingested[7:0];
          end else if (ingested[14:8] == 7'd4) begin
            pwm_duty_cycle <= ingested[7:0];
          end
          counter <= 4'd0;
          state <= IDLE;
    end
  end
end

endmodule

