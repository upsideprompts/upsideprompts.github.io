import 'dart:async';

import 'package:flutter/material.dart';

import 'quotes_data.dart';

class QuotesProvider with ChangeNotifier {
  List<Quote> _quotes = [];
  List<Quote> get quotes => List.unmodifiable(_quotes);

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _autoScrollInterval = 5000;
  int get autoScrollInterval => _autoScrollInterval;

  bool _autoScrollEnabled = true;
  bool get autoScrollEnabled => _autoScrollEnabled;

  Timer? _autoScrollTimer;
  List<Quote> _source = [];

  QuotesProvider() {
    _load();
  }

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _source = await loadQuotesFromAsset();
      _quotes = shuffleQuotesAlternatingPeople(_source);
      _currentIndex = 0;
      _isLoading = false;
      notifyListeners();
      startIfNeeded();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load quotes.json';
      notifyListeners();
    }
  }

  void startIfNeeded() {
    if (_autoScrollEnabled && _quotes.isNotEmpty) {
      _startAutoScroll();
    }
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

  void toggleAutoScroll(bool enabled) {
    _autoScrollEnabled = enabled;
    notifyListeners();
    if (enabled) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void changeAutoScrollInterval(int intervalMs) {
    _autoScrollInterval = intervalMs;
    notifyListeners();
    if (_autoScrollEnabled) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _stopAutoScroll();
    if (_quotes.isEmpty) return;
    _autoScrollTimer = Timer.periodic(
      Duration(milliseconds: _autoScrollInterval),
      (_) => nextQuote(),
    );
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void refreshQuotes() {
    if (_source.isEmpty) {
      _load();
      return;
    }
    _quotes = shuffleQuotesAlternatingPeople(_source);
    _currentIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopAutoScroll();
    super.dispose();
  }
}
