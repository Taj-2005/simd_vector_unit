# `results/` — the numbers the report cites

**Cite these files.** Owner: **Jivit** for the cycle data, **Taj** for the
synthesis data.

| File | Contents | Owner |
| :--- | :--- | :--- |
| `cycle_counts.csv` | scalar vs SIMD: cycles, elements/cycle, speed-up for the 16-element add | Jivit |
| `synthesis.csv` | LUTs, flip-flops, Fmax per module, if a tool ran | Taj |

Both are **templates with headers and no data** until the simulations run. An
empty row is honest; a plausible-looking number that no tool produced is not.

## Rules

1. **Every number comes from a tool**, not from arithmetic on paper.
   `cycle_count` is a register inside each top, read by the testbench.
2. **Both machines are counted the same way** — the rules are fixed in
   [`docs/cycle_counting.md`](../docs/cycle_counting.md), written before the
   numbers were collected.
3. **Report what was measured.** If the speed-up is 3.4× rather than 4×, the
   report says 3.4× and explains the gap. A ratio above 4× on a 4-lane
   non-pipelined machine means the two sides were counted differently — find
   that before reporting it.
4. **If synthesis did not run, say so in the report.** "No synthesis tool was
   available in the Phase I environment; planned for Phase II" is a complete and
   acceptable sentence. Quietly omitting the section is not.
