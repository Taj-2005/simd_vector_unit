//=============================================================================
// tb_simd_top - integration testbench for 4-lane SIMD Vector Unit.
//
// Owner: Parthraj Singh Bhati (integration owner)
//
// Tests:
//   1. Demo Program (sim/programs/prog_demo.hex):
//      Quick smoke test with programs/prog_demo.hex and vectors/demo_data.hex.
//      Checks done, cycle_count == 4, and DMEM[2] lane results.
//   2. 16-Element Benchmark (sim/programs/bench_add16.hex):
//      Headline benchmark with vectors/dmem_init.hex.
//      Checks done, cycle_count == 16, and DMEM[8..11] == DMEM[0..3] + DMEM[4..7].
//   3. Logic Benchmark (sim/programs/bench_logic.hex):
//      Logic operations (AND, OR, CMPEQ, CMPLT) with vectors/dmem_init.hex.
//      Checks done, cycle_count == 10, and DMEM[8..11] == expected_logic.hex.
//
// Dumps VCD into waves/tb_simd_top.vcd.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module tb_simd_top;

    localparam LANES = 4;
    localparam VEC_W = LANES * 32;

    reg clk;
    reg rst_demo;
    reg rst_add16;
    reg rst_logic;

    wire done_demo;
    wire [31:0] cycles_demo;

    wire done_add16;
    wire [31:0] cycles_add16;

    wire done_logic;
    wire [31:0] cycles_logic;

    integer errors = 0;
    integer checks = 0;

    // Clock generator: 100MHz (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // 1. Demo DUT
    simd_top #(
        .LANES     (LANES),
        .PROG_FILE ("programs/prog_demo.hex"),
        .DATA_FILE ("vectors/demo_data.hex")
    ) u_dut_demo (
        .clk         (clk),
        .rst         (rst_demo),
        .done        (done_demo),
        .cycle_count (cycles_demo)
    );

    // 2. Benchmark Add16 DUT
    simd_top #(
        .LANES     (LANES),
        .PROG_FILE ("programs/bench_add16.hex"),
        .DATA_FILE ("vectors/dmem_init.hex")
    ) u_dut_add16 (
        .clk         (clk),
        .rst         (rst_add16),
        .done        (done_add16),
        .cycle_count (cycles_add16)
    );

    // 3. Benchmark Logic DUT
    simd_top #(
        .LANES     (LANES),
        .PROG_FILE ("programs/bench_logic.hex"),
        .DATA_FILE ("vectors/dmem_init.hex")
    ) u_dut_logic (
        .clk         (clk),
        .rst         (rst_logic),
        .done        (done_logic),
        .cycle_count (cycles_logic)
    );

    // Expected vectors loaded from golden vector files
    reg [VEC_W-1:0] exp_add   [0:3];
    reg [VEC_W-1:0] exp_logic [0:3];

    task check_condition;
        input [1023:0] name;
        input          cond;
        input [127:0]  actual;
        input [127:0]  expected;
        begin
            checks = checks + 1;
            if (!cond) begin
                errors = errors + 1;
                $display("FAIL  %0s: actual=%h, expected=%h", name, actual, expected);
            end else begin
                $display("ok    %0s", name);
            end
        end
    endtask

    integer timeout_cnt;
    integer i;

    initial begin
        $dumpfile("waves/tb_simd_top.vcd");
        $dumpvars(0, tb_simd_top);

        $readmemh("vectors/expected_add.hex", exp_add);
        $readmemh("vectors/expected_logic.hex", exp_logic);

        // ---------------------------------------------------------------------
        // Run Demo Program
        // ---------------------------------------------------------------------
        rst_demo  = 1'b1;
        rst_add16 = 1'b1;
        rst_logic = 1'b1;
        #25;
        @(negedge clk);
        rst_demo = 1'b0;

        timeout_cnt = 0;
        while (!done_demo && timeout_cnt < 50) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;
        end

        check_condition("demo: done asserted", done_demo === 1'b1, {127'b0, done_demo}, 128'd1);
        check_condition("demo: cycle_count == 4 (excluding HALT)", cycles_demo === 32'd4, {96'b0, cycles_demo}, 128'd4);
        check_condition("demo: DMEM[2] == 0x00000044_00000033_00000022_00000011",
                        u_dut_demo.u_dmem.mem[2] === 128'h00000044_00000033_00000022_00000011,
                        u_dut_demo.u_dmem.mem[2],
                        128'h00000044_00000033_00000022_00000011);

        // ---------------------------------------------------------------------
        // Run bench_add16.hex
        // ---------------------------------------------------------------------
        @(negedge clk);
        rst_add16 = 1'b0;

        timeout_cnt = 0;
        while (!done_add16 && timeout_cnt < 50) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;
        end

        check_condition("bench_add16: done asserted", done_add16 === 1'b1, {127'b0, done_add16}, 128'd1);
        check_condition("bench_add16: cycle_count == 16 (excluding HALT)",
                        cycles_add16 === 32'd16,
                        {96'b0, cycles_add16},
                        128'd16);

        // Verify dmem[8..11] == dmem[0..3] + dmem[4..7] and matches expected_add.hex
        check_condition("bench_add16: dmem[8] == dmem[0] + dmem[4]",
                        u_dut_add16.u_dmem.mem[8] === exp_add[0],
                        u_dut_add16.u_dmem.mem[8],
                        exp_add[0]);
        check_condition("bench_add16: dmem[9] == dmem[1] + dmem[5]",
                        u_dut_add16.u_dmem.mem[9] === exp_add[1],
                        u_dut_add16.u_dmem.mem[9],
                        exp_add[1]);
        check_condition("bench_add16: dmem[10] == dmem[2] + dmem[6]",
                        u_dut_add16.u_dmem.mem[10] === exp_add[2],
                        u_dut_add16.u_dmem.mem[10],
                        exp_add[2]);
        check_condition("bench_add16: dmem[11] == dmem[3] + dmem[7]",
                        u_dut_add16.u_dmem.mem[11] === exp_add[3],
                        u_dut_add16.u_dmem.mem[11],
                        exp_add[3]);

        // ---------------------------------------------------------------------
        // Run bench_logic.hex
        // ---------------------------------------------------------------------
        @(negedge clk);
        rst_logic = 1'b0;

        timeout_cnt = 0;
        while (!done_logic && timeout_cnt < 50) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;
        end

        check_condition("bench_logic: done asserted", done_logic === 1'b1, {127'b0, done_logic}, 128'd1);
        check_condition("bench_logic: cycle_count == 10 (excluding HALT)",
                        cycles_logic === 32'd10,
                        {96'b0, cycles_logic},
                        128'd10);

        check_condition("bench_logic: dmem[8] (AND) == expected_logic[0]",
                        u_dut_logic.u_dmem.mem[8] === exp_logic[0],
                        u_dut_logic.u_dmem.mem[8],
                        exp_logic[0]);
        check_condition("bench_logic: dmem[9] (OR) == expected_logic[1]",
                        u_dut_logic.u_dmem.mem[9] === exp_logic[1],
                        u_dut_logic.u_dmem.mem[9],
                        exp_logic[1]);
        check_condition("bench_logic: dmem[10] (CMPEQ) == expected_logic[2]",
                        u_dut_logic.u_dmem.mem[10] === exp_logic[2],
                        u_dut_logic.u_dmem.mem[10],
                        exp_logic[2]);
        check_condition("bench_logic: dmem[11] (CMPLT) == expected_logic[3]",
                        u_dut_logic.u_dmem.mem[11] === exp_logic[3],
                        u_dut_logic.u_dmem.mem[11],
                        exp_logic[3]);

        // ---------------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------------
        $display("");
        if (errors != 0) begin
            $display("FAIL  tb_simd_top: %0d error(s) in %0d check(s)", errors, checks);
        end else if (checks == 0) begin
            $display("SKIP  tb_simd_top: no checks executed");
        end else begin
            $display("PASS  tb_simd_top: %0d/%0d checks", checks, checks);
        end

        $finish;
    end

endmodule
