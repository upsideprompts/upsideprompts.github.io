import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quotes_data.dart';
import '../models/quotes_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final GlobalKey _captureKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _sharing = false;
  bool _chromeVisible = true;
  late final AnimationController _chromeController;
  late final Animation<Offset> _chromeSlide;

  @override
  void initState() {
    super.initState();
    _chromeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    );
    _chromeSlide = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _chromeController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _chromeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) {
      _chromeController.forward();
    } else {
      _chromeController.reverse();
    }
  }

  Rect? _shareOrigin() {
    final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  Future<void> _shareQuote(Quote quote, {Uint8List? imageBytes}) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = imageBytes ?? await _captureQuotePng();
      final fileName =
          'baseballbits_${quote.author.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: fileName,
            ),
          ],
          text: '"${quote.quote}" — ${quote.author}',
          subject: 'Baseball Bits',
          title: 'Baseball Bits',
          downloadFallbackEnabled: true,
          sharePositionOrigin: _shareOrigin(),
        ),
      );
    } catch (e) {
      // Fallback to text-only share when image capture isn't available.
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: '"${quote.quote}" — ${quote.author}',
            subject: 'Baseball Bits',
            title: 'Baseball Bits',
          ),
        );
      } catch (e2) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share quote: $e2')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareCurrentQuote(QuotesProvider provider) async {
    final quote = provider.currentQuote;
    if (quote == null) return;
    await _shareQuote(quote);
  }

  Future<ui.Image> _waitForCaptureImage() async {
    await WidgetsBinding.instance.endOfFrame;
    for (var attempt = 0; attempt < 20; attempt++) {
      final boundary =
          _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null && boundary.hasSize) {
        try {
          return await boundary.toImage(pixelRatio: 3);
        } catch (_) {}
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await WidgetsBinding.instance.endOfFrame;
    }
    throw StateError('Quote image was not ready to capture');
  }

  Future<Uint8List> _captureQuotePng() async {
    final image = await _waitForCaptureImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode quote image');
    }
    return byteData.buffer.asUint8List();
  }

  void _openSearch(QuotesProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2744),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _SearchSheet(
          provider: provider,
          onShare: (quote) => _shareQuote(quote),
          onOpenQuote: (quote) {
            final jumped = provider.jumpToQuoteById(quote.id);
            if (jumped && _pageController.hasClients) {
              _pageController.jumpToPage(provider.currentIndex);
            }
          },
        );
      },
    );
  }

  void _openFeedback(QuotesProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2744),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FeedbackSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: _chromeVisible
          ? AppBar(
              title: const Text('Baseball Bits'),
              backgroundColor: const Color(0x991E3C72),
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: 'Search quotes',
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => _openSearch(provider),
                ),
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
            )
          : null,
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
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleChrome,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: provider.quotes.length,
                            onPageChanged: provider.goToQuote,
                            itemBuilder: (context, index) {
                              final quote = provider.quotes[index];
                              final card = QuoteCard(
                                quote: quote,
                                isActive: index == provider.currentIndex,
                              );
                              if (index == provider.currentIndex) {
                                return RepaintBoundary(
                                  key: _captureKey,
                                  child: card,
                                );
                              }
                              return card;
                            },
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 24 + bottomInset,
                          child: SlideTransition(
                            position: _chromeSlide,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Material(
                                      key: _shareButtonKey,
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        tooltip: 'Share quote image',
                                        onPressed: _sharing
                                            ? null
                                            : () => _shareCurrentQuote(provider),
                                        icon: _sharing
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.ios_share,
                                                color: Colors.white,
                                                size: 26,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Material(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        tooltip: provider.currentQuote != null &&
                                                provider.isFavorite(
                                                    provider.currentQuote!)
                                            ? 'Remove favorite'
                                            : 'Favorite quote',
                                        onPressed: provider.currentQuote == null
                                            ? null
                                            : () => provider.toggleFavorite(
                                                  provider.currentQuote!,
                                                ),
                                        icon: Icon(
                                          Icons.sports_baseball,
                                          color: provider.currentQuote != null &&
                                                  provider.isFavorite(
                                                      provider.currentQuote!)
                                              ? const Color(0xFFFFC107)
                                              : Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _SecondaryBar(
                                  provider: provider,
                                  onJumpToQuote: (quote) {
                                    final jumped =
                                        provider.jumpToQuoteById(quote.id);
                                    if (jumped && _pageController.hasClients) {
                                      _pageController
                                          .jumpToPage(provider.currentIndex);
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Material(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => _openFeedback(provider),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.feedback_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Feedback',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _SecondaryBar extends StatelessWidget {
  const _SecondaryBar({
    required this.provider,
    required this.onJumpToQuote,
  });

  final QuotesProvider provider;
  final ValueChanged<Quote> onJumpToQuote;

  static const _categories = [
    'Favorite',
    'Innovation',
    'Focus',
    'Appreciation',
    'Improvement',
  ];

  static const _backgroundStyles = [
    'Stadiums',
    'Fields',
    'Baseball Diamonds',
    'Solid Colors',
  ];

  Future<void> _showCategories(BuildContext context) {
    final barContext = context;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A2744),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 14),
                const Text(
                  'Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                for (final option in _categories)
                  ListTile(
                    title: Text(
                      option,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      if (option == 'Favorite' && barContext.mounted) {
                        _showFavorites(barContext);
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFavorites(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2744),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer<QuotesProvider>(
          builder: (context, provider, _) {
            final favorites = provider.favorites;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: Column(
                    children: [
                      _sheetHandle(),
                      const SizedBox(height: 14),
                      const Text(
                        'Favorites',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: favorites.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    "You haven't favorited any quotes yet.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: favorites.length,
                                itemBuilder: (context, index) {
                                  final quote = favorites[index];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.sports_baseball,
                                      color: Color(0xFFFFC107),
                                    ),
                                    title: Text(
                                      '"${quote.quote}" — ${quote.author}',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      onJumpToQuote(quote);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showBackgrounds(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A2744),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 14),
                const Text(
                  'Backgrounds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                for (final option in _backgroundStyles)
                  ListTile(
                    title: Text(
                      option,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                    ),
                    onTap: () {
                      // Selection wiring comes later.
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _sheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: 'Categories',
            icon: const Icon(Icons.list_alt, size: 28, color: Colors.white),
            onPressed: () => _showCategories(context),
          ),
          IconButton(
            tooltip: 'Backgrounds',
            icon: const Icon(Icons.image_outlined, size: 28, color: Colors.white),
            onPressed: () => _showBackgrounds(context),
          ),
        ],
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({
    required this.provider,
    required this.onShare,
    required this.onOpenQuote,
  });

  final QuotesProvider provider;
  final Future<void> Function(Quote quote) onShare;
  final ValueChanged<Quote> onOpenQuote;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Quote? _selected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.provider.searchQuotes(_controller.text);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _selected == null ? 'Search quotes' : 'Quote',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (_selected == null) ...[
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Search by quote or author',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: results.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching quotes',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final quote = results[index];
                              return ListTile(
                                title: Text(
                                  '"${quote.quote}" — ${quote.author}',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                onTap: () => setState(() => _selected = quote),
                              );
                            },
                          ),
                  ),
                ] else ...[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '"${_selected!.quote}" — ${_selected!.author}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => widget.onShare(_selected!),
                                  icon: const Icon(Icons.ios_share),
                                  label: const Text('Share'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    await widget.provider
                                        .toggleFavorite(_selected!);
                                    setState(() {});
                                  },
                                  icon: Icon(
                                    Icons.sports_baseball,
                                    color: widget.provider.isFavorite(_selected!)
                                        ? const Color(0xFFFFC107)
                                        : Colors.white,
                                  ),
                                  label: Text(
                                    widget.provider.isFavorite(_selected!)
                                        ? 'Favorited'
                                        : 'Favorite',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2A5298),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => setState(() => _selected = null),
                            child: const Text(
                              'Back to search',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              widget.onOpenQuote(_selected!);
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Show on screen',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({required this.provider});

  final QuotesProvider provider;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _controller.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.provider.saveFeedback(_controller.text);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks — your feedback was saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Feedback',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Tell us what you think…',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2A5298),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save feedback'),
              ),
            ],
          ),
        ),
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
    const quoteSize = 28.0;
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
                      '"${quote.quote}" — ${quote.author}',
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
                if (quote.category.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
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
