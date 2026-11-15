# `fuzz/` — random-program verification

Owner: **Taj**.

Runs randomly generated programs on `simd_top` and on an independent Python
simulator of the instruction set, then compares the final data memory and the
cycle count.

```bash
python fuzz/run_fuzz.py                      # 300 programs, fixed seed
python fuzz/run_fuzz.py --count 2000 --seed 7
```

Needs `iverilog` on PATH; it compiles its own harness into `fuzz/build/`.

| File | What it is |
| :--- | :--- |
| `isa_sim.py` | instruction-level model of the whole machine, written from `docs/spec.md` |
| `tb_fuzz.v` | runs one program and dumps the final memory |
| `run_fuzz.py` | generates programs, runs both, compares |

## Why this exists

The unit testbenches check each module against what its author expected.
`tb_system` and `tb_simd_top` check the integrated machine against the golden
model — but only on three hand-written programs. All three happen to start with
a `VLD`, and that one coincidence hid a real bug for days:

> **The register file and data memory were being written while `rst` was
> asserted.** `ctrl_unit` is combinational and decodes whatever `instr_mem`
> outputs for the current `pc`, so instruction 0's write enables were live
> during reset. A `VLD` is idempotent, so re-running it changed nothing and
> every test still passed. Any other first instruction — an ALU op reading its
> own destination, or a `VST` — corrupted state before the program started.

Nothing in a hand-written test suite was going to find that, because nobody
writes a program whose first instruction is `VCMPEQ V4, V4, V0`. A fuzzer
writes thousands of them.

Fixed by gating both write enables in `simd_top.v`:

```verilog
.we (rf_we  && !rst && !done_reg),   // vreg_file
.we (mem_wr && !rst && !done_reg),   // dmem
```

## What it covers

Every opcode including the undefined ones (which must behave as NOPs), random
registers, random addresses, programs of 4 to 28 instructions, random 128-bit
memory contents. It checks the **cycle count** as well as the data, so a timing
change shows up too.

It does **not** cover: `LANES` other than 4, programs longer than `IMEM_WORDS`,
or reset asserted mid-program.

## Determinism

The seed is fixed, so a failure is reproducible: the failing program is printed
as hex words and can be dropped straight into `fuzz/build/prog.hex`.
