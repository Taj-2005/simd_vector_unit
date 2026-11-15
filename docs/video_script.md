# Video script — 4:50 planned, 5:00 hard limit

**15 marks, the largest single item.** Owner of the final cut: **Himanshu**.
Owner of the upload link and the submission: **Parthraj**.

Three things the video must do, from the course instructions: state the project
idea, introduce **all five** members by name, and show the prototype working.

Record each slot as a **separate** screen-share clip. One bad take then costs one
retake instead of the whole video.

---

## Slots

| Time | Speaker | Say and show |
| :--- | :--- | :--- |
| 0:00–0:40 | All five, Parth leads | Project 11, SIMD Vector Processing Unit, Modern Computer Architecture. Each member says their name and the block they built — **8 seconds each** |
| 0:40–1:25 | Parth | Top-level block diagram; instruction format; how the control unit drives the datapath |
| 1:25–2:00 | Satya | Register-file and memory waveform in GTKWave; what the testbench checks |
| 2:00–2:40 | Himanshu | Four lanes computing together on the `vec_alu` waveform; the op table |
| 2:40–3:25 | Taj | System testbench running in the terminal printing PASS; the golden-model idea; synthesis numbers if available |
| 3:25–4:20 | Jivit | Scalar vs SIMD cycle table for the 16-element add; the cycle-counting rules |
| 4:20–4:50 | Parth | What is done, what Phase II adds, and where the GitHub repo is |

## Rules

- **Three bullet points each, not a script.** Reading a script aloud sounds
  read; three bullets sound like you understand it. Write yours below.
- **Practise once with a timer.** 45 seconds is shorter than it looks.
- Show the thing running, not slides about the thing running. Taj's slot is a
  live terminal; Satya's and Himanshu's are live GTKWave.
- Check the final file length **before** uploading.
- Open the link in a **private browser window** to confirm it plays for someone
  who is not logged in.

## Bullet points — fill in your own

**Parth (0:40–1:25)**
- _TODO_
- _TODO_
- _TODO_

**Satya (1:25–2:00)**
- _TODO_
- _TODO_
- _TODO_

**Himanshu (2:00–2:40)**
- Walk through the `vec_alu` GTKWave waveform: 4 independent 32-bit lanes operating in parallel across a 128-bit datapath in a single cycle, parameterised via `generate`.
- Highlight opcode set and the signed comparator (`CMPLT`): explain why signed evaluation matters (so $-1 < 1$ evaluates to true) and why compares return narrow boolean $1/0$ values.
- Point to the $40\,\text{ns}$ and $50\,\text{ns}$ compare markers showing $[0, 1, 0, 1]$ output across lanes, proving zero carry/borrow leakage and strict lane isolation.

**Taj (2:40–3:25)**
- _TODO_
- _TODO_
- _TODO_

**Jivit (3:25–4:20)**
- _TODO_
- _TODO_
- _TODO_

**Parth (4:20–4:50)**
- _TODO_
- _TODO_
- _TODO_
