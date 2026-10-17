import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quotes_data.dart';

class QuotesProvider with ChangeNotifier {
  static const _favoritesKey = 'baseballbits_favorites';
  static const _feedbackKey = 'baseballbits_feedback';

  List<Quote> _quotes = [];
  List<Quote> get quotes => List.unmodifiable(_quotes);

  List<Quote> _source = [];
  List<Quote> get allQuotes => List.unmodifiable(_source);

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  int _deckGeneration = 0;
  int get deckGeneration => _deckGeneration;

  String? _deckMessage;
  String? get deckMessage => _deckMessage;

  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final Set<String> _favoriteIds = {};
  final List<Quote> _favorites = [];
  List<Quote> get favorites => List.unmodifiable(_favorites);

  final List<Map<String, String>> _feedbackEntries = [];
  List<Map<String, String>> get feedbackEntries =>
      List.unmodifiable(_feedbackEntries);

  QuotesProvider() {
    _load();
  }

  Quote? get currentQuote =>
      _quotes.isEmpty ? null : _quotes[_currentIndex];

  bool isFavorite(Quote quote) => _favoriteIds.contains(quote.id);

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _loadPersisted();
      _source = await loadQuotesFromAsset();
      _quotes = shuffleQuotesAlternatingPeople(_source);
      _currentIndex = 0;
      _deckMessage = null;
      _deckGeneration++;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load quotes.json';
      notifyListeners();
    }
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final favRaw = prefs.getString(_favoritesKey);
    _favoriteIds.clear();
    _favorites.clear();
    if (favRaw != null && favRaw.isNotEmpty) {
      final decoded = jsonDecode(favRaw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final quote = Quote(
            firstname: (map['firstname'] ?? '').toString(),
            lastname: (map['lastname'] ?? '').toString(),
            category: (map['category'] ?? '').toString(),
            quote: (map['quote'] ?? '').toString(),
            backgroundColor: const Color(0xCC1E3C72),
            textColor: const Color(0xFFFCFCFC),
            backgroundImage: baseballFieldBackgrounds.first,
          );
          if (_favoriteIds.add(quote.id)) {
            _favorites.add(quote);
          }
        }
      }
    }

    _feedbackEntries.clear();
    final feedbackRaw = prefs.getString(_feedbackKey);
    if (feedbackRaw != null && feedbackRaw.isNotEmpty) {
      final decoded = jsonDecode(feedbackRaw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          _feedbackEntries.add({
            'text': (map['text'] ?? '').toString(),
            'at': (map['at'] ?? '').toString(),
          });
        }
      }
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = [
      for (final q in _favorites)
        {
          'firstname': q.firstname,
          'lastname': q.lastname,
          'category': q.category,
          'quote': q.quote,
        },
    ];
    await prefs.setString(_favoritesKey, jsonEncode(payload));
  }

  Future<void> toggleFavorite(Quote quote) async {
    if (_favoriteIds.contains(quote.id)) {
      _favoriteIds.remove(quote.id);
      _favorites.removeWhere((q) => q.id == quote.id);
    } else {
      _favoriteIds.add(quote.id);
      _favorites.insert(0, quote);
    }
    notifyListeners();
    await _saveFavorites();
  }

  Future<void> saveFeedback(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _feedbackEntries.insert(0, {
      'text': trimmed,
      'at': DateTime.now().toIso8601String(),
    });
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_feedbackKey, jsonEncode(_feedbackEntries));
  }

  List<Quote> searchQuotes(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<Quote>.from(_source);
    return _source
        .where(
          (quote) =>
              quote.quote.toLowerCase().contains(q) ||
              quote.author.toLowerCase().contains(q) ||
              quote.category.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Moves to [id] in the current deck.
  ///
  /// Returns true when the deck stayed the same and the page should jump.
  /// Returns false when the full list was restored so the deck can rebuild
  /// already positioned on that quote.
  bool revealQuote(String id) {
    final index = _quotes.indexWhere((q) => q.id == id);
    if (index >= 0) {
      _currentIndex = index;
      notifyListeners();
      return true;
    }
    _quotes = List<Quote>.from(_source);
    _deckMessage = _quotes.isEmpty ? 'No quotes found' : null;
    final restored = _quotes.indexWhere((q) => q.id == id);
    if (restored < 0) {
      _currentIndex = 0;
      _deckGeneration++;
      notifyListeners();
      return false;
    }
    _currentIndex = restored;
    _deckGeneration++;
    notifyListeners();
    return false;
  }

  void showCategory(String name) {
    final List<Quote> matched;
    if (name == 'Favorite') {
      matched = _source.where((q) => _favoriteIds.contains(q.id)).toList();
      _deckMessage = matched.isEmpty
          ? "You haven't favorited any quotes yet."
          : null;
    } else {
      matched =
          _source.where((q) => q.category == name).toList();
      _deckMessage = matched.isEmpty ? 'No $name quotes yet.' : null;
    }
    matched.shuffle();
    _quotes = matched;
    _currentIndex = 0;
    _deckGeneration++;
    notifyListeners();
  }

  void nextQuote() {
    if (_quotes.isEmpty) return;
    _isAnimating = true;
    notifyListeners();
    _currentIndex = (_currentIndex + 1) % _quotes.length;
    _isAnimating = false;
    notifyListeners();
  }

  void previousQuote() {
    if (_quotes.isEmpty) return;
    _isAnimating = true;
    notifyListeners();
    _currentIndex = (_currentIndex - 1 + _quotes.length) % _quotes.length;
    _isAnimating = false;
    notifyListeners();
  }

  void goToQuote(int index) {
    if (index >= 0 && index < _quotes.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void refreshQuotes() {
    if (_source.isEmpty) {
      _load();
      return;
    }
    _quotes = shuffleQuotesAlternatingPeople(_source);
    _currentIndex = 0;
    _deckMessage = null;
    _deckGeneration++;
    notifyListeners();
  }
}
