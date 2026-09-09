#!/usr/bin/env python3

import json
import re
import os

def extract_all_questions():
    # New Jersey Rappers + Python Trivia Questions
    ALL_QUESTIONS = [
        {
            "index": 0,
            "question": "NJ's own "Eminem" "the Slim Shady" from "The Slim Shady LP" freestyled over the beat "Guilty Conscience." Which Python data structure would you use to store a dictionary with the track name, lyrics snippet, and original rapper's debut year?",
            "correct": "A dictionary with string keys and mixed values.",
            "wrong": [
                "A list of separate strings.",
                "A single boolean value.",
                "A floating-point number for storage."
            ],
            "explanation": "Just like storing track metadata (name, lyrics, debut year), Python dictionaries with string keys and mixed values are perfect for organizing complex musical information."
        },
        {
            "index": 1,
            "question": """The Roots""""" from "Illadelph Halflife" debuted with "Do You Want More?" in 1993. In Python, write a function that takes a list of "The Roots" band members and returns only those who perform vocals, similar to how you're asked about NJ's finest.
            """,
            "correct": "def filter_vocalists(members):\n    return [member for member in members if member['vocals'] == True]",
            "wrong": [
                "def select_members(members):\n    return [m for m in members if m['vocals'] >= True]",
                "def get_vocalists(members):\n    return [member for member in members if member.get('vocals', False)]",
                "def vocal_members(members):\n    return [m for m in members if m['vocals'] == 'yes']"
            ],
            "explanation": "Just as you'd want to identify which members of 'The Roots' do vocals for interviews, list comprehensions in Python allow you to efficiently filter and select specific elements from a list based on conditions."
        },
        {
            "index": 2,
            "question": """_**Jay-Z**""""" from Brooklyn (but NJ-rooted) released 'Reasonable Doubt' in 1996, which had the hit 'Big Pimpin.' In Python, what keyword creates a dictionary literal to store the track's metadata (title, featured artist, production year)?",
            "correct": "The curly brace { }.",
            "wrong": [
                "The square bracket [ ].",
                "The parenthesis ( ).",
                "The angle bracket < >."
            ],
            "explanation": "Just as 'Reasonable Doubt' established Jay-Z's legacy, Python dictionaries with curly braces create the perfect structure for storing track metadata like title, featured artist, and production year in an organized way."
        },
        {
            "index": 3,
            "question": """_**Fabolous**""""" from Brooklyn but often associated with Jersey streets released 'The Fighter' featuring 'Jadakiss.' In Python, what do you call the process of giving a variable a more descriptive name, like changing 'song_title' to 'fabulous_track_name'?",
            "correct": "Variable naming and assignment.",
            "wrong": [
                "Function definition.",
                "Class inheritance.",
                "Method overriding."
            ],
            "explanation": "Just as Fabolous evolved from 'J' to 'Fabolous' for better brand recognition, Python programmers use descriptive variable naming to make their code more readable and maintainable."
        },
        {
            "index": 4,
            "question": """_**Bone Crusher**""""" from Baltimore but known in Jersey clubs released 'Never Scared' in 2003. Write code that imports both the 'datetime' module and a custom module called 'nj_hiphop' for your project.",
            "correct": "import datetime\nfrom nj_hiphop import tracks",
            "wrong": [
                "import datetime\nimport nj_hiphop",
                "from datetime import *\nfrom nj_hiphop import *",
                "import datetime\nnj_hiphop = __import__('nj_hiphop')"
            ],
            "explanation": "Just as Bone Crusher's 'Never Scared' needs the right tools to perform, proper Python imports are essential for building projects. Using 'from nj_hiphop import tracks' allows you to directly access your hip-hop tracks without the module prefix."
        },
        {
            "index": 5,
            "question": ""**_Jadakiss_**"" from Yonkers NY but known in NJ rap circles released 'Kiss of Death' in 2004. In Python, what type of loop would you use to simulate a 'NY drill' beat that repeats a pattern 8 times?
            """,
            "correct": "A for loop with range(8).",
            "wrong": [
                "A while loop with no condition.",
                "A do-while loop with true condition.",
                "A recursive function call."
            ],
            "explanation": "Just as NY drill beats have repetitive patterns, a for loop with range(8) in Python creates that looping beat pattern that repeats exactly 8 times, creating the intense, relentless rhythm that defines the genre."
        },
        {
            "index": 6,
            "question": ""**_Fat Joe_**"" from Bronx but known in Jersey rap released 'Jealous Ones Still Envy' in 2001. In Python, what data structure would you use to represent a 'Jersey Mafia' of rappers where each member has their own net worth and favorite hook?
            """,
            "correct": "A dictionary of dictionaries.",
            "wrong": [
                "A list of lists.",
                "A single string.",
                "A boolean value."
            ],
            "explanation": "Just as a 'Jersey Mafia' has different leaders with their own teams and specialties, a dictionary of dictionaries in Python perfectly represents nested relationships where each rapper has their own net worth and musical preferences."
        },
        {
            "index": 7,
            "question": ""**_Busta Rhymes_**""" from Brooklyn but known in Jersey clubs released 'Flip Flop Boom' in 1998. What data type would you use to store a list of Jersey club anthems (as strings) that are available for streaming?
            """,
            "correct": "A list of strings.",
            "wrong": [
                "A single string with commas.",
                "A boolean value.",
                "A floating-point number."
            ],
            "explanation": "Just as Jersey club anthems are individual tracks that can be played in any order, a list of strings in Python can store multiple anthems where each element is a specific song available for streaming."
        },
        {
            "index": 8,
            "question": ""**_Method Man_**""" from Staten Island released 'Treachous Three' in 1991 with 'Start It Up.' In Python, what would you use to store metadata for a 12-track album including track titles, features, and release year?
            """,
            "correct": "A dictionary with 'tracks' as a key containing a list of track dictionaries.",
            "wrong": [
                "A single string containing all track information.",
                "A boolean value indicating whether it's collaborative.",
                "A floating-point number representing the album's length."
            ],
            "explanation": "Just as Method Man's 'Treachous Three' contains 12 tracks with rich metadata, Python dictionaries with nested lists of dictionaries are perfect for storing complex album information including track titles, features, and release year in an organized way."
        },
        {
            "index": 9,
            "question": "**_Tracey 'Tract Money' Adams_**" from NJ released 'The Mix Tape' in 1996. Write a function that takes a list of 'Tract Money's' mixtape tracks and returns only those with explicit content flagged as 'explicit': true.
            """,
            "correct": "def filter_explicit_tracks(tracks):\n    return [track for track in tracks if track['explicit'] == True]",
            "wrong": [
                "def explicit_tracks(tracks):\n    return [track for track in tracks if track['explicit'] >= True]",
                "def select_tracks(tracks):\n    return [t for t in tracks if t.get('explicit', False)]",
                "def track_explicit(tracks):\n    return [track for track in tracks if track['explicit'] == 'yes']"
            ],
            "explanation": "Just as you'd want to filter explicit tracks for specific audiences, Python list comprehensions allow you to efficiently filter data based on boolean conditions. The correct solution uses '== True' to match the 'explicit': true condition."
        },
        {
            "index": 10,
            "question": "**_Joe Budden_**" from NJ released 'The Album' in 1997. In Python, what decorator would you use to create a reusable function that generates 'Joe Budden' interview quotes with different guest names?
            """,
            "correct": "A function with parameters and f-strings for dynamic content.",
            "wrong": [
                "A class inheritance decorator.",
                "A lambda function.",
                "A recursive decorator."
            ],
            "explanation": "Just as Joe Budden's interviews can be adapted for different topics, Python functions with parameters and f-strings allow you to create reusable code that generates dynamic content like interview quotes with different guest names."
        },
        {
            "index": 11,
            "question": "**_Cee Lo Green_**" from Atlanta but known in Jersey jazz rap released 'Stray Dog' in 1996. What programming concept creates a loop that processes each element in a list of 'Cee Lo's' soulful verses and applies a melodic pattern?
            """,
            "correct": "A for loop iterating over the list.",
            "wrong": [
                "A while loop with manual indexing.",
                "A recursive function call.",
                "A dictionary comprehension."
            ],
            "explanation": "Just as Cee Lo Green's soulful verses each follow a melodic pattern, a for loop in Python processes each element in a list of verses sequentially, creating the consistent rhythm and flow that makes his music distinctive."
        },
        {
            "index": 12,
            "question": "**_The Notorious B.I.G.**""" from Brooklyn but NJ-influenced released 'Ready to Die' in 1994. In Python, what mathematical operator would you use to triple a _**Diddy**"""'s impact, similar to how the Notorious B.I.G. magnified his influence?
            """,
            "correct": "The multiplication operator (*).",
            "wrong": [
                "The addition operator (+).",
                "The division operator (/).",
                "The exponent operator (**)."
            ],
            "explanation": "Just as the Notorious B.I.G. tripled hip-hop's cultural impact, the multiplication operator (*) in Python creates a much stronger result, making something three times more powerful than it would be otherwise."
        },
        {
            "index": 13,
            "question": "**_Kanye West**"" from Atlanta but NJ-raised released 'The College Dropout' in 2004. In Python, what data structure would you use to store information about a Grammy-winning feature track including artist, song, year, and category?
            """,
            "correct": "A dictionary with keys for artist, song, year, and category.",
            "wrong": [
                "A list of strings.",
                "A boolean value.",
                "A floating-point number."
            ],
            "explanation": "Just as Kanye West's Grammy-winning collaborations have specific details about the feature track, a Python dictionary with keys for artist, song, year, and category perfectly stores all the important information about Grammy-winning partnerships in an organized way."
        },
        {
            "index": 14,
            "question": "**_Cam'ron_**" from NY but NJ-culturally released 'Razor Mountain' in 2003. Write a function that takes a list of 'Cam'ron's' jersey connections and returns only those with jersey cities listed as 'Jersey City' or 'Newark'.
            """,
            "correct": "def filter_jersey_cities(connections):\n    return [conn for conn in connections if conn['city'] in ['Jersey City', 'Newark']]",
            "wrong": [
                "def jersey_connections(connections):\n    return [c for c in connections if c['city'] == 'Jersey City']",
                "def select_connections(connections):\n    return [c for c in connections if c.get('city') == 'Newark']",
                "def city_filter(connections):\n    return [conn for conn in connections if conn['city'] == 'Jersey City' or conn['city'] == 'Newark']"
            ],
            "explanation": "Just as Cam'ron's music connects different Jersey cities, Python list comprehensions with conditional logic allow you to filter data based on specific criteria. The correct solution uses 'in ['Jersey City', 'Newark']' to match multiple valid Jersey cities."
        },
        {
            "index": 15,
            "question": "**_Spider Loc_**" from NJ released 'Trap Door' in 2003. In Python, what programming concept creates a reusable function that generates 'Spider Loc' verse patterns with different flow rhymes?
            """,
            "correct": "A function with parameters and docstrings for documentation.",
            "wrong": [
                "A class inheritance.",
                "A lambda function.",
                "A recursive generator."
            ],
            "explanation": "Just as Spider Loc's verse patterns can be adapted for different scenarios, Python functions with parameters and docstrings create reusable, well-documented code that generates rap verse patterns. The docstring helps other developers understand how to use the function."
        },
        {
            "index": 16,
            "question": "**_Ja Rule_**" from NY but NJ-based released 'Pain Is Love' in 2001. Write a function that takes a list of 'Ja Rule's' jersey collaborations and returns only those with jersey artists listed as 'Method Man' or 'Capone'.
            """,
            "correct": "def filter_jersey_collabs(collabs):\n    return [collab for collab in collabs if collab['artist'] in ['Method Man', 'Capone']]",
            "wrong": [
                "def jersey_collabs(collabs):\n    return [collab for collab in collabs if collab['artist'] == 'Method Man']",
                "def select_collabs(collabs):\n    return [collab for collab in collabs if collab.get('artist') == 'Capone']",
                "def artist_filter(collabs):\n    return [collab for collab in collabs if collab['artist'] == 'Method Man' or collab['artist'] == 'Capone']"
            ],
            "explanation": "Just as Ja Rule collaborated with Jersey legends like Method Man and Capone, Python list comprehensions with conditional logic allow you to filter data based on specific artist criteria. The correct solution uses 'in ['Method Man', 'Capone']' to match multiple valid Jersey artists."
        },
        {
            "index": 17,
            "question": "**_Diddy_**" (formerly Puff Daddy) from NY but NJ-influenced released 'No Way Out' in 1997. What data type would you use to store information about viral TikTok videos including views, likes, and the challenge name?
            """,
            "correct": "A dictionary with 'views', 'likes', and 'challenge' as keys.",
            "wrong": [
                "A single string containing all video data.",
                "A boolean value indicating if it's viral.",
                "A floating-point number representing engagement rate."
            ],
            "explanation": "Just as Diddy's TikTok challenges became cultural phenomena with measurable impact, a Python dictionary with keys for 'views', 'likes', and 'challenge' perfectly captures the metadata of viral TikTok videos, organizing all the important statistics in one place."
        },
        {
            "index": 18,
            "question": "**_Rapper Dorrough_**" from NJ released 'Ice Cream Pyrex' in 2010. In Python, what programming concept creates a reusable function that generates 'Dorrough' dance move descriptions with different outfit colors?
            """,
            "correct": "A function with parameters and docstrings for documentation.",
            "wrong": [
                "A class inheritance.",
                "A lambda function.",
                "A recursive generator."
            ],
            "explanation": "Just as Dorrough's dance moves can be described with different outfit colors, Python functions with parameters and docstrings create reusable, well-documented code that generates descriptive dance move patterns. The docstring helps other developers understand how to use the function."
        },
        {
            "index": 19,
            "question": "**_Pusha T_**" from NY but NJ-culturally significant released 'My Name Is My Name' in 2013. Which pioneering 1990s Atlanta bass and hip-hop artist scored major regional hits with club anthems like 'Baby Baby' and 'Love in Miami'?",
            "correct": "Kilo Ali.",
            "wrong": [
                "Outkast.",
                "Goodie Mob.",
                "Jeezy."
            ],
            "explanation": "Kilo Ali was a pioneering Atlanta hip-hop artist in the 1990s known for regional club hits like 'Baby Baby' and 'Love in Miami,' helping establish Atlanta's reputation in the Southern rap scene."
        }
    ]

if __name__ == "__main__":
    questions = extract_all_questions()
    output_file = Path(__file__).resolve().parent / "questions.json"
    
    with output_file.open("w", encoding="utf-8") as f:
        json.dump({"ALL_QUESTIONS": questions}, f, indent=2)
    
    print(f"Generated {len(questions)} questions in {output_file}")