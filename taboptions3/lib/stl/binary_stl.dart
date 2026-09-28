import 'dart:typed_data';

/// Binary STL parser (fabbers.com / StereoLithography Interface format):
///   [80 bytes header]
///   [uint32 LE triangle count]
///   repeated:
///     [3×float32 normal][3×float32 v1][3×float32 v2][3×float32 v3][uint16 attr]
class BinaryStlMesh {
  BinaryStlMesh({
    required this.header,
    required this.triangleCount,
    required this.positions,
    required this.normals,
  });

  final String header;
  final int triangleCount;

  /// Flat XYZ triples: length == triangleCount * 9
  final Float32List positions;

  /// Per-vertex normals (facet normal repeated): length == triangleCount * 9
  final Float32List normals;

  static BinaryStlMesh parse(ByteData data) {
    if (data.lengthInBytes < 84) {
      throw StateError('STL too small for binary header + count');
    }

    final headerBytes = Uint8List.sublistView(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      0,
      80,
    );
    final header = String.fromCharCodes(headerBytes)
        .replaceAll(RegExp(r'\x00+$'), '')
        .trim();

    final triangleCount = data.getUint32(80, Endian.little);
    final expected = 84 + triangleCount * 50;
    if (data.lengthInBytes < expected) {
      throw StateError(
        'STL truncated: need $expected bytes, got ${data.lengthInBytes}',
      );
    }

    final positions = Float32List(triangleCount * 9);
    final normals = Float32List(triangleCount * 9);

    var offset = 84;
    var p = 0;
    for (var i = 0; i < triangleCount; i++) {
      final nx = data.getFloat32(offset, Endian.little);
      final ny = data.getFloat32(offset + 4, Endian.little);
      final nz = data.getFloat32(offset + 8, Endian.little);
      offset += 12;

      for (var v = 0; v < 3; v++) {
        final x = data.getFloat32(offset, Endian.little);
        final y = data.getFloat32(offset + 4, Endian.little);
        final z = data.getFloat32(offset + 8, Endian.little);
        offset += 12;
        positions[p] = x;
        positions[p + 1] = y;
        positions[p + 2] = z;
        normals[p] = nx;
        normals[p + 1] = ny;
        normals[p + 2] = nz;
        p += 3;
      }

      offset += 2; // attribute byte count
    }

    return BinaryStlMesh(
      header: header.isEmpty ? 'binary STL' : header,
      triangleCount: triangleCount,
      positions: positions,
      normals: normals,
    );
  }

  /// Center mesh at origin and return extents (max axis length).
  double centerInPlace() {
    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity, maxZ = -double.infinity;

    for (var i = 0; i < positions.length; i += 3) {
      final x = positions[i];
      final y = positions[i + 1];
      final z = positions[i + 2];
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (z < minZ) minZ = z;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      if (z > maxZ) maxZ = z;
    }

    final cx = (minX + maxX) * 0.5;
    final cy = (minY + maxY) * 0.5;
    final cz = (minZ + maxZ) * 0.5;

    for (var i = 0; i < positions.length; i += 3) {
      positions[i] -= cx;
      positions[i + 1] -= cy;
      positions[i + 2] -= cz;
    }

    final sx = maxX - minX;
    final sy = maxY - minY;
    final sz = maxZ - minZ;
    return [sx, sy, sz].reduce((a, b) => a > b ? a : b);
  }
}
