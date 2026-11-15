# `docs/waveforms/` — GTKWave screenshots

Committed evidence for the report and the video. The raw `.vcd` files in
`sim/waves/` are regenerated and git-ignored; these PNGs are kept.

| File | From | Shows | Owner |
| :--- | :--- | :--- | :--- |
| `vreg_file.png` | `tb_vreg_file` | writing all 8 registers, both read ports active, read-and-write in the same cycle | Satya |
| `vec_alu.png` | `tb_vec_alu` | four lanes computing four different results in one cycle | Himanshu |
| `system_pass.png` | `tb_system` | the self-checking run printing PASS | Taj |

## Making one

Two routes, and the first is preferred.

**Generated from the VCD (reproducible).** `vec_alu.png` is produced this way:

```bash
make -C sim vec_alu                       # -> sim/waves/tb_vec_alu.vcd
python docs/waveforms/make_waveform.py    # VCD -> vec_alu.svg
make -C docs/waveforms                    # svg -> PNG + PDF
```

Every value in the figure is parsed out of the VCD the simulator wrote, so the
diagram cannot drift from what the hardware actually did. An earlier
hand-drawn version of this same figure showed `0x00000064` where the simulation
produced `0x0000005A` — which is exactly the failure mode this avoids. The
figure states on its face that it is a reconstruction, not a screenshot.

**A real GTKWave capture.** Also fine, and better for showing *how* you explore
a waveform:

```bash
make -C sim vec_alu
make -C sim wave-vec_alu   # opens GTKWave
```

Add the signals, set the radix to hex, zoom to the interesting cycles, and save
the screenshot here. If you do this, caption it as a GTKWave screenshot — and
if you draw a figure by hand instead, caption it as a reconstruction. What is
not acceptable is a drawing captioned as a tool capture.

**Crop to the cycles that make the point.** A full-timeline screenshot at
default zoom proves nothing to anyone, least of all in a 40-second video slot.
Label the lanes if the signal names alone do not make the grouping obvious.
