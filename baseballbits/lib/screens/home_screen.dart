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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Baseball Bits'),
        backgroundColor: const Color(0x991E3C72),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Shuffle quotes',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              provider.refreshQuotes();
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : provider.error != null
              ? Center(
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                )
              : provider.quotes.isEmpty
                  ? const Center(
                      child: Text(
                        'No quotes found',
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: provider.quotes.length,
                          onPageChanged: provider.goToQuote,
                          itemBuilder: (context, index) {
                            final quote = provider.quotes[index];
                            return QuoteCard(
                              quote: quote,
                              isActive: index == provider.currentIndex,
                            );
                          },
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 200,
                          child: _FloatingBar(
                            provider: provider,
                            onPrevious: () {
                              provider.previousQuote();
                              _goTo(provider.currentIndex);
                            },
                            onNext: () {
                              provider.nextQuote();
                              _goTo(provider.currentIndex);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _FloatingBar extends StatelessWidget {
  const _FloatingBar({
    required this.provider,
    required this.onPrevious,
    required this.onNext,
  });

  final QuotesProvider provider;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 36, color: Colors.white),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              'Quote ${provider.currentIndex + 1} of ${provider.quotes.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 36, color: Colors.white),
            onPressed: onNext,
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
    // Quote 20→28, author 17→24, category 13→18 (+40%)
    const quoteSize = 28.0;
    const authorSize = 24.0;
    const categorySize = 18.0;
    const iconSize = 78.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          quote.backgroundImage,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: quote.backgroundColor);
          },
        ),
        Container(color: quote.backgroundColor),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 280),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_baseball, size: iconSize, color: Colors.white70),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      '"${quote.quote}"',
                      style: TextStyle(
                        fontSize: quoteSize,
                        fontWeight: FontWeight.w600,
                        color: quote.textColor,
                        height: 1.35,
                        shadows: const [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black54,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '— ${quote.author}',
                  style: TextStyle(
                    fontSize: authorSize,
                    fontStyle: FontStyle.italic,
                    color: quote.textColor.withValues(alpha: 0.92),
                    shadows: const [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black54,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                if (quote.category.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: quote.textColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      quote.category,
                      style: TextStyle(
                        fontSize: categorySize,
                        fontWeight: FontWeight.w600,
                        color: quote.textColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
