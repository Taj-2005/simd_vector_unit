# Cycle-counting rules

**Owner: Jivit.** Written before the numbers are collected, not after — rules
chosen once a result is in hand are rules fitted to the result.

The whole project rests on one comparison: cycles on `simd_top` against cycles
on `scalar_top` for the same 16-element array add. That comparison is only
meaningful if both machines are counted the same way, so the rules are fixed
here and both tops implement them.

---

## The rules

> **Fill each cell with what the RTL actually does, then make both tops obey
> it.** If the two machines disagree on any row, the speed-up number is not a
> speed-up number.

| Rule | SIMD (`simd_top`) | Scalar (`scalar_top`) |
| :--- | :--- | :--- |
| A vector/scalar load costs | 1 cycle (`VLD`), moving `LANES` = 4 elements | 1 cycle (`S_LDA`/`S_LDB`), moving 1 element |
| An ALU operation costs | 1 cycle (`VADD`), computing 4 lanes at once | 1 cycle (`S_ADD`), computing 1 element |
| A store costs | 1 cycle (`VST`), writing 4 elements | 1 cycle (`S_ST`), writing 1 element |
| Loop overhead (index increment, branch) | none — the ISA has no branch, so `bench_add16` is straight-line code and `pc` advances alongside each instruction | none — the index increment rides along with the store in `S_ST` rather than taking its own cycle |
| Reset cycles | not counted | not counted |
| The `HALT`/final cycle | excluded (cycle_count counts clock cycles of executed instructions after reset, excluding the HALT cycle) | excluded (scalar baseline must count the exact same way) |
| Counting starts | first cycle after `rst` falls | first cycle after `rst` falls |
| Counting stops | the cycle `done` goes high | the cycle `done` goes high |

Every cost above is read off the RTL, not estimated:

- **SIMD** issues one instruction per cycle with no pipeline, so each `VLD`,
  `VADD` and `VST` is exactly one cycle. `bench_add16` is 8 × `VLD`, 4 × `VADD`,
  4 × `VST` and one `HALT` — 17 instructions, 16 counted.
- **Scalar** spends one cycle in each of `S_LDA`, `S_LDB`, `S_ADD` and `S_ST`,
  so four cycles per element.

**Why loop overhead is zero on both sides, and why that is the honest choice.**
The vector ISA has no branch instruction, so the benchmark is fully unrolled
straight-line code and its `pc` increments for free alongside each instruction.
Giving the scalar machine a separate counted cycle for its index increment would
charge it for bookkeeping the SIMD machine does not pay for either, and would
inflate the speed-up. So `scalar_top` folds the increment into its store cycle.
The comparison therefore comes down to the one thing it is supposed to measure:
how many elements each machine moves and computes per cycle.

## Non-negotiables

1. **Same memory cost per element.** If a vector load moves 4 elements in one
   cycle, a scalar load moves 1 element in one cycle. Giving the scalar machine
   a 4-element-wide load would hide the whole effect being measured; giving it a
   multi-cycle load it does not actually take would manufacture one.
2. **Same adder.** `scalar_top` instantiates Himanshu's `lane_alu`, so the two
   machines differ in how many ALUs run per cycle and in nothing else.
3. **Same data.** Both machines run from the same `sim/vectors/dmem_init.hex`.
4. **Count in the RTL, not on paper.** `cycle_count` is a register in each top
   and is read by the testbench. A hand-derived number is not a measurement.
5. **Report what the simulation says.** If the speed-up comes out at 3.4× and
   not 4×, the report says 3.4× and explains the gap — loop overhead, the
   serial load/store pattern, whatever it turns out to be. Tuning the counters
   until they produce 4.00 is the one thing that would be dishonest.

## The table this produces

Goes in `results/cycle_counts.csv` and in report section 4.3.

| Machine | Elements | Cycles | Elements/cycle | Speed-up |
| :--- | ---: | ---: | ---: | ---: |
| `scalar_top` | 16 | 64 | 0.25 | 1.00× |
| `simd_top` (4 lanes) | 16 | **16** | **1.00** | **4.00×** |

## Upper bound, so the result can be sanity-checked

Four lanes cannot beat 4× on a non-pipelined, one-instruction-per-cycle machine.
With the benchmark as written — `VLD`, `VLD`, `VADD`, `VST` per vector, 4
vectors, plus `HALT` — the SIMD side issues 17 instructions, 16 of them counted.
The scalar machine spends one cycle in each of `S_LDA`, `S_LDB`, `S_ADD` and
`S_ST` per element: 4 × 16 = 64. A measured ratio above 4× would mean something
is being counted differently on the two sides.

## Measured

**64 against 16 cycles, a speed-up of exactly 4.00×.**

The result lands precisely on the theoretical bound, and that is worth
explaining rather than presenting as a lucky round number. It happens because
the benchmark is pure data-parallel work with nothing else in it:

- Every scalar operation has an exact vector counterpart — load, load, add,
  store — so the instruction mix is identical on both sides and nothing is
  being compared against a different algorithm.
- Loop overhead is zero on both machines (see the rule above), so neither side
  carries bookkeeping the other avoids.
- The element count, 16, is an exact multiple of `LANES`, so no lane is idle in
  any iteration. With 17 elements the SIMD machine would need a fifth vector
  iteration to process a single element and the speed-up would fall to 3.2×.

So 4.00× is the ceiling being reached under ideal conditions, not evidence that
SIMD is four times better in general. Any workload with partial vectors,
data-dependent branching, or non-contiguous memory access would score lower.
That honesty is the point of fixing the counting rules before measuring.
