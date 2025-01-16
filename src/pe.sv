module pe(
  input            clk,
  input [7:0]      op_a,
  input [7:0]      op_b,
  input [7:0]      op_c,
  input            op_en,
  input [3:0]      op_i,
  output reg [8:0] result
);

  typedef enum logic [3:0] {ADD, SUB, MUL, MAC} op_t;
  op_t op;

  assign op = op_i;
  always @(posedge clk) begin
    if (op_en) begin
      case (op)
        ADD: result <= op_a + op_b;
        SUB: result <= op_a - op_b;
        MUL: result <= op_a * op_b;
        MAC: result <= op_a * op_b + op_c;
        default: result <= 0;
      endcase
      // pe_if.done <= 1;
    end
  end
endmodule: pe

//---------------------------------------
// Interface for the adder/subtractor DUT
//---------------------------------------
interface pe_if(
  input bit clk,
  input [7:0] a,
  input [7:0] b,
  input [7:0] c,
  input       en,
  input [3:0] op,
  input [8:0] result
);

  clocking cb @(posedge clk);
    output    a;
    output    b;
    output    c;
    output    en;
    output    op;
    input     result;
  endclocking // cb

endinterface: pe_if

//---------------
// Interface bind
//---------------
bind pe pe_if pe_if0(
  .clk(clk),
  .a(op_a),
  .b(op_b),
  .c(op_c),
  .en(op_en),
  .op(op_i),
  .result(result)
);
