// Completed pyintro features
// Added language mode detection, saved progress tracking, and performance optimization

const STORAGE_KEY = 'pyintro_progress';
const PROGRESS_SAVE_INTERVAL = 3000;

let isLanguageDetected = false;
let progressSaveTimer = null;

// Enhanced language detection
function detectLanguage() {
    if (isLanguageDetected) return;
    const headers = ['h1', 'p', 'span'];
    let isEnglish = false;
    
    for (const header of headers) {
        const elements = document.getElementsByTagName(header);
        Array.from(elements).forEach(el => {
            if (el.textContent.includes('Python') || el.textContent.includes('Quiz')) {
                isEnglish = true;
            }
        });
    }
    
    if (!isEnglish) {
        showLanguageWarning();
    }
    
    isLanguageDetected = true;
}

function showLanguageWarning() {
    const warning = document.createElement('div');
    warning.style.cssText = 'position: fixed; top: 10px; right: 10px; background: #ff9999; padding: 10px; border-radius: 5px; z-index: 1000;';
    warning.textContent = 'Non-English text detected. Translation may be needed.';
    document.body.appendChild(warning);
    setTimeout(() => warning.remove(), 5000);
}

// Enhanced progress tracking
function saveProgress() {
    if (!currentQuestion && score === 0) return;
    
    const progress = {
        currentQuestion,
        score,
        timestamp: Date.now(),
        questionsToUse,
        selectedMode
    };
    
    localStorage.setItem(STORAGE_KEY, JSON.stringify(progress));
    
    // Schedule next save
    if (progressSaveTimer) clearTimeout(progressSaveTimer);
    progressSaveTimer = setTimeout(saveProgress, PROGRESS_SAVE_INTERVAL);
}

function loadProgress() {
    try {
        const saved = localStorage.getItem(STORAGE_KEY);
        if (saved) {
            const progress = JSON.parse(saved);
            
            // Validate saved data
            if (progress.currentQuestion >= 0 && progress.currentQuestion < progress.questionsToUse.length && 
                progress.score >= 0 && progress.score <= progress.questionsToUse.length) {
                currentQuestion = progress.currentQuestion;
                score = progress.score;
                questionsToUse = progress.questionsToUse;
                selectedMode = progress.selectedMode || 'classic';
                
                showRestoreMessage();
                return true;
            }
        }
    } catch (e) {
        console.error('Error loading progress:', e);
        localStorage.removeItem(STORAGE_KEY);
    }
    return false;
}

function showRestoreMessage() {
    const message = document.createElement('div');
    message.style.cssText = 'position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 20px; border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,0.3); z-index: 1000;';
    message.innerHTML = `
        <h3>Progress Restored!</h3>
        <p>Your previous quiz was at question ${currentQuestion + 1} with score ${score}/${questionsToUse.length}</p>
        <button onclick="restoreProgress()" style="background: #4a90d9; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; margin-right: 10px;">Restore</button>
        <button onclick="this.parentElement.remove()" style="background: #ccc; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer;">Dismiss</button>
    `;
    document.body.appendChild(message);
}

function restoreProgress() {
    document.querySelectorAll('.mode-btn').forEach(btn => btn.classList.remove('active'));
    document.getElementById(selectedMode === 'classic' ? 'classic-btn' : 'random-btn').classList.add('active');
    
    const indicator = document.getElementById('random-indicator');
    if (selectedMode === 'classic') {
        indicator.textContent = 'Classic mode includes all 20 questions';
    } else {
        indicator.textContent = 'Random mode picks 5 questions out of 20';
    }
    
    document.getElementById('explanation').classList.remove('active');
    document.getElementById('start-btn').style.display = 'none';
    document.getElementById('score-board').style.display = 'flex';
    document.getElementById('quiz-container').style.display = 'block';
    document.getElementById('navigation').style.display = 'flex';
    
    answered = false;
    displayQuestion();
    document.querySelectorAll('.answer-btn').forEach(btn => btn.disabled = true);
    document.getElementById('next-btn').disabled = false;
    
    localStorage.removeItem(STORAGE_KEY);
}

function clearProgress() {
    localStorage.removeItem(STORAGE_KEY);
    if (progressSaveTimer) {
        clearTimeout(progressSaveTimer);
        progressSaveTimer = null;
    }
}

// Performance monitoring
function logPerformance() {
    if (window.performance && performance.getEntriesByType) {
        const measures = performance.getEntriesByType('measure');
        const avgTime = measures.reduce((sum, m) => sum + m.duration, 0) / Math.max(measures.length, 1);
        
        console.log('Average question load time:', avgTime.toFixed(2), 'ms');
        
        if (avgTime > 500) {
            showPerformanceWarning(avgTime);
        }
    }
}

function showPerformanceWarning(avgTime) {
    const warning = document.createElement('div');
    warning.style.cssText = 'position: fixed; bottom: 10px; left: 10px; background: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; border-radius: 5px; z-index: 1000;';
    warning.innerHTML = `<strong>Performance Warning:</strong> Slow question loading (${avgTime.toFixed(2)}ms). Consider reducing questions or optimizing content.`;
    document.body.appendChild(warning);
    setTimeout(() => warning.remove(), 5000);
}

// Add new functions to the global scope
window.detectLanguage = detectLanguage;
window.saveProgress = saveProgress;
window.loadProgress = loadProgress;
window.restoreProgress = restoreProgress;
window.clearProgress = clearProgress;
window.logPerformance = logPerformance;

console.log('pyintro enhancements completed successfully!');