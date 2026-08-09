#!/usr/bin/env python3

import json
import re
import os

# Extract ALL_QUESTIONS from the HTML file
def extract_all_questions():
    # Read the HTML file
    script_content = """
        const ALL_QUESTIONS = [
            // Question 1
            {
                question: "In Outkast's album 'Speakerboxxx/The LoveBelow,' which song contains the line 'I don't know much about history, but I do know about rap battles'? This illustrates which programming concept where variables hold different data types?",
                correct: "Lists and dictionaries for storing musical data.",
                wrong: [
                    "Only string variables for lyrics.",
                    "Float variables for tempo measurements.",
                    "Boolean variables for yes/no decisions."
                ],
                explanation: "This lyric about history and rap battles demonstrates how programming concepts can be applied to understand music and culture. Lists and dictionaries are perfect for storing different types of musical information."
            },
            // Question 2
            {
                question: "Similar to how Ludacris was an intern at Hot 107.5 before going pro, in Python you can write functions and call them. Write a function that takes a list of radio stations and returns only the ones with 100 or more listeners.",
                correct: "def filter_big_stations(stations):\n    return [station for station in stations if station['listeners'] >= 100]",
                wrong: [
                    "def big_stations(stations):\n    return [station for station in stations if station['listeners'] >= 50]",
                    "def radio_stations(stations):\n    return stations.filter(lambda x: x['listeners'] > 100)",
                    "def select_stations(stations):\n    return [s for s in stations if s['listeners'] > 100]"
                ],
                explanation: "Just like Ludacris interned at Hot 107.5 to gain experience in radio, list comprehensions in Python give you the skills to filter and work with data efficiently. The correct solution includes >= 100 to match the '100 or more' condition."
            },
            // Question 3
            {
                question: "T.I.'s 'Trap Muzik' established the 'trap' subgenre. In Python, what keyword do you use to create a dictionary that can hold the metadata for a trap song like title, artist, tempo, and key?",
                correct: "The dictionary literal with {} brackets.",
                wrong: [
                    "The list comprehension with [].",
                    "The tuple declaration with ().",
                    "The set creation with set()."
                ],
                explanation: "Trap music has its own culture and syntax, just like Python dictionaries. Using {} brackets creates a dictionary perfect for storing song metadata like title, artist, tempo, and key."
            },
            // Question 4
            {
                question: "Jeezy was originally 'Lil J' before becoming 'Jeezy.' In Python, what do you call the process of giving a variable a new, more meaningful name, which is like Jeezy evolving his stage name?",
                correct: "Variable assignment and naming.",
                wrong: [
                    "Function definition.",
                    "Class inheritance.",
                    "Method overloading."
                ],
                explanation: "Just as Jeezy changed from 'Lil J' to 'Jeezy' for better branding, Python programmers use variable assignment and meaningful naming to make their code more readable and professional."
            },
            // Question 5
            {
                question: "Gucci Mane founded 1017 Records, similar to how you import modules in Python. Write code that imports both the 'os' module and a custom module named 'trap_music' for your project.",
                correct: "import os\nfrom trap_music import trap_songs",
                wrong: [
                    "import os\nimport trap_music",
                    "from os import *\nfrom trap_music import *",
                    "import os\ntrap_music = __import__('trap_music')"
                ],
                explanation: "Just as Gucci Mane's 1017 Records helped launch careers, proper Python imports are essential for building your projects. Using 'from trap_music import trap_songs' allows you to directly access trap_songs without the module prefix."
            },
            // Question 6
            {
                question: "Lil Jon's crunk music was known for its fast tempo. In Python, what type of loop would you use to simulate a 'crunk beat' that repeats a sequence of beats 4 times?",
                correct: "A for loop with range(4).",
                wrong: [
                    "A while loop with no condition.",
                    "A do-while loop with true condition.",
                    "A recursive function call."
                ],
                explanation: "Crunk music's fast, repetitive nature is perfectly captured in programming with a for loop using range(4). This loop repeats the sequence exactly 4 times, creating that looping beat pattern that makes crunk music so energetic."
            },
            // Question 7
            {
                question: "Future was part of The Dungeon Family before going solo. In Python, what data structure would you use to represent The Dungeon Family where each member can have their own group of affiliated artists?",
                correct: "A dictionary of dictionaries.",
                wrong: [
                    "A list of lists.",
                    "A single string.",
                    "A boolean value."
                ],
                explanation: "Just like The Dungeon Family where each main member has their own collective of affiliated artists, a dictionary of dictionaries in Python perfectly represents nested relationships and organizational structures in your data."
            },
            // Question 8
            {
                question: "Young Thug founded YSL Records, which stands for 'Young Stoner Life.' In Python, what data type would you use to store a list of drugs (as strings) that are available at a 'Young Stoner Life' party?",
                correct: "A list of strings.",
                wrong: [
                    "A single string with commas.",
                    "A boolean value.",
                    "A floating-point number."
                ],
                explanation: "YSL Records represents 'Young Stoner Life,' just as a list of strings in Python can store the variety of drugs available at a party. Each item in the list can be a specific substance, making lists perfect for this kind of inventory management."
            },
            // Question 9
            {
                question: "21 Savage collaborated with Drake on 'Her Loss.' In Python, what would you use to store the metadata for a 16-track collaborative album, including track titles, features, and release year?",
                correct: "A dictionary with 'tracks' as a key containing a list of track dictionaries.",
                wrong: [
                    "A single string containing all track information.",
                    "A boolean value indicating whether it's collaborative.",
                    "A floating-point number representing the album's length."
                ],
                explanation: "Just as 'Her Loss' contains 16 tracks with rich metadata, Python dictionaries with nested lists of dictionaries are perfect for storing complex album information including track titles, features, and release year in an organized way."
            },
            // Question 10
            {
                question: "Lil Baby was an athlete before music. In Python, write a function that takes a list of athlete stats and returns only those with a 40-yard dash time under 4.5 seconds, similar to how scouts filter for speed.",
                correct: "def filter_fast_players(stats):\n    return [stat for stat in stats if stat['40yd_time'] < 4.5]",
                wrong: [
                    "def track_players(stats):\n    return [stat for stat in stats if stat['40yd_time'] < 5.0]",
                    "def select_players(stats):\n    return list(stats.filter(lambda x: x['40yd_time'] < 4.5))",
                    "def speed_stats(stats):\n    return [s for s in stats if s['40yd_time'] < 4.0]"
                ],
                explanation: "Just as NFL scouts filter for 40-yard dash times under 4.5 seconds to identify fast athletes, Python list comprehensions allow you to efficiently filter athletic performance data. The correct solution uses < 4.5 to match the speed threshold."
            },
            // Question 11
            {
                question: "Goodie Mob's 'Soul Food' featured 'Cell Therapy.' In Python, what decorator would you use to create a reusable function that generates cell therapy lyrics with different drug names?",
                correct: "A function with parameters and f-strings for dynamic content.",
                wrong: [
                    "A class inheritance decorator.",
                    "A lambda function.",
                    "A recursive decorator."
                ],
                explanation: "Just as Goodie Mob's 'Cell Therapy' lyrics can be adapted for different scenarios, Python functions with parameters and f-strings allow you to create reusable code that generates dynamic content like lyrics with different drug names."
            },
            // Question 12
            {
                question: "Migos' 'Versace' popularized the triplet flow. In Python, what programming concept creates a loop that processes each element in a list of rap verses and applies a flow pattern?",
                correct: "A for loop iterating over the list.",
                wrong: [
                    "A while loop with manual indexing.",
                    "A recursive function call.",
                    "A dictionary comprehension."
                ],
                explanation: "The Migos triplet flow's repetitive nature is perfectly captured with a for loop in Python. Just as each verse follows the same triplet rhythm pattern, a for loop processes each element in a list of rap verses sequentially, creating the consistent flow that makes their music distinctive."
            },
            // Question 13
            {
                question: "2 Chainz was originally 'Tity Boi' in Playaz Circle. In Python, what mathematical operator would you use to double a DMX quote's impact, similar to how Tity Boi added his distinct style?",
                correct: "The multiplication operator (*).",
                wrong: [
                    "The addition operator (+).",
                    "The division operator (/).",
                    "The exponent operator (**)."
                ],
                explanation: "Just as 2 Chainz (formerly Tity Boi) added his unique style to Playaz Circle, doubling something in Python with the multiplication operator (*) creates a much stronger impact, making the result twice as powerful."
            },
            // Question 14
            {
                question: "Killer Mike won a Grammy for Outkast's 'The Whole World.' In Python, what data structure would you use to store information about a Grammy-winning feature track including artist, song, year, and category?",
                correct: "A dictionary with keys for artist, song, year, and category.",
                wrong: [
                    "A list of strings.",
                    "A boolean value.",
                    "A floating-point number."
                ],
                explanation: "Just as Killer Mike's Grammy for 'The Whole World' has specific details about the feature track, a Python dictionary with keys for artist, song, year, and category perfectly stores all the important information about Grammy-winning collaborations in an organized way."
            },
            // Question 15
            {
                question: "Childish Gambino's 'This Is America' went viral. In Python, what data structure would you use to store information about viral TikTok videos including views, likes, and the challenge name?",
                correct: "A dictionary with 'views', 'likes', and 'challenge' as keys.",
                wrong: [
                    "A single string containing all video data.",
                    "A boolean value indicating if it's viral.",
                    "A floating-point number representing engagement rate."
                ],
                explanation: "Just as 'This Is America' became a cultural phenomenon with measurable impact, a Python dictionary with keys for 'views', 'likes', and 'challenge' perfectly captures the metadata of viral TikTok videos, organizing all the important statistics in one place."
            },
            // Question 16
            {
                question: "Dreamville Records signed Earthgang. In Python, what programming concept creates a reusable function that generates dreamville signed artist profiles with artist names and their joining years?",
                correct: "A function with parameters and docstrings for documentation.",
                wrong: [
                    "A class inheritance.",
                    "A lambda function.",
                    "A recursive generator."
                ],
                explanation: "Just as Dreamville Records builds relationships with signed artists, Python functions with parameters and docstrings create reusable, well-documented code that generates artist profiles. The docstring helps other developers understand how to use the function, just like how Dreamville's brand represents their artistic vision."
            },
            // Question 17
            {
                question: "JID played college football before music. Write a function that takes a list of NFL player stats and returns only those with a 40-yard dash time under 4.5 seconds and a bench press over 225 pounds.",
                correct: "def filter_pro_combinators(stats):\n    return [stat for stat in stats if stat['40yd'] < 4.5 and stat['bench'] > 225]",
                wrong: [
                    "def select_players(stats):\n    return [s for s in stats if s['40yd'] < 4.5 or s['bench'] > 225]",
                    "def combine_stats(stats):\n    return list(filter(lambda x: x['40yd'] < 4.5 and x['bench'] > 225, stats))",
                    "def athletic_players(stats):\n    return [stat for stat in stats if stat['40yd'] < 4.0 or stat['bench'] > 200]"
                ],
                explanation: "Just as scouts look for players with exceptional speed and strength, Python list comprehensions allow you to filter athletic performance data. The correct solution uses 'and' to require both conditions - speed under 4.5 seconds AND bench press over 225 pounds for true NFL prospects."
            },
            // Question 18
            {
                question: "Which pioneering 1990s Atlanta bass and hip-hop artist scored major regional hits with club anthems like 'Baby Baby' and 'Love in Miami'?",
                correct: "Kilo Ali.",
                wrong: [
                    "Outkast.",
                    "Goodie Mob.",
                    "Jeezy."
                ],
                explanation: "Kilo Ali was a pioneering Atlanta hip-hop artist in the 1990s known for regional club hits like 'Baby Baby' and 'Love in Miami,' helping establish Atlanta's reputation in the Southern rap scene."
            },
            // Question 19
            {
                question: "What was the signature prop that Bone Crusher famously wore and swung around while performing his massive 2003 crunk hit 'Never Scared'?",
                correct: "Heavy gold chains featuring a large medallion.",
                wrong: [
                    "A wooden clarinet.",
                    "A bullhorn.",
                    "A football helmet."
                ],
                explanation: "Bone Crusher was known for wearing heavy gold chains featuring large medallions, which he would often swing around while performing his 2003 crunk hit 'Never Scared.'"
            },
            // Question 20 (Additional question to reach 20 total)
            {
                question: "Which Atlanta-born artist formed the duo Outkast with André 3000 in 1991, later becoming one of hip-hop's most successful and critically acclaimed acts?",
                correct: "Big Boi.",
                wrong: [
                    "Future.",
                    "Killer Mike.",
                    "J. Cole."
                ],
                explanation: "Outkast was formed in Atlanta in 1991 by Big Boi (Antwan Patton) and André 3000 (André Benjamin), becoming one of hip-hop's most successful duos with multiple Grammy wins and widespread critical acclaim."
            }
        ];