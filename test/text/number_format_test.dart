import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ported from the Trace Elements donor's NumberFormatTest.kt: pins
/// half-to-even rounding so displayed values match the KMP app.
void main() {
  test('zero decimals rounds to integer', () {
    expect(1.5.toDecimalString(0), '2');
    expect(1.4.toDecimalString(0), '1');
    expect(0.0.toDecimalString(0), '0');
  });

  test('one decimal rounds to tenth', () {
    expect(1.5.toDecimalString(1), '1.5');
    expect(1.95.toDecimalString(1), '2.0');
    expect(0.1.toDecimalString(1), '0.1');
    expect(0.0.toDecimalString(1), '0.0');
  });

  test('two decimals pad short fractional parts', () {
    expect(1.5.toDecimalString(2), '1.50');
    expect(1.05.toDecimalString(2), '1.05');
    expect(1.0.toDecimalString(2), '1.00');
  });

  test('rounds half to even (banker\'s)', () {
    expect(0.5.toDecimalString(0), '0');
    expect(1.5.toDecimalString(0), '2');
    expect(2.5.toDecimalString(0), '2');
    expect(3.5.toDecimalString(0), '4');
  });

  test('rollover digits carry', () {
    expect(9.95.toDecimalString(1), '10.0');
    expect(99.5.toDecimalString(0), '100');
  });
}
