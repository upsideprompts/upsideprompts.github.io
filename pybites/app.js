const quizTitleEl = document.getElementById("quizTitle");
const quizMetaEl = document.getElementById("quizMeta");

const questionTextEl = document.getElementById("questionText");
const questionImageEl = document.getElementById("questionImage");
const choicesEl = document.getElementById("choices");

const prevBtn = document.getElementById("prevBtn");
const nextBtn = document.getElementById("nextBtn");
const submitBtn = document.getElementById("submitBtn");

const progressBarEl = document.getElementById("progressBar");
const progressTextEl = document.getElementById("progressText");

let quiz = null;
let currentIndex = 0;
let selected = []; // stores selected choice index per question (number or null)

init();

async function init() {
 try {
 const res = await fetch("./questions.json", { cache: "no-store" });
 if (!res.ok) throw new Error("Could not load questions.json");
 quiz = await res.json();

 selected = new Array(quiz.questions.length).fill(null);

 hookEvents();
 render();
 } catch (err) {
 questionTextEl.textContent = "Error loading quiz data.";
 progressTextEl.textContent = String(err.message || err);
 }
}

function hookEvents() {
 prevBtn.addEventListener("click", () => {
 if (currentIndex > 0) {
 currentIndex--;
 render();
 }
 });

 nextBtn.addEventListener("click", () => {
 if (selected[currentIndex] === null) {
 alert("Please choose an answer first.");
 return;
 }
 if (currentIndex < quiz.questions.length - 1) {
 currentIndex++;
 render();
 }
 });

 submitBtn.addEventListener("click", () => {
 if (selected[currentIndex] === null) {
 alert("Please answer the last question.");
 return;
 }
 showResults();
 });

 document.addEventListener("keydown", (e) => {
 const n = Number(e.key);
 if (n >= 1 && n <= 4) {
 choose(n - 1);
 }
 });
}

function render() {
 const total = quiz.questions.length;
 const q = quiz.questions[currentIndex];

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
 btn.className = "choice" + (selected[currentIndex] === idx ? " selected" : "");
 btn.textContent = text;
 btn.addEventListener("click", () => choose(idx));
 choicesEl.appendChild(btn);
 });

 prevBtn.disabled = currentIndex === 0;

 const onLast = currentIndex === total - 1;
 nextBtn.style.display = onLast ? "none" : "inline-block";
 submitBtn.style.display = onLast ? "inline-block" : "none";
 submitBtn.disabled = selected[currentIndex] === null;

 updateProgress();
}

function choose(choiceIndex) {
 selected[currentIndex] = choiceIndex;
 render();
}

function updateProgress() {
 const total = quiz.questions.length;
 const answered = selected.filter(v => v !== null).length;
 const percent = Math.round((answered / total) * 100);

 progressBarEl.style.width = percent + "%";
 progressTextEl.textContent = `${answered}/${total} answered (${percent}%)`;
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
 <ol>
 ${quiz.questions.map((q, i) => {
 const isCorrect = selected[i] === q.correctIndex;
 return `<li>
 ${isCorrect ? "✅" : "❌"} Question ${i + 1}
 </li>`;
 }).join("")}
 </ol>
 <button class="btn" id="restartBtn" type="button">Restart</button>
 `;

 document.getElementById("app").innerHTML = resultsHtml;
 document.getElementById("restartBtn").addEventListener("click", () => location.reload());
}