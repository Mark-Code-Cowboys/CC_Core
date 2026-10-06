import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('entities: named, decimal, hex, unknown', () {
    expect(
      unescapeHtml('a &amp; b &lt;c&gt; &frac12; &#189; &#xBD; &bogus;'),
      'a & b <c> ½ ½ ½ &bogus;',
    );
    expect(unescapeHtml('plain'), 'plain');
  });
  test('stripHtml keeps block breaks as lines; inline flattens', () {
    expect(stripHtml('<p>One</p><p>Two<br>Three</p>'), 'One\nTwo\nThree');
    expect(stripHtmlInline('<p>One</p><p>Two</p>'), 'One Two');
    expect(
      stripHtmlInline('Powered by <a href="x">Google</a>'),
      'Powered by Google',
    );
  });
}
