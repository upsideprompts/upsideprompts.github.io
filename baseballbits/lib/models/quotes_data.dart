import 'package:flutter/material.dart';

class Quote {
  final String text;
  final String author;
  final Color backgroundColor;
  final Color textColor;
  final String category;
  final String quoteImage;

  Quote({
    required this.text,
    required this.author,
    required this.backgroundColor,
    required this.textColor,
    required this.category,
    required this.quoteImage,
  });
}

// Collection of 20 quotes with diverse backgrounds and themes
final List<Quote> quotesData = [
  Quote(
    text: "The only way to do great work is to love what you do.",
    author: "Steve Jobs",
    backgroundColor: Color(0xFF2C3E50),
    textColor: Color(0xFFFCFCFC),
    category: "Motivation",
    quoteImage: "https://picsum.photos/seed/quote1/800/600",
  ),
  Quote(
    text: "Life is what happens when you're busy making other plans.",
    author: "John Lennon",
    backgroundColor: Color(0xFF16A085),
    textColor: Color(0xFFF5F5F5),
    category: "Life",
    quoteImage: "https://picsum.photos/seed/quote2/800/600",
  ),
  Quote(
    text: "The future belongs to those who believe in the beauty of their dreams.",
    author: "Eleanor Roosevelt",
    backgroundColor: Color(0xFF8E44AD),
    textColor: Color(0xFFFFFFFF),
    category: "Dreams",
    quoteImage: "https://picsum.photos/seed/quote3/800/600",
  ),
  Quote(
    text: "Success is not final, failure is not fatal: It is the courage to continue that counts.",
    author: "Winston Churchill",
    backgroundColor: Color(0xFF2C3E50),
    textColor: Color(0xFFFCFCFC),
    category: "Success",
    quoteImage: "https://picsum.photos/seed/quote4/800/600",
  ),
  Quote(
    text: "In the middle of difficulty lies opportunity.",
    author: "Albert Einstein",
    backgroundColor: Color(0xFF16A085),
    textColor: Color(0xFFF5F5F5),
    category: "Opportunity",
    quoteImage: "https://picsum.photos/seed/quote5/800/600",
  ),
  Quote(
    text: "Don't count the days, make the days count.",
    author: "Muhammad Ali",
    backgroundColor: Color(0xFF8E44AD),
    textColor: Color(0xFFFFFFFF),
    category: "Motivation",
    quoteImage: "https://picsum.photos/seed/quote6/800/600",
  ),
  Quote(
    text: "The best time to plant a tree was 20 years ago. The second best time is now.",
    author: "Chinese Proverb",
    backgroundColor: Color(0xFF2C3E50),
    textColor: Color(0xFFFCFCFC),
    category: "Wisdom",
    quoteImage: "https://picsum.photos/seed/quote7/800/600",
  ),
  Quote(
    text: "Your time is limited, don't waste it living someone else's life.",
    author: "Steve Jobs",
    backgroundColor: Color(0xFF16A085),
    textColor: Color(0xFFF5F5F5),
    category: "Life",
    quoteImage: "https://picsum.photos/seed/quote8/800/600",
  ),
  Quote(
    text: "The purpose of our lives is to be happy.",
    author: "Dalai Lama",
    backgroundColor: Color(0xFF8E44AD),
    textColor: Color(0xFFFFFFFF),
    category: "Happiness",
    quoteImage: "https://picsum.photos/seed/quote9/800/600",
  ),
  Quote(
    text: "Do not wait to build your future, put your future in building.",
    author: "Muhammad Ali",
    backgroundColor: Color(0xFF2C3E50),
    textColor: Color(0xFFFCFCFC),
    category: "Motivation",
    quoteImage: "https://picsum.photos/seed/quote10/800/600",
  ),
  Quote(
    text: "You only live once, but if you do it right, once is enough.",
    author: "Mae West",
    backgroundColor: Color(0xFF16A085),
    textColor: Color(0xFFF5F5F5),
    category: "Life",
    quoteImage: "https://picsum.photos/seed/quote11/800/600",
  ),
  Quote(
    text: "Many of life's failures are people who did not realize how close they were to success when they gave up.",
    author: "Thomas Edison",
    backgroundColor: Color(0xFF8E44AD),
    textColor: Color(0xFFFFFFFF),
    category: "Success",
    quoteImage: "https://picsum.photos/seed/quote12/800/600",
  ),
  Quote(
    text: "You can't use up creativity. The more you use, the more you have.",
    author: "Maya Angelou",
    backgroundColor: Color(0xFF2C3E50),
    textColor: Color(0xFFFCFCFC),
    category: "Creativity",
    quoteImage: "https://picsum.photos/seed/quote13/800/600",
  ),
  Quote(
    text: "The two most important days in your life are the day you are born and the day you find out why.",
    author: "Mark Twain",
    backgroundColor: Color(0xFF16A085),
    textColor: Color(0xFFF5F5F5),
    category: "Life",
    quoteImage: "https://picsum.photos/seed/quote14/800/600",
  ),
  Quote(
    text: "Life is 10% what happens to us and 90% how we react to it.",
    author: "Charles Swindoll",
    backgroundColor: Color(0xFF8E44AD),
    textColor: Color(0xFFFFFFFF),
    category: "Life",
    quoteImage: "https://picsum.photos/seed/quote15/800/600",
  ),
  Quote(
    text: "The best revenge is massive success.",
    author: "Frank Sinatra",
    backgroundColor: Color(0xFF2C3E50),
    textColor: Color(0xFFFCFCFC),
    category: "Motivation",
    quoteImage: "https://picsum.photos/seed/quote16/800/600",
  ),
  Quote(
    text: "You can't use up creativity. The more you use, the more you have.",
    author: "Maya Angelou",
    backgroundColor: Color(0xFF2C3E50),
    textColor: Color(0xFFFCFCFC),
    category: "Creativity",
    quoteImage: "https://picsum.photos/seed/quote17/800/600",
  ),
  Quote(
    text: "The two most important days in your life are the day you are born and the day you find out why.",
    author: "Mark Twain",
    backgroundColor: Color(0xFF16A085),
    textColor: Color(0xFFF5F5F5),
    category: "Life",
    quoteImage: "https://picsum.photos/seed/quote18/800/600",
  ),
  Quote(
    text: "Whether you think you can or you think you can't, you're right.",
    author: "Henry Ford",
    backgroundColor: Color(0xFF2C3E50),
    textColor: Color(0xFFFCFCFC),
    category: "Motivation",
    quoteImage: "https://picsum.photos/seed/quote19/800/600",
  ),
  Quote(
    text: "The only limit to our realization of tomorrow is our doubts of today.",
    author: "Franklin D. Roosevelt",
    backgroundColor: Color(0xFF16A085),
    textColor: Color(0xFFF5F5F5),
    category: "Future",
    quoteImage: "https://picsum.photos/seed/quote20/800/600",
  ),
  Quote(
    text: "It always seems impossible until it's done.",
    author: "Nelson Mandela",
    backgroundColor: Color(0xFF2C3E50),
    textColor: Color(0xFFFCFCFC),
    category: "Determination",
    quoteImage: "https://picsum.photos/seed/quote21/800/600",
  ),
];