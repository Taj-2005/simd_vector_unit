//=============================================================================
// vreg_file - 8 vector registers of 128 bits, 2 read ports, 1 write port.
//
// Owner: Satya (feat/satya-vreg-file)
// Testbench: tb/tb_vreg_file.v
// Report section: 4.2 contributes the register-file paragraph and waveform
//
// Three-operand instructions (vd = vs1 op vs2) need two operands in the same
// cycle, which is why there are two read ports; only one result is produced per
// instruction, so one write port is enough.
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

    // Reset state. Without this the registers start as x, and a program that
    // reads a register before writing it would propagate unknowns into the
    // datapath - which shows up much later as an unexplained system-test
    // failure rather than as an obvious bug here.
    initial begin
        for (i = 0; i < NREGS; i = i + 1) begin
            regs[i] = {VEC_W{1'b0}};
        end
    end

    // Single synchronous write port.
    always @(posedge clk) begin
        if (we) begin
            regs[waddr] <= wdata;
        end
    end

    // Two independent combinational read ports.
    //
    // READ-DURING-WRITE BEHAVIOUR (frozen decision, see docs/spec.md and report
    // section 4.2): because the write commits on the clock edge and the reads
    // are combinational, reading the register being written in the same cycle
    // returns the OLD value. The new value is visible from the next cycle.
    //
    // simd_top depends on this. A VST that immediately follows the VADD which
    // produced its data reads V[vs1] in the cycle after the write commits, so
    // it sees the new value; swapping to write-first (bypass) semantics would
    // change the benchmark's timing and the cycle counts in results/.
    assign rdata1 = regs[raddr1];
    assign rdata2 = regs[raddr2];

endmodule
