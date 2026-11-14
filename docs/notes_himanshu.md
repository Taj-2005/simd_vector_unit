# What I built and why — Himanshu Pandey

| | |
| :--- | :--- |
| **Enrollment** | 2401020095 |
| **GitHub** | [@14-himanshu](https://github.com/14-himanshu) |
| **Role** | Datapath · ALU lanes, vector ALU, final video edit |
| **Branch prefix** | `feat/himanshu-*` |
| **Report section** | Proposed Solution 4.2 — lane and datapath design |
| **Video slot** | 2:00–2:40 · **also edits and uploads the final video** |

## What I built

1. **`rtl/lane_alu.v`** — 32-bit scalar ALU supporting 6 operations (`ADD`, `SUB`, `AND`, `OR`, `CMPEQ`, `CMPLT` signed) plus optional `SHL`. Pure combinational module taking operands `a[31:0]`, `b[31:0]`, and `op[2:0]`, outputting `y[31:0]`.
2. **`rtl/vec_alu.v`** — Parameterized vector ALU instantiating `LANES` (default 4) parallel copies of `lane_alu` via a Verilog `generate` loop over 128-bit vector inputs (`LANES * LANE_W`).
3. **`tb/tb_lane_alu.v`** and **`tb/tb_vec_alu.v`** — Comprehensive self-checking unit testbenches verifying all operations, corner cases (overflow, underflow, sign extensions, signed vs unsigned comparison), and 4-lane independence (alternating equality/inequality checks across lanes).
4. **ALU waveform** (`docs/waveforms/vec_alu.png`) — GTKWave-styled waveform demonstrating four independent lanes computing distinct outputs in a single clock cycle, including `[0, 1, 0, 1]` patterns for vector comparisons.
5. **The final video** — Stitched from all 5 team members' clips, keeping the duration strictly under 5:00, uploaded unlisted. Link in [`video/README.md`](../video/README.md).

## Why I built it that way

- **Why `LANES` is a parameter and not a literal 4:**
  Parameterizing `LANES` and `LANE_W` isolates the architectural vector length from the datapath implementation. Widening the SIMD unit from 4 lanes (128-bit vector) to 8 lanes (256-bit vector) or 16 lanes is a single parameter change in `simd_defs.vh` / top-level instantiation. No structural code inside `vec_alu` needs modification.

- **Why compares return 1 or 0 in bit 0 rather than an all-ones mask:**
  Returning boolean integers (`32'd1` or `32'd0`) directly allows comparison results to be used as numeric masks, loop predicates, or boolean sums (e.g. population count / reduction) without requiring additional conversion logic or bit extraction.

- **Why CMPLT is signed, and what an unsigned comparator would still pass:**
  Standard integer algorithms and array indexing often involve signed arithmetic comparisons (e.g., negative offsets, relative temperatures, signed coordinates). An unsigned comparator treats `-1` (`0xFFFFFFFF`) as $4,294,967,295$, which would evaluate `(-1 < 1)` as FALSE. Using Verilog's `$signed(a) < $signed(b)` ensures correct two's complement evaluation where `-1 < 1` evaluates to TRUE.

- **What the generate loop costs in area versus a hand-written four-lane block:**
  In modern synthesis tools (such as Vivado or Yosys), an unrolled `generate` loop synthesizes to the exact same gate netlist as manually instantiated individual lane modules. It incurs zero area or latency overhead while vastly improving code readability, maintainability, and scalability.

## Questions I should be able to answer in the viva

- **Point at the waveform and show that lane 2 cannot affect lane 1:**
  In `docs/waveforms/vec_alu.png`, under `VCMPEQ` and `VCMPLT` at $40\,\text{ns}$ and $50\,\text{ns}$, Lane 0 evaluates to `1`, Lane 1 evaluates to `0`, Lane 2 evaluates to `1`, and Lane 3 evaluates to `0`. If any carry, borrow, or cross-talk leaked across lane boundaries, Lane 1 would corrupt or match Lane 0 or 2. Each lane produces its result purely as a function of `a[i]` and `b[i]`.
- **What exactly changes in the design if `LANES` goes from 4 to 8:**
  Only `LANES = 8` in `simd_defs.vh` (and port vector width `LANES * LANE_W = 256` bits). The `generate` loop automatically unrolls 8 lane instances, mapping bits `[32*i +: 32]` for $i \in [0, 7]$.
- **Why is there no carry between lanes, and when would you want one?**
  In SIMD processing, lanes represent independent parallel data elements (e.g., separate pixels, audio samples, or matrix entries). Carrying between lanes would violate data independence and introduce sequential carry-propagation latency across the 128-bit datapath. A cross-lane carry/reduction is only desirable during specialized vector reduction instructions (like horizontal vector sum `VREDSUM`), which would use a dedicated reduction tree rather than the elementwise ALU.
