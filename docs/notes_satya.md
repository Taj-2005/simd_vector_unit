# What I built and why — Satya Yadav

| | |
| :--- | :--- |
| **Enrollment** | 2401010427 |
| **GitHub** | [@ACE-pwd](https://github.com/ACE-pwd) |
| **Role** | Storage · vector register file, data memory, literature review |
| **Branch prefix** | `feat/satya-*` |
| **Report section** | Literature Review |
| **Video slot** | 1:25–2:00 |

## What I built

1. **`rtl/vreg_file.v`** — _TODO: 8 × 128-bit, two read ports, one write port._
2. **`rtl/dmem.v`** — _TODO: 16 × 128-bit, clocked write, combinational read._
3. **`tb/tb_vreg_file.v`** and **`tb/tb_dmem.v`** — _TODO_
4. **Register-file waveform** — `docs/waveforms/` — _TODO_
5. **Literature Review** — [`docs/literature_review.md`](literature_review.md)
   → `report/sections/01_literature_review.tex`
6. **References** — 6 to 8 verified entries, collected into
   [`docs/refs.bib`](refs.bib) for Taj to format.

## Why I built it that way

_TODO. The decisions to record:_

- _Same-cycle read and write: does a read return the old or the new value, and
  why? `simd_top`'s `VST`-after-`VADD` timing depends on this answer._
- _Why the reads are combinational rather than clocked._
- _How `$readmemh` initialises the data memory, and what happens when the file
  is short or the path is wrong._

## Questions I should be able to answer in the viva

- Why does a 4-lane SIMD machine need a 128-bit-wide register file rather than
  four 32-bit ones?
- What does "2 read ports, 1 write port" cost in hardware?
- Where does our design sit in Flynn's taxonomy, and why?
