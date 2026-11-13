# `golden/` — Python golden model

Owner: **Taj**. A bit-exact reference for the six vector operations, independent
of the RTL.

`tb/tb_system.v` does not check `simd_top` against a hand-written expectation —
it checks it against vectors produced here. So "the hardware is correct" becomes
a test result rather than an opinion, and a disagreement points at exactly one
of two places instead of at a vague feeling that something is off.

## Files

| File | What it is |
| :--- | :--- |
| `golden_model.py` | the reference: lane ops, vector ops, 128-bit packing, hex I/O |
| `gen_vectors.py` | deterministic vector generation into `sim/vectors/` |

Tests: [`tests/test_golden_model.py`](../tests/test_golden_model.py) — 32 cases.

```bash
pytest tests/ -v
make -C sim vectors        # or: python golden/gen_vectors.py
```

## Why no third-party libraries

The model defines what *correct* means for this project. A numpy version
difference must not be able to change that, so the standard library is all it
uses.

## The three conventions it pins down

1. **Lane 0 is the low-order lane** — lane *i* is bits `[i*32 +: 32]`, matching
   the `generate` loop in `vec_alu.v`. Reversing this compiles fine and fails
   `tb_system` with four wrong lanes and no obvious cause.
2. **Arithmetic wraps** — ADD and SUB are modulo 2³² with no flags, because the
   hardware has no carry-out.
3. **Compares are narrow and signed** — 1 or 0 in bit 0, zeros above, and CMPLT
   compares two's-complement values.

Those three are design decisions, not implementation details. Fixing them in
Python first is what stopped them from being decided accidentally and
differently by three people writing RTL in parallel.

## Why the vectors are committed

Generated files are usually not committed. These are, because `tb_system.v`
compares against them: the repository must hold the exact bytes the expectations
were built from. The seed is fixed (`--seed 11`), so regenerating is
byte-identical and CI fails if the committed files ever drift from the model.

## Why vector pair 0 is crafted

Random 16-bit values made every lane answer the compares the same way — a test
that would still pass with the comparator deleted. Pair 0 is built by hand
instead, one lane per interesting case:

| Lane | A | B | CMPEQ | CMPLT | catches |
| ---: | :--- | :--- | :--: | :--: | :--- |
| 0 | *x* | *x* | 1 | 0 | a comparator stuck at 0 |
| 1 | *x* | *x* − 1 | 0 | 0 | greater-than read as less-than |
| 2 | *x* | *x* + 1 | 0 | 1 | the ordinary less-than case |
| 3 | `0xFFFFFFFF` | `0x00000001` | 0 | 1 | an **unsigned** comparator, and ADD wrapping to 0 |

Pairs 1–3 stay random, so the array add is not fitted to one hand-picked case.
