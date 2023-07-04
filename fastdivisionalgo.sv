module FastDivisionFSM (
  input logic clk,
  input logic rst,
  input logic signed [31:0] dividend,
  input logic signed [31:0] divisor,
  output logic signed [31:0] quotient,
  output logic signed [31:0] remainder,
  output logic valid
);
  typedef enum logic [2:0] {
    IDLE,
    SHIFT,
    SUBTRACT,
    RESTORE
  } State;

  State state;
  logic signed [31:0] quotient_reg;
  logic signed [31:0] remainder_reg;
  logic signed [31:0] dividend_reg;
  logic signed [31:0] divisor_reg;
  logic signed_divisor;
  logic [32:0] remainder_tmp;
  logic [31:0] quotient_tmp;
  logic sign_quotient;
  logic sign_remainder;

  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      state <= IDLE;
      quotient_reg <= 0;
      remainder_reg <= 0;
      dividend_reg <= 0;
      divisor_reg <= 0;
      valid <= 0;
    end else begin
      case (state)
        IDLE:
          if (divisor_reg != 0) begin
            state <= SHIFT;
          end
        SHIFT:
          state <= SUBTRACT;
        SUBTRACT:
          state <= RESTORE;
        RESTORE:
          if (remainder_tmp[32] || (state != RESTORE && remainder_tmp[32:1] >= divisor_reg)) begin
            state <= SHIFT;
          end else begin
            state <= IDLE;
          end
      endcase

      quotient_reg <= quotient_tmp;
      remainder_reg <= remainder_tmp[31:0];
      dividend_reg <= dividend;
      divisor_reg <= divisor;
      valid <= (state == IDLE) ? 1 : 0;
    end
  end

  always_comb begin
    signed_divisor = (divisor_reg < 0);
    sign_quotient = (dividend_reg < 0) ^ (divisor_reg < 0);
    sign_remainder = (dividend_reg < 0);

    case (state)
      IDLE:
        quotient_tmp = 0;
        remainder_tmp = 0;
      SHIFT:
        quotient_tmp = quotient_tmp << 1;
        remainder_tmp = (remainder_tmp << 1) | dividend_reg[31];
      SUBTRACT:
        remainder_tmp = remainder_tmp - (signed_divisor ? -divisor_reg : divisor_reg);
      RESTORE:
        if (remainder_tmp[32] || (state != RESTORE && remainder_tmp[32:1] >= (signed_divisor ? -divisor_reg : divisor_reg))) begin
          quotient_tmp = quotient_tmp | 1;
          remainder_tmp = remainder_tmp + (signed_divisor ? -divisor_reg : divisor_reg);
        end
    endcase

    quotient = (sign_quotient) ? -quotient_reg : quotient_reg;
    remainder = (sign_remainder) ? -remainder_reg : remainder_reg;
  end
endmodule