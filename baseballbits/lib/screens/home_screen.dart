import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quotes_data.dart';
import '../models/quotes_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _lastProviderIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPageFromProvider(QuotesProvider provider) {
    if (!_pageController.hasClients) return;
    if (provider.currentIndex == _lastProviderIndex) return;
    _lastProviderIndex = provider.currentIndex;
    _pageController.animateToPage(
      provider.currentIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPageFromProvider(provider);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baseball Bits'),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Shuffle quotes',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              provider.refreshQuotes();
              _lastProviderIndex = 0;
              _pageController.jumpToPage(0);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: provider.quotes.length,
              onPageChanged: (index) {
                _lastProviderIndex = index;
                provider.goToQuote(index);
              },
              itemBuilder: (context, index) {
                final quote = provider.quotes[index];
                return QuoteCard(
                  quote: quote,
                  isActive: index == provider.currentIndex,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Text(
                  'Quote ${provider.currentIndex + 1} of ${provider.quotes.length}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 36),
                      onPressed: () {
                        provider.previousQuote();
                        _lastProviderIndex = provider.currentIndex;
                        _pageController.animateToPage(
                          provider.currentIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 36),
                      onPressed: () {
                        provider.nextQuote();
                        _lastProviderIndex = provider.currentIndex;
                        _pageController.animateToPage(
                          provider.currentIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Auto-scroll'),
                    Switch(
                      value: provider.autoScrollEnabled,
                      onChanged: provider.toggleAutoScroll,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
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
                    SizedBox(
                      width: 40,
                      child: Text('${provider.autoScrollInterval ~/ 1000}s'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                provider.quotes.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == provider.currentIndex
                        ? const Color(0xFF1E3C72)
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

  const QuoteCard({
    super.key,
    required this.quote,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: quote.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                quote.quoteImage,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white24,
                    alignment: Alignment.center,
                    child: const Icon(Icons.sports_baseball, size: 64, color: Colors.white70),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  '— ${quote.author}',
                  style: TextStyle(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    color: quote.textColor.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: quote.textColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    quote.category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: quote.textColor,
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
