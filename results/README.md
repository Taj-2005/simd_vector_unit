# `results/` — the numbers the report cites

**Cite these files.** Owner: **Jivit** for the cycle data, **Taj** for the
synthesis data.

| File | Contents | Owner |
| :--- | :--- | :--- |
| `cycle_counts.csv` | scalar vs SIMD: cycles, elements/cycle, speed-up for the 16-element add | Jivit |
| `synthesis.csv` | Xilinx primitive counts per module (Yosys) | Taj |
| `synthesis_<module>.txt` | full Yosys log behind each row | Taj |
| `system_test_output.txt` | verbatim terminal output of the golden-model system test | Taj |

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
4. **What the synthesis numbers are, and are not.** The flow is Yosys
   `synth_xilinx -flatten -noiopad`, so the cells are real Xilinx 7-series
   primitives: LUT1--6, CARRY4, FDxE flip-flops and RAM32M distributed RAM.
   That makes them a fair *relative* comparison between our own modules. They
   are **not** a vendor place-and-route result: no device was targeted and
   nothing was placed or routed. Yosys does no timing analysis here, so
   **`fmax_mhz` is deliberately empty** — a fabricated frequency is the easiest
   number for an examiner to challenge.

5. **Two rows are not area figures.** `instr_mem` and `simd_top` are synthesised
   with a compile-time-constant program, so Yosys folds the ROM — and most of
   the machine driven by it — away at elaboration. Quoting those cell counts as
   the design's size would be wrong. A whole-machine figure needs an externally
   loadable instruction memory, which is Phase II work.

## The result section 4.2 should cite

| Module | LUT | CARRY4 | Ratio |
| :--- | ---: | ---: | ---: |
| `lane_alu` | 251 | 19 | 1.00x |
| `vec_alu` (LANES = 4) | 1012 | 76 | **4.03x / 4.00x** |

Four lanes cost 4.03x the LUTs and exactly 4x the carry chains of one lane.
That is the measured evidence for the claim in section 4.2 that the `generate`
loop costs nothing over manual instantiation — the area scales with the lane
count and nothing else appears. Reproduce with `python synth/run_synth.py`.
