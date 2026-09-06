import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one tile and one name per continent, codes agreeing', () {
    expect(continentTiles, hasLength(7));
    expect(continentNames.keys.toSet(),
        {for (final t in continentTiles) t.code});
  });
}
