# `docs/waveforms/` — GTKWave screenshots

Committed evidence for the report and the video. The raw `.vcd` files in
`sim/waves/` are regenerated and git-ignored; these PNGs are kept.

| File | From | Shows | Owner |
| :--- | :--- | :--- | :--- |
| `vreg_file.png` | `tb_vreg_file` | writing all 8 registers, both read ports active, read-and-write in the same cycle | Satya |
| `vec_alu.png` | `tb_vec_alu` | four lanes computing four different results in one cycle | Himanshu |
| `system_pass.png` | `tb_system` | the self-checking run printing PASS | Taj |

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
