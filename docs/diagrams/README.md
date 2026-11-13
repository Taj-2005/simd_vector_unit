# `docs/diagrams/` — block diagrams

Owner: **Taj**. Three diagrams, each as **both PNG** (for the slides and the
video) **and PDF** (vector, so the IEEE report does not print a blurry figure).

| File | Shows |
| :--- | :--- |
| `top_level.{png,pdf}` | instruction memory → control → register file → `vec_alu` → data memory, plus the cycle counter |
| `datapath.{png,pdf}` | the 128-bit datapath: two read ports, four lanes, the write-back mux that chooses between the ALU result and the memory read |
| `lane.{png,pdf}` | inside one `lane_alu`: the op decode and the six operations |

`report/main.tex` already has this directory on its `\graphicspath`, so
`\includegraphics{top_level.pdf}` works with no path prefix.

Draw them in draw.io, Excalidraw or similar. Keep the module and signal names
**identical** to [`spec.md`](../spec.md) — a diagram that calls a signal
`write_en` while the RTL calls it `we` is the kind of thing an examiner asks
about, and the honest answer is unflattering.
