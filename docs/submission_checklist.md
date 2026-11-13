# Submission checklist

**Taj ticks the repository and report rows; Parth ticks the rest and submits
the Google Form.** Deadline 16 Nov 2026, 11:59 PM IST; target 9 PM.

## Repository (5 marks)

- [ ] `report/` contains the report **PDF and the LaTeX source**
- [ ] README has the **video link at the top**, plus the spec, the module list,
      and how to run the simulation in 3 commands
- [ ] All RTL, testbenches, hex programs, golden model and diagrams are in the
      repository
- [ ] **Every member has commits on at least two different days**
- [ ] Every member's commits are under **their own GitHub account**
- [ ] No member's file was overwritten by someone else
- [ ] File names match [spec.md](spec.md) exactly
- [ ] CI is green on `main`
- [ ] All four teammates added as collaborators (Taj)

## Code

- [ ] `make -C sim lint` — every module and testbench elaborates
- [ ] `make -C sim test` — no testbench prints FAIL
- [ ] `make -C sim system DEFS=-DDUT_READY` prints **PASS**
- [ ] `pytest tests/` passes
- [ ] `make -C sim vectors` leaves no diff — the committed vectors match the model
- [ ] `results/cycle_counts.csv` holds real numbers from both simulations
- [ ] Synthesis attempted; numbers in `results/`, or the report says plainly that
      no tool was available

## Report (10 marks)

- [ ] Abstract (150–200 words, written last)
- [ ] Literature Review
- [ ] Proposed Solution 4.1, 4.2, 4.3
- [ ] Individual Contributions — one row per member, everyone has checked their
      own row
- [ ] References, IEEE style, 6–8 entries, **every one verified** and no TODO
      fields left in `refs.bib`
- [ ] IEEEtran two-column format, 4–6 pages
- [ ] At least one block diagram and one waveform inside the PDF
- [ ] No separate Results section — preliminary numbers sit inside 4.3

## Video (15 marks)

- [ ] Under 5:00
- [ ] Names **all five** members
- [ ] Shows the prototype working
- [ ] Uploaded as unlisted, link in `video/README.md` and at the top of the README
- [ ] Opens in a **private browser window**

## Submission

- [ ] Google Form submitted with the repository link
- [ ] Submitted **before** the deadline, not at it
