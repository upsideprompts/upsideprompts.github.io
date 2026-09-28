import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class Quote {
  final String firstname;
  final String lastname;
  final String category;
  final String quote;
  final Color backgroundColor;
  final Color textColor;

  Quote({
    required this.firstname,
    required this.lastname,
    required this.category,
    required this.quote,
    required this.backgroundColor,
    required this.textColor,
  });

  String get author => '$firstname $lastname'.trim();

  factory Quote.fromJson(Map<String, dynamic> json, int index) {
    const backgrounds = <Color>[
      Color(0xFF1E3C72),
      Color(0xFF2A5298),
      Color(0xFF0B3D1C),
      Color(0xFF1A5276),
      Color(0xFF154360),
      Color(0xFF1B4F72),
    ];
    return Quote(
      firstname: (json['firstname'] ?? '').toString(),
      lastname: (json['lastname'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      quote: (json['quote'] ?? '').toString(),
      backgroundColor: backgrounds[index % backgrounds.length],
      textColor: const Color(0xFFFCFCFC),
    );
  }
}

Future<List<Quote>> loadQuotesFromAsset({
  String path = 'quotes.json',
}) async {
  final raw = await rootBundle.loadString(path);
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const FormatException('quotes.json must be a JSON array');
  }
  return [
    for (var i = 0; i < decoded.length; i++)
      Quote.fromJson(Map<String, dynamic>.from(decoded[i] as Map), i),
  ];
}
