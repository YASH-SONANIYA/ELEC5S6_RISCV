//==============================================================================
// Module: rvc_alu.v
// Description: Parameterized ALU supporting RV32C, RV64C, and RV128C
//              Includes ADDW and SUBW 32-bit sign-extended word operations
//==============================================================================
module rvc_alu #(
    parameter XLEN = 64
)(
    input  wire [XLEN-1:0] a,
    input  wire [XLEN-1:0] b,
    input  wire [3:0]      alu_op,
    output reg  [XLEN-1:0] alu_out,
    output wire            zero
);

    wire [31:0] addw_res = a[31:0] + b[31:0];
    wire [31:0] subw_res = a[31:0] - b[31:0];

    always @(*) begin
        case (alu_op)
            4'd0: alu_out = a + b;                                      // ADD
            4'd1: alu_out = a - b;                                      // SUB
            4'd2: alu_out = a & b;                                      // AND
            4'd3: alu_out = a | b;                                      // OR
            4'd4: alu_out = a ^ b;                                      // XOR
            4'd5: alu_out = a >> b[6:0];                                // SRL
            4'd6: alu_out = $signed(a) >>> b[6:0];                      // SRA
            4'd7: alu_out = b;                                          // PASS B (C.LUI)
            4'd8: alu_out = a << b[6:0];                                // SLL
            4'd9: alu_out = {{(XLEN-32){addw_res[31]}}, addw_res};      // ADDW / ADDIW (RV64C/128C)
            4'd10:alu_out = {{(XLEN-32){subw_res[31]}}, subw_res};      // SUBW (RV64C/128C)
            default: alu_out = {XLEN{1'b0}};
        endcase
    end

    assign zero = (alu_out == {XLEN{1'b0}});

endmodule