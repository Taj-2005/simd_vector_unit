//=============================================================================
// tb_vec_alu - four lanes computing four different things at once.
//
// Owner: Himanshu
//
// STUB. The point of this testbench is lane independence: give every lane a
// different value, and prove lane 2 does not leak into lane 1. Save a GTKWave
// screenshot of this run - it is the 2:00 to 2:40 video slot.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module tb_vec_alu;

    localparam LANES = 4;

    reg  [LANES*32-1:0] a, b;
    reg  [2:0]          op;
    wire [LANES*32-1:0] y;

    integer errors = 0;
    integer checks = 0;
    integer i;

    vec_alu #(.LANES(LANES)) dut (.a(a), .b(b), .op(op), .y(y));

    initial begin
        $dumpfile("waves/tb_vec_alu.vcd");
        $dumpvars(0, tb_vec_alu);

        // TODO(himanshu): drive four distinct lane pairs and check each lane
        // separately. Lane i lives at bits [i*32 +: 32].
        //
        //   a = {32'd40, 32'd30, 32'd20, 32'd10};   // lane 3 .. lane 0
        //   b = {32'd4,  32'd3,  32'd2,  32'd1};
        //   op = `ALU_ADD; #1;
        //   for (i = 0; i < LANES; i = i + 1)
        //       if (y[i*32 +: 32] !== (a[i*32 +: 32] + b[i*32 +: 32])) errors = errors + 1;
        //
        // Also run one compare op where the lanes disagree - say lanes 0 and 2
        // equal, lanes 1 and 3 not - so the screenshot shows 1,0,1,0 across the
        // lanes rather than four identical values.

        $display("");
        if (errors != 0)
            $display("FAIL  tb_vec_alu: %0d error(s) in %0d check(s)", errors, checks);
        else if (checks == 0)
            $display("SKIP  tb_vec_alu: no checks written yet - see the TODO above");
        else
            $display("PASS  tb_vec_alu: %0d/%0d checks", checks, checks);
        $finish;
    end

endmodule
