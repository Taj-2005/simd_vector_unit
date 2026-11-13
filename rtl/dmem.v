//=============================================================================
// dmem - 16 words of 128 bits. Clocked write, combinational read.
//
// Owner: Satya (feat/satya-dmem)
// Testbench: tb/tb_dmem.v
//
// STUB. INIT_FILE is loaded with $readmemh so the benchmark data can be set
// from sim/vectors/ without recompiling.
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

    // TODO(satya): implement. Shape:
    //
    //   reg [VEC_W-1:0] mem [0:WORDS-1];
    //   initial if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
    //   always @(posedge clk) if (we) mem[addr] <= wdata;
    //   assign rdata = mem[addr];
    //
    // $readmemh fills from index 0 upward and leaves untouched words as x.
    // The benchmark layout in docs/spec.md is A at words 0-3, B at 4-7,
    // C at 8-11, so an init file of 8 lines is correct and expected.
    assign rdata = {VEC_W{1'b0}};

endmodule
