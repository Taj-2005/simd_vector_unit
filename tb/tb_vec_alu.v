//=============================================================================
// tb_vec_alu - four lanes computing four different things at once.
//
// Owner: Himanshu
//
// The point of this testbench is lane independence: give every lane a
// different value, and prove lane 2 does not leak into lane 1. Save a GTKWave
// screenshot of this run - it is the 2:00 to 2:40 video slot.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module tb_vec_alu;

    localparam LANES  = 4;
    localparam LANE_W = 32;

    reg  [LANES*LANE_W-1:0] a, b;
    reg  [2:0]              op;
    wire [LANES*LANE_W-1:0] y;

    integer errors = 0;
    integer checks = 0;

    vec_alu #(.LANES(LANES), .LANE_W(LANE_W)) dut (
        .a (a),
        .b (b),
        .op(op),
        .y (y)
    );

    task check;
        input [511:0]              name;
        input [LANES*LANE_W-1:0]   expected;
        begin
            #10;
            checks = checks + 1;
            if (y !== expected) begin
                errors = errors + 1;
                $display("FAIL  %0s: op=%b -> y=%h, expected %h", name, op, y, expected);
            end else begin
                $display("ok    %0s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/tb_vec_alu.vcd");
        $dumpvars(0, tb_vec_alu);

        // Vector layout: {lane 3, lane 2, lane 1, lane 0}

        // Test 1: VADD - 4 distinct additions
        a  = {32'd40, 32'd30, 32'd20, 32'd10};
        b  = {32'd4,  32'd3,  32'd2,  32'd1};
        op = `ALU_ADD;
        check("vadd 4 distinct lanes", {32'd44, 32'd33, 32'd22, 32'd11});

        // Test 2: VSUB - 4 distinct subtractions including signed & wrap
        a  = {32'd15, 32'd0,  32'd50,  32'd100};
        b  = {32'd5,  32'd1,  32'd70,  32'd10};
        op = `ALU_SUB;
        check("vsub with negative and wrap", {32'd10, 32'hFFFFFFFF, -32'd20, 32'd90});

        // Test 3: VAND - distinct bitwise masks
        a  = {32'hFFFF0000, 32'hAAAAAAAA, 32'hF0F0F0F0, 32'h12345678};
        b  = {32'h0000FFFF, 32'h55555555, 32'h0FF00FF0, 32'hFFFFFFFF};
        op = `ALU_AND;
        check("vand independent bitwise", {32'h00000000, 32'h00000000, 32'h00F000F0, 32'h12345678});

        // Test 4: VOR - distinct bitwise combinations
        a  = {32'hF0000000, 32'h00F00000, 32'h0000F000, 32'h000000F0};
        b  = {32'h0F000000, 32'h000F0000, 32'h00000F00, 32'h0000000F};
        op = `ALU_OR;
        check("vor independent bitwise", {32'hFF000000, 32'h00FF0000, 32'h0000FF00, 32'h000000FF});

        // Test 5: VCMPEQ - alternating match/mismatch (0, 1, 0, 1) across lanes
        // Lane 3: 400 == 500 -> 0
        // Lane 2: -50 == -50 -> 1
        // Lane 1: 200 == 201 -> 0
        // Lane 0: 100 == 100 -> 1
        a  = {32'd400, -32'd50, 32'd200, 32'd100};
        b  = {32'd500, -32'd50, 32'd201, 32'd100};
        op = `ALU_CMPEQ;
        check("vcmpeq alternating 0,1,0,1 pattern", {32'd0, 32'd1, 32'd0, 32'd1});

        // Test 6: VCMPLT - signed comparison across lanes
        // Lane 3: -50 < -100 -> 0
        // Lane 2: -100 < -50 -> 1
        // Lane 1: 10 < 5     -> 0
        // Lane 0: -5 < 5     -> 1
        a  = {-32'd50,  -32'd100, 32'd10, -32'd5};
        b  = {-32'd100, -32'd50,  32'd5,   32'd5};
        op = `ALU_CMPLT;
        check("vcmplt signed compare 0,1,0,1 pattern", {32'd0, 32'd1, 32'd0, 32'd1});

        // Test 7: VSHL - independent shift amounts
        a  = {32'd1,  32'd1, 32'd1, 32'd1};
        b  = {32'd16, 32'd8, 32'd4, 32'd1};
        op = `ALU_SHL;
        check("vshl independent shifts", {32'd65536, 32'd256, 32'd16, 32'd2});

        #20;
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
