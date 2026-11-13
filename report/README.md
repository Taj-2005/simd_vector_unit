# `report/` — IEEE Phase I report

**10 marks.** Owner of the template, the Abstract, the References and the final
PDF: **Taj**. Each section has its own owner and its own file.

## Rules

- **One file per section owner.** Nobody edits `main.tex` except Taj; nobody
  edits someone else's `sections/*.tex`. That is what keeps Overleaf and git
  from fighting.
- **Exactly five parts**, per the course instructions: Abstract, Literature
  Review, Proposed Solution, Individual Contributions, References.
- **No separate Results section in Phase I.** Preliminary numbers live inside
  4.3 and move to a full Results and Discussion section in Phase II.
- 4 to 6 pages, IEEEtran two-column, with at least one block diagram and one
  waveform inside.
- **Export the Overleaf source into this directory on Sunday and again on
  Monday**, with the PDF at the end. The repository is 5 of the marks and the
  report text counts as a contribution — it must appear in the history.

## Files

| File | Section | Owner |
| :--- | :--- | :--- |
| `main.tex` | document, authors, structure | Taj |
| `sections/00_abstract.tex` | Abstract, 150–200 words, written **last** | Taj |
| `sections/01_literature_review.tex` | Literature Review, 1–1.5 pages | Satya |
| `sections/02_solution_architecture.tex` | 4.1 architecture and control, 1 page | Parth |
| `sections/03_solution_datapath.tex` | 4.2 lane and datapath, 1 page | Himanshu |
| `sections/04_solution_evaluation.tex` | 4.3 baseline and evaluation, 0.5 page | Jivit |
| `sections/05_contributions.tex` | Individual Contributions, 0.5 page | Jivit collects |

Citations come from [`../docs/refs.bib`](../docs/refs.bib) — a single shared
file, so any section can cite any entry.

## Compiling

On Overleaf, set the compiler to pdfLaTeX and the main document to `main.tex`.
Locally:

```bash
cd report
pdflatex main && bibtex main && pdflatex main && pdflatex main
```

Two pdfLaTeX passes after BibTeX, or the citations render as `[?]`.

Commit the final PDF as `report/simd_vector_unit_phase1_report.pdf` on Monday,
alongside the LaTeX source. Not yet present - it is written last, once the
cycle numbers exist.
