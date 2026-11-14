# What I built and why — Parthraj Singh Bhati

| | |
| :--- | :--- |
| **Enrollment** | 2401010320 |
| **GitHub** | [@parthrajsinghbhati](https://github.com/parthrajsinghbhati) |
| **Role** | Integration lead · spec freeze, control unit, `simd_top`, submission |
| **Branch** | `parth/control-integration` |
| **Report section** | Proposed Solution 4.1 — architecture and control (`report/section_4_1_architecture.tex`) |
| **Video slots** | 0:40–1:25 (architecture & datapath) and 4:20–4:50 (summary & demo) |

## What I built

1. **The frozen spec** ([`docs/spec.md`](spec.md) + [`rtl/simd_defs.vh`](../rtl/simd_defs.vh)):
   Confirmed and froze the 16-bit ISA, opcode mapping, memory addressing (`instr[3:0]`), store source register (`vs1` via `raddr1`), and cycle-counting rules.
2. **`rtl/ctrl_unit.v`**: Pure combinational 16-bit instruction decoder generating `we`, `waddr`, `raddr1`, `raddr2`, `alu_op`, `mem_rd`, `mem_wr`, and `halt`.
3. **`tb/tb_ctrl_unit.v`**: Exhaustive directed unit testbench verifying every opcode (arithmetic, logic, compares, shift, memory, halt) and undefined NOP cases; 13/13 checks passing.
4. **`rtl/instr_mem.v`**: Parameterised 32-word program ROM loaded via `$readmemh`, with combinational read and default `HALT` padding.
5. **`sim/prog_demo.hex` & `sim/demo_data.hex`**: Clean self-contained verification program and vector dataset for integration testing.
6. **`rtl/simd_top.v`**: Top-level single-cycle SIMD processor integrating fetch, decode, register file, vector ALU, data memory, write-back multiplexer, and cycle counter.
7. **`sim/stubs/`**: Non-invasive throwaway behavioral stubs (`lane_alu.v`, `vec_alu.v`, `vreg_file.v`, `dmem.v`) to enable early integration testing without altering teammates' files.
8. **`tb/tb_simd_top.v`**: Self-checking integration testbench checking vector execution, lane-by-lane memory write-back, and cycle counting; 7/7 checks passing.
9. **`report/section_4_1_architecture.tex`**: IEEE-style report section documenting architecture, 16-bit encoding, control signal decode table, and datapath flow.

## Why I built it that way

- **Direct ALU Opcode Mapping (`alu_op = instr[14:12]`):**
  By numbering arithmetic/logic opcodes `0000` through `0110`, their low 3 bits directly match `alu_op[2:0]`. Bit 3 (`0xxx` vs `1xxx`) separates compute from memory/control. This avoids multi-level decoding tables and keeps combinational delay minimal.
- **`VST` Source Register Convention (`raddr1 = vs1`):**
  In `VST vs1, [addr]`, the source vector is taken from `vs1` (`instr[8:6]`). Since `raddr1` is already wired to `vs1`, read port 1 directly drives memory write data (`dmem.wdata = rdata1`). This eliminates the need for an address multiplexer at register file read port 1.
- **Inert Undefined Opcodes (NOP):**
  Any undefined opcode defaults to `we = 0`, `mem_rd = 0`, `mem_wr = 0`, `halt = 0`, preventing unintended state corruption or hang.
- **Cycle-Counting Convention (Excluding HALT):**
  `cycle_count` increments strictly for active instruction cycles executed after reset deassertion. When `HALT` is reached, `done` asserts, the PC freezes, and `cycle_count` does not count the HALT cycle. Jivit's scalar core follows this identical rule for an honest comparison.
- **Single-Cycle Unpipelined Model for Phase I:**
  A 1-cycle-per-instruction design provides a clean baseline that cleanly demonstrates a ~4× speed-up from SIMD vector parallelism alone, without confounding pipeline hazards, forwarding, or branch penalties.

## Questions I should be able to answer in the viva

- **Walk through the 16 bits of `0x0408` and say what the machine does with it:**
  - `0x0408` in binary: `0000 0100 0000 1000`.
  - `instr[15:12] = 0000`: `OP_VADD` (vector add).
  - `instr[11:9]  = 010`: `vd = V2` (destination register).
  - `instr[8:6]   = 000`: `vs1 = V0` (first source register).
  - `instr[5:3]   = 001`: `vs2 = V1` (second source register).
  - `instr[2:0]   = 000`: unused.
  - The control unit sets `we = 1`, `mem_rd = 0`, `mem_wr = 0`, `halt = 0`, `alu_op = 000` (ADD).
  - `vreg_file` reads `V0` onto `rdata1` and `V1` onto `rdata2`.
  - `vec_alu` computes `y = V0 + V1` across all 4 lanes in parallel.
  - At the next rising clock edge, `wdata = alu_y` is written into register `V2`, and `pc` increments by 1.
- **What would change in `ctrl_unit` if `LANES` became 8?**
  - **Nothing.** The control unit is completely lane-agnostic. It decodes 16-bit instructions into 3-bit register addresses and 3-bit ALU opcodes. Only `vec_alu`, `vreg_file`, and `dmem` scale their data widths with `LANES * 32`.
- **How does the control unit know whether to write the ALU result or the memory read data back to the register file?**
  - Via the `mem_rd` control line: `mem_rd` asserts high exclusively for `VLD` (`opcode == 1000`). The write-back multiplexer is `assign rf_wdata = mem_rd ? dmem_rdata : alu_y;`.
