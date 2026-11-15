//=============================================================================
// tb_dmem - 16 x 128-bit data memory: clocked write, combinational read.
//
// Owner: Satya
//=============================================================================
`timescale 1ns / 1ps

module tb_dmem;

    localparam VEC_W = 128;
    localparam WORDS = 16;

    reg              clk = 1'b0;
    reg              we;
    reg  [3:0]       addr;
    reg  [VEC_W-1:0] wdata;
    wire [VEC_W-1:0] rdata;

    // Second instance, loaded from a hex file, to prove the INIT_FILE path.
    reg  [3:0]       iaddr;
    wire [VEC_W-1:0] irdata;

    integer errors = 0;
    integer checks = 0;
    integer i;

    always #5 clk = ~clk;

    dmem #(.VEC_W(VEC_W), .WORDS(WORDS)) dut (
        .clk(clk), .we(we), .addr(addr), .wdata(wdata), .rdata(rdata)
    );

    dmem #(.VEC_W(VEC_W), .WORDS(WORDS), .INIT_FILE("vectors/dmem_init.hex")) dut_init (
        .clk(clk), .we(1'b0), .addr(iaddr), .wdata({VEC_W{1'b0}}), .rdata(irdata)
    );

    function [VEC_W-1:0] pattern;
        input integer n;
        begin
            pattern = {32'h11110000 + n[31:0], 32'h22220000 + n[31:0],
                       32'h33330000 + n[31:0], 32'h44440000 + n[31:0]};
        end
    endfunction

    task check;
        input [511:0]     name;
        input [VEC_W-1:0] actual;
        input [VEC_W-1:0] expected;
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
        $dumpfile("waves/tb_dmem.vcd");
        $dumpvars(0, tb_dmem);

        we = 0; addr = 0; wdata = 0; iaddr = 0;

        // --- 1. write every word, then read each one back -----------------
        for (i = 0; i < WORDS; i = i + 1) begin
            @(negedge clk);
            we    = 1'b1;
            addr  = i[3:0];
            wdata = pattern(i);
        end
        @(negedge clk);
        we = 1'b0;

        for (i = 0; i < WORDS; i = i + 1) begin
            addr = i[3:0];
            #1;
            check("read back word i", rdata, pattern(i));
        end

        // --- 2. writing word 5 disturbs neither 4 nor 6 -------------------
        @(negedge clk);
        we    = 1'b1;
        addr  = 4'd5;
        wdata = {VEC_W{1'b1}};
        @(negedge clk);
        we = 1'b0;

        addr = 4'd4; #1; check("word 4 undisturbed by write to 5", rdata, pattern(4));
        addr = 4'd6; #1; check("word 6 undisturbed by write to 5", rdata, pattern(6));
        addr = 4'd5; #1; check("word 5 took the new value",        rdata, {VEC_W{1'b1}});

        // --- 3. we = 0 must not write -------------------------------------
        // A write-enable that is ignored is a bug the system test would only
        // find much later, and by then it looks like a control-unit bug.
        @(negedge clk);
        we    = 1'b0;
        addr  = 4'd7;
        wdata = {VEC_W{1'b0}};
        @(negedge clk);
        addr = 4'd7; #1;
        check("we=0 leaves word 7 untouched", rdata, pattern(7));

        // --- 4. the INIT_FILE path actually loaded ------------------------
        // $readmemh silently does nothing when the path is wrong, which is the
        // most common reason a benchmark quietly computes zeros. dmem_init.hex
        // holds A in words 0-3 and B in words 4-7, so word 0 must be non-zero
        // and words 8-11 (never written by the file) must still be zero.
        iaddr = 4'd0; #1;
        checks = checks + 1;
        if (irdata === {VEC_W{1'b0}} || irdata === {VEC_W{1'bx}}) begin
            errors = errors + 1;
            $display("FAIL  INIT_FILE did not load: word 0 = %h", irdata);
        end else begin
            $display("ok    INIT_FILE loaded word 0 = %h", irdata);
        end

        iaddr = 4'd8; #1;
        check("word past the init file is zero, not x", irdata, {VEC_W{1'b0}});

        #10;
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
