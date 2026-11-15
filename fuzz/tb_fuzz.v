//=============================================================================
// tb_fuzz - harness for the random-program fuzzer.
//
// Owner: Taj. Driven by fuzz/run_fuzz.py, which writes build/prog.hex and
// build/data.hex, runs this, and compares the dumped memory against
// fuzz/isa_sim.py. Not a pass/fail testbench on its own: it only reports what
// the hardware did, and Python decides whether that is right.
//=============================================================================
`timescale 1ns / 1ps

module tb_fuzz;

    localparam TIMEOUT = 5000;

    reg         clk = 1'b0;
    reg         rst;
    wire        done;
    wire [31:0] cycle_count;

    integer i;
    integer waited;

    always #5 clk = ~clk;

    simd_top #(
        .LANES     (4),
        .PROG_FILE ("fuzz/build/prog.hex"),
        .DATA_FILE ("fuzz/build/data.hex")
    ) dut (
        .clk(clk), .rst(rst), .done(done), .cycle_count(cycle_count)
    );

    initial begin
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;

        waited = 0;
        while (done !== 1'b1 && waited < TIMEOUT) begin
            @(posedge clk);
            waited = waited + 1;
        end

        if (done !== 1'b1) begin
            $display("HANG");       // the machine never halted
            $finish;
        end

        $display("CYCLES %0d", cycle_count);
        for (i = 0; i < 16; i = i + 1) begin
            $display("MEM %0d %h", i, dut.u_dmem.mem[i]);
        end
        $display("END");
        $finish;
    end

endmodule
