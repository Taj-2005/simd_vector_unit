//=============================================================================
// instr_mem - program ROM, 16-bit words, loaded with $readmemh.
//
// Owner: Parthraj (feat/parth-instr-mem), program contents agreed with Jivit
//
// STUB. The hex file is a run-time argument, not a compile-time one, so the
// same build runs both benchmark programs in sim/programs/.
//=============================================================================
`timescale 1ns / 1ps

module instr_mem #(
    parameter WORDS     = 64,
    parameter ADDR_W    = 6,
    parameter INIT_FILE = "programs/bench_add16.hex"
) (
    input  wire [ADDR_W-1:0] addr,
    output wire [15:0]       instr
);

    // TODO(parth): implement. Shape:
    //
    //   reg [15:0] rom [0:WORDS-1];
    //   initial begin
    //       integer i;
    //       for (i = 0; i < WORDS; i = i + 1) rom[i] = 16'hF000;   // HALT
    //       $readmemh(INIT_FILE, rom);
    //   end
    //   assign instr = rom[addr];
    //
    // Pre-filling with HALT matters: if the program is shorter than WORDS, a
    // runaway program counter stops the machine instead of executing x and
    // hanging the simulation with no message.
    assign instr = 16'hF000;

endmodule
