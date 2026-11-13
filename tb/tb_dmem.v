//=============================================================================
// tb_dmem - 16 x 128-bit data memory: clocked write, combinational read.
//
// Owner: Satya
//
// STUB.
//=============================================================================
`timescale 1ns / 1ps

module tb_dmem;

    localparam VEC_W = 128;

    reg              clk = 1'b0;
    reg              we;
    reg  [3:0]       addr;
    reg  [VEC_W-1:0] wdata;
    wire [VEC_W-1:0] rdata;

    integer errors = 0;
    integer checks = 0;

    always #5 clk = ~clk;

    dmem #(.VEC_W(VEC_W)) dut (
        .clk(clk), .we(we), .addr(addr), .wdata(wdata), .rdata(rdata)
    );

    initial begin
        $dumpfile("waves/tb_dmem.vcd");
        $dumpvars(0, tb_dmem);

        we = 0; addr = 0; wdata = 0;

        // TODO(satya): write every word, read it back, and check that writing
        // word 5 does not disturb word 4 or word 6. Then check that we = 0
        // leaves memory untouched - a write-enable that is ignored is a bug
        // tb_system will only find much later, and by then it looks like a
        // control-unit bug.
        //
        // Run the INIT_FILE path too: instantiate a second dmem with
        // .INIT_FILE("vectors/a.hex") and check word 0 matches the first line
        // of that file. $readmemh silently does nothing if the path is wrong,
        // which is the most common reason a benchmark produces zeros.

        $display("");
        if (errors != 0)
            $display("FAIL  tb_dmem: %0d error(s) in %0d check(s)", errors, checks);
        else if (checks == 0)
            $display("SKIP  tb_dmem: no checks written yet - see the TODO above");
        else
            $display("PASS  tb_dmem: %0d/%0d checks", checks, checks);
        $finish;
    end

endmodule
