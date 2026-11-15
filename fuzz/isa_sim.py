"""Independent instruction-level simulator of the SIMD machine.

Models `simd_top` the way `docs/spec.md` describes it -- register file, data
memory, program counter and cycle counter -- deliberately written from the spec
rather than from the Verilog, so that a shared misreading of the spec is less
likely to cancel out.

`golden_model.py` already defines what one *instruction* computes. This defines
what a *program* does, which is what the fuzzer needs in order to check the
integrated processor rather than the ALU alone.

Owner: Taj.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "golden"))

from golden_model import pack, unpack, vec_op  # noqa: E402

NREGS = 8
WORDS = 16

OP_ALU_MAX = 0b0110  # 0000..0110 are ALU ops, and alu_op is opcode[2:0]
OP_VLD = 0b1000
OP_VST = 0b1001
OP_HALT = 0b1111


def simulate(prog: list[int], mem_init: list[int], max_steps: int = 100_000):
    """Run one program. Returns (memory, registers, cycle_count).

    Mirrors simd_top exactly on the two things that are easy to get wrong:
    the register file starts at zero, and the HALT cycle is not counted.
    """
    regs = [0] * NREGS
    mem = list(mem_init) + [0] * (WORDS - len(mem_init))
    pc = 0
    cycles = 0

    for _ in range(max_steps):
        # instr_mem pre-fills with HALT, so reading past the program halts.
        instr = prog[pc] if pc < len(prog) else OP_HALT << 12
        opcode = instr >> 12
        vd = (instr >> 9) & 0b111
        vs1 = (instr >> 6) & 0b111
        vs2 = (instr >> 3) & 0b111
        addr = instr & 0b1111

        if opcode == OP_HALT:
            return mem, regs, cycles

        cycles += 1
        if opcode <= OP_ALU_MAX:
            regs[vd] = pack(vec_op(opcode & 0b111, unpack(regs[vs1]), unpack(regs[vs2])))
        elif opcode == OP_VLD:
            regs[vd] = mem[addr]
        elif opcode == OP_VST:
            mem[addr] = regs[vs1]
        # Any other opcode is undefined and must behave as a NOP: no register
        # write, no memory write, no halt.
        pc += 1

    raise RuntimeError("program never halted")
