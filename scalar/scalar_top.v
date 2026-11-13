//=============================================================================
// scalar_top - the one-ALU baseline the SIMD unit is compared against.
//
// Owner: Jivit (feat/jivit-scalar-top)
// Testbench: tb/tb_scalar_top.v - checks C[i] = A[i] + B[i] for all 16
// Report section: 4.3, baseline and evaluation method
//
// STUB. Reuses Himanshu's lane_alu so the comparison is fair: same adder, same
// synthesis, the only difference is how many of them run per cycle. Building a
// second adder here would make the speed-up number meaningless, and an examiner
// will ask.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module scalar_top #(
    parameter N         = 16,        // elements per array
    parameter DATA_FILE = ""
) (
    input  wire        clk,
    input  wire        rst,
    output wire        done,
    output wire [31:0] cycle_count
);

    // TODO(jivit): implement the baseline loop over N elements:
    //
    //   load A[i] -> load B[i] -> add -> store C[i]
    //
    // State machine, one lane_alu instance, a 32-bit-wide scalar memory, and a
    // cycle counter that follows the same rules as simd_top's. Shape:
    //
    //   localparam S_LDA = 0, S_LDB = 1, S_ADD = 2, S_ST = 3, S_DONE = 4;
    //
    //   lane_alu u_alu (.a(ra), .b(rb), .op(`ALU_ADD), .y(sum));
    //
    // Honesty rule for 4.3, and the thing the whole comparison rests on: count
    // the scalar loads and stores at the same cost as the vector ones. If VLD
    // is one cycle for 4 elements then a scalar load is one cycle for 1
    // element. Four cycles per element against one cycle per vector is a 4x
    // upper bound on a 4-lane machine; if the measured number comes out
    // different, report the measured number and explain the difference - do
    // not tune the counters until they produce 4.00.
    assign done        = 1'b0;
    assign cycle_count = 32'b0;

endmodule
