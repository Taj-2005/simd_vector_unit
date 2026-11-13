# What I built and why — Jivit Rana

| | |
| :--- | :--- |
| **Enrollment** | 2401010202 |
| **GitHub** | [@Jivit87](https://github.com/Jivit87) |
| **Role** | Baseline and evaluation · scalar core, benchmarks, the speed-up number |
| **Branch prefix** | `feat/jivit-*` |
| **Report sections** | Proposed Solution 4.3 — baseline and evaluation method; Individual Contributions table |
| **Video slot** | 3:25–4:20 |

## What I built

1. **`scalar/scalar_top.v`** — _TODO: one-ALU baseline over 16 elements, reusing
   Himanshu's `lane_alu`._
2. **`tb/tb_scalar_top.v`** — _TODO_
3. **`sim/programs/*.hex`** — benchmark programs, encoding agreed with Parth.
4. **[`docs/cycle_counting.md`](cycle_counting.md)** — the counting rules, written
   before the numbers were collected.
5. **`results/cycle_counts.csv`** — the comparison table: cycles, elements per
   cycle, speed-up.
6. **The Individual Contributions table** — three lines from each member.

## Why I built it that way

_TODO. The decisions to record:_

- _Why the baseline reuses `lane_alu` instead of its own adder._
- _Each row of the cycle-counting table, and why the two machines are counted
  the same way._
- _What the measured speed-up was, and why it is not exactly 4×._

## Questions I should be able to answer in the viva

- What is the theoretical maximum speed-up here, and why can't we exceed it?
- If the measured speed-up were above 4×, what would that tell you about the
  measurement?
- What would change if the arrays were 17 elements instead of 16?
