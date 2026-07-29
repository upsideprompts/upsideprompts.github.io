import json
import datetime
import re

# Create baseball data for July 29, 2026
today = datetime.datetime(2026, 7, 29)

baseballData = [
    {
        'teams': 'New York Yankees @ Detroit Tigers',
        'stadium': 'Comerica Park',
        'day': 'Wednesday, July 29, 2026',
        'time': '7:10 PM EDT',
        'price': '$68 avg',
        'link': 'https://www.mlb.com/yankees/schedule/2026/07/29'
    },
    {
        'teams': 'New York Mets vs Miami Marlins',
        'stadium': 'Citi Field',
        'day': 'Wednesday, July 29, 2026',
        'time': '1:10 PM EDT',
        'price': '$65 avg',
        'link': 'https://www.mlb.com/mets/schedule/2026/07/29'
    },
    {
        'teams': 'Brooklyn Cyclones vs Winston-Salem Dash',
        'stadium': 'Maimonides Park',
        'day': 'Wednesday, July 29, 2026',
        'time': '12:00 PM',
        'price': '$25 avg',
        'link': 'https://www.milb.com/brooklyn/schedule/2026/07/29'
    }
]

# Create hiking data for July 29, 2026
hikingData = [
    {
        'title': 'Inwood Hill Park Nature Exploration Hike',
        'location': 'NYC Urban Park Rangers',
        'time': 'Wednesday, July 29 - 5:00 PM EDT',
        'difficulty': 'Easy',
        'link': 'https://www.nycgovparks.org/parks/inwood-hill-park/events'
    },
    {
        'title': 'Central Park Evening Discovery Walk',
        'location': 'NYC Walks and Talks',
        'time': 'Wednesday, July 29 - 7:00 PM EDT',
        'difficulty': 'Easy (~2 miles)',
        'link': 'https://www.meetup.com/nyc-walks/events/'
    },
    {
        'title': 'Hudson River Park Waterfront Walk',
        'location': 'Brooklyn Hikers Meetup',
        'time': 'Wednesday, July 29 - 6:30 PM EDT',
        'difficulty': 'Easy',
        'link': 'https://www.meetup.com/brooklyn-hikers/events/'
    },
    {
        'title': 'Pelham Bay Park Coastal Trail',
        'location': 'Westchester Hiking Club',
        'time': 'Wednesday, July 29 - 5:30 PM EDT',
        'difficulty': 'Moderate',
        'link': 'https://www.meetup.com/westchester-hiking/events/'
    },
    {
        'title': 'Brooklyn Bridge Park Path',
        'location': 'Brooklyn Hikers Meetup',
        'time': 'Wednesday, July 29 - 6:00 PM EDT',
        'difficulty': 'Easy (~3 miles)',
        'link': 'https://www.meetup.com/brooklyn-hikers/events/'
    }
]

# Read the current index.html
with open('/root/.openclaw/workspace/nystrollstuff/index.html', 'r') as f:
    html_content = f.read()

# Generate JavaScript with the new data
new_js = f'''
<script>
        // Wednesday, July 29, 2026 Baseball Games
        const baseballData = {json.dumps(baseballData, indent: 8)};

        // Wednesday July 29 NYC hiking opportunities
        const hikingData = {json.dumps(hikingData, indent: 8)};

        function loadBaseball() {{
            const container = document.getElementById('baseball-container');
            container.innerHTML = baseballData.map(item => `
                <div class="card">
                    <h3><a href="{item.link}" target="_blank">{item.teams}</a></h3>
                    <p><strong>Stadium:</strong> {item.stadium}</p>
                    <p><strong>Day:</strong> {item.day}</p>
                    <p><strong>Time:</strong> {item.time}</p>
                    <p><strong>Price:</strong> {item.price}</p>
                </div>
            `).join('');
        }}

        function loadHiking() {{
            const container = document.getElementById('hiking-container');
            container.innerHTML = hikingData.map(item => `
                <div class="card">
                    <h3><a href="{item.link}" target="_blank">{item.title}</a></h3>
                    <p><strong>Location:</strong> {item.location}</p>
                    <p><strong>Time:</strong> {item.time}</p>
                    <p><strong>Difficulty:</strong> {item.difficulty}</p>
                </div>
            `).join('');
        }}

        function updateTimestamp() {{
            const now = new Date();
            document.getElementById('last-update').textContent = now.toLocaleString();
        }}

        // Load all data
        loadBaseball();
        loadHiking();
        updateTimestamp();
    </script>
'''

# Replace the old JavaScript section
pattern = r'<script>\s*//.*Monday.*const baseballData =.*?function updateTimestamp\(\)\s*{.*?\n}'
new_html = re.sub(pattern, new_js, html_content, flags=re.DOTALL)

# Save the updated file
with open('/root/.openclaw/workspace/nystrollstuff/index.html', 'w') as f:
    f.write(new_html)

print('Successfully updated nystrollstuff/index.html with July 29, 2026 baseball and hiking events')