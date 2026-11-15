# `docs/waveforms/` — GTKWave screenshots

Committed evidence for the report and the video. The raw `.vcd` files in
`sim/waves/` are regenerated and git-ignored; these PNGs are kept.

| File | From | Shows | Owner |
| :--- | :--- | :--- | :--- |
| `vreg_file.png` | `tb_vreg_file` | writing all 8 registers, both read ports active, read-and-write in the same cycle | Satya |
| `vec_alu.png` | `tb_vec_alu` | four lanes computing four different results in one cycle | Himanshu |
| `system_pass.png` | `tb_system` | the self-checking run printing PASS | Taj |

> ### ⚠ `vec_alu.png` must be re-captured before submission
>
> The committed `vec_alu.png` is **not a GTKWave capture** — it is a hand-drawn
> recreation. Two things give it away: GTKWave draws value cells as angled
> hexagons with a signal-tree pane, and one cell disagrees with the simulation
> (`SUB` lane 0 shows `00000064` where `tb_vec_alu` produces `0000005A`, which
> is the 90 the image itself annotates).
>
> Every number it shows is otherwise correct and the simulation already produces
> all of them, so there is nothing to fabricate — it just has to be captured:
>
> ```bash
> make -C sim vec_alu          # writes sim/waves/tb_vec_alu.vcd
> gtkwave sim/waves/tb_vec_alu.vcd
> ```
>
> Add `op`, `a`, `b`, `y`, and the four `lane[i].u_lane.y` signals, set the
> radix to hex, zoom to 0-70 ns, and save the screenshot over `vec_alu.png`.
> Report section 4.2 and the 2:00-2:40 video slot both point at this figure.

## Making one

```bash
make -C sim vec_alu        # produces sim/waves/tb_vec_alu.vcd
make -C sim wave-vec_alu   # opens it in GTKWave
```

Then add the signals you want, zoom to the interesting cycles, and save the
screenshot here.

**Crop to the cycles that make the point.** A full-timeline screenshot at
default zoom proves nothing to anyone, least of all in a 40-second video slot.
Label the lanes if the signal names alone do not make the grouping obvious.
