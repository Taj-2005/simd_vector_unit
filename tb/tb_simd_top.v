//=============================================================================
// tb_simd_top - integration testbench for 4-lane SIMD Vector Unit.
//
// Owner: Parthraj Singh Bhati (integration owner)
//
// Tests:
//   - Executes sim/prog_demo.hex:
//       0: VLD  V0, [0]     (loads DMEM[0] into V0)
//       1: VLD  V1, [1]     (loads DMEM[1] into V1)
//       2: VADD V2, V0, V1 (adds vectors in parallel)
//       3: VST  V2, [2]     (stores result into DMEM[2])
//       4: HALT             (halts and freezes PC)
//   - Asserts execution halts and done goes high
//   - Asserts cycle_count == 4 (excluding HALT cycle)
//   - Verifies vector stored in DMEM[2] across all 4 lanes
//   - Dumps VCD into waves/tb_simd_top.vcd
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module tb_simd_top;

    localparam LANES = 4;
    localparam VEC_W = LANES * 32;

    reg clk;
    reg rst;
    wire done;
    wire [31:0] cycle_count;

    integer errors = 0;
    integer checks = 0;

    // Clock generator: 100MHz (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT instantiation
    simd_top #(
        .LANES     (LANES),
        .PROG_FILE ("prog_demo.hex"),
        .DATA_FILE ("demo_data.hex")
    ) dut (
        .clk         (clk),
        .rst         (rst),
        .done        (done),
        .cycle_count (cycle_count)
    );

    wire [VEC_W-1:0] result_vec = dut.u_dmem.mem[2];
    wire [31:0] r_lane0 = result_vec[31:0];
    wire [31:0] r_lane1 = result_vec[63:32];
    wire [31:0] r_lane2 = result_vec[95:64];
    wire [31:0] r_lane3 = result_vec[127:96];

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

    initial begin
        $dumpfile("waves/tb_simd_top.vcd");
        $dumpvars(0, tb_simd_top);

        // Reset pulse
        rst = 1'b1;
        #25;
        @(negedge clk);
        rst = 1'b0;

        // Watchdog loop: wait for done or timeout after 50 cycles
        timeout_cnt = 0;
        while (!done && timeout_cnt < 50) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;
        end

        // 1. Check completion flag
        check_condition("done asserted", done === 1'b1, {127'b0, done}, 128'd1);

        // 2. Check cycle counting: 4 instructions before HALT
        check_condition("cycle_count == 4 (excluding HALT cycle)",
                        cycle_count === 32'd4,
                        {96'b0, cycle_count},
                        128'd4);

        // 3. Check Lane 0 result: 1 + 16 = 17 (0x11)
        check_condition("Lane 0 result: DMEM[2][31:0] == 0x00000011",
                        r_lane0 === 32'h00000011,
                        {96'b0, r_lane0},
                        128'h00000011);

        // 4. Check Lane 1 result: 2 + 32 = 34 (0x22)
        check_condition("Lane 1 result: DMEM[2][63:32] == 0x00000022",
                        r_lane1 === 32'h00000022,
                        {96'b0, r_lane1},
                        128'h00000022);

        // 5. Check Lane 2 result: 3 + 48 = 51 (0x33)
        check_condition("Lane 2 result: DMEM[2][95:64] == 0x00000033",
                        r_lane2 === 32'h00000033,
                        {96'b0, r_lane2},
                        128'h00000033);

        // 6. Check Lane 3 result: 4 + 64 = 68 (0x44)
        check_condition("Lane 3 result: DMEM[2][127:96] == 0x00000044",
                        r_lane3 === 32'h00000044,
                        {96'b0, r_lane3},
                        128'h00000044);

        // 7. Full 128-bit vector verification
        check_condition("Full vector DMEM[2] == 0x00000044_00000033_00000022_00000011",
                        result_vec === 128'h00000044_00000033_00000022_00000011,
                        result_vec,
                        128'h00000044_00000033_00000022_00000011);

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
