import 'package:flutter/material.dart';
import 'quotes_data.dart';
import 'dart:async';

class QuotesProvider with ChangeNotifier {
  List<Quote> _quotes = [];
  List<Quote> get quotes => List.unmodifiable(_quotes);
  
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;
  
  int _autoScrollInterval = 5000; // 5 seconds
  int get autoScrollInterval => _autoScrollInterval;
  
  bool _autoScrollEnabled = true;
  bool get autoScrollEnabled => _autoScrollEnabled;
  
  QuotesProvider() {
    _loadQuotes();
  }
  
  Future<void> _loadQuotes() async {
    if (_quotes.isEmpty) {
      _quotes = quotesData;
      notifyListeners();
    }
  }
  
  void nextQuote() {
    if (_quotes.isEmpty) return;
    
    _isAnimating = true;
    notifyListeners();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _currentIndex = (_currentIndex + 1) % _quotes.length;
      _isAnimating = false;
      notifyListeners();
    });
  }
  
  void previousQuote() {
    if (_quotes.isEmpty) return;
    
    _isAnimating = true;
    notifyListeners();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _currentIndex = (_currentIndex - 1 + _quotes.length) % _quotes.length;
      _isAnimating = false;
      notifyListeners();
    });
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
    _autoScrollTimer = Timer.periodic(
      Duration(milliseconds: _autoScrollInterval),
      (_) => nextQuote(),
    );
  }
  
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }
  
  void refreshQuotes() {
    _quotes = List.from(quotesData);
    _currentIndex = 0;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }
  
  Timer? _autoScrollTimer;
}