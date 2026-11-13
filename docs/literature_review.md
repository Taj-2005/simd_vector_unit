# Literature review — working notes

**Owner: Satya.** 1 to 1.5 pages in the report. This file is the drafting space;
the finished prose goes into `report/sections/01_literature_review.tex`, and the
citation list into [`refs.bib`](refs.bib).

## What has to be covered

From the Phase I plan, in roughly this order:

1. **Flynn's taxonomy** — SISD, SIMD, MISD, MIMD, and where a 4-lane vector unit
   sits in it. One paragraph; this is the framing the rest of the review hangs
   on.
2. **Scalar versus SIMD execution** — one ALU per cycle against *LANES* ALUs per
   cycle, and the cost: register-file width, instruction encoding, and the fact
   that only data-parallel code benefits.
3. **Vector processors** — the CRAY-1 line: vector registers, vector length, why
   long vectors amortise instruction overhead. Note what we deliberately left
   out (vector length register, chaining).
4. **Short-vector SIMD in commodity CPUs** — SSE, AVX, ARM NEON: fixed-width
   registers, packed sub-word operations, and the compiler's role.
5. **The RISC-V vector extension** — scalable vector length as the modern
   alternative to fixed-width SIMD, and how it contrasts with our fixed 4 lanes.
6. **Soft vector processors on FPGAs** — the closest work to what we built:
   configurable lane counts, area/performance trade-offs, why `LANES` as a
   parameter is the standard approach.

## Starting points to verify

The plan names these. **Open each one yourself before citing it** — a reference
nobody has read is the thing an examiner finds fastest, and the report commits
to "only sources someone has opened".

| Source | Why it is relevant | Verified? |
| :--- | :--- | :--- |
| Flynn (1966), *Proceedings of the IEEE* — very high-speed computing systems | the taxonomy itself | ☐ |
| Hennessy & Patterson, *Computer Architecture: A Quantitative Approach* — vector and SIMD chapters | textbook treatment, and the source for the speed-up framing | ☐ |
| RISC-V Vector Extension specification | scalable vectors, the modern contrast | ☐ |
| Russell (1978), *Communications of the ACM* — the CRAY-1 | the canonical vector machine | ☐ |
| Yu, Lemieux & Eagleson, FPGA 2008 — soft vector processors | directly comparable work | ☐ |

Target: 6 to 8 references. Two or three more beyond this list is fine if they
are read; padding the list is not.

## How this connects to our design

The review should not end as a list of other people's machines. Close it by
pointing at our own decisions, which gives Parth's section 4.1 something to
build on:

- Fixed 4 lanes, not a vector length register — why that is the right scope for
  Phase I, and what it costs.
- One instruction per cycle, no chaining and no pipeline — so the expected
  speed-up is bounded by the lane count.
- A parameterised lane count as the standard FPGA soft-vector approach.

## Draft

_Write here, then move the prose into the LaTeX file._
