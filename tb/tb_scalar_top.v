//=============================================================================
// tb_scalar_top - the baseline computes C[i] = A[i] + B[i] for all 16 elements.
//
// Owner: Jivit
//
// STUB. This testbench also produces the scalar half of the comparison table:
// print cycle_count when done goes high and record it in results/.
//=============================================================================
`timescale 1ns / 1ps

module tb_scalar_top;

    reg         clk = 1'b0;
    reg         rst;
    wire        done;
    wire [31:0] cycle_count;

    integer errors  = 0;
    integer checks  = 0;               // increment this in every check, or the
                                       // final line reports SKIP instead of PASS
    integer timeout = 2000;            // cycles, then give up and say so

    always #5 clk = ~clk;

    scalar_top #(.N(16)) dut (
        .clk(clk), .rst(rst), .done(done), .cycle_count(cycle_count)
    );

    initial begin
        $dumpfile("waves/tb_scalar_top.vcd");
        $dumpvars(0, tb_scalar_top);

        rst = 1'b1; repeat (2) @(posedge clk);
        rst = 1'b0;

        // TODO(jivit): wait for done with a bounded wait, never a bare
        // wait(done) - a stuck state machine then hangs CI instead of failing.
        //
        //   fork
        //       begin wait (done); end
        //       begin repeat (timeout) @(posedge clk);
        //             $display("FAIL  timeout after %0d cycles", timeout);
        //             errors = errors + 1; end
        //   join_any
        //   disable fork;
        //
        // Then read C[0..15] out of the scalar memory and check each element
        // against A[i] + B[i] from the same init file the SIMD run uses - the
        // comparison is only fair if both machines ran the same numbers.
        //
        //   $display("scalar cycles for N=16: %0d", cycle_count);

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
