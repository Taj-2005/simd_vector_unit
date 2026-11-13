# `sim/` — running the simulation

**Always run from this directory**, or with `make -C sim`. Every `$readmemh`
path in the RTL and every `$dumpfile` path in the testbenches is relative to
`sim/`; running from the repository root makes `$readmemh` silently load nothing
and the benchmark then computes zeros with no error message.

## Targets

```bash
make -C sim lint        # compile everything, run nothing   <- what CI gates on
make -C sim test        # compile and run all 7 testbenches
make -C sim lane_alu    # one testbench by name
make -C sim vectors     # regenerate golden vectors (deterministic)
make -C sim wave-system # open the system-test waveform in GTKWave
make -C sim clean
```

`make -C sim system DEFS=-DDUT_READY` turns on the system test's result
comparison. Leave it off until `simd_top` is wired up — the testbench then
reports SKIP instead of a FAIL everyone already knows about.

## What the output means

| Line | Meaning |
| :--- | :--- |
| `PASS tb_x: n/n checks` | ran `n` checks, all passed |
| `SKIP tb_x: no checks written yet` | the testbench compiles but asserts nothing — the module's owner still has work to do |
| `FAIL tb_x: n error(s)` | a real failure; fix before pushing |

**SKIP is not a pass.** It means the testbench was never written. CI tolerates
SKIP while modules are stubs and fails on any `FAIL`, so a module can land
before its testbench without blocking the branch — but nothing ships with a
SKIP against it.

## Directories

| Path | Committed? | Contents |
| :--- | :--- | :--- |
| `programs/` | yes | benchmark programs as `$readmemh` hex, one comment per instruction |
| `vectors/` | yes | golden vectors from `golden/gen_vectors.py` |
| `build/` | no | `.vvp` simulation binaries |
| `waves/` | no | `.vcd` dumps — the screenshots you keep go in `docs/waveforms/` |

`vectors/` is generated **and** committed, deliberately: `tb_system.v` compares
against it, so the repository has to hold the exact bytes the expectations were
built from. The seed is fixed, so regenerating produces no diff — and CI checks
exactly that.
