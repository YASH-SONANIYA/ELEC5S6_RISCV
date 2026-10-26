//==============================================================================
// Module: rvc_datapath.v
// Description: Parameterized Datapath for RV32C, RV64C, and RV128C
//==============================================================================
module rvc_datapath #(
    parameter XLEN = 64
)(
    input  wire            clk,
    input  wire            rst_n,
    input  wire [15:0]     instr,
    input  wire [4:0]      rs1_addr,
    input  wire [4:0]      rs2_addr,
    input  wire [4:0]      rd_addr,
    input  wire [4:0]      imm_type,
    input  wire [3:0]      alu_op,
    input  wire            alu_src,
    input  wire            reg_write,
    input  wire            mem_read,
    input  wire            mem_write,
    input  wire [1:0]      mem_size,
    input  wire [1:0]      wb_sel,
    input  wire            is_branch,
    input  wire            branch_cond,
    input  wire            is_jump,
    input  wire            is_jumpr,
    output reg  [XLEN-1:0] pc,
    output wire [XLEN-1:0] alu_result,
    output wire [XLEN-1:0] wb_data_out
);

    wire [XLEN-1:0] rs1_data;
    wire [XLEN-1:0] rs2_data;
    wire [XLEN-1:0] imm_out;
    wire [XLEN-1:0] alu_in_b;
    wire [XLEN-1:0] alu_out;
    wire            alu_zero;
    wire [XLEN-1:0] mem_rdata;
    reg  [XLEN-1:0] wb_data;

    wire [XLEN-1:0] pc_plus_2;
    wire [XLEN-1:0] pc_branch_target;
    wire [XLEN-1:0] next_pc;
    wire            branch_taken;

    regfile #(.XLEN(XLEN)) u_rf (
        .clk      (clk),
        .rst_n    (rst_n),
        .we       (reg_write),
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rd_addr  (rd_addr),
        .wr_data  (wb_data),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    rvc_imm_gen #(.XLEN(XLEN)) u_imm (
        .instr    (instr),
        .imm_type (imm_type),
        .imm_out  (imm_out)
    );

    assign alu_in_b = (alu_src) ? imm_out : rs2_data;

    rvc_alu #(.XLEN(XLEN)) u_alu (
        .a       (rs1_data),
        .b       (alu_in_b),
        .alu_op  (alu_op),
        .alu_out (alu_out),
        .zero    (alu_zero)
    );

    data_mem #(.XLEN(XLEN)) u_dmem (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .mem_size  (mem_size),
        .addr      (alu_out),
        .wr_data   (rs2_data),
        .rd_data   (mem_rdata)
    );

    assign pc_plus_2 = pc + {{(XLEN-2){1'b0}}, 2'd2};

    always @(*) begin
        case (wb_sel)
            2'b00:   wb_data = alu_out;
            2'b01:   wb_data = mem_rdata;
            2'b10:   wb_data = pc_plus_2;
            default: wb_data = alu_out;
        endcase
    end

    assign branch_taken = is_branch & ((branch_cond == 1'b0) ? (rs1_data == {XLEN{1'b0}}) : (rs1_data != {XLEN{1'b0}}));
    assign pc_branch_target = pc + imm_out;

    assign next_pc = (is_jumpr)                ? {rs1_data[XLEN-1:1], 1'b0} :
                     (is_jump || branch_taken) ? pc_branch_target           :
                                                 pc_plus_2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= {XLEN{1'b0}};
        end else begin
            pc <= next_pc;
        end
    end

    assign alu_result  = alu_out;
    assign wb_data_out = wb_data;

endmodule