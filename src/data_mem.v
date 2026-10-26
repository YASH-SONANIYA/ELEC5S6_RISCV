//==============================================================================
// Module: data_mem.v
// Description: Multi-Width Data Memory supporting 32-bit (LW/SW), 
//              64-bit (LD/SD), and 128-bit (LQ/SQ) accesses
//              Safe for XLEN = 32, 64, and 128 elaboration in ModelSim
//==============================================================================
module data_mem #(
    parameter XLEN = 64
)(
    input  wire            clk,
    input  wire            mem_read,
    input  wire            mem_write,
    input  wire [1:0]      mem_size,  // 2'b00: 32-bit Word, 2'b01: 64-bit Doubleword, 2'b10: 128-bit Quadword
    input  wire [XLEN-1:0] addr,
    input  wire [XLEN-1:0] wr_data,
    output reg  [XLEN-1:0] rd_data
);

    // 64 words of 32-bit memory (256 Bytes total)
    reg [31:0] mem [0:63];
    integer i;

    wire [5:0] word_idx = addr[7:2];

    // Zero-pad wr_data up to 128 bits so slices [63:32] and [127:64] are always valid
    wire [127:0] wr_data_ext = {{(128-XLEN){1'b0}}, wr_data};

    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

    // Synchronous Write
    always @(posedge clk) begin
        if (mem_write) begin
            mem[word_idx] <= wr_data_ext[31:0];
            if ((mem_size == 2'b01 || mem_size == 2'b10) && (XLEN >= 64)) begin
                mem[word_idx + 6'd1] <= wr_data_ext[63:32];
            end
            if ((mem_size == 2'b10) && (XLEN == 128)) begin
                mem[word_idx + 6'd2] <= wr_data_ext[95:64];
                mem[word_idx + 6'd3] <= wr_data_ext[127:96];
            end
        end
    end

    // Combinational Read (Sign-extended to 128 bits, then sliced to XLEN)
    wire [31:0] w0 = mem[word_idx];
    wire [31:0] w1 = mem[word_idx + 6'd1];
    wire [31:0] w2 = mem[word_idx + 6'd2];
    wire [31:0] w3 = mem[word_idx + 6'd3];

    reg [127:0] rd_data_128;

    always @(*) begin
        if (!mem_read) begin
            rd_data_128 = 128'd0;
        end else begin
            case (mem_size)
                2'b00:   rd_data_128 = {{96{w0[31]}}, w0};         // 32-bit Word sign-extended
                2'b01:   rd_data_128 = {{64{w1[31]}}, w1, w0};     // 64-bit Doubleword sign-extended
                2'b10:   rd_data_128 = {w3, w2, w1, w0};           // 128-bit Quadword
                default: rd_data_128 = {{96{w0[31]}}, w0};
            endcase
        end
        rd_data = rd_data_128[XLEN-1:0];
    end

endmodule