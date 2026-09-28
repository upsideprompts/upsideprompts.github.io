import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:taboptions3/stl/binary_stl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses Cassette_Keyring binary STL asset', () async {
    final data = await rootBundle.load('assets/Cassette_Keyring.stl');
    final mesh = BinaryStlMesh.parse(data);
    expect(mesh.triangleCount, 5472);
    expect(mesh.positions.length, 5472 * 9);
    final extent = mesh.centerInPlace();
    expect(extent, greaterThan(1));
  });
}
