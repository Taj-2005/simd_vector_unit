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
| A vector/scalar load costs | _TODO_ cycle(s) | _TODO_ cycle(s) |
| An ALU operation costs | _TODO_ | _TODO_ |
| A store costs | _TODO_ | _TODO_ |
| Loop overhead (index increment, branch) | _TODO_ | _TODO_ |
| Reset cycles | not counted | not counted |
| The `HALT`/final cycle | _TODO_ | _TODO_ |
| Counting starts | first cycle after `rst` falls | first cycle after `rst` falls |
| Counting stops | the cycle `done` goes high | the cycle `done` goes high |

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
| `scalar_top` | 16 | _TODO_ | _TODO_ | 1.00× |
| `simd_top` (4 lanes) | 16 | _TODO_ | _TODO_ | _TODO_ |

## Upper bound, so the result can be sanity-checked

Four lanes cannot beat 4× on a non-pipelined, one-instruction-per-cycle machine.
With the benchmark as written — `VLD`, `VLD`, `VADD`, `VST` per vector, 4
vectors, plus `HALT` — the SIMD side issues 17 instructions. A scalar machine
doing load, load, add, store per element over 16 elements issues about 64, plus
loop overhead. A measured ratio above 4× means something is being counted
differently on the two sides; find it before reporting it.
