//==============================================================================
// Module: riscv_16bit_core.v
// Description: Top-Level Parameterized Compressed RISC-V Core
//              Set XLEN = 32 (RV32C), 64 (RV64C), or 128 (RV128C)
//==============================================================================
module riscv_16bit_core #(
    parameter XLEN = 64
)(
    input  wire            clk,
    input  wire            rst_n,
    input  wire [15:0]     instr,
    output wire [XLEN-1:0] pc,
    output wire [XLEN-1:0] alu_result,
    output wire [XLEN-1:0] wb_data_out,
    output wire            illegal_op
);

    wire [4:0] rs1_addr;
    wire [4:0] rs2_addr;
    wire [4:0] rd_addr;
    wire [4:0] imm_type;
    wire [3:0] alu_op;
    wire       alu_src;
    wire       reg_write;
    wire       mem_read;
    wire       mem_write;
    wire [1:0] mem_size;
    wire [1:0] wb_sel;
    wire       is_branch;
    wire       branch_cond;
    wire       is_jump;
    wire       is_jumpr;

    wire safe_reg_write = reg_write & ~illegal_op;
    wire safe_mem_write = mem_write & ~illegal_op;

    rvc_decoder #(.XLEN(XLEN)) u_decoder (
        .instr       (instr),
        .rs1_addr    (rs1_addr),
        .rs2_addr    (rs2_addr),
        .rd_addr     (rd_addr),
        .imm_type    (imm_type),
        .alu_op      (alu_op),
        .alu_src     (alu_src),
        .reg_write   (reg_write),
        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .mem_size    (mem_size),
        .wb_sel      (wb_sel),
        .is_branch   (is_branch),
        .branch_cond (branch_cond),
        .is_jump     (is_jump),
        .is_jumpr    (is_jumpr),
        .illegal_op  (illegal_op)
    );

    rvc_datapath #(.XLEN(XLEN)) u_datapath (
        .clk         (clk),
        .rst_n       (rst_n),
        .instr       (instr),
        .rs1_addr    (rs1_addr),
        .rs2_addr    (rs2_addr),
        .rd_addr     (rd_addr),
        .imm_type    (imm_type),
        .alu_op      (alu_op),
        .alu_src     (alu_src),
        .reg_write   (safe_reg_write),
        .mem_read    (mem_read),
        .mem_write   (safe_mem_write),
        .mem_size    (mem_size),
        .wb_sel      (wb_sel),
        .is_branch   (is_branch),
        .branch_cond (branch_cond),
        .is_jump     (is_jump),
        .is_jumpr    (is_jumpr),
        .pc          (pc),
        .alu_result  (alu_result),
        .wb_data_out (wb_data_out)
    );

endmodule