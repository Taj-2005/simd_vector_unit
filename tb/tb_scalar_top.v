//=============================================================================
// tb_scalar_top - the baseline computes C[i] = A[i] + B[i] for all 16 elements.
//
// Owner: Jivit
//
// Checks the result of every element against the Python golden model, not
// against arithmetic done inside this testbench: a testbench that recomputes
// the expected value with the same '+' the DUT uses proves very little.
//=============================================================================
`timescale 1ns / 1ps

module tb_scalar_top;

    localparam N      = 16;
    localparam A_BASE = 0;
    localparam B_BASE = 16;
    localparam C_BASE = 32;

    reg         clk = 1'b0;
    reg         rst;
    wire        done;
    wire [31:0] cycle_count;

    reg [31:0] exp_scalar [0:N-1];

    integer errors  = 0;
    integer checks  = 0;
    integer timeout = 2000;            // cycles, then give up and say so
    integer waited;
    integer i;

    always #5 clk = ~clk;

    scalar_top #(
        .N(N), .A_BASE(A_BASE), .B_BASE(B_BASE), .C_BASE(C_BASE),
        .DATA_FILE("vectors/scalar_init.hex")
    ) dut (
        .clk(clk), .rst(rst), .done(done), .cycle_count(cycle_count)
    );

    task check;
        input [511:0] name;
        input [31:0]  actual;
        input [31:0]  expected;
        begin
            checks = checks + 1;
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL  %0s: got %h, expected %h", name, actual, expected);
            end else begin
                $display("ok    %0s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/tb_scalar_top.vcd");
        $dumpvars(0, tb_scalar_top);

        $readmemh("vectors/expected_scalar.hex", exp_scalar);
        if (exp_scalar[0] === 32'hxxxxxxxx) begin
            $display("FAIL  could not read vectors/expected_scalar.hex");
            $display("      run  make -C sim vectors  first");
            $finish;
        end

        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;

        // Bounded wait: a stuck state machine must fail the test, not hang CI.
        waited = 0;
        while (done !== 1'b1 && waited < timeout) begin
            @(posedge clk);
            waited = waited + 1;
        end

        if (done !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL  done never asserted within %0d cycles", timeout);
        end else begin
            $display("scalar baseline finished: cycle_count = %0d for N = %0d",
                     cycle_count, N);
        end

        // Every element against the golden model.
        for (i = 0; i < N; i = i + 1) begin
            check("C[i] == A[i] + B[i]", dut.mem[C_BASE + i], exp_scalar[i]);
        end

        // The inputs must be untouched - a store that walked off the end of C
        // would corrupt them and still leave C looking correct.
        checks = checks + 1;
        if (dut.mem[A_BASE] === 32'b0 || dut.mem[B_BASE] === 32'b0) begin
            errors = errors + 1;
            $display("FAIL  input arrays were clobbered");
        end else begin
            $display("ok    input arrays A and B left intact");
        end

        $display("");
        if (errors != 0)
            $display("FAIL  tb_scalar_top: %0d error(s) in %0d check(s)", errors, checks);
        else if (checks == 0)
            $display("SKIP  tb_scalar_top: no checks written yet - see the TODO above");
        else
            $display("PASS  tb_scalar_top: %0d/%0d checks", checks, checks);
        $finish;
    end

endmodule
