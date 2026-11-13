//=============================================================================
// tb_vreg_file - write all 8 registers, read both ports, read and write in the
// same cycle.
//
// Owner: Satya
//
// STUB. The VCD this produces is the register-file waveform for the report and
// for the 1:25 to 2:00 video slot, so dump it even while the checks are thin.
//=============================================================================
`timescale 1ns / 1ps

module tb_vreg_file;

    localparam VEC_W = 128;

    reg          clk = 1'b0;
    reg          we;
    reg  [2:0]   waddr, raddr1, raddr2;
    reg  [VEC_W-1:0] wdata;
    wire [VEC_W-1:0] rdata1, rdata2;

    integer errors = 0;
    integer checks = 0;
    integer i;

    always #5 clk = ~clk;              // 100 MHz, 10 ns period

    vreg_file #(.VEC_W(VEC_W)) dut (
        .clk(clk), .we(we), .waddr(waddr), .wdata(wdata),
        .raddr1(raddr1), .raddr2(raddr2),
        .rdata1(rdata1), .rdata2(rdata2)
    );

    initial begin
        $dumpfile("waves/tb_vreg_file.vcd");
        $dumpvars(0, tb_vreg_file);

        we = 0; waddr = 0; wdata = 0; raddr1 = 0; raddr2 = 0;

        // TODO(satya): three tests.
        //
        // 1. Write a distinct pattern into all 8 registers, then read each one
        //    back on port 1 and on port 2:
        //
        //      for (i = 0; i < 8; i = i + 1) begin
        //          @(negedge clk);
        //          we = 1; waddr = i[2:0];
        //          wdata = {4{32'h1000_0000 + i}};
        //      end
        //
        // 2. Both ports reading different registers in the same cycle return
        //    different data - that is what "2 read ports" has to mean.
        //
        // 3. Read and write the same address in the same cycle. With a clocked
        //    write and a combinational read the read returns the OLD value.
        //    Assert whichever behaviour you implemented, and write the choice
        //    into your report paragraph: simd_top's VST-after-VADD timing
        //    depends on it.

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
