import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quotes_provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final provider = Provider.of<QuotesProvider>(context, listen: false);
      if (_pageController.page != null) {
        final index = _pageController.page!.round();
        if (index != _currentIndex && index >= 0 && index < provider.quotes.length) {
          setState(() {
            _currentIndex = index;
          });
          provider.goToQuote(index);
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuotesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Quote Slider'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              provider.refreshQuotes();
              _pageController.animateToPage(
                0,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Main Quote Slider
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: provider.quotes.length,
              itemBuilder: (context, index) {
                final quote = provider.quotes[index];
                return QuoteCard(
                  quote: quote,
                  isActive: index == _currentIndex,
                  isAnimating: provider.isAnimating,
                );
              },
            ),
          ),

          // Navigation Controls
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Quote Counter
                Text(
                  "Quote ${_currentIndex + 1} of ${provider.quotes.length}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),

                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, size: 32),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, size: 32),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Auto-scroll Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Auto-scroll: '),
                    Switch(
                      value: provider.autoScrollEnabled,
                      onChanged: (value) {
                        provider.toggleAutoScroll(value);
                      },
                    ),
                  ],
                ),

                // Auto-scroll Interval Slider
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: provider.autoScrollInterval.toDouble(),
                          min: 2000,
                          max: 10000,
                          divisions: 8,
                          label: '${provider.autoScrollInterval ~/ 1000}s',
                          onChanged: (value) {
                            provider.changeAutoScrollInterval(value.round());
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${provider.autoScrollInterval ~/ 1000}s',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dots Indicator
          Container(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                provider.quotes.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentIndex
                        ? Colors.blue
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final bool isActive;
  final bool isAnimating;

  const QuoteCard({
    required this.quote,
    required this.isActive,
    required this.isAnimating,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: quote.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Quote Image
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  quote.quoteImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
            ),
          ),

          // Quote Text
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '"${quote.text}"',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: quote.textColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  '- ${quote.author}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: quote.textColor.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: quote.textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    quote.category,
                    style: TextStyle(
                      fontSize: 14,
                      color: quote.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}