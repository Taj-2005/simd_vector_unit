"""Fuzz the whole processor against the independent ISA simulator.

    python fuzz/run_fuzz.py                 # 300 programs, fixed seed
    python fuzz/run_fuzz.py --count 2000 --seed 7

Generates random but legal programs -- every opcode including the undefined
ones, random registers, random addresses -- runs each on `simd_top` and on
`fuzz/isa_sim.py`, and compares the final data memory and the cycle count.

This is the test that found the reset write-enable bug: the unit testbenches all
passed, because every hand-written benchmark happens to start with an
idempotent VLD. Owner: Taj.
"""

from __future__ import annotations

import argparse
import random
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from isa_sim import WORDS, simulate  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "fuzz" / "build"
VVP = BUILD / "fuzz.vvp"

OPS_ALU = [0b0000, 0b0001, 0b0010, 0b0011, 0b0100, 0b0101, 0b0110]
OPS_UNDEFINED = [0b0111, 0b1010, 0b1011, 0b1100, 0b1101, 0b1110]

# instr_mem holds `IMEM_WORDS instructions; stay clear of the limit so a
# truncated program is never mistaken for a hang.
MAX_PROGRAM = 28


def build() -> None:
    BUILD.mkdir(parents=True, exist_ok=True)
    rtl = sorted((ROOT / "rtl").glob("*.v"))
    cmd = [
        "iverilog",
        "-g2005",
        "-Wall",
        "-I",
        str(ROOT / "rtl"),
        "-s",
        "tb_fuzz",
        "-o",
        str(VVP),
        str(ROOT / "fuzz" / "tb_fuzz.v"),
    ] + [str(f) for f in rtl]
    subprocess.run(cmd, check=True)


def gen_program(rng: random.Random, n: int) -> list[int]:
    prog = []
    for _ in range(n):
        roll = rng.random()
        if roll < 0.30:
            prog.append((0b1000 << 12) | (rng.randrange(8) << 9) | rng.randrange(WORDS))
        elif roll < 0.55:
            prog.append((0b1001 << 12) | (rng.randrange(8) << 6) | rng.randrange(WORDS))
        elif roll < 0.92:
            prog.append(
                (rng.choice(OPS_ALU) << 12)
                | (rng.randrange(8) << 9)
                | (rng.randrange(8) << 6)
                | (rng.randrange(8) << 3)
            )
        else:
            prog.append((rng.choice(OPS_UNDEFINED) << 12) | rng.randrange(0x1000))
    prog.append(0b1111 << 12)  # always terminate
    return prog


def write_hex(path: Path, words: list[int], digits: int) -> None:
    path.write_text("".join(f"{w:0{digits}x}\n" for w in words))


def run_rtl():
    out = subprocess.run(["vvp", str(VVP)], capture_output=True, text=True, cwd=ROOT).stdout
    if "HANG" in out:
        return None, None
    cycles, mem = None, [None] * WORDS
    for line in out.splitlines():
        parts = line.split()
        if parts[:1] == ["CYCLES"]:
            cycles = int(parts[1])
        elif parts[:1] == ["MEM"]:
            mem[int(parts[1])] = int(parts[2], 16)
    return cycles, mem


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--seed", type=int, default=2026)
    ap.add_argument("--count", type=int, default=300)
    args = ap.parse_args()

    build()
    rng = random.Random(args.seed)

    for t in range(args.count):
        prog = gen_program(rng, rng.randrange(4, MAX_PROGRAM))
        data = [rng.getrandbits(128) for _ in range(WORDS)]
        write_hex(BUILD / "prog.hex", prog, 4)
        write_hex(BUILD / "data.hex", data, 32)

        exp_mem, _, exp_cycles = simulate(prog, data)
        got_cycles, got_mem = run_rtl()

        listing = " ".join(f"{w:04x}" for w in prog)
        if got_cycles is None:
            print(f"FAIL [{t}] machine never halted\n  program: {listing}")
            return 1
        if got_cycles != exp_cycles:
            print(
                f"FAIL [{t}] cycle count: rtl={got_cycles} model={exp_cycles}\n  program: {listing}"
            )
            return 1
        wrong = [i for i in range(WORDS) if got_mem[i] != exp_mem[i]]
        if wrong:
            print(f"FAIL [{t}] memory mismatch at words {wrong}")
            for i in wrong[:3]:
                print(f"    word {i}:  rtl = {got_mem[i]:032x}")
                print(f"             model = {exp_mem[i]:032x}")
            print(f"  program: {listing}")
            return 1

    print(
        f"PASS  {args.count}/{args.count} random programs match the ISA simulator "
        f"(seed {args.seed})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
