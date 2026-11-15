//=============================================================================
// tb_system - golden-model system test for simd_top.
//
// Owner: Taj (feat/taj-system-test)
//
// Runs the integrated machine on both benchmark programs and checks every
// result word against vectors produced by the independent Python golden model
// in golden/. This is the testbench the 2:40-3:25 video slot shows running.
//
// The vectors are generated, never hand-written:
//
//     make -C sim vectors        # golden/gen_vectors.py -> sim/vectors/*.hex
//     make -C sim system
//
// Relationship to tb_simd_top: that one is Parth's integration test and checks
// the machine against values computed inside the testbench. This one checks it
// against an independently derived model. The overlap is deliberate - two
// people deriving "correct" separately is the point, and a disagreement
// between these two testbenches is more informative than either passing alone.
//
// `DUT_DMEM is the only place this reaches inside the DUT, so if the instance
// names in simd_top change, change that one line.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

`define DUT_DMEM(d) d.u_dmem.mem

module tb_system;

    //-------------------------------------------------------------------------
    // Data-memory layout, fixed by docs/spec.md: A at words 0-3, B at 4-7,
    // results at 8-11. Both programs write their results to the same place.
    //-------------------------------------------------------------------------
    localparam LANES   = 4;
    localparam VEC_W   = LANES * 32;
    localparam NVEC    = 4;                 // 16 elements / 4 lanes
    localparam A_BASE  = 0;
    localparam B_BASE  = 4;
    localparam C_BASE  = 8;
    localparam TIMEOUT = 1000;

    // Cycle counts follow docs/cycle_counting.md: one cycle per instruction,
    // HALT excluded. bench_add16 is 17 instructions, bench_logic is 11.
    localparam CYCLES_ADD16 = 16;
    localparam CYCLES_LOGIC = 10;

    // Unsized on purpose: padding a string literal to a fixed-width vector
    // prepends NUL bytes, and $readmemh then fails to open a file whose name
    // looks perfectly correct in the log.
    localparam DATA_FILE = "vectors/dmem_init.hex";

    reg clk = 1'b0;
    reg rst;

    wire        done_add16, done_logic;
    wire [31:0] cycles_add16, cycles_logic;

    reg [VEC_W-1:0] exp_add   [0:NVEC-1];
    reg [VEC_W-1:0] exp_logic [0:NVEC-1];
    reg [VEC_W-1:0] dmem_img  [0:2*NVEC-1];   // the init file holds A and B only

    integer errors = 0;
    integer checks = 0;
    integer waited;
    integer i;

    always #5 clk = ~clk;

    simd_top #(.LANES(LANES), .PROG_FILE("programs/bench_add16.hex"), .DATA_FILE(DATA_FILE))
        dut_add16 (.clk(clk), .rst(rst), .done(done_add16), .cycle_count(cycles_add16));

    simd_top #(.LANES(LANES), .PROG_FILE("programs/bench_logic.hex"), .DATA_FILE(DATA_FILE))
        dut_logic (.clk(clk), .rst(rst), .done(done_logic), .cycle_count(cycles_logic));

    //-------------------------------------------------------------------------
    task check;
        input [511:0]     name;
        input [VEC_W-1:0] actual;
        input [VEC_W-1:0] expected;
        begin
            checks = checks + 1;
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL  %0s", name);
                $display("        got %h", actual);
                $display("       want %h", expected);
            end else begin
                $display("ok    %0s = %h", name, actual);
            end
        end
    endtask

    task check_int;
        input [511:0] name;
        input integer actual;
        input integer expected;
        begin
            checks = checks + 1;
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL  %0s: got %0d, expected %0d", name, actual, expected);
            end else begin
                $display("ok    %0s = %0d", name, actual);
            end
        end
    endtask

    //-------------------------------------------------------------------------
    initial begin
        $dumpfile("waves/tb_system.vcd");
        $dumpvars(0, tb_system);

        $display("");
        $display("tb_system: %0d-lane SIMD against the Python golden model", LANES);
        $display("-------------------------------------------------------------");

        $readmemh("vectors/expected_add.hex",   exp_add);
        $readmemh("vectors/expected_logic.hex", exp_logic);
        $readmemh(DATA_FILE,                    dmem_img);
        if (exp_add[0] === {VEC_W{1'bx}} || exp_logic[0] === {VEC_W{1'bx}}) begin
            $display("FAIL  could not read the golden vectors");
            $display("      run  make -C sim vectors  first");
            $finish;
        end

        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;

        waited = 0;
        while ((done_add16 !== 1'b1 || done_logic !== 1'b1) && waited < TIMEOUT) begin
            @(posedge clk);
            waited = waited + 1;
        end

        if (done_add16 !== 1'b1 || done_logic !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL  a machine never halted within %0d cycles", TIMEOUT);
        end

        // --- bench_add16: C[i] = A[i] + B[i], 16 elements ------------------
        $display("");
        $display("bench_add16 - 16-element array add");
        check_int("cycle count", cycles_add16, CYCLES_ADD16);
        for (i = 0; i < NVEC; i = i + 1) begin
            check("C[i]", `DUT_DMEM(dut_add16)[C_BASE + i], exp_add[i]);
        end
        // A store that walked past C would corrupt the inputs and still leave
        // C looking correct, so check the inputs survived.
        for (i = 0; i < 2 * NVEC; i = i + 1) begin
            check("input word untouched", `DUT_DMEM(dut_add16)[A_BASE + i], dmem_img[i]);
        end

        // --- bench_logic: AND, OR, CMPEQ, CMPLT ----------------------------
        $display("");
        $display("bench_logic - AND, OR, CMPEQ, signed CMPLT");
        check_int("cycle count", cycles_logic, CYCLES_LOGIC);
        check("AND  ", `DUT_DMEM(dut_logic)[C_BASE + 0], exp_logic[0]);
        check("OR   ", `DUT_DMEM(dut_logic)[C_BASE + 1], exp_logic[1]);
        check("CMPEQ", `DUT_DMEM(dut_logic)[C_BASE + 2], exp_logic[2]);
        check("CMPLT", `DUT_DMEM(dut_logic)[C_BASE + 3], exp_logic[3]);

        $display("");
        $display("-------------------------------------------------------------");
        if (errors != 0)
            $display("FAIL  tb_system: %0d error(s) in %0d check(s)", errors, checks);
        else
            $display("PASS  tb_system: %0d/%0d checks against the golden model", checks, checks);
        $display("");
        $finish;
    end

endmodule
