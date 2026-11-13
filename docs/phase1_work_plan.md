# Phase I work plan — Project 11, SIMD Vector Unit

Markdown source of the team plan PDF, kept editable in the repository so an
ownership change is a reviewable diff rather than a message nobody can find.

**Deadline: 16 Nov 2026, 11:59 PM IST.** The plan targets **9 PM** as the real
deadline, leaving three hours of margin.

**Marks: report 10, video 15, GitHub 5.** Every one of the five members owns one
RTL block, one testbench, one report section and one video slot, so all three
components depend on everyone.

---

## Who owns what

| Member | Code / RTL | Testing and tools | Report section | Video slot |
| :--- | :--- | :--- | :--- | :--- |
| **Parthraj** | `ctrl_unit`, `simd_top`, program ROM | `tb_ctrl_unit`; repo setup and merges | Proposed Solution 4.1: architecture and control | 0:40–1:25 and 4:20–4:50 |
| **Satya** | `vreg_file`, 128-bit `dmem` | `tb_vreg_file`, `tb_dmem`; register-file waveform | Literature Review | 1:25–2:00 |
| **Himanshu** | `lane_alu`, `vec_alu` (4 lanes) | `tb_lane_alu`, `tb_vec_alu`; ALU waveform; edits and uploads the final video | Proposed Solution 4.2: lane and datapath design | 2:00–2:40 |
| **Taj** | Python golden model, self-checking system testbench | block diagrams, synthesis run, GTKWave screenshots | Abstract, References, IEEE formatting, final PDF | 2:40–3:25 |
| **Jivit** | `scalar_top` baseline, benchmark programs (hex) | cycle counters; scalar vs SIMD comparison table | Proposed Solution 4.3: baseline and evaluation method; Individual Contributions table | 3:25–4:20 |

Nobody is only a writer and nobody is only a coder. All five say their name in
the 0:00–0:40 intro.

---

## How the work flows

```
Parth: freeze the spec  (Fri night)
   ├─> Himanshu: lane_alu ──> vec_alu
   │        └─> Jivit: scalar_top (reuses lane_alu)
   ├─> Satya: vreg_file + dmem
   ├─> Parth: ctrl_unit + instr_mem
   └─> Taj: golden model + diagrams + Overleaf template   (needs nobody)
                 │
                 └─> Parth: simd_top integration  (needs Satya, Himanshu, Jivit)
                          └─> Taj: tb_system + synthesis + waveforms
                                   └─> Jivit: cycle table and speed-up
                                            └─> Taj: final PDF
                                            └─> Himanshu: final video
```

Parth's spec unblocks everyone. The five blocks run in parallel on Saturday;
only integration has to wait, and only on three of them.

---

## Per-member task lists

### Parthraj — control unit, integration, repo owner

- **Fri night** — create the GitHub repo with `rtl/`, `tb/`, `scalar/`, `sim/`,
  `docs/`, `report/`, `video/`; add all four teammates as collaborators.
- **Fri night** — push a README holding the spec and the interface tables, and
  tell the group the spec is frozen.
- **Sat** — `ctrl_unit.v`: decode the 16-bit instruction into `we`, `waddr`,
  `raddr1`, `raddr2`, `alu_op`, `mem_rd`, `mem_wr`, `halt`.
- **Sat** — `tb_ctrl_unit.v`, one directed check per opcode.
- **Sat** — `instr_mem.v` loading a hex program with `$readmemh`; agree the
  benchmark program with Jivit.
- **Sun** — `simd_top.v`: wire control, register file, `vec_alu`, data memory and
  a cycle counter; fix port mismatches *with* the owners.
- **Sun** — run Taj's system testbench and debug until it prints PASS.
- **Mon** — review and merge all branches, then write 4.1 (about one page).
- **Mon** — present both video slots and submit the Google Form.

**Done when:** `simd_top` runs the 16-element array add and `cycle_count` is
correct.

### Satya — register file, memory, literature review

- **Sat morning** — `vreg_file.v`: 8 × 128-bit, two combinational read ports, one
  clocked write port.
- **Sat morning** — `dmem.v`: 16 × 128-bit, clocked write, combinational read,
  initialised from a hex file.
