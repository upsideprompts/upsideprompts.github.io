import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

import '../stl/binary_stl.dart';

class StlViewer extends StatefulWidget {
  const StlViewer({
    super.key,
    required this.mesh,
    required this.extent,
  });

  final BinaryStlMesh mesh;
  final double extent;

  @override
  State<StlViewer> createState() => _StlViewerState();
}

class _StlViewerState extends State<StlViewer> {
  double _rotX = -0.35;
  double _rotY = 0.55;
  late double _distance;
  Offset? _lastPan;

  @override
  void initState() {
    super.initState();
    _distance = widget.extent * 1.85;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount >= 2) {
        _distance = (_distance / details.scale.clamp(0.85, 1.15))
            .clamp(widget.extent * 0.6, widget.extent * 5.0);
      } else if (_lastPan != null) {
        final delta = details.focalPoint - _lastPan!;
        _rotY += delta.dx * 0.008;
        _rotX = (_rotX + delta.dy * 0.008).clamp(-1.2, 1.2);
      }
      _lastPan = details.focalPoint;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final dy = event.scrollDelta.dy;
          setState(() {
            _distance = (_distance * (dy > 0 ? 1.08 : 0.92))
                .clamp(widget.extent * 0.6, widget.extent * 5.0);
          });
        }
      },
      child: GestureDetector(
        onScaleStart: (details) => _lastPan = details.focalPoint,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: (_) => _lastPan = null,
        child: CustomPaint(
          painter: _StlPainter(
            mesh: widget.mesh,
            rotX: _rotX,
            rotY: _rotY,
            distance: _distance,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _StlPainter extends CustomPainter {
  _StlPainter({
    required this.mesh,
    required this.rotX,
    required this.rotY,
    required this.distance,
  });

  final BinaryStlMesh mesh;
  final double rotX;
  final double rotY;
  final double distance;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = mesh.positions;
    final normals = mesh.normals;
    final triCount = mesh.triangleCount;

    // Orient cassette upright, then apply user orbit (matches taboptions2 JS).
    final model = Matrix4.identity()
      ..rotateX(-math.pi / 2)
      ..rotateX(rotX)
      ..rotateY(rotY);

    final light = Vector3(0.45, 0.75, 0.55)..normalize();
    final fill = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..color = const Color(0x33FFFFFF)
      ..isAntiAlias = true;

    final tris = <_ProjectedTri>[];
    final focal = size.shortestSide * 0.95;

    for (var i = 0; i < triCount; i++) {
      final base = i * 9;
      final v0 = _xf(model, positions[base], positions[base + 1], positions[base + 2]);
      final v1 = _xf(model, positions[base + 3], positions[base + 4], positions[base + 5]);
      final v2 = _xf(model, positions[base + 6], positions[base + 7], positions[base + 8]);

      final n = _xfN(model, normals[base], normals[base + 1], normals[base + 2]);
      // Camera looks from +Z toward origin; front faces have positive n.z roughly.
      final facing = n.dot(Vector3(0, 0.15, 1)..normalize());
      if (facing < 0.05) continue;

      final z0 = v0.z + distance;
      final z1 = v1.z + distance;
      final z2 = v2.z + distance;
      if (z0 < 1 || z1 < 1 || z2 < 1) continue;

      final p0 = _proj(v0.x, v0.y, z0, size, focal);
      final p1 = _proj(v1.x, v1.y, z1, size, focal);
      final p2 = _proj(v2.x, v2.y, z2, size, focal);
      final depth = (z0 + z1 + z2) / 3;
      final shade = (0.30 + 0.70 * math.max(0.0, n.dot(light))).clamp(0.0, 1.0);
      tris.add(_ProjectedTri(p0, p1, p2, depth, shade));
    }

    tris.sort((a, b) => b.depth.compareTo(a.depth)); // far → near

    for (final t in tris) {
      final path = Path()
        ..moveTo(t.a.dx, t.a.dy)
        ..lineTo(t.b.dx, t.b.dy)
        ..lineTo(t.c.dx, t.c.dy)
        ..close();
      fill.color = Color.fromRGBO(
        (110 + 55 * t.shade).round(),
        (190 + 35 * t.shade).round(),
        235,
        0.26 + 0.24 * t.shade,
      );
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  Vector3 _xf(Matrix4 m, double x, double y, double z) {
    final v = Vector3(x, y, z);
    m.transform3(v);
    return v;
  }

  Vector3 _xfN(Matrix4 m, double x, double y, double z) {
    final n = Vector3(x, y, z);
    final r = Matrix4.zero()
      ..setEntry(0, 0, m.entry(0, 0))
      ..setEntry(0, 1, m.entry(0, 1))
      ..setEntry(0, 2, m.entry(0, 2))
      ..setEntry(1, 0, m.entry(1, 0))
      ..setEntry(1, 1, m.entry(1, 1))
      ..setEntry(1, 2, m.entry(1, 2))
      ..setEntry(2, 0, m.entry(2, 0))
      ..setEntry(2, 1, m.entry(2, 1))
      ..setEntry(2, 2, m.entry(2, 2))
      ..setEntry(3, 3, 1);
    r.transform3(n);
    if (n.length2 > 0) n.normalize();
    return n;
  }

  Offset _proj(double x, double y, double z, Size size, double focal) {
    return Offset(
      size.width * 0.5 + (x * focal) / z,
      size.height * 0.5 - (y * focal) / z,
    );
  }

  @override
  bool shouldRepaint(covariant _StlPainter oldDelegate) {
    return oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY ||
        oldDelegate.distance != distance ||
        oldDelegate.mesh != mesh;
  }
}

class _ProjectedTri {
  _ProjectedTri(this.a, this.b, this.c, this.depth, this.shade);
  final Offset a;
  final Offset b;
  final Offset c;
  final double depth;
  final double shade;
}
