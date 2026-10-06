import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('readSafeText: null, numbers, caps, markup, script', () {
    expect(readSafeText(null, 'f'), isNull);
    expect(readSafeText('  ', 'f'), isNull);
    expect(readSafeText(4, 'f'), '4');
    expect(readSafeText('<b>Bold</b> &amp; plain', 'f'), 'Bold & plain');
    expect(
      () => readSafeText('x' * 501, 'name'),
      throwsA(
        predicate(
          (e) =>
              e is SafeJsonException &&
              e.message.contains('"name"') &&
              e.message.contains('too long'),
        ),
      ),
    );
    expect(
      () => readSafeText('<script>alert(1)</script>', 'f'),
      throwsA(isA<SafeJsonException>()),
    );
    expect(
      () => readSafeText('<img src=x onerror=alert(1)>', 'f'),
      throwsA(isA<SafeJsonException>()),
    );
    expect(() => readSafeText(['a'], 'f'), throwsA(isA<SafeJsonException>()));
  });
  test('readSafeNumber', () {
    expect(readSafeNumber(null, 'n', max: 10), isNull);
    expect(readSafeNumber(3, 'n', max: 10), 3);
    expect(
      () => readSafeNumber(-1, 'n', max: 10),
      throwsA(isA<SafeJsonException>()),
    );
    expect(
      () => readSafeNumber(11, 'n', max: 10),
      throwsA(isA<SafeJsonException>()),
    );
    expect(
      () => readSafeNumber(double.nan, 'n', max: 10),
      throwsA(isA<SafeJsonException>()),
    );
    expect(
      () => readSafeNumber('3', 'n', max: 10),
      throwsA(isA<SafeJsonException>()),
    );
  });
  test('readSafeHttpUrl', () {
    expect(readSafeHttpUrl('https://ex.com/a', 'u'), 'https://ex.com/a');
    expect(readSafeHttpUrl(null, 'u'), isNull);
    expect(
      () => readSafeHttpUrl('javascript:alert(1)', 'u'),
      throwsA(isA<SafeJsonException>()),
    );
    expect(
      () => readSafeHttpUrl('ftp://x', 'u'),
      throwsA(isA<SafeJsonException>()),
    );
  });
  test('safeFileName', () {
    expect(safeFileName('../../etc/passwd'), 'passwd');
    expect(safeFileName('a b/c?.png'), 'c_.png');
    expect(safeFileName('..'), 'file');
    expect(safeFileName('', fallback: 'page'), 'page');
  });
}