- **Sat** — `tb_vreg_file.v` (write all 8, read both ports, read and write in the
  same cycle) and `tb_dmem.v`; **push both before noon** so Parth can integrate.
- **Sat** — dump a VCD, open it in GTKWave, save a clean screenshot of the
  register-file test to `docs/waveforms/`.
- **Sat–Sun** — Literature Review, 1 to 1.5 pages: see
  [literature_review.md](literature_review.md).
- **Sun** — collect 6 to 8 real references and send them to Taj in IEEE format.
  **Open every source yourself before citing it.**
- **Mon** — present the 1:25–2:00 slot.

**Done when:** both testbenches pass and the Literature Review is in the shared
report.

### Himanshu — ALU lanes, datapath section, video editing

- **Sat morning** — `lane_alu.v`: 32-bit ALU, ops ADD, SUB, AND, OR, CMPEQ,
  CMPLT (signed), optionally SHL, using the op codes in [spec.md](spec.md).
- **Sat morning** — **push `lane_alu.v` early, even before its testbench**,
  because Jivit needs the port list.
- **Sat** — `vec_alu.v`: `LANES` copies of `lane_alu` in a generate loop over a
  128-bit input.
- **Sat** — `tb_lane_alu.v` (each op, zero, maximum and negative values, equal
  and unequal compares) and `tb_vec_alu.v` (four different values at once).
- **Sat** — save a GTKWave screenshot of `vec_alu` showing four lanes computing
  together.
- **Sun** — report 4.2, lane and datapath design (about one page): op table,
  lane replication, why `LANES` is a parameter.
- **Sun** — help whoever is behind, usually Parth on integration or Jivit on the
  benchmark programs.
- **Mon 2 PM onward** — screen-record, stitch everyone's clips, keep it under
  5:00, upload as unlisted, send the link to Parth.

**Done when:** both ALU testbenches pass and the final video is uploaded with a
working link.

### Taj — golden model, system test, diagrams, report assembly

- **Sat morning** — set up the Overleaf project with the IEEEtran conference
  template, share it with all four, add the five section headings.
- **Sat** — Python golden model of the 6 vector ops, outputting random input
  vectors and expected results to hex files.
- **Sat** — three block diagrams (top level, datapath, one lane) as PNG and PDF,
  pushed to `docs/diagrams/`.
- **Sun** — `tb_system.v`: self-checking, runs `simd_top`, compares against the
  golden vectors, prints PASS or FAIL per test.
- **Sun** — synthesis with Vivado if installed, otherwise Yosys; record LUTs,
  flip-flops and Fmax where the tool reports them. **If no tool works, say so in
  the report** rather than skipping it silently.
- **Sun** — save GTKWave screenshots of the system test.
- **Mon morning** — write the Abstract last (150–200 words, once results exist)
  and format the References from Satya's list.
- **Mon** — compile the final PDF, check IEEE format and every required section,
  commit it to `report/`.
- **Mon** — present the 2:40–3:25 slot showing the PASS output.

**Done when:** `tb_system.v` prints PASS and the PDF has all five required
sections.

### Jivit — scalar baseline, benchmarks, performance comparison

- **Sat** — `scalar_top.v`: a one-ALU core looping over 16 elements doing load A,
  load B, add, store, **reusing `lane_alu`** so the comparison is fair, with a
  `cycle_count` register.
- **Sat** — `tb_scalar_top.v` checking `C[i] = A[i] + B[i]` for all 16 elements.
- **Sat** — with Parth, write the SIMD benchmark as a hex file (VLD, VLD, VADD,
  VST × 4 vectors, then HALT) plus a second program using VAND, VOR and the
  compares.
- **Sat** — write down the cycle-counting rules in one paragraph so the
  comparison is honest: [cycle_counting.md](cycle_counting.md).
- **Sun** — run both machines on the same data; record cycles, elements per cycle
  and speed-up in one table. **Report whatever the numbers are, even if they are
  not 4×.**
- **Sun** — collect a 3-line contribution summary from each member and build the
  Individual Contributions table.
