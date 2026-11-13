# `sim/programs/` — benchmark programs

Owner: **Jivit**, encoding agreed with **Parthraj**.

Plain `$readmemh` input: one 16-bit instruction per line as 4 hex digits.
Icarus allows `//` comments in a memory file, so every line carries its
disassembly — a hex program with no comments is unreviewable, and the examiner
reads these.

| File | Instructions | What it does |
| :--- | ---: | :--- |
| `bench_add16.hex` | 17 | **The headline benchmark.** `C[i] = A[i] + B[i]` for 16 elements: 4 × (VLD, VLD, VADD, VST), then HALT |
| `bench_logic.hex` | 11 | VAND, VOR, VCMPEQ, VCMPLT on the crafted compare pair — covers the ops the array add never touches |

Both start from `../vectors/dmem_init.hex` (A in words 0–3, B in words 4–7) and
store results to words 8–11, where `tb/tb_system.v` checks them.

## Encoding

From [`docs/spec.md`](../../docs/spec.md) §3:

```
register-register:  | 15:12 opcode | 11:9 vd | 8:6 vs1 | 5:3 vs2 | 2:0 unused |
memory (VLD/VST):   | 15:12 opcode | 11:9 vd |   8:7   | 6:3 addr| 2:0 unused |
```

So `0408` is `VADD V2, V0, V1`: opcode `0000`, vd `010`, vs1 `000`, vs2 `001`.

**These two files were written against the *proposed* encoding.** If Parth
changes an op code when freezing the spec, both files change with it — and so
does the comment on every line.
