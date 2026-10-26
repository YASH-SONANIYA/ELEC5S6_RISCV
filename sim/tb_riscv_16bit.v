`timescale 1ns / 1ps

//==============================================================================
// Module: tb_riscv_16bit.v
// Description: Multi-Architecture Self-Checking Testbench
//              Verifies RV32C, RV64C, and RV128C simultaneously
//==============================================================================
module tb_riscv_16bit;

    reg         clk;
    reg         rst_n;

    //--------------------------------------------------------------------------
    // Core 1: RV32C Signals & Instance
    //--------------------------------------------------------------------------
    wire [15:0]  instr;
    wire [31:0]  pc;
    wire [31:0]  alu_result;
    wire [31:0]  wb_data_out;
    wire         illegal_op;

    reg  [15:0]  imem [0:63];
    assign instr = imem[pc[6:1]];

    riscv_16bit_core #(.XLEN(32)) u_dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .instr       (instr),
        .pc          (pc),
        .alu_result  (alu_result),
        .wb_data_out (wb_data_out),
        .illegal_op  (illegal_op)
    );

    //--------------------------------------------------------------------------
    // Core 2: RV64C Signals & Instance (Tests 64-bit Shifts, C.ADDIW, C.SD, C.LD)
    //--------------------------------------------------------------------------
    wire [15:0]  instr_64;
    wire [63:0]  pc_64;
    wire [63:0]  alu_result_64;
    wire [63:0]  wb_data_out_64;
    wire         illegal_op_64;

    reg  [15:0]  imem_64 [0:63];
    assign instr_64 = imem_64[pc_64[6:1]];

    riscv_16bit_core #(.XLEN(64)) u_dut_rv64 (
        .clk         (clk),
        .rst_n       (rst_n),
        .instr       (instr_64),
        .pc          (pc_64),
        .alu_result  (alu_result_64),
        .wb_data_out (wb_data_out_64),
        .illegal_op  (illegal_op_64)
    );

    //--------------------------------------------------------------------------
    // Core 3: RV128C Instance
    //--------------------------------------------------------------------------
    wire [127:0] pc_128, alu_result_128, wb_data_out_128;
    wire         illegal_op_128;

    riscv_16bit_core #(.XLEN(128)) u_dut_rv128 (
        .clk         (clk),
        .rst_n       (rst_n),
        .instr       (instr_64),
        .pc          (pc_128),
        .alu_result  (alu_result_128),
        .wb_data_out (wb_data_out_128),
        .illegal_op  (illegal_op_128)
    );

    integer i;
    integer pass_count;
    integer fail_count;

    always #5 clk = ~clk;

    initial begin
        $dumpfile("elec5s6_simulation.vcd");
        $dumpvars(0, tb_riscv_16bit);

        clk        = 1'b0;
        rst_n      = 1'b0;
        pass_count = 0;
        fail_count = 0;

        for (i = 0; i < 64; i = i + 1) begin
            imem[i]    = 16'h0001; // C.NOP
            imem_64[i] = 16'h0001; // C.NOP
        end

        //----------------------------------------------------------------------
        // Program 1: RV32C Test Program (CI, CA, CL, CS, CB, CR Formats)
        //----------------------------------------------------------------------
        imem[0]  = 16'h4141; // [CI] C.LI x2, 16       -> x2 = 16
        imem[1]  = 16'h6105; // [CI] C.ADDI16SP x2, 32 -> x2 = 48
        imem[2]  = 16'h443D; // [CI] C.LI x8, 15       -> x8 = 15
        imem[3]  = 16'h44D1; // [CI] C.LI x9, 20       -> x9 = 20
        imem[4]  = 16'h9426; // [CR] C.ADD x8, x9      -> x8 = 35
        imem[5]  = 16'h8C05; // [CA] C.SUB x8, x9      -> x8 = 15
        imem[6]  = 16'h040A; // [CI] C.SLLI x8, 2      -> x8 = 60
        imem[7]  = 16'hC0C0; // [CS] C.SW x8, 4(x9)    -> Mem[24] = 60
        imem[8]  = 16'h40C8; // [CL] C.LW x10, 4(x9)   -> x10 = 60
        imem[9]  = 16'hE111; // [CB] C.BNEZ x10, +4    -> Jump to PC=0x16
        imem[10] = 16'h457D; // [CI] C.LI x10, 31      -> Skipped!
        imem[11] = 16'h85AA; // [CR] C.MV x11, x10     -> x11 = 60
        imem[12] = 16'h9002; // [CR] C.EBREAK

        //----------------------------------------------------------------------
        // Program 2: RV64C & RV128C Test Program (64-bit Shifts, C.ADDIW, C.SD, C.LD)
        //----------------------------------------------------------------------
        imem_64[0] = 16'h440D; // [CI] C.LI x8, 3          -> x8 = 3
        imem_64[1] = 16'h1412; // [CI] C.SLLI x8, 36       -> x8 = 3 << 36 = 64'h30_0000_0000
        imem_64[2] = 16'h44A1; // [CI] C.LI x9, 8          -> x9 = 8 (base addr)
        imem_64[3] = 16'hE480; // [CS] C.SD x8, 8(x9)      -> Mem64[16] = 64'h30_0000_0000
        imem_64[4] = 16'h6488; // [CL] C.LD x10, 8(x9)     -> x10 = 64'h30_0000_0000
        imem_64[5] = 16'h2595; // [CI] C.ADDIW x11, 5      -> x11 = 5 (RV64C/128C specific)
        imem_64[6] = 16'h9002; // [CR] C.EBREAK

        #20;
        rst_n = 1'b1;
        #130;

        $display("==============================================================");
        $display("   UNIFIED RV32C / RV64C / RV128C CORE VERIFICATION REPORT    ");
        $display("==============================================================");

        // RV32C Checks
        if (u_dut.u_datapath.u_rf.registers[2] === 32'd48 &&
            u_dut.u_datapath.u_rf.registers[8] === 32'd60 &&
            u_dut.u_datapath.u_rf.registers[11] === 32'd60) begin
            $display("[PASS] RV32C Core (CR, CI, CA, CL, CS, CB) Verified: x2=48, x8=60, x11=60");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] RV32C Core mismatch!");
            fail_count = fail_count + 1;
        end

        // RV64C 64-bit Shift & Doubleword Load/Store (C.SD / C.LD) Check
        if (u_dut_rv64.u_datapath.u_rf.registers[10] === 64'h00000030_00000000) begin
            $display("[PASS] RV64C 64-bit Shift (C.SLLI 36) + C.SD + C.LD Verified: x10 = 0x%h",
                     u_dut_rv64.u_datapath.u_rf.registers[10]);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] RV64C 64-bit Load/Shift failed! Got 0x%h",
                     u_dut_rv64.u_datapath.u_rf.registers[10]);
            fail_count = fail_count + 1;
        end

        // RV64C C.ADDIW Check
        if (u_dut_rv64.u_datapath.u_rf.registers[11] === 64'd5) begin
            $display("[PASS] RV64C C.ADDIW Verified: x11 = %0d", u_dut_rv64.u_datapath.u_rf.registers[11]);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] RV64C C.ADDIW failed!");
            fail_count = fail_count + 1;
        end

        // RV128C Check
        if (u_dut_rv128.u_datapath.u_rf.registers[10] === 128'h00000000_00000000_00000030_00000000) begin
            $display("[PASS] RV128C Core 128-bit Datapath Verified: x10 = 0x%h",
                     u_dut_rv128.u_datapath.u_rf.registers[10]);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] RV128C Core failed!");
            fail_count = fail_count + 1;
        end

        $display("--------------------------------------------------------------");
        $display("TOTAL ARCHITECTURES PASSED: %0d / 4 | FAILED: %0d", pass_count, fail_count);
        $display("==============================================================");
        $finish;
    end

endmodule