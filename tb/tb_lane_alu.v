//=============================================================================
// tb_lane_alu - directed tests for the 32-bit ALU lane.
//
// Owner: Himanshu (same person who writes the module - you test your own RTL)
//
// STUB. Required coverage, from the work plan: every op, zero, maximum and
// negative values, equal and unequal compares.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module tb_lane_alu;

    reg  [31:0] a, b;
    reg  [2:0]  op;
    wire [31:0] y;

    integer errors = 0;
    integer checks = 0;

    lane_alu dut (.a(a), .b(b), .op(op), .y(y));

    // One check, one line of output. Keep the format identical in every
    // testbench so the CI log is readable and the video shows one style.
    task check;
        input [255:0] name;
        input [31:0]  expected;
        begin
            #1;
            checks = checks + 1;
            if (y !== expected) begin
                errors = errors + 1;
                $display("FAIL  %0s: a=%h b=%h op=%b -> y=%h, expected %h",
                         name, a, b, op, y, expected);
            end else begin
                $display("ok    %0s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/tb_lane_alu.vcd");
        $dumpvars(0, tb_lane_alu);

        // TODO(himanshu): fill in the cases. Examples of the ones that matter:
        //
        //   a = 32'd7;  b = 32'd5;  op = `ALU_ADD;   check("add",        32'd12);
        //   a = 32'd5;  b = 32'd7;  op = `ALU_SUB;   check("sub neg",    -32'd2);
        //   a = 32'hFFFFFFFF; b = 32'd1; op = `ALU_ADD; check("wrap",    32'd0);
        //   a = 32'hF0F0F0F0; b = 32'h0FF00FF0; op = `ALU_AND; check("and", 32'h00F000F0);
        //   a = 32'd4;  b = 32'd4;  op = `ALU_CMPEQ; check("eq true",   32'd1);
        //   a = 32'd4;  b = 32'd5;  op = `ALU_CMPEQ; check("eq false",  32'd0);
        //   a = -32'd1; b = 32'd1;  op = `ALU_CMPLT; check("signed lt", 32'd1);
        //   a = 32'd1;  b = -32'd1; op = `ALU_CMPLT; check("signed ge", 32'd0);
        //
        // That last pair is the one worth having: an unsigned comparator passes
        // every other case and fails exactly these two.

        $display("");
        if (errors != 0)
            $display("FAIL  tb_lane_alu: %0d error(s) in %0d check(s)", errors, checks);
        else if (checks == 0)
            $display("SKIP  tb_lane_alu: no checks written yet - see the TODO above");
        else
            $display("PASS  tb_lane_alu: %0d/%0d checks", checks, checks);
        $finish;
    end

endmodule
