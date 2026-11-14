# SIMD Vector Processing Unit

> **Video:** _TODO — paste the unlisted link here before submitting._

A parameterised 4-lane SIMD vector unit in Verilog, verified against an
independent Python golden model and compared against a one-ALU scalar baseline
on the same benchmark and the same data.

**Course project — Modern Computer Architecture, Project 11.** Phase I of two.

| Phase | Scope |
| :--- | :--- |
| **Phase I** (this repo, current) | 4-lane SIMD unit, scalar baseline, golden-model verification, cycle comparison |
| **Phase II** (planned) | Pipelining, vector length register, masking, full Results and Discussion |

**Marks: report 10, video 15, GitHub 5.** Every member owns one RTL block, one
testbench, one report section and one video slot, so all three components depend
on all five of us. Deadline **16 Nov 2026, 11:59 PM IST**; we target 9 PM.

---

## Current status

The repository scaffold is in place (Taj): layout, build system, CI, the golden
model, the system testbench and the documentation set.

**Every RTL module is a stub** with its frozen port list and a TODO naming its
owner. Stubs compile and elaborate, so nobody is blocked on anyone else's port
list — which is the thing that actually costs a day on a project this size.

```
make -C sim lint         # 7/7 testbenches elaborate     ✓
make -C sim test         # 7/7 run; all report SKIP      — no checks written yet
pytest tests/            # 32/32 golden-model tests pass ✓
make -C docs/diagrams    # 3 diagrams -> PNG + PDF       ✓
```

