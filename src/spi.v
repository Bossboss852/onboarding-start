`default_nettype none

module peripheral (
  input [2:0] ui_in,
  input clk, rst_n
)

//data is ui_in[1], chip select is ui_in[2], sclk is ui_in[0]
reg [2:0] clockstore;
reg [1:0] copistore;
reg [1:0] ncsstore;
localparam maxadress = 4;
parameter IDLE=0, ADDRESS = 1, BITINGEST = 2, IGNORE = 3, MODE = 4;
reg [3:0] state;
reg [3:0] next;
reg [3:0] counter;
reg [6:0] address;
reg [7:0] data;
reg write;
always @(*) begin
    if ((~ncsstore[1])&(state == IDLE)) begin
      next = MODE;
    end else begin
      next = IDLE;
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
    end
end

always @(posedge clk and negedge rst_n) begin
  if (~rst_n) begin
    counter <= 0;
    state <= IDLE;
  end else if begin
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
      end
    end
  end
end

endmodule

