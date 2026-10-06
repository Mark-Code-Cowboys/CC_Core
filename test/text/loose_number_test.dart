import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseLooseNumber forms', () {
    expect(parseLooseNumber('1 1/2'), 1.5);
    expect(parseLooseNumber('1-1/2'), 1.5);
    expect(parseLooseNumber('1½'), 1.5);
    expect(parseLooseNumber('1 ½'), 1.5);
    expect(parseLooseNumber('¾'), 0.75);
    expect(parseLooseNumber('3/4'), 0.75);
    expect(parseLooseNumber('.5'), 0.5);
    expect(parseLooseNumber('2.25'), 2.25);
    expect(parseLooseNumber('7'), 7);
    expect(parseLooseNumber(''), isNull);
    expect(parseLooseNumber('1/0'), isNull);
    expect(parseLooseNumber('abc'), isNull);
  });
  test('firstLooseNumberIn', () {
    expect(firstLooseNumberIn('net wt 12 oz'), 12);
    expect(firstLooseNumberIn('about ½ lb'), 0.5);
    expect(firstLooseNumberIn('none'), isNull);
  });
  test('formatQuantity', () {
    expect(formatQuantity(2), '2');
    expect(formatQuantity(0.25), '¼');
    expect(formatQuantity(2.5), '2½');
    expect(formatQuantity(1.33), '1⅓');
    expect(formatQuantity(0.7), '0.7');
  });
}
