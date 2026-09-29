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
    if (provider.quotes.isEmpty) return;
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
              _lastProviderIndex = 0;
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
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _ControlsBar(
                            provider: provider,
                            pageController: _pageController,
                            onIndexSynced: (index) => _lastProviderIndex = index,
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _ControlsBar extends StatelessWidget {
  const _ControlsBar({
    required this.provider,
    required this.pageController,
    required this.onIndexSynced,
  });

  final QuotesProvider provider;
  final PageController pageController;
  final ValueChanged<int> onIndexSynced;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quote ${provider.currentIndex + 1} of ${provider.quotes.length}',
            style: const TextStyle(fontSize: 22, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 40, color: Colors.white),
                onPressed: () {
                  provider.previousQuote();
                  onIndexSynced(provider.currentIndex);
                  pageController.animateToPage(
                    provider.currentIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 40, color: Colors.white),
                onPressed: () {
                  provider.nextQuote();
                  onIndexSynced(provider.currentIndex);
                  pageController.animateToPage(
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
              const Text('Auto-scroll', style: TextStyle(color: Colors.white70, fontSize: 18)),
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
                width: 44,
                child: Text(
                  '${provider.autoScrollInterval ~/ 1000}s',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
            ],
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
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 220),
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
