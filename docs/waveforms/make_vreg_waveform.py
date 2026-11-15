"""Render the register-file timing diagram from tb_vreg_file's VCD.

    make -C sim vreg_file
    python docs/waveforms/make_vreg_waveform.py
    make -C docs/waveforms

Shows the two read ports serving different registers in the same cycle, and the
read-during-write case where the combinational read returns the OLD value
because the write commits on the clock edge. That behaviour is what simd_top's
VST-after-VADD timing depends on, so it is worth a figure.

Reconstructed from simulator output, not a screenshot. Owner: Taj.
"""

from __future__ import annotations

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
VCD = ROOT / "sim" / "waves" / "tb_vreg_file.vcd"
OUT = ROOT / "docs" / "waveforms" / "vreg_file.svg"
TOP = "tb_vreg_file"
SIGNALS = ["we", "waddr", "wdata", "raddr1", "rdata1", "raddr2", "rdata2"]


def parse():
    lines = VCD.read_text().splitlines()
    scope, ids = [], {}
    for ln in lines:
        s = ln.strip()
        if s.startswith("$scope"):
            scope.append(s.split()[2])
        elif s.startswith("$upscope"):
            scope.pop()
        elif s.startswith("$var"):
            p = s.split()
            ids.setdefault(p[3], []).append(".".join(scope + [p[4]]))
        elif s.startswith("$enddefinitions"):
            break

    want = {f"{TOP}.{n}": n for n in SIGNALS}
    want[f"{TOP}.clk"] = "clk"
    idmap = {}
    for ident, names in ids.items():
        for nm in names:
            if nm in want:
                idmap[ident] = want[nm]
                break

    t, cur, tl = 0, {}, []
    for ln in lines:
        s = ln.strip()
        if not s:
            continue
        if s[0] == "#":
            if cur:
                tl.append((t, dict(cur)))
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
        tl.append((t, dict(cur)))

    # Select the window that actually demonstrates the two claims in the
    # caption: both ports serving different registers (from 98 ns), and the
    # read-during-write at 120 ns returning the old value with the new one
    # visible at 125 ns. Deduplicate on the observable state so the figure
    # shows transitions rather than repeated identical cycles.
    rows, last = [], None
    for time, st in tl:
        if "rdata1" not in st:
            continue
        ns = time // 1000
        if not (96 <= ns <= 130):
            continue
        key = (
            st.get("we"),
            st.get("waddr"),
            st.get("raddr1"),
            st.get("raddr2"),
            st.get("rdata1"),
            st.get("rdata2"),
        )
        if key == last:
            continue
        last = key
        rows.append((ns, st))
    return rows[:8]


def render(rows):
    n = len(rows)
    col, left, top, rh = 118, 150, 86, 38
    w, h = left + col * n + 20, top + rh * len(SIGNALS) + 92

    def cell(v, bits=128):
        if v is None:
            return "-"
        return f"{v:0{bits // 4}x}"[-10:] if bits > 32 else str(v)

    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">',
        "<style>",
        "  .bg{fill:#fff}",
        "  .lbl{font:600 11px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#111}",
        "  .v{font:10.5px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#111;text-anchor:middle}",
        "  .t{font:9px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#667;text-anchor:middle}",
        "  .c{fill:#f4f6f8;stroke:#111;stroke-width:1}",
        "  .w{fill:#e2f0f0;stroke:#0a4d4f;stroke-width:1}",
        "  .note{font:italic 10.5px ui-sans-serif,system-ui,sans-serif;fill:#555}",
        "  .hd{font:600 13px ui-sans-serif,system-ui,sans-serif;fill:#111}",
        "  .grid{stroke:#e3e8ec;stroke-width:1}",
        "</style>",
        f'<rect class="bg" x="0" y="0" width="{w}" height="{h}"/>',
        '<text class="hd" x="14" y="26">tb_vreg_file — two read ports, one write port</text>',
        '<text class="note" x="14" y="46">Reconstructed from sim/waves/tb_vreg_file.vcd by '
        "docs/waveforms/make_vreg_waveform.py — not a screenshot.</text>",
        '<text class="note" x="14" y="62">128-bit values truncated to their low 40 bits '
        "for width. Radix: hex.</text>",
    ]
    for i, (ns, _) in enumerate(rows):
        x = left + col * i
        out.append(f'<text class="t" x="{x + col // 2}" y="{top - 8}">{ns} ns</text>')
        out.append(
            f'<line class="grid" x1="{x}" y1="{top}" x2="{x}" y2="{top + rh * len(SIGNALS)}"/>'
        )
    out.append(
        f'<line class="grid" x1="{left + col * n}" y1="{top}" '
        f'x2="{left + col * n}" y2="{top + rh * len(SIGNALS)}"/>'
    )

    for r, sig in enumerate(SIGNALS):
        y = top + rh * r
        out.append(f'<text class="lbl" x="14" y="{y + 25}">{sig}</text>')
        for i, (_, st) in enumerate(rows):
            x = left + col * i
            bits = 128 if "data" in sig else 32
            cls = "w" if sig in ("we", "waddr", "wdata") else "c"
            out.append(
                f'<rect class="{cls}" x="{x + 4}" y="{y + 6}" '
                f'width="{col - 8}" height="24" rx="3"/>'
            )
            out.append(
                f'<text class="v" x="{x + col // 2}" y="{y + 23}">{cell(st.get(sig), bits)}</text>'
            )

    y = top + rh * len(SIGNALS) + 26
    out.append(
        f'<text class="note" x="14" y="{y}">Both read ports serve different '
        f'registers in the same cycle — that is what "2 read ports" has to mean.</text>'
    )
    out.append(
        f'<text class="note" x="14" y="{y + 17}">On a read and write to the same '
        f"address, the combinational read returns the OLD value; the write commits "
        f"on the clock edge.</text>"
    )
    out.append("</svg>")
    return "\n".join(out)


def main() -> int:
    if not VCD.exists():
        print(f"no VCD at {VCD} — run: make -C sim vreg_file", file=sys.stderr)
        return 1
    rows = parse()
    if not rows:
        print("parsed no cycles", file=sys.stderr)
        return 1
    OUT.write_text(render(rows))
    print(f"wrote {OUT.relative_to(ROOT)} from {len(rows)} cycles")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
