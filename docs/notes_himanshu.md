# What I built and why — Himanshu Pandey

| | |
| :--- | :--- |
| **Enrollment** | 2401020095 |
| **GitHub** | [@14-himanshu](https://github.com/14-himanshu) |
| **Role** | Datapath · ALU lanes, vector ALU, final video edit |
| **Branch prefix** | `feat/himanshu-*` |
| **Report section** | Proposed Solution 4.2 — lane and datapath design |
| **Video slot** | 2:00–2:40 · **also edits and uploads the final video** |

## What I built

1. **`rtl/lane_alu.v`** — _TODO: 32-bit ALU, six ops plus optional SHL._
2. **`rtl/vec_alu.v`** — _TODO: `LANES` copies in a generate loop._
3. **`tb/tb_lane_alu.v`** and **`tb/tb_vec_alu.v`** — _TODO_
4. **ALU waveform** showing four lanes computing together — `docs/waveforms/`
5. **The final video** — stitched from all five clips, under 5:00, uploaded
   unlisted. Link in [`video/README.md`](../video/README.md).

## Why I built it that way

_TODO. The decisions to record:_

- _Why `LANES` is a parameter and not a literal 4._
- _Why compares return 1 or 0 in bit 0 rather than an all-ones mask._
- _Why CMPLT is signed, and what an unsigned comparator would still pass._
- _What the generate loop costs in area versus a hand-written four-lane block._

## Questions I should be able to answer in the viva

- Point at the waveform and show that lane 2 cannot affect lane 1.
- What exactly changes in the design if `LANES` goes from 4 to 8?
- Why is there no carry between lanes, and when would you want one?
