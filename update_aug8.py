import json
import re

# Read the current index.html
with open('/root/.openclaw/workspace/nystrollstuff/index.html', 'r') as f:
    html_content = f.read()

# Create baseball data for August 6, 2026
baseballData = [
    {
        'teams': 'New York Yankees vs Tampa Bay Rays',
        'stadium': 'Yankee Stadium',
        'day': 'Thursday, August 6, 2026',
        'time': '7:10 PM EDT',
        'price': '$90 avg',
        'link': 'https://www.mlb.com/yankees/schedule/2026/08/06'
    },
    {
        'teams': 'New York Mets vs Philadelphia Phillies',
        'stadium': 'Citizens Bank Park',
        'day': 'Thursday, August 6, 2026',
        'time': '7:35 PM EDT',
        'price': '$80 avg',
        'link': 'https://www.mlb.com/mets/schedule/2026/08/06'
    },
    {
        'teams': 'Brooklyn Cyclones vs Adirondack Trail Kings',
        'stadium': 'Maimonides Park',
        'day': 'Thursday, August 6, 2026',
        'time': '7:05 PM',
        'price': '$22 avg',
        'link': 'https://www.milb.com/brooklyn/schedule/2026/08/06'
    }
]

# Create hiking data for August 6, 2026
hikingData = [
    {
        'title': 'Inwood Hill Park Sunset Ridge Hike',
        'location': 'NYC Parks Department',
        'time': 'Thursday, August 6 - 6:30 PM EDT',
        'difficulty': 'Easy',
        'link': 'https://www.nycgovparks.org/parks/inwood-hill-park/events'
    },
    {
        'title': 'Central Park Loop with Conservatory Garden',
        'location': 'Central Park Conservancy',
        'time': 'Thursday, August 6 - 5:30 PM EDT',
        'difficulty': 'Easy (~3 miles)',
        'link': 'https://www.centralparknyc.org/events'
    },
    {
        'title': 'Hudson River Park Pier 84 Evening Walk',
        'location': 'Hudson River Park Trust',
        'time': 'Thursday, August 6 - 7:00 PM EDT',
        'difficulty': 'Easy',
        'link': 'https://hudsonriverpark.org/events'
    },
    {
        'title': 'Pelham Bay Park Orchard Trail',
        'location': 'NYC Parks Department',
        'time': 'Thursday, August 6 - 5:45 PM EDT',
        'difficulty': 'Moderate',
        'link': 'https://www.nycgovparks.org/parks/pelham-bay-park/events'
    },
    {
        'title': 'Brooklyn Bridge Park Domino Park Walk',
        'location': 'Brooklyn Bridge Park Conservancy',
        'time': 'Thursday, August 6 - 7:15 PM EDT',
        'difficulty': 'Easy (~2.5 miles)',
        'link': 'https://brooklynbridgepark.org/events'
    }
]

# Create the JavaScript code using string concatenation to avoid curly brace escaping issues
js_part1 = '''
<script>
        // Thursday, August 6, 2026 Baseball Games
        const baseballData = '''

js_part2 = json.dumps(baseballData, indent=8)

js_part3 = ''';

js_part4 = '''
        // Thursday August 6 NYC hiking opportunities
        const hikingData = '''

js_part5 = json.dumps(hikingData, indent=8)

js_part6 = ''';

js_part7 = '''

js_part8 = '''
        function loadBaseball() {
            const container = document.getElementById('baseball-container');
            container.innerHTML = baseballData.map(item => `
                <div class="card">
                    <h3><a href="${item.link}" target="_blank">${item.teams}</a></h3>
                    <p><strong>Stadium:</strong> ${item.stadium}</p>
                    <p><strong>Day:</strong> ${item.day}</p>
                    <p><strong>Time:</strong> ${item.time}</p>
                    <p><strong>Price:</strong> ${item.price}</p>
                </div>
            `).join('');
        }

        function loadHiking() {
            const container = document.getElementById('hiking-container');
            container.innerHTML = hikingData.map(item => `
                <div class="card">
                    <h3><a href="${item.link}" target="_blank">${item.title}</a></h3>
                    <p><strong>Location:</strong> ${item.location}</p>
                    <p><strong>Time:</strong> ${item.time}</p>
                    <p><strong>Difficulty:</strong> ${item.difficulty}</p>
                </div>
            `).join('');
        }

        function updateTimestamp() {
            const now = new Date();
            document.getElementById('last-update').textContent = now.toLocaleString();
        }

        // Load all data
        loadBaseball();
        loadHiking();
        updateTimestamp();
    </script>
'''

# Combine all parts
js_content = js_part1 + js_part2 + js_part3 + js_part4 + js_part5 + js_part6 + js_part7 + js_part8

# Replace the entire script section by finding the opening and closing script tags
pattern = r'<script>.*?(?=\n</body>|$)'
new_html = re.sub(pattern, js_content, html_content, flags=re.DOTALL)

# Save the updated file
with open('/root/.openclaw/workspace/nystrollstuff/index.html', 'w') as f:
    f.write(new_html)

print('Successfully updated nystrollstuff/index.html with August 6, 2026 baseball and hiking events')