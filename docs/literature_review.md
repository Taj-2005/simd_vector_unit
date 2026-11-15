# Literature review — working notes

**Owner: Taj** (taken over from Satya). 1 to 1.5 pages in the report. This
file is the drafting space;
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

All five are now in [`refs.bib`](refs.bib) with **verified bibliographic
metadata** — volume, pages, year and DOI checked against Crossref or the
publisher, not written from memory. What is still missing is the other half:
somebody has to **read** them.

| Source | Key | Metadata | Read by |
| :--- | :--- | :--- | :--- |
| Flynn (1966), *Proc. IEEE* 54(12):1901–1909 | `flynn1966` | ✓ | ☐ |
| Hennessy & Patterson, *Computer Architecture*, 6th ed. (2017) | `hennessy2017` | ✓ | ☐ |
| Russell (1978), *CACM* 21(1):63–72 — the CRAY-1 | `russell1978` | ✓ | ☐ |
| Yu, Lemieux & Eagleston, FPGA 2008, pp. 222–232 | `yu2008soft` | ✓ | ☐ |
| RISC-V "V" Vector Extension v1.0 (2021) | `riscvvector` | ✓ | ☐ |

Two corrections worth knowing: the surname is **Eagleston**, not Eagleson, and
the textbook entry is the **6th edition** — change it if you read a different
one.

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
