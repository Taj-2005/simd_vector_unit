# `docs/diagrams/` — block diagrams

Owner: **Taj**. Three diagrams, each committed as **SVG** (the source), **PNG**
(slides and video) and **PDF** (vector, so the IEEE report does not print a
blurry figure).

| Diagram | Shows |
| :--- | :--- |
| `top_level` | `instr_mem → ctrl_unit → vreg_file → vec_alu → dmem`, the write-back mux, and the cycle counter |
| `datapath` | the 128-bit datapath: two read ports, the lane split, four independent lanes, the lane concat, the write-back mux |
| `lane` | inside one `lane_alu`: all seven operations computed in parallel, one mux selected by `op[2:0]` |

## Editing

**Edit the `.svg`, never the PNG or PDF.** SVG is text, so a diagram change
shows up as a reviewable diff rather than an opaque binary blob.

```bash
make -C docs/diagrams          # regenerate every PNG and PDF
```

Needs librsvg (`brew install librsvg`, or `apt-get install -y librsvg2-bin`).

## Using them in the report

`report/main.tex` already has this directory on its `\graphicspath`, so no path
prefix is needed:

```latex
\begin{figure}[t]
  \centering
  \includegraphics[width=\columnwidth]{top_level.pdf}
  \caption{Top-level organisation of the 4-lane SIMD vector unit.}
  \label{fig:top}
\end{figure}
```

Use the **PDF** in the report and the **PNG** in slides or the video.

## Rules these follow

- **Module and signal names are identical to [`spec.md`](../spec.md) §4.** A
  diagram that calls a signal `write_en` while the RTL calls it `we` is exactly
  what an examiner picks up on, and the honest answer is unflattering.
- **The instruction encoding is deliberately absent.** It is the part of the
  spec still open to change (see [`scaffold_notes.md`](../scaffold_notes.md)
  A1–A2); it belongs in Parth's report section 4.1, where renumbering costs a
  table edit rather than a redraw.
- **Greyscale-safe.** No information is carried by colour alone — line weight
  separates a 128-bit vector bus from a control signal, because the report may
  well be printed in black and white.
