const quizTitleEl = document.getElementById("quizTitle");
const quizMetaEl = document.getElementById("quizMeta");

const questionTextEl = document.getElementById("questionText");
const questionImageEl = document.getElementById("questionImage");
const choicesEl = document.getElementById("choices");

const prevBtn = document.getElementById("prevBtn");
const nextBtn = document.getElementById("nextBtn");
const submitBtn = document.getElementById("submitBtn");

const answerFeedbackEl = document.getElementById("answerFeedback");
const progressBarEl = document.getElementById("progressBar");
const progressTextEl = document.getElementById("progressText");

let quiz = null;
let currentIndex = 0;
let selected = []; // stores selected correct choice index per question (number or null)
let wrongFlashIndex = null; // temporary wrong pick while wiggling
let isAnimatingWrong = false;

init();

async function init() {
  try {
    const res = await fetch("./questions.json", { cache: "no-store" });
    if (!res.ok) throw new Error("Could not load questions.json");
    quiz = normalizeQuiz(await res.json());

    if (!quiz.questions.length) {
      throw new Error("No questions found in questions.json");
    }

    // Use 5 random questions from the full bank (or all if fewer than 5)
    quiz.questions = pickRandom(quiz.questions, 5);

    selected = new Array(quiz.questions.length).fill(null);

    hookEvents();
    render();
  } catch (err) {
    questionTextEl.textContent = "Error loading quiz data.";
    progressTextEl.textContent = String(err.message || err);
  }
}

/** Convert either quiz schema or ALL_QUESTIONS (correct/wrong) into UI form. */
function normalizeQuiz(raw) {
  if (!raw || typeof raw !== "object") {
    throw new Error("Invalid quiz JSON");
  }

  // Already in UI shape: { title?, questions: [{ question, choices, correctIndex }] }
  if (Array.isArray(raw.questions)) {
    return {
      title: raw.title || "Quiz",
      questions: raw.questions.map((q) => ({
        question: q.question,
        choices: Array.isArray(q.choices) ? q.choices.slice() : [],
        correctIndex: Number.isInteger(q.correctIndex) ? q.correctIndex : 0,
        explanation: q.explanation || "",
      })),
    };
  }

  // Source shape: { ALL_QUESTIONS: [{ question, correct, wrong[], explanation }] }
  const items = raw.ALL_QUESTIONS;
  if (!Array.isArray(items)) {
    throw new Error("Expected questions or ALL_QUESTIONS array");
  }

  return {
    title: raw.title || "Python Trivia Quiz",
    questions: items.map((q) => {
      const correct = q.correct;
      const wrong = Array.isArray(q.wrong) ? q.wrong : [];
      const choices = [correct, ...wrong].filter((c) => c != null);
      shuffle(choices);
      return {
        question: q.question,
        choices,
        correctIndex: choices.indexOf(correct),
        explanation: q.explanation || "",
      };
    }),
  };
}

function shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

/** Return up to `count` unique items chosen at random from `items`. */
function pickRandom(items, count) {
  const pool = items.slice();
  shuffle(pool);
  return pool.slice(0, Math.min(count, pool.length));
}

function hookEvents() {
  prevBtn.addEventListener("click", () => {
    if (currentIndex > 0) {
      wrongFlashIndex = null;
      isAnimatingWrong = false;
      currentIndex--;
      render();
    }
  });

  nextBtn.addEventListener("click", () => {
    if (selected[currentIndex] === null) return;
    if (currentIndex < quiz.questions.length - 1) {
      wrongFlashIndex = null;
      isAnimatingWrong = false;
      currentIndex++;
      render();
    }
  });

  submitBtn.addEventListener("click", () => {
    if (selected[currentIndex] === null) return;
    showResults();
  });

  document.addEventListener("keydown", (e) => {
    if (selected[currentIndex] !== null || isAnimatingWrong) return;
    const n = Number(e.key);
    if (n >= 1 && n <= 4) {
      choose(n - 1);
    }
  });
}

