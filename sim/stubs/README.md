# Simulation Stubs

These files in `sim/stubs/` are **throwaway test stubs** used solely for early
integration testing of `simd_top.v` and `tb_simd_top.v` while teammates
(Satya, Himanshu) are completing their final RTL modules (`vreg_file.v`, `dmem.v`,
`lane_alu.v`, `vec_alu.v`).

**Opt-In Usage:**
Stubs are strictly **opt-in**. To run `tb_simd_top` against these stubs:
```bash
make -C sim simd_top STUBS=1
# or from repo root:
make simd_top STUBS=1
```

By default (without `STUBS=1`), `simd_top` builds against the real RTL (`rtl/*.v`).
Because teammate blocks in `rtl/` are initially non-functional placeholders, the default
test fails until their real RTL implementations land on `main`.

**Rules:**
- NEVER commit stubs to `rtl/`.
- The default build target always targets real RTL so tests cannot silently pass against stubs.
- Remove these stubs once real modules are merged into `main`.
