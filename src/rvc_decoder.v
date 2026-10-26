//==============================================================================
// Module: rvc_decoder.v
// Description: Universal Compressed RISC-V Decoder (RV32C / RV64C / RV128C)
//              Explicitly implements CR, CI, CSS, CIW, CL, CS, CA, CB, CJ formats
//==============================================================================
module rvc_decoder #(
    parameter XLEN = 64
)(
    input  wire [15:0] instr,
    output reg  [4:0]  rs1_addr,
    output reg  [4:0]  rs2_addr,
    output reg  [4:0]  rd_addr,
    output reg  [4:0]  imm_type,
    output reg  [3:0]  alu_op,
    output reg         alu_src,
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg  [1:0]  mem_size,   // 00: 32b Word, 01: 64b Double, 10: 128b Quad
    output reg  [1:0]  wb_sel,
    output reg         is_branch,
    output reg         branch_cond,
    output reg         is_jump,
    output reg         is_jumpr,
    output reg         illegal_op
);

    wire [1:0] op     = instr[1:0];
    wire [2:0] funct3 = instr[15:13];

    // Compressed 8-register window mapping (x8 to x15) for CIW, CL, CS, CA, CB formats
    wire [4:0] rd_prime  = {2'b01, instr[4:2]};
    wire [4:0] rs1_prime = {2'b01, instr[9:7]};
    wire [4:0] rs2_prime = {2'b01, instr[4:2]};

    wire nzimm_is_zero = ({instr[12], instr[6:2]} == 6'b000000);

    always @(*) begin
        // Default safe state
        rs1_addr    = instr[11:7];
        rs2_addr    = instr[6:2];
        rd_addr     = instr[11:7];
        imm_type    = 5'd0;
        alu_op      = 4'd0;
        alu_src     = 1'b0;
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_size    = 2'b00;
        wb_sel      = 2'b00;
        is_branch   = 1'b0;
        branch_cond = 1'b0;
        is_jump     = 1'b0;
        is_jumpr    = 1'b0;
        illegal_op  = 1'b0;

        if (instr == 16'h0000 || instr == 16'hFFFF) begin
            illegal_op = 1'b1;
        end else begin
            case (op)
                // =============================================================
                // QUADRANT 00 (CIW, CL, CS Formats)
                // =============================================================
                2'b00: begin
                    case (funct3)
                        // [CIW Format] C.ADDI4SPN
                        3'b000: begin
                            if (instr[12:5] == 8'b0) begin
                                illegal_op = 1'b1;
                            end else begin
                                rs1_addr  = 5'd2; // sp
                                rd_addr   = rd_prime;
                                imm_type  = 5'd4;
                                alu_op    = 4'd0; // ADD
                                alu_src   = 1'b1;
                                reg_write = 1'b1;
                            end
                        end

                        // [CL Format] C.LQ (RV128C Quadword Load)
                        3'b001: begin
                            if (XLEN == 128) begin
                                rs1_addr  = rs1_prime;
                                rd_addr   = rd_prime;
                                imm_type  = 5'd15;
                                alu_op    = 4'd0;
                                alu_src   = 1'b1;
                                mem_read  = 1'b1;
                                mem_size  = 2'b10; // 128-bit
                                reg_write = 1'b1;
                                wb_sel    = 2'b01;
                            end else begin
                                illegal_op = 1'b1;
                            end
                        end

                        // [CL Format] C.LW (32-bit Word Load)
                        3'b010: begin
                            rs1_addr  = rs1_prime;
                            rd_addr   = rd_prime;
                            imm_type  = 5'd5;
                            alu_op    = 4'd0;
                            alu_src   = 1'b1;
                            mem_read  = 1'b1;
                            mem_size  = 2'b00; // 32-bit
                            reg_write = 1'b1;
                            wb_sel    = 2'b01;
                        end

                        // [CL Format] C.LD (RV64C / RV128C 64-bit Doubleword Load)
                        3'b011: begin
                            if (XLEN >= 64) begin
                                rs1_addr  = rs1_prime;
                                rd_addr   = rd_prime;
                                imm_type  = 5'd12;
                                alu_op    = 4'd0;
                                alu_src   = 1'b1;
                                mem_read  = 1'b1;
                                mem_size  = 2'b01; // 64-bit
                                reg_write = 1'b1;
                                wb_sel    = 2'b01;
                            end else begin
                                illegal_op = 1'b1;
                            end
                        end

                        // [CS Format] C.SQ (RV128C Quadword Store)
                        3'b101: begin
                            if (XLEN == 128) begin
                                rs1_addr  = rs1_prime;
                                rs2_addr  = rs2_prime;
                                imm_type  = 5'd15;
                                alu_op    = 4'd0;
                                alu_src   = 1'b1;
                                mem_write = 1'b1;
                                mem_size  = 2'b10; // 128-bit
                            end else begin
                                illegal_op = 1'b1;
                            end
                        end

                        // [CS Format] C.SW (32-bit Word Store)
                        3'b110: begin
                            rs1_addr  = rs1_prime;
                            rs2_addr  = rs2_prime;
                            imm_type  = 5'd6;
                            alu_op    = 4'd0;
                            alu_src   = 1'b1;
                            mem_write = 1'b1;
                            mem_size  = 2'b00; // 32-bit
                        end

                        // [CS Format] C.SD (RV64C / RV128C 64-bit Doubleword Store)
                        3'b111: begin
                            if (XLEN >= 64) begin
                                rs1_addr  = rs1_prime;
                                rs2_addr  = rs2_prime;
                                imm_type  = 5'd12;
                                alu_op    = 4'd0;
                                alu_src   = 1'b1;
                                mem_write = 1'b1;
                                mem_size  = 2'b01; // 64-bit
                            end else begin
                                illegal_op = 1'b1;
                            end
                        end

                        default: illegal_op = 1'b1;
                    endcase
                end

                // =============================================================
                // QUADRANT 01 (CI, CJ, CB, CA Formats)
                // =============================================================
                2'b01: begin
                    case (funct3)
                        // [CI Format] C.NOP / C.ADDI
                        3'b000: begin
                            rs1_addr  = instr[11:7];
                            rd_addr   = instr[11:7];
                            imm_type  = 5'd1;
                            alu_op    = 4'd0; // ADD
                            alu_src   = 1'b1;
                            reg_write = (instr[11:7] != 5'd0);
                        end

                        // [CJ Format in RV32C: C.JAL] / [CI Format in RV64C/128C: C.ADDIW]
                        3'b001: begin
                            if (XLEN == 32) begin
                                rd_addr   = 5'd1; // x1 (ra)
                                imm_type  = 5'd10;
                                is_jump   = 1'b1;
                                reg_write = 1'b1;
                                wb_sel    = 2'b10; // PC + 2
                            end else begin
                                // RV64C / RV128C: C.ADDIW (Add 32-bit word immediate & sign-extend)
                                if (instr[11:7] == 5'd0) begin
                                    illegal_op = 1'b1; // rd = 0 is reserved for C.ADDIW
                                end else begin
                                    rs1_addr  = instr[11:7];
                                    rd_addr   = instr[11:7];
                                    imm_type  = 5'd1;
                                    alu_op    = 4'd9; // ADDW
                                    alu_src   = 1'b1;
                                    reg_write = 1'b1;
                                end
                            end
                        end

                        // [CI Format] C.LI
                        3'b010: begin
                            rs1_addr  = 5'd0;
                            rd_addr   = instr[11:7];
                            imm_type  = 5'd1;
                            alu_op    = 4'd0;
                            alu_src   = 1'b1;
                            reg_write = (instr[11:7] != 5'd0);
                        end

                        // [CI Format] C.ADDI16SP / C.LUI
                        3'b011: begin
                            if (instr[11:7] == 5'd0 || nzimm_is_zero) begin
                                illegal_op = 1'b1;
                            end else if (instr[11:7] == 5'd2) begin
                                rs1_addr  = 5'd2;
                                rd_addr   = 5'd2;
                                imm_type  = 5'd3;
                                alu_op    = 4'd0;
                                alu_src   = 1'b1;
                                reg_write = 1'b1;
                            end else begin
                                rd_addr   = instr[11:7];
                                imm_type  = 5'd2;
                                alu_op    = 4'd7; // PASS B
                                alu_src   = 1'b1;
                                reg_write = 1'b1;
                            end
                        end

                        // [CB & CA Formats] Shifts, ANDI, and Register-Register Arithmetic
                        3'b100: begin
                            rs1_addr = rs1_prime;
                            rd_addr  = rs1_prime;
                            case (instr[11:10])
                                // [CB Format] C.SRLI
                                2'b00: begin
                                    if (XLEN == 32 && instr[12] == 1'b1) begin
                                        illegal_op = 1'b1;
                                    end else begin
                                        imm_type  = 5'd11;
                                        alu_op    = 4'd5; // SRL
                                        alu_src   = 1'b1;
                                        reg_write = 1'b1;
                                    end
                                end
                                // [CB Format] C.SRAI
                                2'b01: begin
                                    if (XLEN == 32 && instr[12] == 1'b1) begin
                                        illegal_op = 1'b1;
                                    end else begin
                                        imm_type  = 5'd11;
                                        alu_op    = 4'd6; // SRA
                                        alu_src   = 1'b1;
                                        reg_write = 1'b1;
                                    end
                                end
                                // [CB Format] C.ANDI
                                2'b10: begin
                                    imm_type  = 5'd1;
                                    alu_op    = 4'd2; // AND
                                    alu_src   = 1'b1;
                                    reg_write = 1'b1;
                                end
                                // [CA Format] C.SUB, C.XOR, C.OR, C.AND, C.SUBW, C.ADDW
                                2'b11: begin
                                    rs2_addr  = rs2_prime;
                                    alu_src   = 1'b0;
                                    reg_write = 1'b1;
                                    case ({instr[12], instr[6:5]})
                                        3'b000: alu_op = 4'd1; // C.SUB
                                        3'b001: alu_op = 4'd4; // C.XOR
                                        3'b010: alu_op = 4'd3; // C.OR
                                        3'b011: alu_op = 4'd2; // C.AND
                                        3'b100: begin          // C.SUBW (RV64C / RV128C)
                                            if (XLEN >= 64) alu_op = 4'd10;
                                            else begin reg_write = 1'b0; illegal_op = 1'b1; end
                                        end
                                        3'b101: begin          // C.ADDW (RV64C / RV128C)
                                            if (XLEN >= 64) alu_op = 4'd9;
                                            else begin reg_write = 1'b0; illegal_op = 1'b1; end
                                        end
                                        default: begin
                                            reg_write  = 1'b0;
                                            illegal_op = 1'b1;
                                        end
                                    endcase
                                end
                            endcase
                        end

                        // [CJ Format] C.J
                        3'b101: begin
                            imm_type = 5'd10;
                            is_jump  = 1'b1;
                        end

                        // [CB Format] C.BEQZ
                        3'b110: begin
                            rs1_addr    = rs1_prime;
                            imm_type    = 5'd9;
                            is_branch   = 1'b1;
                            branch_cond = 1'b0;
                        end

                        // [CB Format] C.BNEZ
                        3'b111: begin
                            rs1_addr    = rs1_prime;
                            imm_type    = 5'd9;
                            is_branch   = 1'b1;
                            branch_cond = 1'b1;
                        end
                    endcase
                end

                // =============================================================
                // QUADRANT 10 (CI, CR, CSS Formats)
                // =============================================================
                2'b10: begin
                    case (funct3)
                        // [CI Format] C.SLLI
                        3'b000: begin
                            if (XLEN == 32 && instr[12] == 1'b1) begin
                                illegal_op = 1'b1;
                            end else begin
                                rs1_addr  = instr[11:7];
                                rd_addr   = instr[11:7];
                                imm_type  = 5'd11;
                                alu_op    = 4'd8; // SLL
                                alu_src   = 1'b1;
                                reg_write = (instr[11:7] != 5'd0);
                            end
                        end

                        // [CI Format] C.LQSP (RV128C Quadword Stack Load)
                        3'b001: begin
                            if (XLEN == 128 && instr[11:7] != 5'd0) begin
                                rs1_addr  = 5'd2;
                                rd_addr   = instr[11:7];
                                imm_type  = 5'd16;
                                alu_op    = 4'd0;
                                alu_src   = 1'b1;
                                mem_read  = 1'b1;
                                mem_size  = 2'b10; // 128-bit
                                reg_write = 1'b1;
                                wb_sel    = 2'b01;
                            end else begin
                                illegal_op = 1'b1;
                            end
                        end

                        // [CI Format] C.LWSP (32-bit Word Stack Load)
                        3'b010: begin
                            if (instr[11:7] == 5'd0) begin
                                illegal_op = 1'b1;
                            end else begin
                                rs1_addr  = 5'd2;
                                rd_addr   = instr[11:7];
                                imm_type  = 5'd7;
                                alu_op    = 4'd0;
                                alu_src   = 1'b1;
                                mem_read  = 1'b1;
                                mem_size  = 2'b00; // 32-bit
                                reg_write = 1'b1;
                                wb_sel    = 2'b01;
                            end
                        end

                        // [CI Format] C.LDSP (RV64C / RV128C 64-bit Doubleword Stack Load)
                        3'b011: begin
                            if (XLEN >= 64 && instr[11:7] != 5'd0) begin
                                rs1_addr  = 5'd2;
                                rd_addr   = instr[11:7];
                                imm_type  = 5'd13;
                                alu_op    = 4'd0;
                                alu_src   = 1'b1;
                                mem_read  = 1'b1;
                                mem_size  = 2'b01; // 64-bit
                                reg_write = 1'b1;
                                wb_sel    = 2'b01;
                            end else begin
                                illegal_op = 1'b1;
                            end
                        end

                        // [CR Format] C.JR, C.MV, C.EBREAK, C.JALR, C.ADD
                        3'b100: begin
                            if (instr[12] == 1'b0) begin
                                if (instr[6:2] == 5'd0) begin // [CR] C.JR
                                    if (instr[11:7] == 5'd0) begin
                                        illegal_op = 1'b1;
                                    end else begin
                                        rs1_addr = instr[11:7];
                                        is_jumpr = 1'b1;
                                    end
                                end else begin // [CR] C.MV (rd = rs2)
                                    rs1_addr  = 5'd0;
                                    rs2_addr  = instr[6:2];
                                    rd_addr   = instr[11:7];
                                    alu_op    = 4'd0;
                                    alu_src   = 1'b0;
                                    reg_write = (instr[11:7] != 5'd0);
                                end
                            end else begin
                                if (instr[11:7] == 5'd0 && instr[6:2] == 5'd0) begin
                                    // [CR] C.EBREAK
                                end else if (instr[6:2] == 5'd0) begin // [CR] C.JALR
                                    rs1_addr  = instr[11:7];
                                    rd_addr   = 5'd1;
                                    is_jumpr  = 1'b1;
                                    reg_write = 1'b1;
                                    wb_sel    = 2'b10;
                                end else begin // [CR] C.ADD (rd = rd + rs2)
                                    rs1_addr  = instr[11:7];
                                    rs2_addr  = instr[6:2];
                                    rd_addr   = instr[11:7];
                                    alu_op    = 4'd0;
                                    alu_src   = 1'b0;
                                    reg_write = (instr[11:7] != 5'd0);
                                end
                            end
                        end

                        // [CSS Format] C.SQSP (RV128C Quadword Stack Store)
                        3'b101: begin
                            if (XLEN == 128) begin
                                rs1_addr  = 5'd2;
                                rs2_addr  = instr[6:2];
                                imm_type  = 5'd17;
                                alu_op    = 4'd0;
                                alu_src   = 1'b1;
                                mem_write = 1'b1;
                                mem_size  = 2'b10;
                            end else begin
                                illegal_op = 1'b1;
                            end
                        end

                        // [CSS Format] C.SWSP (32-bit Word Stack Store)
                        3'b110: begin
                            rs1_addr  = 5'd2;
                            rs2_addr  = instr[6:2];
                            imm_type  = 5'd8;
                            alu_op    = 4'd0;
                            alu_src   = 1'b1;
                            mem_write = 1'b1;
                            mem_size  = 2'b00;
                        end

                        // [CSS Format] C.SDSP (RV64C / RV128C 64-bit Doubleword Stack Store)
                        3'b111: begin
                            if (XLEN >= 64) begin
                                rs1_addr  = 5'd2;
                                rs2_addr  = instr[6:2];
                                imm_type  = 5'd14;
                                alu_op    = 4'd0;
                                alu_src   = 1'b1;
                                mem_write = 1'b1;
                                mem_size  = 2'b01;
                            end else begin
                                illegal_op = 1'b1;
                            end
                        end

                        default: illegal_op = 1'b1;
                    endcase
                end

                default: illegal_op = 1'b1;
            endcase
        end
    end

endmodule