A testbench with nothing asserted reports **SKIP**, never PASS. See
[§6](#6-what-the-simulation-output-means).

> **Read [docs/scaffold_notes.md](docs/scaffold_notes.md) first.** It lists
> everything in this repository that goes beyond the team plan, and the five
> open decisions Parth needs to confirm when freezing the spec — the
> instruction op codes, where the `VLD`/`VST` address sits, which register
> `VST` reads, and two more.

**Next, in dependency order:**

- **Parthraj** → confirm or edit the proposed spec, post "spec is frozen", then
  `ctrl_unit`, `instr_mem`, `simd_top`
- **Himanshu** → `lane_alu` **first and pushed early** (Jivit needs the port
  list), then `vec_alu`
- **Satya** → `vreg_file` and `dmem` **before Saturday noon** so Parth can
  integrate
- **Jivit** → `scalar_top`, then the cycle-counting rules and the comparison
- **Taj** → synthesis, waveform screenshots, then the report PDF (golden model and block diagrams are done)

---

## 1. What we are building

A 4-lane SIMD unit with 8 vector registers that runs vector ADD, SUB, AND, OR
and compare in one cycle each, plus a one-ALU scalar baseline so the speed-up
can be **measured** rather than asserted.

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
| Tools | Icarus Verilog + GTKWave (free); Vivado or Yosys for synthesis |

Full spec, including the instruction encoding and the data-memory layout:
**[docs/spec.md](docs/spec.md)**. Its machine-readable twin is
[`rtl/simd_defs.vh`](rtl/simd_defs.vh) — a number that changes in one changes in
the other in the same commit.

> **The spec is FROZEN by Parthraj Singh Bhati (Integration Lead).** The ISA,
> instruction encoding, interface tables, and cycle-counting rules below are final
> for Phase I. All five team members code against these frozen definitions.

### ALU op codes — `alu_op[2:0]`

| `alu_op` | Operation | Definition |
| :--- | :--- | :--- |
| `000` | ADD | `a + b`, modulo 2³², no carry out |
| `001` | SUB | `a - b`, modulo 2³² |
| `010` | AND | bitwise |
| `011` | OR | bitwise |
| `100` | CMPEQ | `{31'b0, (a == b)}` |
| `101` | CMPLT | `{31'b0, ($signed(a) < $signed(b))}` |
| `110` | SHL | `a << b[4:0]` — **optional**, dropped before any required item |

Two conventions that are easy to get wrong, and that both the golden model and
the testbenches assert:

- **Compares are narrow** — 1 or 0 in bit 0 with zeros above, not an all-ones
  mask.
- **CMPLT is signed** — `-1 < 1` must hold. An unsigned comparator passes every
  other case.

### Fixed Instruction Encoding — 16 bits

Bit breakdown:
`instr[15:12]` opcode, `instr[11:9]` vd, `instr[8:6]` vs1, `instr[5:3]` vs2, `instr[3:0]` addr
(`addr` is used only by `VLD`/`VST`, which ignore `vs2`).

```
Register-Register (Compute: VADD, VSUB, VAND, VOR, VCMPEQ, VCMPLT, VSHL):
 15        12 11      9 8       6 5       3 2     0
+------------+---------+---------+---------+-------+
|   opcode   |   vd    |   vs1   |   vs2   | unused|
+------------+---------+---------+---------+-------+

Memory Form (VLD, VST):
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

| Opcode | Instruction | Description |
| :--- | :--- | :--- |
| `0000` | `VADD vd, vs1, vs2` | `vd <- vs1 + vs2` |
| `0001` | `VSUB vd, vs1, vs2` | `vd <- vs1 - vs2` |
| `0010` | `VAND vd, vs1, vs2` | `vd <- vs1 & vs2` |
| `0011` | `VOR vd, vs1, vs2` | `vd <- vs1 \| vs2` |
| `0100` | `VCMPEQ vd, vs1, vs2` | `vd <- (vs1 == vs2) ? 1 : 0` |
| `0101` | `VCMPLT vd, vs1, vs2` | `vd <- ($signed(vs1) < $signed(vs2)) ? 1 : 0` |
| `0110` | `VSHL vd, vs1, vs2` | `vd <- vs1 << vs2[4:0]` *(optional; decode implemented)* |
| `1000` | `VLD vd, addr` | `vd <- dmem[addr]` |
| `1001` | `VST vs1, addr` | `dmem[addr] <- vs1` (source is `vs1`, read via `raddr1`) |
| `1111` | `HALT` | Stop execution, set `done=1`, freeze `PC` |
| other  | NOP | Unknown opcodes behave like NOP (no writes, no halt) |

**Key Decode and Datapath Rules:**
- `alu_op = opcode[2:0]` for opcodes `0000`–`0110`, directly matching the ALU op table.
- `ctrl_unit` ports: input `instr[15:0]`; output `we`, `waddr[2:0]`, `raddr1[2:0]`, `raddr2[2:0]`, `alu_op[2:0]`, `mem_rd`, `mem_wr`, `halt`. Pure combinational.
- Fixed register address wiring: `raddr1 = vs1` (`instr[8:6]`), `raddr2 = vs2` (`instr[5:3]`), `waddr = vd` (`instr[11:9]`).
- For `VST`, `raddr1 = vs1` is the data source written to memory.
- `simd_top` integration: One instruction per clock. Write-back mux: `wdata = mem_rd ? dmem_rdata : alu_y`.
- **Cycle-counting rule:** `HALT` sets `done` and freezes the PC. `cycle_count` counts clock cycles of executed instructions after reset, **excluding the HALT cycle**. Jivit's scalar baseline must count the same way.

---

## 2. Module interfaces

Frozen. These port lists are what four other people instantiate, so change one
only by agreement with its owner — and push the port list early even if the body
is unfinished.

| Module | Inputs | Outputs | Owner |
| :--- | :--- | :--- | :--- |
| `lane_alu` | `a[31:0]`, `b[31:0]`, `op[2:0]` | `y[31:0]` | Himanshu |
| `vec_alu` (4 × `lane_alu`) | `a[127:0]`, `b[127:0]`, `op[2:0]` | `y[127:0]` | Himanshu |
| `vreg_file` | `clk`, `we`, `waddr[2:0]`, `wdata[127:0]`, `raddr1[2:0]`, `raddr2[2:0]` | `rdata1[127:0]`, `rdata2[127:0]` | Satya |
| `dmem` | `clk`, `we`, `addr[3:0]`, `wdata[127:0]` | `rdata[127:0]` | Satya |
| `instr_mem` | `addr[5:0]` | `instr[15:0]` | Parthraj |
| `ctrl_unit` | `instr[15:0]` | `we`, `waddr[2:0]`, `raddr1[2:0]`, `raddr2[2:0]`, `alu_op[2:0]`, `mem_rd`, `mem_wr`, `halt` | Parthraj |
| `simd_top` | `clk`, `rst` | `done`, `cycle_count[31:0]` | Parthraj |
| `scalar_top` | `clk`, `rst` | `done`, `cycle_count[31:0]` | Jivit |

**Lane 0 is the low-order lane**: lane *i* occupies bits `[i*32 +: 32]`. The
`generate` loop in `vec_alu.v`, the packing in the golden model and every
`sim/vectors/*.hex` file agree on this. Reversing it compiles cleanly and fails
the system test with four wrong lanes and no obvious cause.

---

## 3. Repository structure

```
simd_vector_unit/
├── rtl/
│   ├── simd_defs.vh           # geometry, ALU ops, opcodes - machine-readable spec
│   ├── lane_alu.v             # 32-bit ALU lane                      [Himanshu]
│   ├── vec_alu.v              # LANES x lane_alu, generate loop      [Himanshu]
│   ├── vreg_file.v            # 8 x 128-bit, 2R1W                    [Satya]
│   ├── dmem.v                 # 16 x 128-bit, $readmemh init         [Satya]
│   ├── ctrl_unit.v            # 16-bit instruction decode            [Parthraj]
│   ├── instr_mem.v            # program ROM                          [Parthraj]
│   └── simd_top.v             # integration + cycle counter          [Parthraj]
├── scalar/
│   └── scalar_top.v           # one-ALU baseline, reuses lane_alu    [Jivit]
├── tb/
│   ├── tb_lane_alu.v  tb_vec_alu.v                                   [Himanshu]
│   ├── tb_vreg_file.v tb_dmem.v                                      [Satya]
│   ├── tb_ctrl_unit.v                                                [Parthraj]
│   ├── tb_scalar_top.v                                               [Jivit]
│   └── tb_system.v            # self-checking, golden-model based    [Taj]
├── sim/
│   ├── Makefile               # the only way the simulation is run
│   ├── programs/*.hex         # benchmark programs, commented        [Jivit]
│   ├── vectors/*.hex          # golden vectors (generated, committed)
│   ├── build/  waves/         # git-ignored
│   └── README.md
├── golden/
│   ├── golden_model.py        # bit-exact reference for the 6 ops    [Taj]
│   ├── gen_vectors.py         # deterministic vector generation      [Taj]
│   └── README.md
├── tests/
│   └── test_golden_model.py   # 32 tests on the reference itself     [Taj]
├── docs/
│   ├── spec.md                # THE frozen spec
│   ├── phase1_work_plan.md    # editable source of the work plan PDF
│   ├── cycle_counting.md      # how both machines are counted        [Jivit]
│   ├── literature_review.md   # drafting space                       [Satya]
│   ├── video_script.md        # slot-by-slot, 4:50
│   ├── submission_checklist.md
│   ├── refs.bib               # single source of truth for citations
│   ├── notes_<name>.md        # one page per member: "what I built and why"
│   ├── diagrams/              # top level, datapath, lane (PNG + PDF) [Taj]
│   └── waveforms/             # committed GTKWave screenshots
├── report/
│   ├── main.tex               # IEEEtran conference template         [Taj]
│   └── sections/*.tex         # one file per section owner
├── results/
│   ├── cycle_counts.csv       # scalar vs SIMD                       [Jivit]
│   └── synthesis.csv          # LUTs, FFs, Fmax                      [Taj]
├── video/README.md            # the link; clips are not committed
├── .github/workflows/ci.yml   # elaborate, simulate, lint, test
├── pyproject.toml  requirements.txt
└── README.md
```

---

## 4. Setup

Needs Icarus Verilog, GTKWave and Python 3.10+. All free; no licensed tool is
required for Phase I.

```bash
# macOS
brew install icarus-verilog gtkwave

# Ubuntu / WSL
sudo apt-get install -y iverilog gtkwave
```

```bash
git clone https://github.com/<owner>/simd_vector_unit.git
cd simd_vector_unit
pip install -r requirements.txt     # pytest + ruff, for the golden model only
```

Verify the toolchain with `iverilog -V`. Everything below was checked against
Icarus Verilog 13.0.

---

## 5. Running the simulation

Three commands from the repository root:

```bash
make lint     # compile/elaborate every module and testbench (syntax check)
make test     # compile and run all unit and integration testbenches
make system   # run the golden-model-verified system test (tb_system)
```

Running individual unit testbenches:
```bash
make ctrl_unit       # run control unit testbench
make simd_top        # run SIMD integration testbench
make lane_alu        # run ALU lane testbench
make vec_alu         # run vector ALU testbench
make vreg_file       # run vector register file testbench
make dmem            # run data memory testbench
make scalar_top      # run scalar baseline testbench
```

Inspecting waveforms in GTKWave:
```bash
make wave-ctrl_unit  # open tb_ctrl_unit waveform in GTKWave
make wave-simd_top   # open tb_simd_top waveform in GTKWave
make wave-system     # open tb_system waveform in GTKWave
```

Cleaning build artifacts:
```bash
make clean           # remove sim/build/, sim/waves/, and temporary hex files
```

*Note on directory structure*: The top-level `Makefile` automatically delegates all targets to `sim/` (`make -C sim ...`), ensuring that `$readmemh` paths (which are relative to `sim/`) and VCD dumps resolve properly.

---

## 6. What the simulation output means

| Line | Meaning |
| :--- | :--- |
| `PASS tb_x: n/n checks` | ran `n` checks, all passed |
| `SKIP tb_x: no checks written yet` | compiles but asserts nothing — the owner still has work to do |
| `FAIL tb_x: n error(s)` | a real failure; fix it before pushing |

**SKIP is not a pass.** Every testbench counts its checks and reports SKIP while
that count is zero, so a scaffold can never be mistaken for working
verification. CI tolerates SKIP while modules are stubs and fails on any FAIL —
so a module can land before its testbench without blocking the branch, but
nothing ships with a SKIP against it.

`tb_system` additionally reports SKIP, not FAIL, while `simd_top` is a stub:
its `done` output never asserts, and everyone already knows why. Pass
`DEFS=-DDUT_READY` once the integration is wired up and that becomes a hard
failure.

---

## 7. Verification: the golden model

`tb/tb_system.v` does not compare `simd_top` against a hand-written expectation.
It compares it against vectors generated by an independent Python reference in
[`golden/`](golden/), so "the RTL is correct" is a test result rather than an
opinion, and a mismatch points at exactly one of two places.

```bash
make -C sim vectors                     # golden/gen_vectors.py -> sim/vectors/
make -C sim system DEFS=-DDUT_READY     # compare simd_top against it
```

The generator is seeded (`--seed 11`), so every member's regeneration is
byte-identical and the committed vectors always match the committed
expectations. CI fails if they drift — otherwise correct RTL gets blamed for a
stale expectation file.

Vector pair 0 is **crafted rather than random**: random values made every lane
answer the compares identically, which is a test that still passes with the
comparator deleted. Details in [golden/README.md](golden/README.md).

---

## 8. Benchmark and the comparison

16 elements, 4 per vector: 4 vector iterations against 16 scalar ones.

```
SIMD (sim/programs/bench_add16.hex)     Scalar (scalar/scalar_top.v)
  repeat 4 times:                         repeat 16 times:
    VLD  V0, [A+i]                          load  A[i]
    VLD  V1, [B+i]                          load  B[i]
    VADD V2, V0, V1                         add
    VST  V2, [C+i]                          store C[i]
  HALT
```

| Machine | Elements | Cycles | Elements/cycle | Speed-up |
| :--- | ---: | ---: | ---: | ---: |
| `scalar_top` | 16 | — | — | 1.00× |
| `simd_top` (4 lanes) | 16 | — | — | — |

Filled in from `results/cycle_counts.csv` once both simulations run.

Three rules make the comparison mean something, and they are fixed in
[docs/cycle_counting.md](docs/cycle_counting.md) **before** the numbers were
collected:

1. **Same adder.** `scalar_top` instantiates the same `lane_alu`, so the two
   machines differ in how many ALUs run per cycle and in nothing else.
2. **Same memory cost per element.** A vector load moves 4 elements in a cycle;
   a scalar load moves 1 element in a cycle.
3. **Same data**, from the same `sim/vectors/dmem_init.hex`.

Four lanes cannot beat 4× on a non-pipelined, one-instruction-per-cycle machine.
**Whatever the simulation measures is what goes in the report**, with the gap
explained. A measured ratio above 4× means the two sides were counted
differently — find that before reporting it.

---

## 9. Team and ownership

Five members. Everyone owns RTL *and* a testbench *and* report text *and* a
video slot: nobody is only a writer and nobody is only a coder. Everyone must be
able to explain **the whole datapath** in the viva, not only their own block.

### Roster

**Repository owner:** Shaik Tajuddin ([@Taj-2005](https://github.com/Taj-2005))
— created the repository and the scaffold, reviews and merges every pull
request, and is the point of contact for the faculty.

**Integration lead:** Parthraj Singh Bhati
([@parthrajsinghbhati](https://github.com/parthrajsinghbhati)) — owns the frozen
spec, wires `simd_top` together from everyone's modules, and submits the Google
Form.

| Name | Enrollment | Email | GitHub |
| :--- | :--- | :--- | :--- |
| Shaik Tajuddin *(repo owner)* | 2401010436 | shaik.tajuddin2024@nst.rishihood.edu.in | [@Taj-2005](https://github.com/Taj-2005) |
| Parthraj Singh Bhati *(integration lead)* | 2401010320 | parthraj.bhati2024@nst.rishihood.edu.in | [@parthrajsinghbhati](https://github.com/parthrajsinghbhati) |
| Himanshu Pandey | 2401020095 | himanshu.h2024@nst.rishihood.edu.in | [@14-himanshu](https://github.com/14-himanshu) |
| Jivit Rana | 2401010202 | jivit.rana2024@nst.rishihood.edu.in | [@Jivit87](https://github.com/Jivit87) |
| Satya Yadav | 2401010427 | satya.yadav2024@nst.rishihood.edu.in | [@ACE-pwd](https://github.com/ACE-pwd) |

### Ownership

| Member | Code / RTL | Testing and tools | Report section | Video | Branch prefix |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Taj** *(repo owner)* | Python golden model, `tb_system` | repository and build system, block diagrams, synthesis run, GTKWave screenshots; reviews and merges every PR | Abstract, References, IEEE formatting, final PDF | 2:40–3:25 | `feat/taj-*` |
| **Parthraj** *(integration lead)* | `ctrl_unit`, `simd_top`, program ROM | `tb_ctrl_unit`; spec freeze; `simd_top` integration | 4.1 architecture and control | 0:40–1:25, 4:20–4:50 | `feat/parth-*` |
| **Satya** | `vreg_file`, 128-bit `dmem` | `tb_vreg_file`, `tb_dmem`; register-file waveform | Literature Review | 1:25–2:00 | `feat/satya-*` |
| **Himanshu** | `lane_alu`, `vec_alu` | `tb_lane_alu`, `tb_vec_alu`; ALU waveform; **edits and uploads the final video** | 4.2 lane and datapath design | 2:00–2:40 | `feat/himanshu-*` |
| **Jivit** | `scalar_top`, benchmark programs | cycle counters; scalar vs SIMD comparison table | 4.3 baseline and evaluation; Individual Contributions table | 3:25–4:20 | `feat/jivit-*` |

All five say their name in the 0:00–0:40 intro. If someone is stuck, whoever
finishes first takes the next free task — and the usual rescue is Himanshu
helping with integration, with optional items (VSHL, synthesis) dropped before
any required one.

Per-member write-ups: [notes_taj.md](docs/notes_taj.md) ·
[notes_parth.md](docs/notes_parth.md) · [notes_satya.md](docs/notes_satya.md) ·
[notes_himanshu.md](docs/notes_himanshu.md) · [notes_jivit.md](docs/notes_jivit.md)

### Order of work

```
Taj: repo + scaffold + build system + branch rules      (done)
   └─> Parth: freeze the spec
          ├─> Himanshu: lane_alu ──> vec_alu
          │        └─> Jivit: scalar_top  (reuses lane_alu)
          ├─> Satya: vreg_file + dmem
          ├─> Parth: ctrl_unit + instr_mem
          └─> Taj: golden model + diagrams + report template  (done)
                        │
                        └─> Parth: simd_top  (needs Satya, Himanshu, Jivit)
                                 └─> Taj: tb_system + synthesis + waveforms
                                          └─> Jivit: cycle table + speed-up
                                                   ├─> Taj: final PDF
                                                   └─> Himanshu: final video
```

The repository came first, because nobody can commit without it; then Parth's
spec, which unblocks everyone else. The five blocks run in parallel on
Saturday, and only integration has to wait — on three of them. Taj's chain
needs no RTL at all, which is why the golden model, the diagrams and the
report template are already here.

Full per-member task lists and the checkpoint timeline:
[docs/phase1_work_plan.md](docs/phase1_work_plan.md).

---

## 10. Contributing workflow

### GitHub rules — this is 5 of the marks

Reviewers read the commit history to check each person's contribution. **Commits
made from one laptop under one account, or all pushed on Monday night, will look
like one person did everything.**

- **Every member commits their own files from their own GitHub account**, with
  messages that say what changed — `Add vreg_file with 2 read ports`, not
  `update`.
- **Commit as you finish each piece**, across Saturday, Sunday and Monday, not in
  one dump. Everyone needs commits on **at least two different days**.
- One branch per person, `feat/<name>-<task>`. Open a **pull request into
  `main`** and wait for the repository owner's review (Taj). **Never overwrite
  someone else's file** — if a port does not match, talk to the owner.
- Keep file names exactly as in [docs/spec.md](docs/spec.md) so the testbenches
  and `$readmemh` paths line up.
- **Commit the report text too**: export the Overleaf source into `report/` on
  Sunday and again on Monday, with the PDF at the end.
- Everyone keeps their own `docs/notes_<name>.md` — *what I built and why*. The
  viva is assessed individually, and "why" is the half that gets asked about.

### Quality gate

Every push and pull request runs
[`.github/workflows/ci.yml`](.github/workflows/ci.yml): every module and
testbench elaborates together, all seven testbenches run, no `FAIL` line is
tolerated, the committed golden vectors are checked against the model, and the
Python is linted and tested. Run the same checks locally first:

```bash
make -C sim lint && make -C sim test
ruff check golden/ tests/ && ruff format --check golden/ tests/ && pytest tests/
```

Elaborating *all* RTL against *every* testbench is deliberate: a port-list change
in one person's module then fails on their branch, rather than surfacing during
Sunday's integration when there is no time to fix it.

---

## 11. Deliverables

| Item | Marks | Owner | Where |
| :--- | ---: | :--- | :--- |
| IEEE report, 4–6 pages | 10 | Taj assembles; one section each | [report/](report/) |
| Demonstration video, under 5:00 | 15 | Himanshu edits; Parth submits | [video/README.md](video/README.md) |
| GitHub repository and history | 5 | Taj | this repo |

The report has **exactly five parts** — Abstract, Literature Review, Proposed
Solution, Individual Contributions, References — and **no separate Results
section** in Phase I: preliminary numbers stay inside 4.3 and move to a full
Results and Discussion section in Phase II.

**Write what is true on Monday.** If synthesis did not run, the report says so
and marks it as planned. Quietly omitting a section reads worse than a sentence
explaining why it is empty.

Before submitting, work through
[docs/submission_checklist.md](docs/submission_checklist.md).

---

## 12. Phase II preview

Everything deliberately out of scope now, so the report can say what was left
out rather than appear not to have noticed:

- Pipelining and hazard detection — the current machine is one instruction per
  cycle, which is what bounds the speed-up at the lane count.
- A vector length register, so array sizes need not be a multiple of `LANES`.
- Masking and predication; scatter/gather addressing.
- `LANES = 8`, and the area/Fmax curve against lane count.
- A full Results and Discussion section with synthesis numbers.

---

## 13. Stack

Verilog-2001 · Icarus Verilog · GTKWave · GNU Make · Python 3 (standard library
only, for the golden model) · pytest · ruff · Yosys or Vivado for synthesis ·
LaTeX (IEEEtran)