- **Sun** — report 4.3, baseline and evaluation method (about half a page).
- **Mon** — present the 3:25–4:20 slot with the comparison table on screen.

**Done when:** the scalar testbench passes and the comparison table has real
numbers from both simulations.

---

## Timeline — Sat 14 to Mon 16 Nov

Code freeze is **Monday 2 PM**, because the video and the report both need a
frozen design.

| When (IST) | Checkpoint | Who |
| :--- | :--- | :--- |
| Sat by 10 AM | Repo live, spec frozen and posted; Overleaf template shared | Parth, Taj |
| Sat by 12 noon | `lane_alu.v` pushed; `vreg_file.v` and `dmem.v` pushed | Himanshu, Satya |
| Sat by 6 PM | `vec_alu`, `ctrl_unit`, `scalar_top` and their unit testbenches pass | Himanshu, Parth, Jivit |
| Sat by 9 PM | Golden model and 3 block diagrams pushed; benchmark hex files agreed | Taj, Jivit, Parth |
| Sun by 2 PM | `simd_top.v` integrated and running one program | Parth |
| Sun by 6 PM | System testbench prints PASS; cycle table filled; synthesis attempted | Taj, Jivit |
| Sun by 10 PM | First draft of every report section in Overleaf; reference list sent | All, Satya |
| Mon by 12 noon | Abstract written; contributions table done; all report text final | Taj, Jivit |
| Mon 2 PM | **Code freeze** — only bug fixes after this | Parth |
| Mon 2–5 PM | Record clips and edit the video; check length is under 5:00 | All, Himanshu |
| Mon 5–7 PM | Final PDF compiled; README links the report and video; commit history checked | Taj, Parth |
| Mon by 9 PM | Form submitted with the GitHub link | Parth |

**If you fall behind, tell the group within the hour** rather than at the
checkpoint. The usual rescue: Himanshu helps with integration, and optional
items (VSHL, synthesis) get dropped before any required one.

---

## Report sections and owners

Exactly five parts, 4 to 6 pages in the IEEEtran two-column template, with the
block diagram and one waveform inside. **Phase I has no separate Results
section** — preliminary numbers stay inside 4.3 and move to a full Results and
Discussion section in Phase II. Write what is true on Monday: if synthesis did
not run, say it is planned.

| Section | Content | Owner | Length |
| :--- | :--- | :--- | :--- |
| Abstract | Problem, what we built, what we measured | Taj (writes last) | 150–200 words |
| Literature Review | Flynn's taxonomy, vector and SIMD machines, FPGA soft vector processors | Satya | 1–1.5 pages |
| Proposed Solution 4.1 | Architecture, instruction format, control unit | Parth | 1 page |
| Proposed Solution 4.2 | Lane ALU, vector datapath, register file and memory | Himanshu | 1 page |
| Proposed Solution 4.3 | Scalar baseline, benchmark, cycle-counting rules, prototype status | Jivit | 0.5 page |
| Individual Contributions | One row per member: modules, testbenches, report sections, video slot, commit count | Jivit collects, everyone checks their own row | 0.5 page |
| References | IEEE style, only sources someone has opened | Taj formats, Satya collects | 6–8 entries |

---

## Video — 4:50, hard limit 5:00

15 marks, the largest single item. It must state the project idea, introduce all
five members by name, and show the prototype working. Record each slot as a
**separate** screen-share clip so a bad take can be redone alone. Full script:
[video_script.md](video_script.md).

---

## GitHub rules

5 marks, and reviewers read the commit history to check each person's
contribution. Commits made from one laptop under one account, or all pushed on
Monday night, **will look like one person did everything**.

- Every member commits their own files from their own GitHub account, with
  messages that say what changed (e.g. `Add vreg_file with 2 read ports`).
- Commit as you finish each piece, across Saturday, Sunday and Monday — not in
  one dump.
- Work on your own branch and merge into `main` through Parth, or push straight
  to `main` only for your own files. **Never overwrite someone else's file.**
- Commit the report text too: export the Overleaf source into `report/` on
  Sunday and Monday, with the PDF at the end.
- Keep file names exactly as in the spec so imports and testbenches line up.
- **Every member must have commits on at least two different days.**
