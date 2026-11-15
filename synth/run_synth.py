"""Synthesise each module with Yosys and record area figures.

    python synth/run_synth.py

Writes `results/synthesis.csv` plus a full Yosys log per module under
`results/synthesis_<module>.txt`.

Owner: Taj.

WHAT THESE NUMBERS ARE, AND ARE NOT. The flow is Yosys `synth_xilinx`, flattened
and without I/O pads, so the cells are real Xilinx 7-series primitives: LUT1-6,
CARRY4, FDxE flip-flops and RAM32M distributed RAM. That makes the counts a fair
relative area comparison between our own modules -- which is the comparison
report section 4.2 makes when it argues the generate loop costs nothing over
manual instantiation.

They are NOT a vendor place-and-route result: no device was targeted, nothing was
placed or routed, and Yosys does no timing analysis. **Fmax is therefore left
empty rather than guessed.** Say exactly that in the report; a fabricated
frequency is the easiest number for an examiner to challenge.
"""

from __future__ import annotations

import csv
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SIM = ROOT / "sim"  # run from here so $readmemh paths resolve
RESULTS = ROOT / "results"

# (top module, source files) - relative to sim/, matching how simulation runs.
MODULES = [
    ("lane_alu", ["../rtl/lane_alu.v"]),
    ("vec_alu", ["../rtl/vec_alu.v", "../rtl/lane_alu.v"]),
    ("vreg_file", ["../rtl/vreg_file.v"]),
    ("dmem", ["../rtl/dmem.v"]),
    ("ctrl_unit", ["../rtl/ctrl_unit.v"]),
    ("instr_mem", ["../rtl/instr_mem.v"]),
    ("scalar_top", ["../scalar/scalar_top.v", "../rtl/lane_alu.v"]),
    (
        "simd_top",
        [
            f"../rtl/{n}.v"
            for n in (
                "simd_top",
                "ctrl_unit",
                "instr_mem",
                "vreg_file",
                "dmem",
                "vec_alu",
                "lane_alu",
            )
        ],
    ),
]


def run_one(top: str, sources: list[str]):
    script = (
        f"read_verilog -I ../rtl {' '.join(sources)}; "
        f"synth_xilinx -top {top} -flatten -noiopad; "
        f"stat"
    )
    proc = subprocess.run(["yosys", "-p", script], cwd=SIM, capture_output=True, text=True)
    log = proc.stdout + proc.stderr

    # Commit the final `stat` block, not the whole Yosys transcript. The full
    # log is ~1600 lines per module, embeds this machine's install paths, and
    # carries elapsed times / memory peaks / a logfile hash that change on every
    # run - so committing it would mean a dirty tree after any re-run, for no
    # extra evidence. The stat block is the result and is reproducible.
    marker = f"=== {top} ==="
    if marker in log:
        report = log[log.rindex(marker) :]
        report = report[: report.index("End of script")] if "End of script" in report else report
    else:
        report = "\n".join(
            line
            for line in log.splitlines()
            if "error" in line.lower() or "warning" in line.lower()
        )
    header = (
        f"# {top} - yosys synth_xilinx -flatten -noiopad\n"
        f"# regenerate with: python synth/run_synth.py\n\n"
    )
    (RESULTS / f"synthesis_{top}.txt").write_text(header + report.rstrip() + "\n")
    if proc.returncode != 0:
        return {
            "luts": "n/a",
            "ffs": "n/a",
            "carry": "n/a",
            "ram": "n/a",
            "cells": "n/a",
            "note": "yosys returned an error; see the log",
        }

    # `synth_xilinx` prints several stat blocks; the last one is the result.
    marker = f"=== {top} ==="
    block = log[log.rindex(marker) :] if marker in log else log
    block = block[: block.index("End of script")] if "End of script" in block else block

    def total(pattern):
        return sum(int(n) for n, _ in re.findall(rf"^\s+(\d+)\s+({pattern})$", block, re.M))

    cells = re.search(r"^\s+(\d+)\s+cells$", block, re.M)
    luts = total(r"LUT[1-6]")
    ffs = total(r"FD\w*")
    carry = total(r"CARRY\d*")
    ram = total(r"RAM\w*")

    note = ""
    if ram:
        note = f"{ram} RAM32M distributed-RAM primitives"
    # instr_mem holds a compile-time-constant program, so Yosys folds the ROM
    # (and, in simd_top, most of the machine driven by it) away. The remaining
    # figure is not an area estimate and must not be quoted as one.
    if top in ("instr_mem", "simd_top"):
        note = (
            "constant program folds at elaboration; not a usable area figure "
            "- see results/README.md"
        )
    return {
        "luts": luts,
        "ffs": ffs,
        "carry": carry,
        "ram": ram,
        "cells": cells.group(1) if cells else "n/a",
        "note": note,
    }


def main() -> int:
    RESULTS.mkdir(exist_ok=True)
    rows = []
    for top, sources in MODULES:
        print(f"synthesising {top} ...", flush=True)
        r = run_one(top, sources)
        rows.append(
            {
                "module": top,
                "tool": "yosys synth_xilinx -flatten -noiopad",
                "luts": r["luts"],
                "flip_flops": r["ffs"],
                "carry4": r["carry"],
                "cells": r["cells"],
                "fmax_mhz": "",  # no timing analysis in this flow - empty on purpose
                "notes": r["note"],
            }
        )
        print(
            f"   LUT {r['luts']:>5}   FF {r['ffs']:>4}   CARRY4 {r['carry']:>3}   "
            f"cells {r['cells']:>5}   {r['note']}"
        )

    out = RESULTS / "synthesis.csv"
    with open(out, "w", newline="") as fh:
        w = csv.DictWriter(
            fh,
            fieldnames=[
                "module",
                "tool",
                "luts",
                "flip_flops",
                "carry4",
                "cells",
                "fmax_mhz",
                "notes",
            ],
        )
        w.writeheader()
        w.writerows(rows)
    print(f"\nwrote {out.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
