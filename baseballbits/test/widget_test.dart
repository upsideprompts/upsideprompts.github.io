import 'package:flutter_test/flutter_test.dart';

import 'package:baseballbits/models/quotes_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adjacent quotes always have different authors (including wrap)', () async {
    final source = await loadQuotesFromAsset();
    expect(source.length, greaterThan(10));
    for (var trial = 0; trial < 25; trial++) {
      final shuffled = shuffleQuotesAlternatingPeople(source);
      expect(shuffled.length, greaterThan(1));
      for (var i = 0; i < shuffled.length; i++) {
        final next = shuffled[(i + 1) % shuffled.length];
        expect(
          shuffled[i].author,
          isNot(equals(next.author)),
          reason: 'trial $trial index $i (${shuffled[i].author}) next to ${next.author}',
        );
      }
      // Scenic backgrounds assigned
      expect(shuffled.every((q) => q.backgroundImage.contains('backgrounds/')), isTrue);
    }
  });
}
