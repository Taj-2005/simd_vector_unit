//=============================================================================
// simd_top - the SIMD machine: fetch, decode, vector register file, vec_alu,
// data memory, cycle counter.
//
// Owner: Parthraj (feat/parth-simd-top) - integration
// Testbenches: tb/tb_system.v (Taj, self-checking against the golden model)
// Report section: 4.1, architecture and control
//
// STUB. Needs vreg_file.v and dmem.v from Satya, vec_alu.v from Himanshu, and
// a hex program from Jivit. Port mismatches get fixed with the module owner,
// never by editing their file.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module simd_top #(
    parameter LANES     = 4,
    parameter PROG_FILE = "programs/bench_add16.hex",
    parameter DATA_FILE = ""
) (
    input  wire        clk,
    input  wire        rst,
    output wire        done,
    output wire [31:0] cycle_count
);

    // TODO(parth): wire it up. One instruction per cycle, no pipeline, so the
    // structure is:
    //
    //   reg [5:0]  pc;
    //   reg [31:0] cycles;
    //   reg        halted;
    //
    //   instr_mem #(.INIT_FILE(PROG_FILE)) u_imem (.addr(pc), .instr(instr));
    //   ctrl_unit                          u_ctrl (.instr(instr), ...);
    //   vreg_file #(.VEC_W(LANES*32))      u_vrf  (...);
    //   vec_alu   #(.LANES(LANES))         u_valu (...);
    //   dmem      #(.INIT_FILE(DATA_FILE)) u_dmem (...);
    //
    //   always @(posedge clk) begin
    //       if (rst) begin pc <= 0; cycles <= 0; halted <= 0; end
    //       else if (!halted) begin
    //           cycles <= cycles + 1;
    //           if (halt) halted <= 1'b1;
    //           else      pc     <= pc + 1'b1;
    //       end
    //   end
    //
    // Three rules the comparison depends on, so they belong in 4.1 and in
    // docs/cycle_counting.md, and scalar_top must follow the same ones:
    //   1. the HALT cycle is counted, and counting stops after it;
    //   2. the write-back of an instruction completes in its own cycle, so a
    //      VST immediately after the VADD that produced the data must read the
    //      new register value - check this against vreg_file's same-cycle
    //      read/write behaviour before you claim the benchmark is correct;
    //   3. cycle_count is only valid once done is high.
    //
    // The write-back mux is the one place VLD and VADD disagree: VLD writes
    // dmem rdata, everything else writes the vec_alu result.
    assign done        = 1'b0;
    assign cycle_count = 32'b0;

endmodule
