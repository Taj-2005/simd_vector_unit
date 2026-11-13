# Scaffold notes — what is here beyond the team plan

Prepared by **Taj** while setting up the repository. Read this once before
starting work.

The Phase I team plan specifies the folders `rtl/`, `tb/`, `scalar/`, `sim/`,
`docs/`, `report/`, `video/`, five RTL blocks, their testbenches, a Python
golden model and a report. All of that is here. This file lists everything
**extra** that is not in the plan, split into three groups:

- **Needs a decision** — I had to pick something the plan left open. Parth
  confirms or changes it when freezing the spec.
- **Added tooling** — infrastructure the plan does not mention and nobody has to
  maintain, but which should not be a surprise.
- **Conventions** — rules the scaffold enforces, worth knowing before you fight
  one of them.

---

## A. Needs a decision (Parth, when freezing the spec)

### A1. Concrete instruction op codes

The plan fixes the ALU op codes (`000` ADD … `110` SHL) and the field layout
(`opcode[15:12]`, `vd[11:9]`, `vs1[8:6]`, `vs2[5:3]`) but **not the instruction
op codes**. I proposed the map in [spec.md §3](spec.md#3-instruction-encoding--16-bits),
chosen so that `alu_op = instr[14:12]` falls out with no decode table and bit 3
separates compute from memory/control.

**Decide:** keep it or renumber. If you renumber, keep those two properties —
`ctrl_unit` gets noticeably more complicated without them.

### A2. Where the VLD/VST address lives

The plan gives no address field. A 16-word data memory needs 4 bits, and the
register fields are 3 bits each, so I put the address in **`instr[6:3]`**,
overlapping `vs1[0]` and `vs2`. Bits `8:7` are then unused for memory ops.

**Decide:** confirm, or move it. Either way `sim/programs/*.hex` changes with it.

### A3. Which register `VST` reads

`VST` stores `V[vd]`, and `vd` is in bits `11:9` — not in the `vs1` field that
`raddr1` normally comes from. Two ways to resolve it: drive
`raddr1 = vd` when the opcode is `VST`, or mux the store data in `simd_top`.

**Decide:** pick one, say which in report section 4.1, and make
`tb_ctrl_unit.v` assert it. This is the decode detail most likely to be wrong
and least likely to be noticed until integration.

### A4. Same-cycle read and write on the register file

With a clocked write and combinational reads, a read of the address being
written returns the **old** value. `simd_top`'s `VST`-immediately-after-`VADD`
timing depends on this.

**Decide (Satya, with Parth):** implement one behaviour, assert it in
`tb_vreg_file.v`, and write it into report section 4.2.

### A5. The benchmark programs already exist

`sim/programs/bench_add16.hex` (17 instructions) and `bench_logic.hex` (11) are
written and commented line by line, against the **proposed** encoding. The plan
assigns these to **Jivit, agreed with Parth** — they are a starting point, not a
claim on that task. If A1 or A2 changes, both files and every comment change
with them.

### A6. Repository ownership — RESOLVED

The plan has Parth creating the repository on Friday night. **In practice Taj
created it and built the scaffold**, because his chain of work (golden model,
diagrams, report template) depends on nobody — he was the one person free on
Friday while everyone else was waiting on the spec.

**Resolved: Taj is the repository owner** — he created it, owns the build system
and CI, and reviews and merges every pull request. **Parth is the integration
lead** and keeps everything the plan makes his: freezing the spec, `ctrl_unit`,
`instr_mem`, wiring `simd_top` together, and submitting the Google Form.

This is the one place the repository deviates from the submitted plan PDF, so it
is also noted at the top of [phase1_work_plan.md](phase1_work_plan.md). Nothing
else about anyone's workload changes.

**Still to do:** add all four teammates as collaborators, or none of them can
commit — and "every member commits from their own account" is what the 5 GitHub
marks are assessed on.

---

## B. Added tooling

| Addition | Why |
| :--- | :--- |
| `rtl/simd_defs.vh` | One include with the geometry, ALU ops and op codes, so `ctrl_unit` and the testbenches use names instead of magic numbers. Compile with `-I rtl`. |
| `sim/Makefile` | Seven testbenches × compile-and-run is not a command anyone should type by hand. Add a testbench by adding its name to `UNIT_TESTS`. |
| `.github/workflows/ci.yml` | Elaborates every module against every testbench on each push, so a port-list change fails on the author's branch instead of during Sunday's integration. Also runs the testbenches, greps for `FAIL`, and checks the committed vectors still match the model. |
| `tests/` + `pyproject.toml` + `requirements.txt` | 32 pytest cases on the golden model, plus ruff. The model is what the RTL is judged against, so a wrong model costs a day of debugging correct hardware. |
| `results/` with header-only CSVs | Somewhere for the cycle and synthesis numbers to land that is not "in the report text". Templates are empty on purpose. |
| `docs/spec.md` | The plan's spec tables, in one place that can be frozen and cited, with the encoding filled in. |
| `docs/cycle_counting.md` | The plan asks Jivit for "one paragraph" of counting rules. It is a table here because the speed-up number is the project's headline claim. |
| `docs/diagrams/*.svg` + `Makefile` | The plan says "draw 3 block diagrams in draw.io or similar". They are hand-authored SVG instead, so a diagram edit is a reviewable text diff rather than an opaque binary; `make -C docs/diagrams` regenerates the PNG and PDF. |
| `docs/scaffold_notes.md` | This file. |
| `docs/phase1_work_plan.md` | The plan PDF as editable markdown, so an ownership change is a reviewable diff. |
| `docs/notes_<name>.md` | One page per member, *what I built and why*. The viva is assessed individually and "why" is the half that gets asked about, so it is worth writing down while the reason is still fresh. |
| `.gitattributes` | `eol=lf` on every text type. Two of us are on Windows; this avoids whole-file diffs on merge. |
| `docs/video_script.md`, `docs/submission_checklist.md` | The plan's video table and final checklist, as working documents with checkboxes. |

---

## C. Conventions the scaffold enforces

### C1. A stub reports SKIP, never PASS

Every testbench counts its checks and prints `SKIP` while that count is zero.
The first version of this scaffold printed `PASS` for six testbenches that
asserted nothing — which would have let all five of us tick off work nobody had
done. CI tolerates SKIP and fails on `FAIL`, so a module can land before its
testbench, but nothing ships with a SKIP against it.

### C2. `tb_system` is honest about the stub

While `simd_top` is a stub its `done` never asserts, so `tb_system` reports SKIP
rather than FAIL. Pass `DEFS=-DDUT_READY` once integration is wired up and it
becomes a hard failure. One macro, `` `DUT_DMEM ``, is the only place the
testbench reaches inside the DUT — if your instance names differ, change that
line, not the testbench.

### C3. Golden vectors are generated *and* committed

Generated files normally are not. These are, because `tb_system.v` compares
against them: the repository must hold the exact bytes the expectations were
built from. The seed is fixed, so regenerating produces no diff, and CI fails if
the committed files ever drift from the model.

### C4. Vector pair 0 is crafted, not random

Random 16-bit values made every lane answer the compares identically — a test
that still passes with the comparator deleted. Pair 0 covers equal, greater,
less, and the signed case (`-1 < 1`) that an unsigned comparator gets wrong,
plus an ADD that wraps to zero. Pairs 1–3 stay random.

### C5. Simulations always run from `sim/`

Every `$readmemh` and `$dumpfile` path is relative to `sim/`. Running `vvp` from
the repository root makes `$readmemh` load nothing and the benchmark compute
zeros, with no error. The Makefile is the guard rail; use it.

### C6. The golden model uses no third-party libraries

It defines what *correct* means for this project. A numpy version difference
must not be able to change that.

---

## D. Verified on this machine

Icarus Verilog 13.0, Python 3.14, macOS.

```
make -C sim lint       7/7 testbenches elaborate, no warnings
make -C sim test       7/7 run; all report SKIP (no checks written yet)
pytest tests/          32/32 pass
ruff check + format    clean
make -C docs/diagrams  3 diagrams -> PNG (1800px) + PDF (vector)
```

**Not verified:** nothing in `rtl/` or `scalar/` computes anything yet — they are
stubs with frozen port lists. The first real `PASS` from `tb_system` is Sunday's
checkpoint.
