//=============================================================================
// tb_ctrl_unit - directed testbench for instruction decode control unit.
//
// Owner: Parthraj Singh Bhati (spec and integration owner)
//
// Tests:
//   - All compute opcodes: VADD, VSUB, VAND, VOR, VCMPEQ, VCMPLT, VSHL (optional)
//   - Memory operations: VLD, VST (asserting vs1 -> raddr1 store source)
//   - Control: HALT
//   - Undefined/unknown opcodes (asserting NOP behaviour: no writes, no halt)
//
// Pure combinational DUT, self-checking, dumps VCD into waves/tb_ctrl_unit.vcd.
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
        .instr  (instr),
        .we     (we),
        .waddr  (waddr),
        .raddr1 (raddr1),
        .raddr2 (raddr2),
        .alu_op (alu_op),
        .mem_rd (mem_rd),
        .mem_wr (mem_wr),
        .halt   (halt)
    );

    task check;
        input [255:0] name;
        input         exp_we;
        input         exp_rd;
        input         exp_wr;
        input         exp_halt;
        input [2:0]   exp_alu_op;
        input [2:0]   exp_waddr;
        input [2:0]   exp_raddr1;
        input [2:0]   exp_raddr2;
        begin
            #1;
            checks = checks + 1;
            if (we !== exp_we || mem_rd !== exp_rd || mem_wr !== exp_wr ||
                halt !== exp_halt || alu_op !== exp_alu_op ||
                waddr !== exp_waddr || raddr1 !== exp_raddr1 || raddr2 !== exp_raddr2) begin
                errors = errors + 1;
                $display("FAIL  %0s: instr=%h -> we=%b rd=%b wr=%b halt=%b alu=%b waddr=%0d raddr1=%0d raddr2=%0d",
                         name, instr, we, mem_rd, mem_wr, halt, alu_op, waddr, raddr1, raddr2);
                $display("      Expected: we=%b rd=%b wr=%b halt=%b alu=%b waddr=%0d raddr1=%0d raddr2=%0d",
                         exp_we, exp_rd, exp_wr, exp_halt, exp_alu_op, exp_waddr, exp_raddr1, exp_raddr2);
            end else begin
                $display("ok    %0s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/tb_ctrl_unit.vcd");
        $dumpvars(0, tb_ctrl_unit);

        // 1. VADD V2, V0, V1: opcode=0000, vd=2, vs1=0, vs2=1
        //    instr = {4'b0000, 3'd2, 3'd0, 3'd1, 3'b000} = 16'h0408
        instr = 16'h0408;
        check("0000 VADD V2, V0, V1", 1'b1, 1'b0, 1'b0, 1'b0, `ALU_ADD, 3'd2, 3'd0, 3'd1);

        // 2. VSUB V3, V4, V5: opcode=0001, vd=3, vs1=4, vs2=5
        //    instr = {4'b0001, 3'd3, 3'd4, 3'd5, 3'b000} = 16'h1728
        instr = 16'h1728;
        check("0001 VSUB V3, V4, V5", 1'b1, 1'b0, 1'b0, 1'b0, `ALU_SUB, 3'd3, 3'd4, 3'd5);

        // 3. VAND V4, V6, V7: opcode=0010, vd=4, vs1=6, vs2=7
        //    instr = {4'b0010, 3'd4, 3'd6, 3'd7, 3'b000} = 16'h29b8
        instr = 16'h29b8;
        check("0010 VAND V4, V6, V7", 1'b1, 1'b0, 1'b0, 1'b0, `ALU_AND, 3'd4, 3'd6, 3'd7);

        // 4. VOR V5, V1, V2: opcode=0011, vd=5, vs1=1, vs2=2
        //    instr = {4'b0011, 3'd5, 3'd1, 3'd2, 3'b000} = 16'h3a50
        instr = 16'h3a50;
        check("0011 VOR V5, V1, V2", 1'b1, 1'b0, 1'b0, 1'b0, `ALU_OR, 3'd5, 3'd1, 3'd2);

        // 5. VCMPEQ V6, V2, V3: opcode=0100, vd=6, vs1=2, vs2=3
        //    instr = {4'b0100, 3'd6, 3'd2, 3'd3, 3'b000} = 16'h4c98
        instr = 16'h4c98;
        check("0100 VCMPEQ V6, V2, V3", 1'b1, 1'b0, 1'b0, 1'b0, `ALU_CMPEQ, 3'd6, 3'd2, 3'd3);

        // 6. VCMPLT V7, V3, V4: opcode=0101, vd=7, vs1=3, vs2=4
        //    instr = {4'b0101, 3'd7, 3'd3, 3'd4, 3'b000} = 16'h5ee0
        instr = 16'h5ee0;
        check("0101 VCMPLT V7, V3, V4", 1'b1, 1'b0, 1'b0, 1'b0, `ALU_CMPLT, 3'd7, 3'd3, 3'd4);

        // 7. VSHL V1, V5, V6: opcode=0110, vd=1, vs1=5, vs2=6 (optional)
        //    instr = {4'b0110, 3'd1, 3'd5, 3'd6, 3'b000} = 16'h6370
        instr = 16'h6370;
        check("0110 VSHL V1, V5, V6 (optional)", 1'b1, 1'b0, 1'b0, 1'b0, `ALU_SHL, 3'd1, 3'd5, 3'd6);

        // 8. VLD V1, addr 4: opcode=1000, vd=1, vs1=0, vs2=0, addr=4
        //    instr = {4'b1000, 3'd1, 3'd0, 2'b00, 4'd4} = 16'h8204
        instr = 16'h8204;
        check("1000 VLD V1, [4]", 1'b1, 1'b1, 1'b0, 1'b0, 3'b000, 3'd1, 3'd0, 3'd0);

        // 9. VST vs1=2, addr 8: opcode=1001, vd=0, vs1=2, addr=8
        //    instr = {4'b1001, 3'd0, 3'd2, 2'b00, 4'd8} = 16'h9088
        //    VST data source is vs1, read via raddr1=2
        instr = 16'h9088;
        check("1001 VST V2, [8] (raddr1=vs1=2)", 1'b0, 1'b0, 1'b1, 1'b0, 3'b000, 3'd0, 3'd2, 3'd1);

        // 10. HALT: opcode=1111
        //     instr = 16'hF000
        instr = 16'hF000;
        check("1111 HALT", 1'b0, 1'b0, 1'b0, 1'b1, 3'b000, 3'd0, 3'd0, 3'd0);

        // 11. Undefined opcode 0111: must behave as NOP (no writes, no halt)
        instr = 16'h7A58;
        check("0111 Undefined (NOP)", 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 3'd5, 3'd1, 3'd3);

        // 12. Undefined opcode 1010: must behave as NOP (no writes, no halt)
        instr = 16'hA123;
        check("1010 Undefined (NOP)", 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 3'd0, 3'd4, 3'd4);

        // 13. Undefined opcode 1100: must behave as NOP (no writes, no halt)
        instr = 16'hCEEE;
        check("1100 Undefined (NOP)", 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 3'd7, 3'd3, 3'd5);

        $display("");
        if (errors != 0) begin
            $display("FAIL  tb_ctrl_unit: %0d error(s) in %0d check(s)", errors, checks);
        end else if (checks == 0) begin
            $display("SKIP  tb_ctrl_unit: no checks written yet");
        end else begin
            $display("PASS  tb_ctrl_unit: %0d/%0d checks", checks, checks);
        end
        $finish;
    end

endmodule
