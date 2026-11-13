//=============================================================================
// ctrl_unit - decodes one 16-bit instruction into datapath control.
//
// Owner: Parthraj (feat/parth-ctrl-unit)
// Testbench: tb/tb_ctrl_unit.v - one directed check per opcode
// Report section: 4.1, architecture and control
//
// STUB. This module is pure combinational decode: no state, no clock. The
// cycle counter and the program counter live in simd_top.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module ctrl_unit (
    input  wire [15:0] instr,
    output wire        we,        // vector register-file write enable
    output wire [2:0]  waddr,
    output wire [2:0]  raddr1,
    output wire [2:0]  raddr2,
    output wire [2:0]  alu_op,
    output wire        mem_rd,
    output wire        mem_wr,
    output wire        halt
);

    // TODO(parth): implement the decode. The field macros in simd_defs.vh give
    // you the slices; the op codes were numbered so that the ALU op is just
    // instr[14:12] for every arithmetic and logic instruction.
    //
    //   wire [3:0] opcode = `F_OPCODE(instr);
    //   wire is_alu = (opcode[3] == 1'b0);            // 0000..0110
    //
    //   assign alu_op = instr[14:12];
    //   assign waddr  = `F_VD(instr);
    //   assign raddr1 = `F_VS1(instr);                // VST reads via port 1:
    //   assign raddr2 = `F_VS2(instr);                //   see the note below
    //   assign we     = is_alu || (opcode == `OP_VLD);
    //   assign mem_rd = (opcode == `OP_VLD);
    //   assign mem_wr = (opcode == `OP_VST);
    //   assign halt   = (opcode == `OP_HALT);
    //
    // Decide one thing and write it in 4.1: VST stores V[vd], and vd is in
    // bits 11:9, not in the vs1 field. Either drive raddr1 = `F_VD(instr) when
    // the opcode is VST, or mux the store data in simd_top. Pick one, say which
    // in the report, and make tb_ctrl_unit assert it.
    //
    // Unknown opcode must be inert: we = mem_rd = mem_wr = halt = 0. A decoder
    // that writes a register on a junk word is the bug that costs marks.
    assign we     = 1'b0;
    assign waddr  = 3'b0;
    assign raddr1 = 3'b0;
    assign raddr2 = 3'b0;
    assign alu_op = 3'b0;
    assign mem_rd = 1'b0;
    assign mem_wr = 1'b0;
    assign halt   = 1'b0;

endmodule
