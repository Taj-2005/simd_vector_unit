//=============================================================================
// dmem - 16 words of 128 bits. Clocked write, combinational read.
//
// Owner: Satya (feat/satya-dmem)
// Testbench: tb/tb_dmem.v
//
// One vector word holds LANES elements side by side, so a single VLD moves 4
// elements in one cycle. That is the whole reason the SIMD machine beats the
// scalar baseline, and it is why the memory is 128 bits wide rather than 32.
//
// COUPLING, do not rename: the storage array must stay
//   reg [VEC_W-1:0] mem [0:WORDS-1]
// because tb/tb_simd_top.v and tb/tb_system.v read results hierarchically
// through u_dmem.mem. See docs/spec.md.
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

    // Zero the array before loading. $readmemh fills from index 0 upward and
    // leaves everything past the end of the file untouched, so without this the
    // benchmark's result words (8-11) would start as x: the store would then be
    // checked against x and the failure would look like a datapath bug rather
    // than an uninitialised memory.
    initial begin
        for (i = 0; i < WORDS; i = i + 1) begin
            mem[i] = {VEC_W{1'b0}};
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // Synchronous write.
    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= wdata;
        end
    end

    // Combinational read, so VLD can load and write back within one cycle.
    assign rdata = mem[addr];

endmodule
