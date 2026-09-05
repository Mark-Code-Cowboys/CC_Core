import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes shouted print, leaves user casing alone', () {
    expect(titleCaseShouted('BIG PINES RV PARK'), 'Big Pines Rv Park');
    expect(titleCaseShouted('Pine Hollow Golf Club'),
        'Pine Hollow Golf Club'); // mixed case passes through
    expect(titleCaseShouted(''), '');
  });
}
