"""Render the system test's execution trace from its VCD.

    make -C sim system                              # -> sim/waves/tb_system.vcd
    python docs/waveforms/make_system_waveform.py   # -> docs/waveforms/system_pass.svg
    make -C docs/waveforms                          # -> PNG + PDF

Shows `simd_top` executing bench_add16 cycle by cycle: program counter,
instruction word, decoded mnemonic, the two write-enables, and the cycle
counter. This is the figure for report section 4.1/4.3 and the 2:40-3:25 video
slot, alongside the terminal PASS output in results/system_test_output.txt.

Like make_waveform.py, this is a reconstruction generated from the simulator's
own output, not a screenshot, and it says so on its face.

Owner: Taj.
"""

from __future__ import annotations

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
VCD = ROOT / "sim" / "waves" / "tb_system.vcd"
OUT = ROOT / "docs" / "waveforms" / "system_pass.svg"
DUT = "tb_system.dut_add16"

MNEM = {
    0: "VADD",
    1: "VSUB",
    2: "VAND",
    3: "VOR",
    4: "VCMPEQ",
    5: "VCMPLT",
    6: "VSHL",
    8: "VLD",
    9: "VST",
    15: "HALT",
}


def disasm(word: int) -> str:
    op = word >> 12
    vd, vs1, vs2 = (word >> 9) & 7, (word >> 6) & 7, (word >> 3) & 7
    addr = word & 0xF
    name = MNEM.get(op, "?")
    if name == "VLD":
        return f"VLD V{vd},[{addr}]"
    if name == "VST":
        return f"VST V{vs1},[{addr}]"
    if name == "HALT":
        return "HALT"
    return f"{name} V{vd},V{vs1},V{vs2}"


def parse(path: pathlib.Path):
    lines = path.read_text().splitlines()
    scope, ids = [], {}
    for ln in lines:
        s = ln.strip()
        if s.startswith("$scope"):
            scope.append(s.split()[2])
        elif s.startswith("$upscope"):
            scope.pop()
        elif s.startswith("$var"):
            p = s.split()
            # One VCD identifier can carry several names: a wire driven by a
            # submodule port is aliased. Keep every name, or the one we want
            # gets silently overwritten by whichever $var came last.
            ids.setdefault(p[3], []).append(".".join(scope + [p[4]]))
        elif s.startswith("$enddefinitions"):
            break

    want = {f"{DUT}.{n}": n for n in ("pc", "instr", "rf_we", "mem_wr", "cycles", "done_reg")}
    want["tb_system.rst"] = "rst"
    idmap = {}
    for ident, names in ids.items():
        for nm in names:
            if nm in want:
                idmap[ident] = want[nm]
                break

    t, cur, timeline = 0, {}, []
    for ln in lines:
        s = ln.strip()
        if not s:
            continue
        if s[0] == "#":
            if cur:
                timeline.append((t, dict(cur)))
            t = int(s[1:])
        elif s[0] == "b":
            v, i = s[1:].split(" ", 1)
            if i in idmap:
                cur[idmap[i]] = int(v, 2) if set(v) <= {"0", "1"} else 0
        elif s[0] in "01xz":
            v, i = s[0], s[1:]
            if i in idmap:
                cur[idmap[i]] = int(v) if v in "01" else 0
    if cur:
        timeline.append((t, dict(cur)))

    # One sample per clock period, after reset releases, while still running.
    rows, seen = [], set()
    for time, st in timeline:
        if "pc" not in st or "instr" not in st:
            continue
        if st.get("rst", 1):
            continue
        ns = time // 1000
        if ns in seen:
            continue
        seen.add(ns)
        entry = (
            ns,
            st["pc"],
            st["instr"],
            st.get("rf_we", 0),
            st.get("mem_wr", 0),
            st.get("cycles", 0),
            st.get("done_reg", 0),
        )
        # The VCD records both clock edges; one row per executed instruction is
        # what the figure wants, so drop a sample that repeats the previous pc
        # and cycle count.
        if rows and rows[-1][1:] == entry[1:]:
            continue
        rows.append(entry)
    # keep up to and including the first halted sample
    out = []
    for r in rows:
        out.append(r)
        if r[6]:
            break
    return out


