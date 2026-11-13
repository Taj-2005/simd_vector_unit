"""Golden model for the Project 11 SIMD vector unit.

A bit-exact Python reference for the six vector operations the RTL implements.
`tb/tb_system.v` compares `simd_top`'s data memory against vectors generated
from this model, so a disagreement is a real bug in one of the two and not a
difference of opinion about what the instruction means.

Owner: Taj. Mirrors the frozen spec in `docs/spec.md` and the op codes in
`rtl/simd_defs.vh` -- if those change, this file changes in the same commit.

Three conventions matter and are the usual source of a mismatch:

1. **Lane 0 is the low-order lane.** A vector is packed little-end first, so
   lane ``i`` occupies bits ``[i*32 +: 32]`` exactly as the ``generate`` loop in
   ``vec_alu.v`` wires it. Printing a vector therefore shows lane 3 leftmost.
2. **Arithmetic wraps.** ADD and SUB are modulo 2**32 with no flags, because the
   hardware has no carry-out. ``0xFFFFFFFF + 1 == 0``.
3. **Compares are signed and narrow.** CMPEQ and CMPLT write 1 or 0 into bit 0
   of the lane and zero into bits 31:1 -- not an all-ones mask -- and CMPLT
   compares two's-complement values, so ``-1 < 1``.
"""

from __future__ import annotations

LANES = 4
LANE_W = 32
VEC_W = LANES * LANE_W
LANE_MASK = (1 << LANE_W) - 1
SIGN_BIT = 1 << (LANE_W - 1)

# ALU op codes, identical to the `ALU_* macros in rtl/simd_defs.vh.
ALU_ADD = 0b000
ALU_SUB = 0b001
ALU_AND = 0b010
ALU_OR = 0b011
ALU_CMPEQ = 0b100
ALU_CMPLT = 0b101
ALU_SHL = 0b110


def to_signed(value: int) -> int:
    """Reinterpret a 32-bit pattern as two's complement."""
    value &= LANE_MASK
    return value - (1 << LANE_W) if value & SIGN_BIT else value


def to_unsigned(value: int) -> int:
    """Reduce any integer to the 32-bit pattern the hardware would hold."""
    return value & LANE_MASK


def lane_add(a: int, b: int) -> int:
    return to_unsigned(a + b)


def lane_sub(a: int, b: int) -> int:
    return to_unsigned(a - b)


def lane_and(a: int, b: int) -> int:
    return to_unsigned(a) & to_unsigned(b)


def lane_or(a: int, b: int) -> int:
    return to_unsigned(a) | to_unsigned(b)


def lane_cmpeq(a: int, b: int) -> int:
    return 1 if to_unsigned(a) == to_unsigned(b) else 0


def lane_cmplt(a: int, b: int) -> int:
    """Signed less-than. An unsigned comparator passes every test but this one."""
    return 1 if to_signed(a) < to_signed(b) else 0


def lane_shl(a: int, b: int) -> int:
    """Optional op. Only the low 5 bits of the shift amount are used."""
    return to_unsigned(to_unsigned(a) << (to_unsigned(b) & 0x1F))


LANE_OPS = {
    ALU_ADD: lane_add,
    ALU_SUB: lane_sub,
    ALU_AND: lane_and,
    ALU_OR: lane_or,
    ALU_CMPEQ: lane_cmpeq,
    ALU_CMPLT: lane_cmplt,
    ALU_SHL: lane_shl,
}

OP_NAMES = {
    "add": ALU_ADD,
    "sub": ALU_SUB,
    "and": ALU_AND,
    "or": ALU_OR,
    "cmpeq": ALU_CMPEQ,
    "cmplt": ALU_CMPLT,
    "shl": ALU_SHL,
}


def lane_op(op: int, a: int, b: int) -> int:
    """Apply one ALU op to one lane. Mirrors `lane_alu.v`."""
    try:
        return LANE_OPS[op](a, b)
    except KeyError:
        raise ValueError(f"undefined ALU op code {op:#05b}") from None


def vec_op(op: int, a: list[int], b: list[int], lanes: int = LANES) -> list[int]:
    """Apply one ALU op across all lanes. Mirrors `vec_alu.v`.

    Lanes are independent: lane ``i`` sees only ``a[i]`` and ``b[i]``, which is
    the property `tb_vec_alu.v` is written to prove.
    """
    if len(a) != lanes or len(b) != lanes:
        raise ValueError(f"expected {lanes} lanes per operand, got {len(a)} and {len(b)}")
    return [lane_op(op, a[i], b[i]) for i in range(lanes)]


def pack(lanes: list[int]) -> int:
    """Pack lanes into one VEC_W-bit word. Lane 0 goes in the low bits."""
    word = 0
    for i, value in enumerate(lanes):
        word |= to_unsigned(value) << (i * LANE_W)
    return word


def unpack(word: int, lanes: int = LANES) -> list[int]:
    """Split a VEC_W-bit word back into lanes, lane 0 first."""
    return [(word >> (i * LANE_W)) & LANE_MASK for i in range(lanes)]


def to_hex(word: int, width: int = VEC_W) -> str:
    """One `$readmemh` line: fixed-width, lowercase, no 0x prefix."""
    return f"{word & ((1 << width) - 1):0{width // 4}x}"


def from_hex(line: str) -> int:
    """Parse one `$readmemh` line, tolerating the comments Icarus allows."""
    line = line.split("//")[0].strip().replace("_", "")
    if not line:
        raise ValueError("empty hex line")
    return int(line, 16)


def write_hex(path: str, words: list[int], header: str = "") -> None:
    """Write `$readmemh` input: one hex word per line, index 0 first."""
    with open(path, "w") as handle:
        if header:
            for line in header.strip().splitlines():
                handle.write(f"// {line.strip()}\n")
        for word in words:
            handle.write(f"{to_hex(word)}\n")
