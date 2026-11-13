//=============================================================================
// vreg_file - 8 vector registers of 128 bits, 2 read ports, 1 write port.
//
// Owner: Satya (feat/satya-vreg-file)
// Testbench: tb/tb_vreg_file.v
// Report section: 4.2 contributes the register-file paragraph and waveform
//
// STUB. Push the port list early even if the body is unfinished: Parth cannot
// wire simd_top without it.
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

    // TODO(satya): implement. Shape:
    //
    //   reg [VEC_W-1:0] regs [0:NREGS-1];
    //   always @(posedge clk) if (we) regs[waddr] <= wdata;
    //   assign rdata1 = regs[raddr1];      // combinational reads
    //   assign rdata2 = regs[raddr2];
    //
    // Decide and write down in the report which behaviour you chose for a read
    // and a write to the same address in the same cycle. With clocked write and
    // combinational read the read returns the OLD value; the testbench must
    // assert exactly that, and simd_top's timing depends on it.
    assign rdata1 = {VEC_W{1'b0}};
    assign rdata2 = {VEC_W{1'b0}};

endmodule
