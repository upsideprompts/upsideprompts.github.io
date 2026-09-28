import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'stl/binary_stl.dart';
import 'viewer/stl_viewer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TabOptions3App());
}

class TabOptions3App extends StatelessWidget {
  const TabOptions3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tab Options 3 — Cassette Keyring STL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6EC8E8),
          brightness: Brightness.light,
        ),
      ),
      home: const StlHomePage(),
    );
  }
}

class StlHomePage extends StatefulWidget {
  const StlHomePage({super.key});

  @override
  State<StlHomePage> createState() => _StlHomePageState();
}

class _StlHomePageState extends State<StlHomePage> {
  BinaryStlMesh? _mesh;
  double _extent = 40;
  String _status = 'Loading Cassette_Keyring.stl…';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await rootBundle.load('assets/Cassette_Keyring.stl');
      final mesh = BinaryStlMesh.parse(data);
      final extent = mesh.centerInPlace();
      if (!mounted) return;
      setState(() {
        _mesh = mesh;
        _extent = extent;
        _status =
            '${mesh.triangleCount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} facets · ${mesh.header}';
        _error = null;
      });
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _status = '');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load Cassette_Keyring.stl';
        _status = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final facetLabel = _mesh == null
        ? '—'
        : _mesh!.triangleCount
            .toString()
            .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEEF3F7),
              Color(0xFFB7C9D8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    const _TitleBanner(),
                    const SizedBox(height: 8),
                    Text(
                      'Drag to rotate · scroll/pinch to zoom · translucent mesh from binary STL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF1F2A33).withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ViewportCard(
                      mesh: _mesh,
                      extent: _extent,
                      status: _status,
                      error: _error,
                    ),
                    const SizedBox(height: 14),
                    _SpecNotes(facetCount: facetLabel),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBanner extends StatelessWidget {
  const _TitleBanner();

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateX(-0.35),
      child: Container(
        width: 300,
        height: 100,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x666EC8E8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF28465A).withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Text(
          'Cassette Keyring · Binary STL',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0B3D1C),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

class _ViewportCard extends StatelessWidget {
  const _ViewportCard({
    required this.mesh,
    required this.extent,
    required this.status,
    required this.error,
  });

  final BinaryStlMesh? mesh;
  final double extent;
  final String status;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28465A).withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mesh != null) StlViewer(mesh: mesh!, extent: extent),
          if (status.isNotEmpty || error != null)
            Center(
              child: Text(
                error ?? status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: error != null
                      ? const Color(0xFF8B1A1A)
                      : const Color(0xFF1F2A33).withValues(alpha: 0.75),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpecNotes extends StatelessWidget {
  const _SpecNotes({required this.facetCount});

  final String facetCount;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 12,
      height: 1.45,
      color: const Color(0xFF1F2A33).withValues(alpha: 0.78),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Binary STL (fabbers.com)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B3D1C),
            ),
          ),
          const SizedBox(height: 6),
          Text('80-byte header', style: style),
          Text('uint32 little-endian triangle count', style: style),
          Text(
            'Each facet: 12× float32 (normal + 3 vertices) + uint16 attribute',
            style: style,
          ),
          Text(
            'Source: Cassette_Keyring.stl · $facetCount facets',
            style: style,
          ),
        ],
      ),
    );
  }
}
