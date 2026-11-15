//=============================================================================
// tb_vreg_file - write all 8 registers, read both ports, read and write in the
// same cycle.
//
// Owner: Satya
//
// The VCD this produces is the register-file waveform for the report and for
// the 1:25 to 2:00 video slot.
//=============================================================================
`timescale 1ns / 1ps

module tb_vreg_file;

    localparam VEC_W = 128;
    localparam NREGS = 8;

    reg              clk = 1'b0;
    reg              we;
    reg  [2:0]       waddr, raddr1, raddr2;
    reg  [VEC_W-1:0] wdata;
    wire [VEC_W-1:0] rdata1, rdata2;

    integer errors = 0;
    integer checks = 0;
    integer i;

    always #5 clk = ~clk;              // 100 MHz, 10 ns period

    vreg_file #(.VEC_W(VEC_W), .NREGS(NREGS)) dut (
        .clk(clk), .we(we), .waddr(waddr), .wdata(wdata),
        .raddr1(raddr1), .raddr2(raddr2),
        .rdata1(rdata1), .rdata2(rdata2)
    );

    // Distinct, easily recognised contents for register n.
    function [VEC_W-1:0] pattern;
        input integer n;
        begin
            pattern = {32'hA0000000 + n[31:0], 32'hB0000000 + n[31:0],
                       32'hC0000000 + n[31:0], 32'hD0000000 + n[31:0]};
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
        $dumpfile("waves/tb_vreg_file.vcd");
        $dumpvars(0, tb_vreg_file);

        we = 0; waddr = 0; wdata = 0; raddr1 = 0; raddr2 = 0;

        // --- 1. write all 8 registers -------------------------------------
        for (i = 0; i < NREGS; i = i + 1) begin
            @(negedge clk);
            we    = 1'b1;
            waddr = i[2:0];
            wdata = pattern(i);
        end
        @(negedge clk);
        we = 1'b0;

        // --- 2. read every register back on port 1 ------------------------
        for (i = 0; i < NREGS; i = i + 1) begin
            raddr1 = i[2:0];
            #1;
            check("read back V[i] on port 1", rdata1, pattern(i));
        end

        // --- 3. both ports read different registers in the same cycle -----
        // This is what "2 read ports" has to mean: V2 and V5 must come out
        // together, not one after the other.
        raddr1 = 3'd2;
        raddr2 = 3'd5;
        #1;
        check("port 1 reads V2 concurrently", rdata1, pattern(2));
        check("port 2 reads V5 concurrently", rdata2, pattern(5));

        // --- 4. we = 0 must not write -------------------------------------
        @(negedge clk);
        we    = 1'b0;
        waddr = 3'd3;
        wdata = {VEC_W{1'b1}};
        @(negedge clk);
        raddr1 = 3'd3;
        #1;
        check("we=0 leaves V3 untouched", rdata1, pattern(3));

        // --- 5. read-during-write returns the OLD value -------------------
        // Frozen behaviour: the write commits on the clock edge, the reads are
        // combinational, so a read of the register being written in the SAME
        // cycle sees the old contents. simd_top's timing depends on this, so
        // the testbench asserts it rather than leaving it implied.
        @(negedge clk);
        we     = 1'b1;
        waddr  = 3'd4;
        wdata  = {VEC_W{1'b1}};
        raddr1 = 3'd4;
        #1;
        check("read-during-write returns OLD value", rdata1, pattern(4));

        @(posedge clk);              // the write commits here
        #1;
        we = 1'b0;
        check("new value visible after the clock edge", rdata1, {VEC_W{1'b1}});

        // --- 6. writing one register disturbs no other --------------------
        raddr1 = 3'd3;
        raddr2 = 3'd5;
        #1;
        check("neighbour V3 undisturbed", rdata1, pattern(3));
        check("neighbour V5 undisturbed", rdata2, pattern(5));

        #10;
        $display("");
        if (errors != 0)
            $display("FAIL  tb_vreg_file: %0d error(s) in %0d check(s)", errors, checks);
        else if (checks == 0)
            $display("SKIP  tb_vreg_file: no checks written yet - see the TODO above");
        else
            $display("PASS  tb_vreg_file: %0d/%0d checks", checks, checks);
        $finish;
    end

endmodule
