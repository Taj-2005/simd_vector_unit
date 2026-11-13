//=============================================================================
// tb_system - self-checking system testbench for simd_top.
//
// Owner: Taj (feat/taj-system-test)
//
// Runs the integrated machine on the 16-element array-add benchmark and
// compares the result words in data memory against vectors produced by the
// Python golden model in golden/. Prints one line per word and a single final
// PASS or FAIL line, which is what the 2:40 to 3:25 video slot shows.
//
// The golden vectors are generated, not hand-written:
//
//     make -C sim vectors        # golden/gen_vectors.py -> sim/vectors/*.hex
//
// While simd_top is still a stub this testbench compiles, runs, and reports
// the result check as SKIP rather than as a false PASS. Turn the check on with
//
//     make -C sim system DEFS=-DDUT_READY
//
// once Parth has simd_top wired up. The macro below is the only place that
// reaches inside the DUT, so if the instance names in simd_top differ, change
// this one line.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

`define DUT_DMEM dut.u_dmem.mem

module tb_system;

    //-------------------------------------------------------------------------
    // Benchmark under test. The data-memory layout is fixed by docs/spec.md:
    // A at words 0-3, B at words 4-7, C at words 8-11.
    //-------------------------------------------------------------------------
    localparam        LANES     = 4;
    localparam        VEC_W     = LANES * 32;
    localparam        NVEC      = 4;              // 16 elements / 4 lanes
    localparam        C_BASE    = 8;
    localparam        TIMEOUT   = 1000;           // cycles
    // Declared without a bit width on purpose: padding a string literal out to
    // a fixed-width vector prepends NUL bytes, and $readmemh then fails to open
    // a file whose name looks correct in the log.
    localparam PROG_FILE = "programs/bench_add16.hex";
    localparam DATA_FILE = "vectors/dmem_init.hex";
    localparam EXP_FILE  = "vectors/expected_add.hex";

    reg         clk = 1'b0;
    reg         rst;
    wire        done;
    wire [31:0] cycle_count;

    reg [VEC_W-1:0] expected [0:NVEC-1];
    reg [VEC_W-1:0] got;

    integer errors = 0;
    integer checks = 0;
    integer cycles_waited;
    integer i;

    always #5 clk = ~clk;                          // 100 MHz

    simd_top #(
        .LANES     (LANES),
        .PROG_FILE (PROG_FILE),
        .DATA_FILE (DATA_FILE)
    ) dut (
        .clk         (clk),
        .rst         (rst),
        .done        (done),
        .cycle_count (cycle_count)
    );

    //-------------------------------------------------------------------------
    // One word of the result, compared against the golden model.
    //-------------------------------------------------------------------------
    task check_word;
        input integer         index;
        input [VEC_W-1:0]     actual;
        input [VEC_W-1:0]     want;
        begin
            checks = checks + 1;
            if (actual !== want) begin
                errors = errors + 1;
                $display("FAIL  C[%0d]: got %h", index, actual);
                $display("              want %h", want);
            end else begin
                $display("ok    C[%0d] = %h", index, actual);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/tb_system.vcd");
        $dumpvars(0, tb_system);

        $display("");
        $display("tb_system: %0d-lane SIMD, program %0s", LANES, PROG_FILE);
        $display("-----------------------------------------------------------");

        // Golden vectors. $readmemh leaves the array at x if the path is wrong,
        // which would otherwise look like a DUT bug - so say it plainly.
        $readmemh(EXP_FILE, expected);
        if (expected[0] === {VEC_W{1'bx}}) begin
            $display("FAIL  could not read %0s", EXP_FILE);
            $display("      run  make -C sim vectors  first");
            $finish;
        end

        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;

        // Bounded wait: a machine that never halts must fail the test, not hang
        // the CI job.
        cycles_waited = 0;
        while (done !== 1'b1 && cycles_waited < TIMEOUT) begin
            @(posedge clk);
            cycles_waited = cycles_waited + 1;
        end

        if (done !== 1'b1) begin
`ifdef DUT_READY
            errors = errors + 1;
            $display("FAIL  done never asserted within %0d cycles", TIMEOUT);
`else
            $display("SKIP  done never asserted - expected while simd_top is a stub");
`endif
        end else begin
            $display("done after %0d simulated cycles, cycle_count = %0d",
                     cycles_waited, cycle_count);
        end

`ifdef DUT_READY
        for (i = 0; i < NVEC; i = i + 1) begin
            got = `DUT_DMEM[C_BASE + i];
            check_word(i, got, expected[i]);
        end
`else
        $display("SKIP  result check: simd_top is still a stub.");
        $display("      enable with  make -C sim system DEFS=-DDUT_READY");
`endif

        $display("-----------------------------------------------------------");
        if (errors == 0 && checks > 0)
            $display("PASS  tb_system: %0d/%0d words match the golden model", checks, checks);
        else if (errors == 0)
            $display("SKIP  tb_system: nothing checked yet");
        else
            $display("FAIL  tb_system: %0d error(s) in %0d check(s)", errors, checks);
        $display("");
        $finish;
    end

endmodule
