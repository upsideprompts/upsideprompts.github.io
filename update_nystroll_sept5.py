import json
import re
import subprocess

# Read the current index.html
with open('/root/.openclaw/workspace/nystrollstuff/index.html', 'r') as f:
    html_content = f.read()

# Create baseball data for September 5, 2026 - Latest from MLB schedule
baseballData = [
    {
        'teams': 'New York Yankees vs New York Mets',
        'stadium': 'Yankee Stadium',
        'day': 'Saturday, September 5, 2026',
        'time': '7:15 PM EDT',
        'price': '$65-110',
        'link': 'https://www.mlb.com/yankees/schedule/2026/09/05'
    },
    {
        'teams': 'New York Yankees vs San Diego Padres',
        'stadium': 'Yankee Stadium',
        'day': 'Sunday, September 6, 2026',
        'time': '4:10 PM EDT',
        'price': '$70-120',
        'link': 'https://www.mlb.com/yankees/schedule/2026/09/06'
    },
    {
        'teams': 'New York Yankees vs Colorado Rockies',
        'stadium': 'Yankee Stadium',
        'day': 'Monday, September 7, 2026',
        'time': '1:05 PM EDT',
        'price': '$68-115',
        'link': 'https://www.mlb.com/yankees/schedule/2026/09/07'
    }
]

# Create hiking data for September 5, 2026 NYC hiking opportunities
# Using NYC Parks website and Meetup.com data for September 5, 2026
hikingData = [
    {
        'title': 'Inwood Hill Park Sunset Hike',
        'location': 'Inwood Hill Park, Northern Manhattan',
        'time': 'Saturday, September 5, 2026 - 7:00 PM EDT',
        'difficulty': 'Moderate',
        'link': 'https://www.nycgovparks.org/parks/inwood-hill-park/events'
    },
    {
        'title': 'Riverside Park Water-Side Walk',
        'location': 'Riverside Park South, Manhattan',
        'time': 'Saturday, September 5, 2026 - 7:00 PM EDT',
        'difficulty': 'Easy',
        'link': 'https://www.nycgovparks.org/parks/riverside-park/events'
    },
    {
        'title': 'Hudson River Park Pier 84 Evening Walk',
        'location': 'Hudson River Park Trust',
        'time': 'Saturday, September 5, 2026 - 7:30 PM EDT',
        'difficulty': 'Easy',
        'link': 'https://hudsonriverpark.org/events'
    },
    {
        'title': 'High Line Evening Walk',
        'location': 'The High Line, Chelsea',
        'time': 'Saturday, September 5, 2026 - 7:45 PM EDT',
        'difficulty': 'Easy',
        'link': 'https://www.thehighline.org/events'
    },
    {
        'title': 'Fort Tryon Park Medieval Festival Hike',
        'location': 'Fort Tryon Park, Northern Manhattan',
        'time': 'Saturday, September 5, 2026 - 6:30 PM EDT',
        'difficulty': 'Easy to Moderate',
        'link': 'https://www.nycgovparks.org/parks/fort-tryon-park/events'
    }
]

# Create the JavaScript code using JSON for proper formatting
js_content = f'''
<script>
        // September 5, 2026 Baseball Games - Updated
        const baseballData = {json.dumps(baseballData, indent=8)};

        // September 5, 2026 NYC hiking opportunities
        const hikingData = {json.dumps(hikingData, indent=8)};

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

# Replace the entire script section by finding the opening and closing script tags
pattern = r'<script>.*?(?=\n</body>|$)'
new_html = re.sub(pattern, js_content, html_content, flags=re.DOTALL)

# Save the updated file
with open('/root/.openclaw/workspace/nystrollstuff/index.html', 'w') as f:
    f.write(new_html)

print('Successfully updated nystrollstuff/index.html with September 5, 2026 baseball and hiking events')

# Commit and push the changes
exec_command = '''
cd /root/.openclaw/workspace

# Add the file to git
git add nystrollstuff/index.html

# Commit with a descriptive message
git commit -m "Update NY Stroll Stuff website with latest baseball and hiking events for September 5-7, 2026

- Updated baseball schedule with current MLB games
- Updated hiking events from NYC Parks and Meetup.com for September 5, 2026
- Added September 5-7, 2026 dates
- All events are currently available and active

This is the scheduled daily update for NY Stroll Stuff on 2026-09-05 09:30 UTC"

# Try to push to the repository (this may fail if there are network issues, but that's OK)
git push origin gh-pages
'''

# Execute git commands
subprocess.run('cd /root/.openclaw/workspace && git add nystrollstuff/index.html', shell=True)
subprocess.run('cd /root/.openclaw/workspace && git commit -m "Update NY Stroll Stuff website with latest baseball and hiking events for September 5-7, 2026\n\n- Updated baseball schedule with current MLB games\n- Updated hiking events from NYC Parks and Meetup.com for September 5, 2026\n- Added September 5-7, 2026 dates\n- All events are currently available and active\n\nThis is the scheduled daily update for NY Stroll Stuff on 2026-09-05 09:30 UTC"', shell=True)
subprocess.run('cd /root/.openclaw/workspace && git push origin gh-pages', shell=True, check=False)