# `sim/` — running the simulation

**Always run from this directory**, or with `make -C sim`. Every `$readmemh`
path in the RTL and every `$dumpfile` path in the testbenches is relative to
`sim/`; running from the repository root makes `$readmemh` silently load nothing
and the benchmark then computes zeros with no error message.

## Targets

```bash
make -C sim lint        # compile everything, run nothing   <- what CI gates on
make -C sim test        # compile and run all 8 testbenches
make -C sim simd_top    # run SIMD integration testbench (tb_simd_top)
make -C sim integration # alias for simd_top integration test
make -C sim lane_alu    # one testbench by name
make -C sim vectors     # regenerate golden vectors (deterministic)
make -C sim wave-system # open the system-test waveform in GTKWave
make -C sim clean
```

`make -C sim system` runs the golden-model system test. It takes no flags: the
`DUT_READY` gate was removed once the real modules were integrated, so a
regression there now fails the default build instead of hiding behind a SKIP.

## What the output means

| Line | Meaning |
| :--- | :--- |
| `PASS tb_x: n/n checks` | ran `n` checks, all passed |
| `SKIP tb_x: no checks written yet` | the testbench compiles but asserts nothing — the module's owner still has work to do |
| `FAIL tb_x: n error(s)` | a real failure; fix before pushing |

**SKIP is not a pass.** It means the testbench was never written. tb_system
still SKIPs until its result check is enabled; every other testbench must PASS.

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
