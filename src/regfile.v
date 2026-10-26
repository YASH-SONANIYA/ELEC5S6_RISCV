
module regfile #(
    parameter XLEN = 64//DUring instantiation he value xlen can go to 32,64,128 depending on the test cases
)(
    input  wire            clk,
    input  wire            rst_n,
    input  wire            we,
    input  wire [4:0]      rs1_addr,
    input  wire [4:0]      rs2_addr,
    input  wire [4:0]      rd_addr,
    input  wire [XLEN-1:0] wr_data,
    output wire [XLEN-1:0] rs1_data,
    output wire [XLEN-1:0] rs2_data
);

    reg [XLEN-1:0] registers [0:31];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= {XLEN{1'b0}};
            end
        end else if (we && (rd_addr != 5'd0)) begin
            registers[rd_addr] <= wr_data;
        end
    end

    assign rs1_data = (rs1_addr == 5'd0) ? {XLEN{1'b0}} : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? {XLEN{1'b0}} : registers[rs2_addr];

endmodule