//=============================================================================
// tb_ctrl_unit - one directed check per opcode.
//
// Owner: Parthraj
//
// STUB. Pure combinational DUT, so no clock: drive instr, wait #1, check.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module tb_ctrl_unit;

    reg  [15:0] instr;
    wire        we, mem_rd, mem_wr, halt;
    wire [2:0]  waddr, raddr1, raddr2, alu_op;

    integer errors = 0;
    integer checks = 0;

    ctrl_unit dut (
        .instr(instr), .we(we), .waddr(waddr), .raddr1(raddr1),
        .raddr2(raddr2), .alu_op(alu_op), .mem_rd(mem_rd),
        .mem_wr(mem_wr), .halt(halt)
    );

    task check;
        input [255:0] name;
        input         e_we, e_rd, e_wr, e_halt;
        input [2:0]   e_alu_op;
        begin
            #1;
            checks = checks + 1;
            if (we !== e_we || mem_rd !== e_rd || mem_wr !== e_wr ||
                halt !== e_halt || alu_op !== e_alu_op) begin
                errors = errors + 1;
                $display("FAIL  %0s: instr=%h -> we=%b rd=%b wr=%b halt=%b alu=%b",
                         name, instr, we, mem_rd, mem_wr, halt, alu_op);
            end else begin
                $display("ok    %0s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/tb_ctrl_unit.vcd");
        $dumpvars(0, tb_ctrl_unit);

        // TODO(parth): one case per opcode, plus the two that catch real bugs.
        // Encodings are in docs/spec.md; these are the benchmark's own words:
        //
        //   instr = 16'h0408;  check("VADD V2,V0,V1", 1,0,0,0, `ALU_ADD);
        //   instr = 16'h8220;  check("VLD V1,4",      1,1,0,0, 3'bxxx);
        //   instr = 16'h9440;  check("VST V2,8",      0,0,1,0, 3'bxxx);
        //   instr = 16'hF000;  check("HALT",          0,0,0,1, 3'bxxx);
        //
        //   instr = 16'h7000;  check("undefined",     0,0,0,0, 3'bxxx);
        //   instr = 16'hxxxx;  check("unknown bits",  0,0,0,0, 3'bxxx);
        //
        // The last two are the ones to not skip: an undefined opcode must not
        // raise we, mem_wr or halt. Relax alu_op out of the check (pass the
        // value the DUT produces) for the instructions where it is a don't
        // care, rather than pretending it is specified.
        //
        // Also assert raddr1 for VST explicitly, whichever convention 4.1
        // settles on - that is the decode detail most likely to be wrong.

        $display("");
        if (errors != 0)
            $display("FAIL  tb_ctrl_unit: %0d error(s) in %0d check(s)", errors, checks);
        else if (checks == 0)
            $display("SKIP  tb_ctrl_unit: no checks written yet - see the TODO above");
        else
            $display("PASS  tb_ctrl_unit: %0d/%0d checks", checks, checks);
        $finish;
    end

endmodule
