//=============================================================================
// THROWAWAY STUB: dmem (16 x 128-bit data memory)
// Owner of real module: Satya (rtl/dmem.v)
// Used only for early testing of simd_top integration.
//=============================================================================
`timescale 1ns / 1ps

module dmem #(
    parameter WORDS     = 16,
    parameter VEC_W     = 128,
    parameter ADDR_W    = 4,
    parameter INIT_FILE = ""
) (
    input  wire              clk,
    input  wire              we,
    input  wire [ADDR_W-1:0] addr,
    input  wire [VEC_W-1:0]  wdata,
    output wire [VEC_W-1:0]  rdata
);

    reg [VEC_W-1:0] mem [0:WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < WORDS; i = i + 1) begin
            mem[i] = {VEC_W{1'b0}};
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= wdata;
        end
    end

    // Combinational read
    assign rdata = mem[addr];

endmodule
