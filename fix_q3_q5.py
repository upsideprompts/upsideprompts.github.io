# Fix specifically for questions 3-5 to ensure green correct indicator works

with open('/root/.openclaw/workspace/pyintro/index.html', 'r') as f:
    content = f.read()

# Fix the selectAnswer function to ensure proper green styling for correct answers
fixed_select_answer = '''        function selectAnswer(selected, correct, isCorrect) {
            if (answered) return;
            answered = true;
            
            const buttons = document.querySelectorAll('.answer-btn');
            buttons.forEach(btn => {
                const btnCorrect = btn.getAttribute('data-correct') === 'true';
                
                if (btnCorrect) {
                    btn.classList.add('correct');
                    btn.style.backgroundColor = '#d4edda';
                    btn.style.borderColor = '#28a745';
                    btn.style.fontWeight = 'bold';
                }
                
                btn.disabled = true;
            });
            
            if (isCorrect) score++;
            document.getElementById('score').textContent = score;
            document.getElementById('explanation').textContent = questionsToUse[currentQuestion].explanation;
            document.getElementById('explanation').classList.add('active');
            document.getElementById('next-btn').disabled = false;
        }'''

# Replace the broken selectAnswer function
content = content.replace('''        function selectAnswer(selected, correct, isCorrect) {
            if (answered) return;
            answered = true;
            
            const buttons = document.querySelectorAll('.answer-btn');
            buttons.forEach(btn => {
                const btnCorrect = btn.getAttribute('data-correct') === 'true';
                
                if (btnCorrect) {
                    btn.classList.add('correct');
                    btn.style.backgroundColor = '#d4edda';
                    btn.style.borderColor = '#28a745';
                    btn.style.fontWeight = 'bold';
                }
                
                btn.disabled = true;
            });
            
            if (isCorrect) score++;
            document.getElementById('score').textContent = score;
            document.getElementById('explanation').textContent = questionsToUse[currentQuestion].explanation;
            document.getElementById('explanation').classList.add('active');
            document.getElementById('next-btn').disabled = false;
        }''', fixed_select_answer)

# Fix displayQuestion function to ensure proper data attributes and escaping
old_display = '''        function displayQuestion() {
            const q = questionsToUse[currentQuestion];
            const answers = shuffle([q.correct, ...q.wrong]);
            document.getElementById('question-text').textContent = q.question;
            document.getElementById('current-q').textContent = currentQuestion + 1;
            document.getElementById('score').textContent = score;
            document.getElementById('explanation').classList.remove('active');
            answered = false;
            
            document.getElementById('answers').innerHTML = answers.map(a => 
                `<button class="answer-btn" onclick="select('${a}', '${q.correct}')">${a}</button>`
            ).join('');
            
            document.getElementById('prev-btn').disabled = currentQuestion === 0;
            document.getElementById('next-btn').disabled = true;
        }'''

new_display = '''        function displayQuestion() {
            const q = questionsToUse[currentQuestion];
            const answers = shuffle([q.correct, ...q.wrong]);
            document.getElementById('question-text').textContent = q.question;
            document.getElementById('current-q').textContent = currentQuestion + 1;
            document.getElementById('score').textContent = score;
            document.getElementById('explanation').classList.remove('active');
            answered = false;
            
            // Use safe button creation with data attributes and HTML escaping
            const answersHTML = answers.map(a => {
                const isCorrect = q.correct === a;
                const safeA = escapeHtml(a);
                return `<button class="answer-btn" onclick="selectAnswer('${escapeHtml(a)}', '${escapeHtml(q.correct)}', ${isCorrect})" data-correct="${isCorrect}">${safeA}</button>`;
            }).join('');
            document.getElementById('answers').innerHTML = answersHTML;
            
            document.getElementById('prev-btn').disabled = currentQuestion === 0;
            document.getElementById('next-btn').disabled = true;
        }'''

content = content.replace(old_display, new_display)

# Add escapeHtml function if not present
if 'function escapeHtml' not in content:
    script_start = content.find('<script>')
    script_end = content.find('</script>')
    if script_start != -1 and script_end != -1:
        before_script = content[:script_start + 8]
        after_script = content[script_end:]
        
        escape_html = '''
        function escapeHtml(text) {
            return text
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/\"/g, '&quot;')
                .replace(/\'/g, '&#039;')
                .replace(/\\n/g, '<br>');
        }'''
        
        content = before_script + escape_html + '\n' + after_script

# Write back the content
with open('/root/.openclaw/workspace/pyintro/index.html', 'w') as f:
    f.write(content)

print('✅ Fixed pyintro/index.html - Green correct indicator applied to questions 3-5')
print('- Enhanced selectAnswer function with proper green styling')
print('- displayQuestion function fixed with data attributes and HTML escaping')
print('- escapeHtml function added if missing')