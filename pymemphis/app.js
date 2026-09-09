import { createApp } from "./vendor/vue.esm.browser.js";

fetch("./questions.json")
  .then((r) => r.json())
  .then((data) => {
    const questions = Array.isArray(data) ? data : (data.ALL_QUESTIONS || []);
    const app = createApp({
      data() {
        const today = new Date();
        const day = today.getDate();
        const month = today.getMonth() + 1;
        const quizMeta = `Quiz #${day} · ${month}/${day}/${today.getFullYear()}`;

        return {
          questions,
          quizTitle: "Python Trivia Quiz : Memphis Rappers",
          cityBadge: "Memphis",
          metaText: quizMeta,
          currentQuiz: [],
          currentIndex: 0,
          selectedChoice: null,
          answerFeedback: null,
          showResults: false,
          score: 0,
          answeredQuestions: 0,
          do20Enabled: false,
          do20BtnHidden: false,
          userAnswers: [], // Track user's answers for results review
        };
      },
      computed: {
        currentQuestion() {
          return this.currentQuiz[this.currentIndex] || null;
        },
        progressPercent() {
          return this.answeredQuestions > 0
            ? Math.round((this.answeredQuestions / this.currentQuiz.length) * 100)
            : 0;
        },
        showSubmit() {
          return this.currentIndex === this.currentQuiz.length - 1 && this.answeredQuestions > 0;
        },
      },
      methods: {
        startQuiz() {
          this.currentQuiz = this.getRandomQuestions();
          this.currentIndex = 0;
          this.selectedChoice = null;
          this.answerFeedback = null;
          this.showResults = false;
          this.score = 0;
          this.answeredQuestions = 0;
          this.do20Enabled = true;
          this.do20BtnHidden = false;
          this.userAnswers = []; // Reset user answers
        },
        getRandomQuestions() {
          if (this.do20Enabled && !this.do20BtnHidden) {
            this.do20BtnHidden = true;
            return [...this.questions].sort(() => Math.random() - 0.5);
          }
          return [...this.questions]
            .sort(() => Math.random() - 0.5)
            .slice(0, 5);
        },
        selectChoice(choice, isCorrect) {
          if (this.selectedChoice !== null) return;
          this.selectedChoice = choice;
          if (isCorrect) {
            this.score++;
            this.answerFeedback = "Correct";
          } else {
            this.answerFeedback = "Wrong";
          }
          this.answeredQuestions++;
          // Record the user's answer for results review
          this.userAnswers[this.currentIndex] = {
            question: this.currentQuestion,
            selected: choice,
            isCorrect: isCorrect,
            correct: this.currentQuestion.correct,
            explanation: this.currentQuestion.explanation
          };
        },
        nextQuestion() {
          if (this.currentIndex < this.currentQuiz.length - 1) {
            this.currentIndex++;
            this.selectedChoice = null;
            this.answerFeedback = null;
          } else {
            this.showResults = true;
          }
        },
        previousQuestion() {
          if (this.currentIndex > 0) {
            this.currentIndex--;
            this.selectedChoice = null;
            this.answerFeedback = null;
          }
        },
        restart() {
          this.startQuiz();
        },
        getChoiceButtonClass(choice, isCorrect) {
          if (this.selectedChoice === choice) {
            return isCorrect ? "correct" : "wrong";
          }
          return "";
        },
        getResultsReview() {
          let review = [];
          for (let i = 0; i < this.userAnswers.length; i++) {
            const answer = this.userAnswers[i];
            review.push({
              question: answer.question,
              index: i,
              yourAnswer: answer.selected,
              correctAnswer: answer.correct,
              isCorrect: answer.isCorrect,
              explanation: answer.explanation
            });
          }
          return review;
        },
      },
      mounted() {
        this.startQuiz();
      },
    });

    const vm = app.mount("#app");
    window.vm = vm;
  });