//=============================================================================
// simd_defs.vh - shared geometry, ALU op codes and instruction op codes.
//
// Project 11, SIMD Vector Unit. Modern Computer Architecture, Phase I.
//
// This file is the single machine-readable copy of the frozen spec in
// docs/spec.md. If a number changes here it must change there in the same
// commit. Owner: Parthraj (spec owner). Everyone else includes it, nobody else
// edits it - open an issue or message the group instead.
//
// Include it with  `include "simd_defs.vh"  and compile with  -I rtl.
//=============================================================================
`ifndef SIMD_DEFS_VH
`define SIMD_DEFS_VH

//--------------------------------------------------------------------------
// Geometry. LANES is the one knob that must stay a knob: 8 lanes has to be a
// one-line change, so never hardcode 4 anywhere else.
//--------------------------------------------------------------------------
`define LANES       4
`define LANE_W      32
`define VEC_W       128              // LANES * LANE_W
`define NREGS       8                // V0..V7
`define REG_SEL_W   3                // $clog2(NREGS)
`define DMEM_WORDS  16               // 16 words of VEC_W bits
`define DMEM_ADDR_W 4
`define IMEM_WORDS  64
`define IMEM_ADDR_W 6
`define INSTR_W     16

//--------------------------------------------------------------------------
// ALU op codes - alu_op[2:0], identical for lane_alu, vec_alu and the scalar
// baseline. Compares write 1 or 0 into the lowest bit of the lane and zero
// into the other 31 bits.
//--------------------------------------------------------------------------
`define ALU_ADD     3'b000
`define ALU_SUB     3'b001
`define ALU_AND     3'b010
`define ALU_OR      3'b011
`define ALU_CMPEQ   3'b100
`define ALU_CMPLT   3'b101          // signed
`define ALU_SHL     3'b110          // optional, drop before any required item

//--------------------------------------------------------------------------
// Instruction op codes - instr[15:12].
//
// The low three bits of an ALU op code are the ALU op code itself, so the
// control unit can wire  alu_op = instr[14:12]  with no decode table at all.
// Keep that property if you renumber anything.
//--------------------------------------------------------------------------
`define OP_VADD     4'b0000
`define OP_VSUB     4'b0001
`define OP_VAND     4'b0010
`define OP_VOR      4'b0011
`define OP_VCMPEQ   4'b0100
`define OP_VCMPLT   4'b0101
`define OP_VSHL     4'b0110         // optional
`define OP_VLD      4'b1000
`define OP_VST      4'b1001
`define OP_HALT     4'b1111

//--------------------------------------------------------------------------
// Instruction field extraction. Register-register form:
//
//   | 15:12 opcode | 11:9 vd | 8:6 vs1 | 5:3 vs2 | 2:0 unused |
//
// Memory form (VLD, VST) reuses the word: vd is the destination (VLD) or the
// source (VST), and the 4-bit data-memory address sits in bits 6:3.
//--------------------------------------------------------------------------
`define F_OPCODE(i) i[15:12]
`define F_VD(i)     i[11:9]
`define F_VS1(i)    i[8:6]
`define F_VS2(i)    i[5:3]
`define F_MEMADDR(i) i[6:3]

`endif
