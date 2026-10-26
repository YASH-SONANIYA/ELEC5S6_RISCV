//==============================================================================
// Module: rvc_imm_gen.v
// Description: Immediate Generator for RV32C, RV64C, and RV128C
//              Supports CI, CIW, CL, CS, CSS, CB, CJ formats + 64/128-bit offsets
//==============================================================================
module rvc_imm_gen #(
    parameter XLEN = 64
)(
    input  wire [15:0]     instr,
    input  wire [4:0]      imm_type,
    output reg  [XLEN-1:0] imm_out
);

    always @(*) begin
        case (imm_type)
            // 1. CI Format: 6-bit signed immediate (C.ADDI, C.LI, C.ANDI, C.ADDIW)
            5'd1:  imm_out = {{(XLEN-6){instr[12]}}, instr[12], instr[6:2]};

            // 2. CI Format: C.LUI (nzimm[17:12] shifted left by 12, sign-extended)
            5'd2:  imm_out = {{(XLEN-18){instr[12]}}, instr[12], instr[6:2], 12'b0};

            // 3. CI Format: C.ADDI16SP (signed immediate scaled by 16)
            5'd3:  imm_out = {{(XLEN-10){instr[12]}}, instr[12], instr[4:3], instr[5], instr[2], instr[6], 4'b0000};

            // 4. CIW Format: C.ADDI4SPN (unsigned immediate scaled by 4)
            5'd4:  imm_out = {{(XLEN-10){1'b0}}, instr[10:7], instr[12:11], instr[5], instr[6], 2'b00};

            // 5. CL Format: C.LW (unsigned word offset scaled by 4)
            5'd5:  imm_out = {{(XLEN-7){1'b0}}, instr[5], instr[12:10], instr[6], 2'b00};

            // 6. CS Format: C.SW (unsigned word offset scaled by 4)
            5'd6:  imm_out = {{(XLEN-7){1'b0}}, instr[5], instr[12], instr[11:10], instr[6], 2'b00};

            // 7. CI Format: C.LWSP (unsigned stack word offset scaled by 4)
            5'd7:  imm_out = {{(XLEN-8){1'b0}}, instr[3:2], instr[12], instr[6:4], 2'b00};

            // 8. CSS Format: C.SWSP (unsigned stack word offset scaled by 4)
            5'd8:  imm_out = {{(XLEN-8){1'b0}}, instr[8:7], instr[12], instr[11:9], 2'b00};

            // 9. CB Format: C.BEQZ / C.BNEZ (signed branch offset scaled by 2)
            5'd9:  imm_out = {{(XLEN-9){instr[12]}}, instr[12], instr[6:5], instr[2], instr[11:10], instr[4:3], 1'b0};

            // 10. CJ Format: C.J / C.JAL (signed jump offset scaled by 2)
            5'd10: imm_out = {{(XLEN-12){instr[12]}}, instr[12], instr[8], instr[10:9], instr[6], instr[7], instr[2], instr[11], instr[5:3], 1'b0};

            // 11. Shift Amount: shamt (C.SLLI, C.SRLI, C.SRAI)
            // In RV128C, shamt == 0 encodes a 64-bit shift
            5'd11: begin
                if (XLEN == 128 && {instr[12], instr[6:2]} == 6'b000000)
                    imm_out = {{(XLEN-7){1'b0}}, 7'd64};
                else
                    imm_out = {{(XLEN-6){1'b0}}, instr[12], instr[6:2]};
            end

            // 12. CL / CS Format (RV64C/RV128C): C.LD / C.SD (unsigned doubleword offset scaled by 8)
            5'd12: imm_out = {{(XLEN-8){1'b0}}, instr[6:5], instr[12:10], 3'b000};

            // 13. CI Format (RV64C/RV128C): C.LDSP (unsigned stack doubleword offset scaled by 8)
            5'd13: imm_out = {{(XLEN-9){1'b0}}, instr[4:2], instr[12], instr[6:5], 3'b000};

            // 14. CSS Format (RV64C/RV128C): C.SDSP (unsigned stack doubleword offset scaled by 8)
            5'd14: imm_out = {{(XLEN-9){1'b0}}, instr[9:7], instr[12:10], 3'b000};

            // 15. CL / CS Format (RV128C): C.LQ / C.SQ (unsigned quadword offset scaled by 16)
            5'd15: imm_out = {{(XLEN-9){1'b0}}, instr[5], instr[6], instr[10], instr[12:11], 4'b0000};

            // 16. CI Format (RV128C): C.LQSP (unsigned stack quadword offset scaled by 16)
            5'd16: imm_out = {{(XLEN-10){1'b0}}, instr[4:2], instr[12], instr[6], 4'b0000};

            // 17. CSS Format (RV128C): C.SQSP (unsigned stack quadword offset scaled by 16)
            5'd17: imm_out = {{(XLEN-10){1'b0}}, instr[9:7], instr[12:11], 4'b0000};

            default: imm_out = {XLEN{1'b0}};
        endcase
    end

endmodule