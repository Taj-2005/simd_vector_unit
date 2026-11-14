//=============================================================================
// tb_lane_alu - directed tests for the 32-bit ALU lane.
//
// Owner: Himanshu (same person who writes the module - you test your own RTL)
//
// Required coverage, from the work plan: every op, zero, maximum and
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
        input [511:0] name;
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

        // --- ADD Tests ---
        a = 32'd7;          b = 32'd5;          op = `ALU_ADD; check("add standard",          32'd12);
        a = 32'd0;          b = 32'd42;         op = `ALU_ADD; check("add with zero",         32'd42);
        a = 32'hFFFFFFFF;   b = 32'd1;          op = `ALU_ADD; check("add wrap overflow",     32'd0);
        a = -32'd5;         b = -32'd10;        op = `ALU_ADD; check("add two negatives",     -32'd15);
        a = 32'h7FFFFFFF;   b = 32'd1;          op = `ALU_ADD; check("add max signed pos",    32'h80000000);

        // --- SUB Tests ---
        a = 32'd10;         b = 32'd4;          op = `ALU_SUB; check("sub standard",          32'd6);
        a = 32'd42;         b = 32'd0;          op = `ALU_SUB; check("sub zero",              32'd42);
        a = 32'd5;          b = 32'd7;          op = `ALU_SUB; check("sub negative result",   -32'd2);
        a = 32'd0;          b = 32'd1;          op = `ALU_SUB; check("sub wrap underflow",    32'hFFFFFFFF);
        a = 32'd5;          b = -32'd3;         op = `ALU_SUB; check("sub negative operand",  32'd8);

        // --- AND Tests ---
        a = 32'hF0F0F0F0;   b = 32'h0FF00FF0;   op = `ALU_AND; check("and bitwise mask",      32'h00F000F0);
        a = 32'hAAAAAAAA;   b = 32'h00000000;   op = `ALU_AND; check("and with zero",         32'h00000000);
        a = 32'h12345678;   b = 32'hFFFFFFFF;   op = `ALU_AND; check("and with all ones",     32'h12345678);

        // --- OR Tests ---
        a = 32'hF0F00000;   b = 32'h00000F0F;   op = `ALU_OR;  check("or bitwise combine",    32'hF0F00F0F);
        a = 32'h12345678;   b = 32'h00000000;   op = `ALU_OR;  check("or with zero",          32'h12345678);
        a = 32'h12345678;   b = 32'hFFFFFFFF;   op = `ALU_OR;  check("or with all ones",      32'hFFFFFFFF);

        // --- CMPEQ Tests ---
        a = 32'd4;          b = 32'd4;          op = `ALU_CMPEQ; check("cmpeq true positive",   32'd1);
        a = 32'd4;          b = 32'd5;          op = `ALU_CMPEQ; check("cmpeq false positive",  32'd0);
        a = -32'd10;        b = -32'd10;        op = `ALU_CMPEQ; check("cmpeq true negative",   32'd1);
        a = -32'd10;        b = -32'd5;         op = `ALU_CMPEQ; check("cmpeq false negative",  32'd0);
        a = 32'h00000000;   b = 32'h00000000;   op = `ALU_CMPEQ; check("cmpeq zero",            32'd1);
        a = 32'hFFFFFFFF;   b = 32'hFFFFFFFF;   op = `ALU_CMPEQ; check("cmpeq max uint",        32'd1);

        // --- CMPLT Tests (Signed) ---
        a = -32'd1;         b = 32'd1;          op = `ALU_CMPLT; check("cmplt signed neg < pos", 32'd1);
        a = 32'd1;          b = -32'd1;         op = `ALU_CMPLT; check("cmplt signed pos < neg", 32'd0);
        a = -32'd10;        b = -32'd5;         op = `ALU_CMPLT; check("cmplt two negatives lt", 32'd1);
        a = -32'd5;         b = -32'd10;        op = `ALU_CMPLT; check("cmplt two negatives ge", 32'd0);
        a = 32'd5;          b = 32'd10;         op = `ALU_CMPLT; check("cmplt two positives lt", 32'd1);
        a = 32'd10;         b = 32'd5;          op = `ALU_CMPLT; check("cmplt two positives ge", 32'd0);
        a = 32'd7;          b = 32'd7;          op = `ALU_CMPLT; check("cmplt equal values",     32'd0);
        a = 32'h80000000;   b = 32'h7FFFFFFF;   op = `ALU_CMPLT; check("cmplt min signed < max", 32'd1);
        a = 32'h7FFFFFFF;   b = 32'h80000000;   op = `ALU_CMPLT; check("cmplt max signed < min", 32'd0);

        // --- SHL Tests (Optional) ---
        a = 32'd1;          b = 32'd4;          op = `ALU_SHL;   check("shl 1 by 4",            32'd16);
        a = 32'd42;         b = 32'd0;          op = `ALU_SHL;   check("shl by 0",              32'd42);
        a = 32'd1;          b = 32'd31;         op = `ALU_SHL;   check("shl by 31",             32'h80000000);
        a = 32'd1;          b = 32'd36;         op = `ALU_SHL;   check("shl masked shift amt",  32'd16);

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