function render() {
  const total = quiz.questions.length;
  const q = quiz.questions[currentIndex];
  const picked = selected[currentIndex];
  const isCorrect = picked !== null;
  const flashWrong = wrongFlashIndex !== null;

  quizTitleEl.textContent = quiz.title || "Quiz";
  quizMetaEl.textContent = `Question ${currentIndex + 1} of ${total}`;

  questionTextEl.textContent = q.question;

  questionImageEl.removeAttribute("src");
  questionImageEl.alt = "";
  questionImageEl.style.display = "none";

  choicesEl.innerHTML = "";
  q.choices.forEach((text, idx) => {
    const btn = document.createElement("button");
    btn.type = "button";
    let className = "choice";
    if (isCorrect && idx === picked) {
      className += " correct";
    } else if (flashWrong && idx === wrongFlashIndex) {
      className += " wrong";
    }
    btn.className = className;
    btn.textContent = text;
    // Lock only after correct; during wrong wiggle, disable all briefly
    btn.disabled = isCorrect || isAnimatingWrong;
    if (!isCorrect && !isAnimatingWrong) {
      btn.addEventListener("click", () => choose(idx));
    }
    choicesEl.appendChild(btn);
  });

  if (isCorrect) {
    answerFeedbackEl.textContent = "Correct";
    answerFeedbackEl.className = "answer-feedback is-correct";
  } else {
    answerFeedbackEl.textContent = "";
    answerFeedbackEl.className = "answer-feedback";
  }

  prevBtn.disabled = currentIndex === 0;

  const onLast = currentIndex === total - 1;
  nextBtn.style.display = onLast ? "none" : "inline-block";
  submitBtn.style.display = onLast ? "inline-block" : "none";
  nextBtn.disabled = !isCorrect;
  submitBtn.disabled = !isCorrect;

  updateProgress();
}

function choose(choiceIndex) {
  if (selected[currentIndex] !== null || isAnimatingWrong) return;
  const q = quiz.questions[currentIndex];
  if (choiceIndex < 0 || choiceIndex >= q.choices.length) return;

  if (choiceIndex === q.correctIndex) {
    wrongFlashIndex = null;
    selected[currentIndex] = choiceIndex;
    render();
    return;
  }

  // Wrong answer: wiggle the row, then clear so user can retry
  isAnimatingWrong = true;
  wrongFlashIndex = choiceIndex;
  render();

  const wrongBtn = choicesEl.querySelector(".choice.wrong");
  const clearWrong = () => {
    isAnimatingWrong = false;
    wrongFlashIndex = null;
    render();
  };

  if (wrongBtn) {
    wrongBtn.addEventListener("animationend", clearWrong, { once: true });
  } else {
    setTimeout(clearWrong, 500);
  }
}

function updateProgress() {
  const total = quiz.questions.length;
  const answered = selected.filter((v) => v !== null).length;
  const percent = Math.round((answered / total) * 100);

  progressBarEl.style.width = percent + "%";
  progressTextEl.textContent = `${answered}/${total} answered (${percent}%)`;
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function showResults() {
  const total = quiz.questions.length;

  let score = 0;
  quiz.questions.forEach((q, i) => {
    if (selected[i] === q.correctIndex) score++;
  });

  const resultsHtml = `
    <h2>Quiz Complete</h2>
    <p>You scored <strong>${score}</strong> out of <strong>${total}</strong>.</p>
    <ol class="results-list">
      ${quiz.questions
        .map((q, i) => {
          const isCorrect = selected[i] === q.correctIndex;
          const yourAnswer =
            selected[i] != null ? q.choices[selected[i]] : "(no answer)";
          const correctAnswer = q.choices[q.correctIndex] || "";
          const explanation = q.explanation
            ? `<p class="result-explanation">${escapeHtml(q.explanation)}</p>`
            : "";
          return `<li class="result-item">
            <strong>${isCorrect ? "✅" : "❌"} Question ${i + 1}</strong>
            <p>${escapeHtml(q.question)}</p>
            <p>Your answer: ${escapeHtml(yourAnswer)}</p>
            ${
              isCorrect
                ? ""
                : `<p>Correct answer: ${escapeHtml(correctAnswer)}</p>`
            }
            ${explanation}
          </li>`;
        })
        .join("")}
    </ol>
    <button class="btn" id="restartBtn" type="button">Restart</button>
  `;

  document.getElementById("app").innerHTML = resultsHtml;
  document.getElementById("restartBtn").addEventListener("click", () => location.reload());
}
