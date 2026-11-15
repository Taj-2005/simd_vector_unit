//=============================================================================
// THROWAWAY STUB: vreg_file (8 x 128-bit vector registers, 2R1W)
// Owner of real module: Satya (rtl/vreg_file.v)
// Used only for early testing of simd_top integration.
//=============================================================================
`timescale 1ns / 1ps

module vreg_file #(
    parameter NREGS   = 8,
    parameter VEC_W   = 128,
    parameter REG_SEL = 3
) (
    input  wire               clk,
    input  wire               we,
    input  wire [REG_SEL-1:0] waddr,
    input  wire [VEC_W-1:0]   wdata,
    input  wire [REG_SEL-1:0] raddr1,
    input  wire [REG_SEL-1:0] raddr2,
    output wire [VEC_W-1:0]   rdata1,
    output wire [VEC_W-1:0]   rdata2
);

    reg [VEC_W-1:0] regs [0:NREGS-1];
    integer i;

    initial begin
        for (i = 0; i < NREGS; i = i + 1) begin
            regs[i] = {VEC_W{1'b0}};
        end
    end

    always @(posedge clk) begin
        if (we) begin
            regs[waddr] <= wdata;
        end
    end

    // Combinational reads
    assign rdata1 = regs[raddr1];
    assign rdata2 = regs[raddr2];

endmodule
