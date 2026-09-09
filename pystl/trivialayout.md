# Prompt Summary: City Rap + Python Trivia Game

Use this as the reusable prompt/spec to build another city trivia quiz like `/pystl` (same pattern as `/pybites` and `/pyphilly`).

---

## Goal

Build a static browser trivia game that mixes **local hip-hop history** with **Python syntax and parameters**. Default to a short random quiz, allow expanding to the full bank, and show a scored results review at the end.

---

## Content theme

- **City / brand:** St. Louis → title badge `STL`
- **Topic mix:** real local rapper/crew/album history + Python coding concepts
- **Python focus:** function syntax, parameters (positional, default, `*args`, `**kwargs`, keywords), data structures, loops, comparisons, imports, slices, `enumerate`, `zip`, return values
- **Bank size:** 20 questions

---

## Files to create

| File | Role |
|------|------|
| `index.html` | Page shell: title, question area, choices, controls, progress |
| `styles.css` | Layout and visual states for choices / feedback / results |
| `app.js` | Load JSON, normalize, render, input handling, results |
| `questions.json` | Question bank consumed by the app |
| `questions.py` | Optional source that regenerates `questions.json` |

---

## Layout

Centered single-card UI on a gradient page:

1. **Header** — quiz title + city badge + `Question X of Y`
2. **Card (`#app`)** —
   - Question text (`#questionText`)
   - Optional image slot (`#questionImage`, hidden unless used)
   - Choice buttons grid (`#choices`)
   - Answer feedback line (`#answerFeedback`)
   - Controls: Previous / Next / Submit
   - Progress bar + `N/total answered (%)`
   - Optional **Do 20 questions** button (shown only on short-quiz Q1)

Match the pybites/pyphilly card layout so behavior and styling stay consistent across city quizzes.

---

## Question display

- Show **one question at a time**
- Render the question as plain text
- Render each choice as a **button** (`.choice`)
- Choice visual states:
  - default
  - `.selected` — incorrect pick kept so Next still works
  - `.wrong` — brief wiggle animation on miss
  - `.correct` — lock in when the right answer is chosen
- On correct answer, show feedback text **Correct**
- Wrong answers may be retried after the wiggle; correct answers lock the question

---

## JSON input format

Primary schema used by `/pystl`:

```json
{
  "ALL_QUESTIONS": [
    {
      "index": 0,
      "question": "History hook + Python question…",
      "correct": "Right answer text or code",
      "wrong": [
        "Wrong option 1",
        "Wrong option 2",
        "Wrong option 3"
      ],
      "explanation": "Short why this is correct, tying city fact to Python."
    }
  ]
}
```

Rules:

- Prefer **1 correct + 3 wrong** options
- App shuffles choices at load so the correct answer is not always first
- Code snippets may include `\n` for multi-line answers
- Optional alternate schema also supported by `app.js`:
  `{ "title": "...", "questions": [{ "question", "choices", "correctIndex", "explanation" }] }`

Generate JSON from `questions.py` with:

```bash
python3 questions.py
```

---

## App input / behavior

On load:

1. `fetch("./questions.json")`
2. Normalize into `{ question, choices, correctIndex, explanation }`
3. Default quiz = **5 random** questions from the bank
4. **Do 20 questions** expands to the full shuffled bank

User input:

- Click a choice button, or press keys `1`–`4`
- **Previous** / **Next** navigate; Next/Submit require an answer
- On the last question, **Submit** replaces Next
- Correct answer locks that question; wrong answer wiggles then allows retry

---

## Results screen

After Submit, replace `#app` with:

- Score: `You scored X out of Y`
- Ordered review of each question:
  - ✅ / ❌
  - Question text
  - Your answer
  - Correct answer (if wrong)
  - Explanation (if present)
- **Restart** button → reload the page

---

## Reusable prompt (copy/paste)

```text
Create a static trivia quiz folder like /pystl for <CITY> rappers + Python syntax/parameters.

Include index.html, styles.css, app.js, questions.json, and questions.py.
Use the same layout as /pybites: centered gradient page, title with city badge,
one question at a time, choice buttons, Correct feedback, Previous/Next/Submit,
progress bar, and optional “Do 20 questions”.

Write 20 questions that mix real <CITY> hip-hop history with Python concepts
(function defs, defaults, *args/**kwargs, keywords, lists/dicts, loops,
comparisons, imports, slices, enumerate, zip, return values).

Store questions in questions.json as:
{ "ALL_QUESTIONS": [{ "index", "question", "correct", "wrong": [...], "explanation" }] }

On load, pick 5 random questions; allow expanding to all 20.
Shuffle choices. Wrong answers wiggle and can be retried; correct answers lock.
On Submit, show score plus per-question review (your answer, correct answer if needed,
explanation) and a Restart button.
```

---

## Related examples

- `/pybites` — Atlanta-themed original pattern
- `/pyphilly` — Philadelphia variant with the same UI
- `/pystl` — St. Louis variant (this folder)
