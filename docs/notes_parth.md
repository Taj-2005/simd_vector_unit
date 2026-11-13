# What I built and why — Parthraj Singh Bhati

| | |
| :--- | :--- |
| **Enrollment** | 2401010320 |
| **GitHub** | [@parthrajsinghbhati](https://github.com/parthrajsinghbhati) |
| **Role** | Integration lead · spec, control unit, `simd_top`, submission |
| **Branch prefix** | `feat/parth-*` |
| **Report section** | Proposed Solution 4.1 — architecture and control |
| **Video slots** | 0:40–1:25 and 4:20–4:50 |

## What I built

1. **The frozen spec** ([`docs/spec.md`](spec.md) + [`rtl/simd_defs.vh`](../rtl/simd_defs.vh))
   — _TODO: confirm or edit the proposed ISA, then post "spec is frozen"._
2. **`rtl/ctrl_unit.v`** — _TODO_
3. **`rtl/instr_mem.v`** — _TODO_
4. **`rtl/simd_top.v`** — _TODO_
5. **`tb/tb_ctrl_unit.v`** — _TODO_
6. **Integration** — wiring `simd_top` from four people's modules, and the
   Google Form submission.

## Why I built it that way

_TODO. Decisions worth writing down, because they will be asked about:_

- _Why the opcode numbering makes `alu_op = instr[14:12]` fall out for free._
- _Which register `VST` reads from, and how the control unit expresses that._
- _What an undefined opcode does, and why it must not raise `we`._
- _Where the cycle counter lives and exactly which cycles it counts._
- _Why one instruction per cycle with no pipeline is the right Phase I scope._

## Questions I should be able to answer in the viva

- Walk through the 16 bits of `0x0408` and say what the machine does with it.
- What would change in `ctrl_unit` if `LANES` became 8?
- How does the control unit know whether to write the ALU result or the memory
  read data back to the register file?
