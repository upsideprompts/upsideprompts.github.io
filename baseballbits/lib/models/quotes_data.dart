import 'dart:convert';
import 'dart:math' show Random, max;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Free scenic baseball-field backgrounds bundled as assets (Unsplash License).
const List<String> baseballFieldBackgrounds = [
  'assets/backgrounds/field1.jpg',
  'assets/backgrounds/field2.jpg',
  'assets/backgrounds/field3.jpg',
  'assets/backgrounds/field4.jpg',
  'assets/backgrounds/field5.jpg',
  'assets/backgrounds/field6.jpg',
  'assets/backgrounds/field7.jpg',
];

class Quote {
  final String firstname;
  final String lastname;
  final String category;
  final String quote;
  final Color backgroundColor;
  final Color textColor;
  final String backgroundImage;

  Quote({
    required this.firstname,
    required this.lastname,
    required this.category,
    required this.quote,
    required this.backgroundColor,
    required this.textColor,
    required this.backgroundImage,
  });

  String get author => '$firstname $lastname'.trim();

  factory Quote.fromJson(Map<String, dynamic> json, int index) {
    const overlays = <Color>[
      Color(0xCC1E3C72),
      Color(0xCC0B3D1C),
      Color(0xCC1A5276),
      Color(0xCC154360),
      Color(0xCC2A5298),
      Color(0xCC1B4F72),
    ];
    return Quote(
      firstname: (json['firstname'] ?? '').toString(),
      lastname: (json['lastname'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      quote: (json['quote'] ?? '').toString(),
      backgroundColor: overlays[index % overlays.length],
      textColor: const Color(0xFFFCFCFC),
      backgroundImage:
          baseballFieldBackgrounds[index % baseballFieldBackgrounds.length],
    );
  }

  Quote withBackground(String imagePath, Color overlay) {
    return Quote(
      firstname: firstname,
      lastname: lastname,
      category: category,
      quote: quote,
      backgroundColor: overlay,
      textColor: textColor,
      backgroundImage: imagePath,
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

/// Random order where no two neighbors (including wrap-around) share an author.
///
/// If one person has more than half the quotes, extras are held out of this
/// round so the constraint can always be satisfied; refresh reshuffles again.
List<Quote> shuffleQuotesAlternatingPeople(
  List<Quote> source, {
  Random? random,
}) {
  final rng = random ?? Random();
  if (source.isEmpty) return [];
  if (source.length == 1) return List<Quote>.from(source);

  final byPerson = <String, List<Quote>>{};
  for (final q in source) {
    byPerson.putIfAbsent(q.author, () => []).add(q);
  }
  for (final list in byPerson.values) {
    list.shuffle(rng);
  }

  // Circular constraint: largest group cannot exceed the rest.
  var total = source.length;
  var maxCount = byPerson.values.map((e) => e.length).reduce(max);
  while (maxCount > total - maxCount && total > 1) {
    // Drop one quote from the largest pile until circular-feasible.
    String? largest;
    var largestLen = -1;
    for (final e in byPerson.entries) {
      if (e.value.length > largestLen) {
        largestLen = e.value.length;
        largest = e.key;
      }
    }
    if (largest == null || byPerson[largest]!.isEmpty) break;
    byPerson[largest]!.removeLast();
    total -= 1;
    maxCount = byPerson.values.map((e) => e.length).fold(0, max);
  }

  final pools = <String, List<Quote>>{
    for (final e in byPerson.entries)
      if (e.value.isNotEmpty) e.key: List<Quote>.from(e.value),
  };
  if (pools.isEmpty) return [];

  final result = <Quote>[];
  String? lastAuthor;

  while (pools.values.any((p) => p.isNotEmpty)) {
    final candidates = pools.entries
        .where((e) => e.value.isNotEmpty && e.key != lastAuthor)
        .toList();
    if (candidates.isEmpty) {
      // Should not happen when max <= others; stop rather than violate rule.
      break;
    }
    candidates.shuffle(rng);
    candidates.sort((a, b) => b.value.length.compareTo(a.value.length));
    final pick = candidates.first;
    result.add(pick.value.removeLast());
    lastAuthor = pick.key;
  }

  if (result.length >= 2 && result.first.author == result.last.author) {
    // Rotate to break wrap-around collision if possible.
    for (var i = 1; i < result.length; i++) {
      final rotated = [...result.skip(i), ...result.take(i)];
      if (rotated.first.author != rotated.last.author &&
          _neighborsAllDifferent(rotated)) {
        return _assignScenicBackgrounds(rotated, rng);
      }
    }
    // Last resort: drop the final quote to keep wrap-around clean.
    result.removeLast();
  }

  return _assignScenicBackgrounds(result, rng);
}

bool _neighborsAllDifferent(List<Quote> quotes) {
  if (quotes.length < 2) return true;
  for (var i = 0; i < quotes.length; i++) {
    final next = quotes[(i + 1) % quotes.length];
    if (quotes[i].author == next.author) return false;
  }
  return true;
}

List<Quote> _assignScenicBackgrounds(List<Quote> quotes, Random rng) {
  final images = List<String>.from(baseballFieldBackgrounds)..shuffle(rng);
  const overlays = <Color>[
    Color(0xB31E3C72),
    Color(0xB30B3D1C),
    Color(0xB3154360),
    Color(0xB31A5276),
    Color(0xB32A5298),
  ];
  return [
    for (var i = 0; i < quotes.length; i++)
      quotes[i].withBackground(
        images[i % images.length],
        overlays[i % overlays.length],
      ),
  ];
}
