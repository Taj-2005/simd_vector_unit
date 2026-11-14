# Frozen spec — 4-lane SIMD vector unit

**Status: FROZEN by Parthraj Singh Bhati (Integration Lead).** This specification
is confirmed and frozen for Phase I implementation. All five team members code against
the frozen interfaces, instruction encoding, and cycle-counting rules defined here.
No field widths, opcodes, or port definitions may change without unanimous team consensus.

The machine-readable copy of this document is [`rtl/simd_defs.vh`](../rtl/simd_defs.vh).
If a number changes in one, it changes in the other **in the same commit**.

---

## 1. What we are building

A 4-lane SIMD vector unit with 8 vector registers, running vector add, subtract,
AND, OR and compare in one cycle each, plus a one-ALU scalar baseline so the
speed-up can be measured rather than asserted.

| Item | Decision |
| :--- | :--- |
| Lanes | 4, as `parameter LANES` — 8 lanes must stay a one-line change |
| Lane width | 32 bits, so a vector is 128 bits |
| Vector registers | 8 (V0–V7), 2 read ports, 1 write port |
| Operations | VADD, VSUB, VAND, VOR, VCMPEQ, VCMPLT; VSHL optional |
| Memory ops | VLD, VST on a 16-word, 128-bit-wide data memory, plus HALT |
| Instruction word | 16 bits |
| Benchmark | Add two 16-element arrays: 4 vector adds against 16 scalar adds |
| Metrics | Cycle count, elements per cycle, speed-up; LUTs and Fmax if a synthesis tool runs |
| Tools | Icarus Verilog + GTKWave; Vivado or Yosys for synthesis |

Issue cost is one instruction per cycle, with no pipelining. That is a
deliberate simplification, and it is the reason the speed-up is expected to
approach the lane count rather than exceed it.

---

## 2. ALU op codes — `alu_op[2:0]`

Shared by `lane_alu`, `vec_alu` and the scalar baseline.

| `alu_op` | Operation | Definition |
| :--- | :--- | :--- |
| `000` | ADD | `y = a + b`, modulo 2³², no carry out |
| `001` | SUB | `y = a - b`, modulo 2³², no borrow out |
| `010` | AND | bitwise |
| `011` | OR | bitwise |
| `100` | CMPEQ | `y = {31'b0, (a == b)}` |
| `101` | CMPLT | `y = {31'b0, ($signed(a) < $signed(b))}` |
| `110` | SHL | `y = a << b[4:0]` — **optional**, drop before any required item |
| `111` | — | undefined; output must be 0, not `x` |

Two details that are easy to get wrong and that both testbenches assert:

- **Compares are narrow.** The result is 1 or 0 in bit 0 with zeros in bits 31:1,
  not an all-ones mask. A mask is the other common convention, and mixing the
  two is a silent mismatch against the golden model.
- **CMPLT is signed.** `-1 < 1` must be true. An unsigned comparator passes
  every other test case.

---

## 3. Instruction encoding — 16 bits

### Register–register form

```
 15        12 11      9 8       6 5       3 2     0
+------------+---------+---------+---------+-------+
|   opcode   |   vd    |   vs1   |   vs2   | unused|
+------------+---------+---------+---------+-------+
```

### Memory form (VLD, VST)

```
VLD:
 15        12 11      9 8                   4 3       0
+------------+---------+---------------------+---------+
|   opcode   |   vd    |       unused        | address |
+------------+---------+---------------------+---------+

VST:
 15        12 11      9 8       6 5         4 3       0
+------------+---------+---------+-----------+---------+
|   opcode   | unused  |   vs1   |  unused   | address |
+------------+---------+---------+-----------+---------+
```

`addr` (`instr[3:0]`) is the 4-bit data-memory address, used only by `VLD`/`VST`
(which ignore `vs2`).
- For `VLD`: `vd` (`instr[11:9]`) is the destination register (`vd <- dmem[addr]`).
- For `VST`: `vs1` (`instr[8:6]`) is the source data register (`dmem[addr] <- vs1`),
  read directly via `raddr1 = vs1` from the register file.

### Op codes — `instr[15:12]`