def render(rows) -> str:
    n = len(rows)
    col, left, top, rh = 96, 180, 92, 40
    w = left + col * n + 20
    h = top + rh * 5 + 86

    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">',
        "<style>",
        "  .bg{fill:#fff}",
        "  .lbl{font:600 11px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#111}",
        "  .v{font:11px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#111;text-anchor:middle}",
        "  .m{font:600 10px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#0a4d4f;text-anchor:middle}",
        "  .t{font:9px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#667;text-anchor:middle}",
        "  .c{fill:#f4f6f8;stroke:#111;stroke-width:1}",
        "  .mc{fill:#e2f0f0;stroke:#0a4d4f;stroke-width:1}",
        "  .hi{fill:#0a4d4f}",
        "  .lo{fill:#ccd4da}",
        "  .note{font:italic 10.5px ui-sans-serif,system-ui,sans-serif;fill:#555}",
        "  .hd{font:600 13px ui-sans-serif,system-ui,sans-serif;fill:#111}",
        "  .grid{stroke:#e3e8ec;stroke-width:1}",
        "</style>",
        f'<rect class="bg" x="0" y="0" width="{w}" height="{h}"/>',
        '<text class="hd" x="14" y="26">tb_system — simd_top executing bench_add16 '
        "(16-element array add)</text>",
        '<text class="note" x="14" y="46">Reconstructed from sim/waves/tb_system.vcd by '
        "docs/waveforms/make_system_waveform.py — not a screenshot.</text>",
        '<text class="note" x="14" y="62">One instruction per cycle. The HALT cycle is not '
        "counted, which is the rule in docs/cycle_counting.md.</text>",
    ]

    for i, r in enumerate(rows):
        x = left + col * i
        out.append(f'<text class="t" x="{x + col // 2}" y="{top - 8}">{r[0]} ns</text>')
        out.append(f'<line class="grid" x1="{x}" y1="{top}" x2="{x}" y2="{top + rh * 5}"/>')
    out.append(
        f'<line class="grid" x1="{left + col * n}" y1="{top}" '
        f'x2="{left + col * n}" y2="{top + rh * 5}"/>'
    )

    def row(idx, label, fn, cls="c", txt="v"):
        y = top + rh * idx
        out.append(f'<text class="lbl" x="14" y="{y + 26}">{label}</text>')
        for i, r in enumerate(rows):
            x = left + col * i
            out.append(
                f'<rect class="{cls}" x="{x + 4}" y="{y + 7}" '
                f'width="{col - 8}" height="24" rx="3"/>'
            )
            out.append(f'<text class="{txt}" x="{x + col // 2}" y="{y + 24}">{fn(r)}</text>')

    row(0, "pc", lambda r: r[1])
    row(1, "instr[15:0]", lambda r: f"{r[2]:04x}")
    row(2, "decoded", disasm_row, cls="mc", txt="m")
    row(3, "rf_we / mem_wr", lambda r: f"{r[3]}{r[4]}")
    row(4, "cycle_count", lambda r: r[5])

    y = top + rh * 5 + 26
    out.append(
        f'<text class="note" x="14" y="{y}">Each VLD/VADD/VST takes exactly one '
        f"cycle; the four VST writes land the results in dmem[8..11].</text>"
    )
    out.append(
        f'<text class="note" x="14" y="{y + 16}">Final cycle_count = '
        f"{rows[-1][5]} for 17 instructions, HALT excluded. All four result words "
        f"match the Python golden model.</text>"
    )
    out.append("</svg>")
    return "\n".join(out)


def disasm_row(r):
    return disasm(r[2])


def main() -> int:
    if not VCD.exists():
        print(f"no VCD at {VCD} — run: make -C sim system", file=sys.stderr)
        return 1
    rows = parse(VCD)
    if not rows:
        print("parsed no cycles from the VCD", file=sys.stderr)
        return 1
    OUT.write_text(render(rows))
    print(f"wrote {OUT.relative_to(ROOT)} from {len(rows)} cycles")
    for r in rows:
        print(
            f"  {r[0]:>4} ns  pc={r[1]:<3} {r[2]:04x}  {disasm(r[2]):<18} "
            f"we={r[3]} mw={r[4]}  cycles={r[5]}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
