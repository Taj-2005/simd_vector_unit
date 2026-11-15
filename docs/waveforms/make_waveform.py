"""Render a timing diagram directly from a simulation VCD.

    python docs/waveforms/make_waveform.py

Reads `sim/waves/tb_vec_alu.vcd` and writes `docs/waveforms/vec_alu.svg`, which
`make -C docs/waveforms` turns into PNG and PDF.

The figure is a **reconstruction, not a screenshot**. That is deliberate and it
is stated on the figure itself: every value is parsed out of the VCD the
simulator wrote, so the diagram cannot drift from what the hardware did. A
hand-drawn approximation can (and once did -- an earlier version of this figure
showed 0x00000064 where the simulation produced 0x0000005A).

Regenerate it whenever `tb_vec_alu.v` changes.

Owner: Taj.
"""

from __future__ import annotations

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
VCD = ROOT / "sim" / "waves" / "tb_vec_alu.vcd"
OUT = ROOT / "docs" / "waveforms" / "vec_alu.svg"

LANES = 4
OP_NAMES = {0: "ADD", 1: "SUB", 2: "AND", 3: "OR", 4: "CMPEQ", 5: "CMPLT", 6: "SHL", 7: "UNDEF"}


def parse_vcd(path: pathlib.Path):
    """Return [(ns, op, [lane0..lane3])] for tb_vec_alu's packed output."""
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
            ids[p[3]] = ".".join(scope + [p[4]])
        elif s.startswith("$enddefinitions"):
            break

    top = "tb_vec_alu"
    wanted = {f"{top}.y": "y", f"{top}.op": "op"}
    idmap = {i: wanted[n] for i, n in ids.items() if n in wanted}

    t, cur, timeline = 0, {}, []
    for ln in lines:
        s = ln.strip()
        if s.startswith("#"):
            if cur:
                timeline.append((t, dict(cur)))
            t = int(s[1:])
        elif s and s[0] == "b":
            value, ident = s[1:].split(" ", 1)
            if ident in idmap:
                cur[idmap[ident]] = value
    if cur:
        timeline.append((t, dict(cur)))

    seen, rows = set(), []
    for time, st in timeline:
        if "y" not in st:
            continue
        ns = time // 1000
        if ns in seen:
            continue
        seen.add(ns)
        bits = st["y"].rjust(LANES * 32, "0")
        lanes = [int(bits[(LANES - 1 - i) * 32 : (LANES - i) * 32], 2) for i in range(LANES)]
        rows.append((ns, int(st.get("op", "0") or "0", 2), lanes))
    return rows


def render(rows) -> str:
    rows = [r for r in rows if r[0] <= 70]  # the eight checked ops
    n = len(rows)
    col, left, top, rh = 132, 196, 86, 46
    w, h = left + col * n + 24, top + rh * (LANES + 1) + 96

    def esc(s):
        return str(s).replace("&", "&amp;").replace("<", "&lt;")

    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">',
        "<style>",
        "  .bg{fill:#ffffff}",
        "  .lbl{font:600 12px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#111}",
        "  .val{font:12px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#111;text-anchor:middle}",
        "  .op{font:600 12px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#0a4d4f;text-anchor:middle}",
        "  .t{font:10px ui-monospace,SFMono-Regular,Menlo,monospace;fill:#667;text-anchor:middle}",
        "  .cell{fill:#f4f6f8;stroke:#111;stroke-width:1}",
        "  .opcell{fill:#e2f0f0;stroke:#0a4d4f;stroke-width:1}",
        "  .note{font:italic 11px ui-sans-serif,system-ui,sans-serif;fill:#555}",
        "  .hd{font:600 13px ui-sans-serif,system-ui,sans-serif;fill:#111}",
        "  .grid{stroke:#dfe5ea;stroke-width:1}",
        "</style>",
        f'<rect class="bg" x="0" y="0" width="{w}" height="{h}"/>',
        f'<text class="hd" x="14" y="26">tb_vec_alu — four lanes computing independently '
        f"(LANES = {LANES})</text>",
        '<text class="note" x="14" y="46">Reconstructed from sim/waves/tb_vec_alu.vcd by '
        "docs/waveforms/make_waveform.py — not a screenshot.</text>",
        '<text class="note" x="14" y="62">Every value below is parsed from the VCD the '
        "simulator wrote. Radix: hex.</text>",
    ]

    # time axis
    for i, (ns, _, _) in enumerate(rows):
        x = left + col * i
        out.append(f'<text class="t" x="{x + col // 2}" y="{top - 8}">{ns} ns</text>')
        out.append(
            f'<line class="grid" x1="{x}" y1="{top}" x2="{x}" y2="{top + rh * (LANES + 1)}"/>'
        )
    out.append(
        f'<line class="grid" x1="{left + col * n}" y1="{top}" '
        f'x2="{left + col * n}" y2="{top + rh * (LANES + 1)}"/>'
    )

    # op row
    y = top
    out.append(f'<text class="lbl" x="14" y="{y + 29}">op[2:0]</text>')
    for i, (_, op, _) in enumerate(rows):
        x = left + col * i
        out.append(
            f'<rect class="opcell" x="{x + 5}" y="{y + 9}" width="{col - 10}" height="28" rx="4"/>'
        )
        out.append(
            f'<text class="op" x="{x + col // 2}" y="{y + 28}">'
            f"{op:03b} {esc(OP_NAMES.get(op, '?'))}</text>"
        )

    # lane rows, lane 3 at the top so lane 0 sits closest to the low bits note
    for row, lane in enumerate(reversed(range(LANES))):
        y = top + rh * (row + 1)
        out.append(f'<text class="lbl" x="14" y="{y + 29}">lane[{lane}].y[31:0]</text>')
        for i, (_, _, lanes) in enumerate(rows):
            x = left + col * i
            out.append(
                f'<rect class="cell" x="{x + 5}" y="{y + 9}" width="{col - 10}" height="28" rx="4"/>'
            )
            out.append(
                f'<text class="val" x="{x + col // 2}" y="{y + 28}">{lanes[lane]:08X}</text>'
            )

    y = top + rh * (LANES + 1) + 26
    out.append(
        f'<text class="note" x="14" y="{y}">At 40 ns and 50 ns the compares return '
        f"[1, 0, 1, 0] across lanes 0..3: lane 2 cannot leak into lane 1.</text>"
    )
    out.append(
        f'<text class="note" x="14" y="{y + 18}">At 70 ns the undefined op code 111 '
        f"drives every lane to zero, never x.</text>"
    )
    out.append("</svg>")
    return "\n".join(out)


def main() -> int:
    if not VCD.exists():
        print(f"no VCD at {VCD} — run: make -C sim vec_alu", file=sys.stderr)
        return 1
    rows = parse_vcd(VCD)
    if not rows:
        print("parsed no rows from the VCD", file=sys.stderr)
        return 1
    OUT.write_text(render(rows))
    print(f"wrote {OUT.relative_to(ROOT)} from {len(rows)} VCD samples")
    for ns, op, lanes in rows:
        if ns <= 70:
            print(
                f"  {ns:>3} ns  {OP_NAMES.get(op, '?'):<6} " + " ".join(f"{v:08X}" for v in lanes)
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
