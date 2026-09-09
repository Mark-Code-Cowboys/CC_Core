import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes shouted print, leaves user casing alone', () {
    expect(titleCaseShouted('BIG PINES RV PARK'), 'Big Pines RV Park');
    expect(titleCaseShouted('Pine Hollow Golf Club'),
        'Pine Hollow Golf Club'); // mixed case passes through
    expect(titleCaseShouted(''), '');
  });

  test('keeps acronyms shouted', () {
    expect(titleCaseShouted('BBQ BRISKET PLATE'), 'BBQ Brisket Plate');
    expect(titleCaseShouted('BLT W/ FRIES'), 'BLT W/ Fries');
    expect(titleCaseShouted('PB&J, NY STYLE'), 'PB&J, NY Style');
    expect(titleCaseShouted('HAZY IPA 16OZ'), 'Hazy IPA 16oz');
  });

  test('lowercases abbreviations of ordinary words', () {
    expect(titleCaseShouted('DR PEPPER'), 'Dr Pepper');
    expect(titleCaseShouted('MAIN ST DINER'), 'Main St Diner');
    expect(titleCaseShouted('MAC N CHEESE'), 'Mac N Cheese');
  });
}
