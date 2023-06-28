module Rest_div(
  input clk,
  input rst,
  input [3:0] Q,
  input [3:0] M,
  output [3:0] quot,
  output [3:0] rem,
  output valid
);

  reg [7:0] Acc, next_Acc;
  reg [1:0] next_state, present_state;
  reg [1:0] next_count, count;
  reg next_valid;

  parameter IDLE = 2'b00;
  parameter SHIFT = 2'b01;
  parameter SUBTRACT = 2'b10;
  parameter RESTORE = 2'b11;

  assign rem = (valid == 1'b1) ? Acc[7:4] : 4'b0;
  assign quot = (valid == 1'b1) ? Acc[3:0] : 4'b0;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Acc <= 8'd0;
      valid <= 1'b0;
      present_state <= IDLE;
      count <= 2'b0;
    end else begin
      Acc <= next_Acc;
      valid <= next_valid;
      present_state <= next_state;
      count <= next_count;
    end
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      next_count <= 2'b0;
      next_valid <= 1'b0;
      next_state <= IDLE;
      next_Acc <= 8'd0;
    end else begin
      case (present_state)
        IDLE:
          begin
            next_count <= 2'b0;
            next_valid <= 1'b0;
            if (M != 0) begin
              next_state <= SHIFT;
              next_Acc <= {4'd0, Q};
            end else begin
              next_state <= IDLE;
              next_Acc <= 8'd0;
            end
          end

        SHIFT:
          begin
            next_Acc <= Acc << 1;
            next_state <= SUBTRACT;
          end

        SUBTRACT:
          begin
            next_Acc <= {(Acc[7:4] - M), Acc[3:0]};
            next_state <= RESTORE;
          end

        RESTORE:
          begin
            if (Acc[7] == 1'b1)
              next_Acc <= {(Acc[7:4] - M), Acc[3:1], 1'b0};
            else
              next_Acc <= {Acc[7:4], Acc[3:1], 1'b1};

            next_count <= next_count + 1'b1;

            if (count == 2'b11) begin
              next_state <= IDLE;
              next_valid <= 1'b1;
            end else begin
              next_state <= SHIFT;
              next_valid <= 1'b0;
            end
          end
      endcase
    end
  end

endmodule
