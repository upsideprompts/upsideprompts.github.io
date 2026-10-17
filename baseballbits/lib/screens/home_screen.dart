import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quotes_data.dart';
import '../models/quotes_provider.dart';
import '../services/feedback_submit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  PageController _pageController = PageController();
  int _controllerGeneration = -1;
  final GlobalKey _captureKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _sharing = false;
  bool _chromeVisible = true;
  late final AnimationController _chromeController;
  late final Animation<Offset> _bottomChromeSlide;
  late final Animation<Offset> _topChromeSlide;

  @override
  void initState() {
    super.initState();
    _chromeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    );
    final curve = CurvedAnimation(
      parent: _chromeController,
      curve: Curves.easeOutCubic,
    );
    _bottomChromeSlide = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(curve);
    _topChromeSlide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void dispose() {
    _chromeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Starts near the middle of a repeated deck so the first quote can swipe
  /// either direction and the pages wrap.
  PageController _pageControllerFor(QuotesProvider provider) {
    if (_controllerGeneration == provider.deckGeneration) {
      return _pageController;
    }
    final length = provider.quotes.length;
    final anchor = length * 500 + provider.currentIndex;
    final previous = _pageController;
    _pageController = PageController(initialPage: anchor, keepPage: false);
    _controllerGeneration = provider.deckGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous.dispose();
    });
    return _pageController;
  }

  void _jumpToLogicalPage(int logicalIndex) {
    final length = context.read<QuotesProvider>().quotes.length;
    if (length == 0 || !_pageController.hasClients) return;
    final current =
        _pageController.page?.round() ?? _pageController.initialPage;
    var delta = logicalIndex - (current % length);
    if (delta > length ~/ 2) delta -= length;
    if (delta < -(length ~/ 2)) delta += length;
    final target = current + delta;
    if (target < 0 || target >= length * 1000) return;
    _pageController.jumpToPage(target);
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
          text: '"${quote.quote}"\n– ${quote.author}',
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
            text: '"${quote.quote}"\n– ${quote.author}',
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

  Future<void> _copyQuoteText(QuotesProvider provider) async {
    final quote = provider.currentQuote;
    if (quote == null) return;
    await Clipboard.setData(
      ClipboardData(text: '"${quote.quote}"\n– ${quote.author}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote copied')),
    );
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
            final sameDeck = provider.revealQuote(quote.id);
            if (sameDeck) _jumpToLogicalPage(provider.currentIndex);
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

  void _openAbout() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final top = MediaQuery.paddingOf(dialogContext).top;
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(top: top + kToolbarHeight + 8, right: 12),
            child: Material(
              color: const Color(0xFF1A2744),
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Baseball QuoteFloat has inspirational quotes from baseball legends, bringing them at the championship level.  You’ll discover a range of quotes on improvement, success, and focus. Customize your categories and backgrounds.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : provider.error != null
              ? Center(
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                )
              : Stack(
                      fit: StackFit.expand,
                      children: [
                        if (provider.quotes.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                provider.deckMessage ?? 'No quotes found',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _toggleChrome,
                            child: PageView.builder(
                              key: ValueKey(provider.deckGeneration),
                              controller: _pageControllerFor(provider),
                              itemCount: provider.quotes.length * 1000,
                              onPageChanged: (index) {
                                provider.goToQuote(
                                  index % provider.quotes.length,
                                );
                              },
                              itemBuilder: (context, index) {
                                final length = provider.quotes.length;
                                final quote = provider.quotes[index % length];
                                final currentPage = _pageController.hasClients
                                    ? (_pageController.page?.round() ??
                                        _pageController.initialPage)
                                    : _pageController.initialPage;
                                final card = QuoteCard(
                                  quote: quote,
                                  isActive: index == currentPage,
                                  backgroundGradient: provider.backgroundGradient,
                                  backgroundImageOverride:
                                      provider.backgroundImageOverride,
                                );
                                if (index == currentPage) {
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
                          top: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            ignoring: !_chromeVisible,
                            child: SlideTransition(
                              position: _topChromeSlide,
                              child: Material(
                                color: const Color(0x991E3C72),
                                elevation: 0,
                                child: SafeArea(
                                  bottom: false,
                                  child: SizedBox(
                                    height: kToolbarHeight,
                                    child: NavigationToolbar(
                                      middle: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Baseball',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(
                                            Icons.sports_baseball,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'QuoteFloat',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          PopupMenuButton<String>(
                                            tooltip: 'More',
                                            color: const Color(0xFF1A2744),
                                            offset: const Offset(0, 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            icon: const Icon(
                                              Icons.more_horiz,
                                              color: Colors.white,
                                            ),
                                            onSelected: (value) {
                                              if (value == 'copy') {
                                                _copyQuoteText(provider);
                                              } else if (value == 'search') {
                                                _openSearch(provider);
                                              } else if (value == 'feedback') {
                                                _openFeedback(provider);
                                              } else if (value == 'about') {
                                                _openAbout();
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'copy',
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Copy Quote Text',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.content_copy,
                                                      color: Colors.white,
                                                      size: 19.2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'search',
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Search',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.search,
                                                      color: Colors.white,
                                                      size: 19.2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'feedback',
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Give Feedback',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.mark_chat_read_outlined,
                                                      color: Colors.white,
                                                      size: 19.2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'about',
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'About',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.info_outline,
                                                      color: Colors.white,
                                                      size: 19.2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 24 + bottomInset,
                          child: IgnorePointer(
                            ignoring: !_chromeVisible,
                            child: AnimatedBuilder(
                              animation: _bottomChromeSlide,
                              builder: (context, child) {
                                final hidden =
                                    (_bottomChromeSlide.value.dy / 1.2)
                                        .clamp(0.0, 1.0);
                                return Transform.translate(
                                  offset: Offset(0, 50 * hidden),
                                  child: child,
                                );
                              },
                              child: SlideTransition(
                                position: _bottomChromeSlide,
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
                                              : () =>
                                                  _shareCurrentQuote(provider),
                                          icon: _sharing
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
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
                                          tooltip: provider.currentQuote !=
                                                      null &&
                                                  provider.isFavorite(
                                                      provider.currentQuote!)
                                              ? 'Remove favorite'
                                              : 'Favorite quote',
                                          onPressed:
                                              provider.currentQuote == null
                                                  ? null
                                                  : () =>
                                                      provider.toggleFavorite(
                                                        provider.currentQuote!,
                                                      ),
                                          icon: Icon(
                                            Icons.sports_baseball,
                                            color: provider.currentQuote !=
                                                        null &&
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
                                  _SecondaryBar(provider: provider),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Material(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
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
                                                Icons.mark_chat_read_outlined,
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
  });

  final QuotesProvider provider;

  static const _categories = [
    'Favorite',
    'Success',
    'Focus',
    'Appreciation',
    'Improvement',
    'Perspectives',
  ];

  static const _plateCaption = 'Step up to the plate.';

  static const _solidBackgrounds = [
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFD6F0FF), Color(0xFF7EC8EA), Color(0xFF4AA3D8)],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE7F8E7), Color(0xFF9ED49E), Color(0xFF5EAE6A)],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8EBD9), Color(0xFFD2B48C), Color(0xFFA67C52)],
    ),
  ];

  Future<void> _showCategories(BuildContext context) {
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
                      provider.showCategory(option);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBackgrounds(BuildContext context) {
    final imageTiles = <Widget>[
      _fieldThumb(
        context: context,
        imagePath: 'assets/backgrounds/VariousImages1.jpeg',
        showShuffle: true,
        onTap: () {
          Navigator.of(context).pop();
          provider.setRandomFieldBackground();
        },
      ),
      for (final path in baseballFieldBackgrounds)
        _fieldThumb(
          context: context,
          imagePath: path,
          onTap: () {
            Navigator.of(context).pop();
            provider.setFieldBackground(path);
          },
        ),
    ];
    while (imageTiles.length % 3 != 0) {
      imageTiles.add(const Expanded(child: SizedBox.shrink()));
    }
    final imageRows = <Widget>[];
    for (var i = 0; i < imageTiles.length; i += 3) {
      imageRows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: imageTiles.sublist(i, i + 3),
        ),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2744),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.88;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Column(
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
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 390),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final gradient in _solidBackgrounds)
                                    _colorThumb(
                                      sheetContext: sheetContext,
                                      gradient: gradient,
                                    ),
                                ],
                              ),
                              ...imageRows,
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
        );
      },
    );
  }

  Widget _colorThumb({
    required BuildContext sheetContext,
    required Gradient gradient,
  }) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(sheetContext).pop();
                provider.setGradientBackground(gradient);
              },
              child: Ink(
                decoration: BoxDecoration(gradient: gradient),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Text(
                      _plateCaption,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldThumb({
    required BuildContext context,
    required String imagePath,
    required VoidCallback onTap,
    bool showShuffle = false,
  }) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: const Color(0xFF0E1A30),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(color: Color(0xFF0E1A30));
                    },
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showShuffle) ...[
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xE61A2744),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shuffle,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          const Text(
                            _plateCaption,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                                  '"${quote.quote}" – ${quote.author}',
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
                            '"${_selected!.quote}"\n– ${_selected!.author}',
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
    final text = _controller.text.trim();
    if (_saving || text.isEmpty) return;
    setState(() => _saving = true);
    try {
      // Same as the HTML page: POST feedback=... to the Apps Script web app.
      await submitFeedbackToSheet(text);
      // Keep a local copy as well.
      await widget.provider.saveFeedback(text);
      if (!mounted) return;
      _controller.clear();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appreciate your feedback!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send feedback: $e')),
      );
      return;
    }
    if (mounted) setState(() => _saving = false);
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
                'Do you have any suggestions to improve our app?',
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
                  hintText: 'Enter your feedback here...',
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
                    : const Text('Submit'),
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
  final Gradient? backgroundGradient;
  final String? backgroundImageOverride;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.isActive,
    this.backgroundGradient,
    this.backgroundImageOverride,
  });

  @override
  Widget build(BuildContext context) {
    const quoteSize = 28.0;
    final onLight = backgroundGradient != null;
    final textColor = onLight ? const Color(0xFF1A2744) : quote.textColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (backgroundGradient != null)
          DecoratedBox(
            decoration: BoxDecoration(gradient: backgroundGradient),
          )
        else
          Image.asset(
            backgroundImageOverride ?? quote.backgroundImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: quote.backgroundColor);
            },
          ),
        if (!onLight) Container(color: quote.backgroundColor),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 45, 28, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 98),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      '"${quote.quote}"\n– ${quote.author}',
                      style: TextStyle(
                        fontSize: quoteSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.35,
                        shadows: onLight
                            ? null
                            : const [
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
