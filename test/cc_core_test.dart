// Smoke test: the barrel file and every module export must resolve.
// ignore: unused_import
import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cc_core library resolves', () {
    expect(true, isTrue);
  });
}
