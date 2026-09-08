#!/usr/bin/env python3

import json

ALL_QUESTIONS = [
    {
        "index": 0,
        "question": "Schoolly D's 'P.S.K. What Does It Mean?' helped pioneer gangsta rap from Philly. In Python, which function definition correctly takes a song title and a year as parameters?",
        "correct": "def release(title, year):",
        "wrong": [
            "def release(title year):",
            "function release(title, year):",
            "def release = (title, year):"
        ],
        "explanation": "Like naming a track and its year on a Schoolly D release, Python function parameters are listed in parentheses and separated by commas: def release(title, year):"
    },
    {
        "index": 1,
        "question": "DJ Jazzy Jeff & The Fresh Prince won a Grammy for 'Parents Just Don't Understand.' In Python, which call uses a default parameter so the city is Philly unless you override it?",
        "correct": "def tour(city='Philly'):",
        "wrong": [
            "def tour(city=='Philly'):",
            "def tour(default city 'Philly'):",
            "def tour[city='Philly']:"
        ],
        "explanation": "Default parameters work like a hometown show on the calendar—Philly is assumed unless you pass another city. Syntax is name='value' in the def line."
    },
    {
        "index": 2,
        "question": "The Roots' album 'Things Fall Apart' is a Philly classic. In Python, which structure best stores album metadata like title, year, and lead MC as named fields?",
        "correct": "album = {'title': 'Things Fall Apart', 'year': 1999, 'mc': 'Black Thought'}",
        "wrong": [
            "album = ['Things Fall Apart', 1999, 'Black Thought']",
            "album = ('Things Fall Apart'; 1999; 'Black Thought')",
            "album = 'Things Fall Apart' + 1999"
        ],
        "explanation": "A dictionary maps keys to values—perfect for labeled album facts. A plain list loses the field names that make the data self-describing."
    },
    {
        "index": 3,
        "question": "Questlove can hold down drums while also producing and bandleading. In Python, which signature accepts any number of extra positional guest features?",
        "correct": "def setlist(headliner, *guests):",
        "wrong": [
            "def setlist(headliner, guests*):",
            "def setlist(headliner, **guests):",
            "def setlist(headliner, &guests):"
        ],
        "explanation": "*guests gathers extra positional arguments into a tuple—like an open mic for as many features as show up after the headliner."
    },
    {
        "index": 4,
        "question": "Beanie Sigel's 'The Truth' put State Property on the map. Which call correctly uses keyword arguments so order does not matter?",
        "correct": "drop(title='The Truth', year=2000)",
        "wrong": [
            "drop(title='The Truth'; year=2000)",
            "drop[title='The Truth', year=2000]",
            "drop(title: 'The Truth', year: 2000)"
        ],
        "explanation": "Keyword arguments name each parameter at the call site: title='The Truth', year=2000. That mirrors labeling tracks clearly instead of relying on position alone."
    },
    {
        "index": 5,
        "question": "Freeway rode with Roc-A-Fella and State Property. Write a function that takes a list of Philly crew members and returns only names longer than 4 letters.",
        "correct": "def filter_names(members):\\n    return [m for m in members if len(m) > 4]",
        "wrong": [
            "def filter_names(members):\\n    return [m for m in members if len(m) < 4]",
            "def filter_names(members):\\n    return members.filter(lambda m: len(m) > 4)",
            "def filter_names(members):\\n    return (m for m if len(m) > 4)"
        ],
        "explanation": "A list comprehension filters a roster the way A&R filters a crew tape. The correct cut keeps names where len(m) > 4."
    },
    {
        "index": 6,
        "question": "Eve broke through with Ruff Ryders and hits like 'Let Me Blow Ya Mind.' In Python, what does a function send back to the caller after it finishes?",
        "correct": "Its return value.",
        "wrong": [
            "Only printed text.",
            "The function name as a string.",
            "Nothing unless you use global."
        ],
        "explanation": "return hands a result back to the caller—like Eve delivering a finished verse to the track. print shows output; it is not the same as returning data."
    },
    {
        "index": 7,
        "question": "Meek Mill's 'Dreams and Nightmares' intro is legendary in Philly sports arenas. Which line builds that title with an f-string from variables dreams and nightmares?",
        "correct": "title = f'{dreams} and {nightmares}'",
        "wrong": [
            "title = f(dreams + ' and ' + nightmares)",
            "title = '{dreams} and {nightmares}'.format",
            "title = f[dreams] and f[nightmares]"
        ],
        "explanation": "f-strings embed expressions in braces inside a quoted string: f'{dreams} and {nightmares}'. That is clean string formatting syntax in modern Python."
    },
    {
        "index": 8,
        "question": "Lil Uzi Vert came up out of Philly with projects like 'Luv Is Rage.' Which statement correctly appends a new track name to a mutable playlist list?",
        "correct": "playlist.append('XO Tour Llif3')",
        "wrong": [
            "playlist.add('XO Tour Llif3')",
            "playlist.push('XO Tour Llif3')",
            "append(playlist, 'XO Tour Llif3')"
        ],
        "explanation": "Lists are mutable; append() adds an item in place. add() is for sets, and push() is not Python list syntax."
    },
    {
        "index": 9,
        "question": "Cassidy made his name in battle rap, where punchlines land or they do not. Which expression correctly checks whether score is at least 10 using a comparison?",
        "correct": "if score >= 10:",
        "wrong": [
            "if score => 10:",
            "if score >= 10 then:",
            "if (score >= 10)"
        ],
        "explanation": "Python comparison syntax uses >= and ends the if header with a colon. => is invalid, and Python does not use then."
    },
    {
        "index": 10,
        "question": "Bahamadia's 'Kollage' is a key Philly underground album. Which import correctly brings in only the path helper from pathlib?",
        "correct": "from pathlib import Path",
        "wrong": [
            "import Path from pathlib",
            "include pathlib.Path",
            "using pathlib import Path"
        ],
        "explanation": "from module import name is the standard way to pull a specific symbol—like sampling one instrument from a larger crate."
    },
    {
        "index": 11,
        "question": "Steady B was part of Philly's early hip-hop wave. Which loop correctly visits each bar in a list of lyrics named bars?",
        "correct": "for bar in bars:",
        "wrong": [
            "foreach bar in bars:",
            "for bar in bars",
            "loop bar over bars:"
        ],
        "explanation": "for item in sequence: is Python's basic iteration syntax. The colon is required; foreach is not Python."
    },
    {
        "index": 12,
        "question": "Kurupt was born in Philadelphia before making waves on the West Coast. Which line reassigns a variable to a new stage name the way artists rebrand?",
        "correct": "artist = 'Kurupt'",
        "wrong": [
            "artist := 'Kurupt'",
            "let artist = 'Kurupt'",
            "artist -> 'Kurupt'"
        ],
        "explanation": "Plain assignment with = updates a name binding in Python. := is the walrus operator for assignment expressions, and let is not Python syntax."
    },
    {
        "index": 13,
        "question": "Tierra Whack's 'Whack World' has 15 one-minute songs. Which slice gets the first 15 tracks from a list called tracks?",
        "correct": "tracks[:15]",
        "wrong": [
            "tracks[15:]",
            "tracks(15)",
            "tracks[1:15]"
        ],
        "explanation": "tracks[:15] is slice syntax for the first 15 items (indexes 0 through 14). tracks[15:] is everything after index 15."
    },
    {
        "index": 14,
        "question": "PnB Rock's 'Selfish' was a Philly-bred hit. Which condition requires BOTH radio=True and streams over 1_000_000?",
        "correct": "if radio and streams > 1_000_000:",
        "wrong": [
            "if radio or streams > 1_000_000:",
            "if radio && streams > 1_000_000:",
            "if radio and then streams > 1_000_000:"
        ],
        "explanation": "and combines boolean conditions in Python. or would pass if either were true; && is not Python syntax."
    },
    {
        "index": 15,
        "question": "Lisa 'Left Eye' Lopes was born in Philadelphia. In Python, which definition correctly creates a method that takes self plus a guest parameter?",
        "correct": "def feature(self, guest):",
        "wrong": [
            "def feature(guest, self):",
            "def feature(this, guest):",
            "method feature(self, guest):"
        ],
        "explanation": "Instance methods take self as the first parameter, then any extra parameters like guest. Putting self second breaks normal method binding."
    },
    {
        "index": 16,
        "question": "State Property's roster (Beanie, Freeway, Peedi, and more) worked as a crew. Which structure best stores an ordered, changeable list of member names?",
        "correct": "crew = ['Beanie Sigel', 'Freeway', 'Peedi Crakk']",
        "wrong": [
            "crew = ('Beanie Sigel', 'Freeway', 'Peedi Crakk')",
            "crew = {'Beanie Sigel', 'Freeway', 'Peedi Crakk'}",
            "crew = 'Beanie Sigel', 'Freeway', 'Peedi Crakk'"
        ],
        "explanation": "A list keeps order and can grow or shrink as the roster changes. Tuples are fixed; sets are unordered."
    },
    {
        "index": 17,
        "question": "Black Thought is known for dense bars. Which loop gives both the bar number and the lyric text while iterating verses?",
        "correct": "for i, line in enumerate(verses):",
        "wrong": [
            "for i, line in verses.enumerate():",
            "for enumerate(i, line) in verses:",
            "for i and line in verses:"
        ],
        "explanation": "enumerate(verses) yields (index, item) pairs—like numbering bars while you spit each line."
    },
    {
        "index": 18,
        "question": "Meek Mill's Dreamchasers mixtape series kept dropping volumes. Which signature accepts arbitrary named options like volume=2 and host='Meek'?",
        "correct": "def mixtape(title, **options):",
        "wrong": [
            "def mixtape(title, *options):",
            "def mixtape(title, options**):",
            "def mixtape(title, &options):"
        ],
        "explanation": "**options collects keyword arguments into a dictionary—ideal for optional mixtape settings passed by name."
    },
    {
        "index": 19,
        "question": "The Roots became the house band for The Tonight Show, locking live beats to late-night cues. Which call pairs each beat with a cue using zip?",
        "correct": "for beat, cue in zip(beats, cues):",
        "wrong": [
            "for beat, cue in beats.zip(cues):",
            "for beat + cue in zip(beats, cues):",
            "for (beat, cue) zip beats, cues:"
        ],
        "explanation": "zip(beats, cues) walks two sequences together—like locking drums to show cues bar by bar."
    },
]


if __name__ == "__main__":
    with open("questions.json", "w", encoding="utf-8") as f:
        json.dump({"ALL_QUESTIONS": ALL_QUESTIONS}, f, indent=2)
        f.write("\n")
    print(f"Saved {len(ALL_QUESTIONS)} questions to questions.json")