| Opcode | Instruction | Effect |
| :--- | :--- | :--- |
| `0000` | `VADD vd, vs1, vs2` | `V[vd] = V[vs1] + V[vs2]`, lanewise |
| `0001` | `VSUB vd, vs1, vs2` | lanewise subtract |
| `0010` | `VAND vd, vs1, vs2` | lanewise AND |
| `0011` | `VOR vd, vs1, vs2` | lanewise OR |
| `0100` | `VCMPEQ vd, vs1, vs2` | lanewise equality |
| `0101` | `VCMPLT vd, vs1, vs2` | lanewise signed less-than |
| `0110` | `VSHL vd, vs1, vs2` | lanewise shift left — **optional** (decode implemented) |
| `1000` | `VLD vd, addr` | `V[vd] = DMEM[addr]` |
| `1001` | `VST vs1, addr` | `DMEM[addr] = V[vs1]` |
| `1111` | `HALT` | stop fetching; freeze PC; `done` goes high |
| other  | NOP | undefined opcode: inert (no writes, no halt) |

**The numbering is load-bearing.** For every arithmetic and logic instruction the
low three bits of the opcode *are* the ALU op code, so the control unit wires
`alu_op = instr[14:12]` (or `opcode[2:0]`) with no decode table. Bit 3 of the opcode
separates compute (`0xxx`) from memory and control (`1xxx`). Keep both properties if
anything is renumbered.

### Cycle Counting Rules
- `HALT` sets `done` and freezes the PC.
- `cycle_count` counts clock cycles of executed instructions after reset, **excluding the HALT cycle**.
- Jivit's scalar baseline must follow the exact same counting convention for an honest comparison.

---

## 4. Module interfaces

Frozen. These port lists are what four other people instantiate, so change them
only by agreement with the module's owner.

| Module | Inputs | Outputs |
| :--- | :--- | :--- |
| `lane_alu` | `a[31:0]`, `b[31:0]`, `op[2:0]` | `y[31:0]` |
| `vec_alu` (4 × `lane_alu`) | `a[127:0]`, `b[127:0]`, `op[2:0]` | `y[127:0]` |
| `vreg_file` | `clk`, `we`, `waddr[2:0]`, `wdata[127:0]`, `raddr1[2:0]`, `raddr2[2:0]` | `rdata1[127:0]`, `rdata2[127:0]` |
| `dmem` | `clk`, `we`, `addr[3:0]`, `wdata[127:0]` | `rdata[127:0]` |
| `instr_mem` | `addr[5:0]` | `instr[15:0]` |
| `ctrl_unit` | `instr[15:0]` | `we`, `waddr[2:0]`, `raddr1[2:0]`, `raddr2[2:0]`, `alu_op[2:0]`, `mem_rd`, `mem_wr`, `halt` |
| `simd_top` | `clk`, `rst` | `done`, `cycle_count[31:0]` |
| `scalar_top` | `clk`, `rst` | `done`, `cycle_count[31:0]` |

### Lane ordering

**Lane 0 is the low-order lane**: lane *i* occupies bits `[i*32 +: 32]` of the
128-bit vector. The `generate` loop in `vec_alu.v`, the packing in
[`golden/golden_model.py`](../golden/golden_model.py) and every
`sim/vectors/*.hex` file follow this. Reversing it does not fail compilation —
it fails `tb_system` with four wrong lanes and no obvious cause.

---

## 5. Data memory layout

16 words of 128 bits. The benchmark uses the first 12:

| Words | Contents |
| :--- | :--- |
| 0–3 | A, the first 16-element array (4 elements per word) |
| 4–7 | B, the second array |
| 8–11 | C, where results are stored |
| 12–15 | unused, free for a second program |

`sim/vectors/dmem_init.hex` holds words 0–7 and is loaded with `$readmemh`;
`tb/tb_system.v` checks words 8–11.

---

## 6. Benchmark

16 elements, 4 per vector, so 4 vector iterations against 16 scalar ones.

```
SIMD (sim/programs/bench_add16.hex)        Scalar (scalar_top)
  repeat 4 times:                            repeat 16 times:
    VLD  V0, [A+i]                             load  A[i]
    VLD  V1, [B+i]                             load  B[i]
    VADD V2, V0, V1                            add
    VST  V2, [C+i]                             store C[i]
  HALT
```

17 instructions against roughly 64 scalar operations. The expected result is a
speed-up near 4× — and "near" is the honest word. Whatever the simulation
measures is what goes in the report, with the difference explained;
[`cycle_counting.md`](cycle_counting.md) fixes the rules so the two machines are
counted the same way.

---

## 7. What is explicitly out of scope for Phase I

No pipelining, no hazard detection, no vector length register, no masking or
predication, no scatter/gather, no cache. Phase II picks from this list. Saying
so in the report is worth more than pretending the omissions were not noticed.
