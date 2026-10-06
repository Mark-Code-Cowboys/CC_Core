import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

const _page = '''
<html><head>
<script type="application/ld+json">{"@type":"BreadcrumbList","itemListElement":[]}</script>
<script type='application/ld+json'>
<![CDATA[
{"@context":"https://schema.org","@graph":[{"@type":"WebPage"},{"@type":["Recipe","NewsArticle"],"name":"Tab	bed"}]}
]]>
</script>
<script>var notLd = {"@type":"Recipe"};</script>
</head></html>''';

void main() {
  test(
    'blocks are extracted in order, CDATA stripped, other scripts ignored',
    () {
      final blocks = extractJsonLdBlocks(_page);
      expect(blocks.length, 2);
      expect(blocks[1], isNot(contains('CDATA')));
    },
  );
  test('lenient decode and typed search across @graph and arrays', () {
    expect(decodeJsonLdBlock('{"a": "tab\there"}'), {'a': 'tab here'});
    expect(decodeJsonLdBlock('nope'), isNull);
    final recipe = firstJsonLdObject(_page, 'Recipe');
    expect(recipe!['name'], 'Tab bed');
    expect(
      findJsonLdObjects({
        '@type': 'http://schema.org/Product',
        'name': 'x',
      }, 'Product').length,
      1,
    );
    expect(
      findJsonLdObjects({
        '@type': 'WebPage',
        'mainEntity': {'@type': 'schema:Product'},
      }, 'product').length,
      1,
    );
    expect(findJsonLdObjects({'@type': 'Thing'}, 'Product'), isEmpty);
  });
  test('parseIsoDuration', () {
    expect(parseIsoDuration('PT1H30M'), const Duration(minutes: 90));
    expect(parseIsoDuration('P0DT0H30M'), const Duration(minutes: 30));
    expect(parseIsoDuration('PT90S'), const Duration(minutes: 2));
    expect(parseIsoDuration('1 hour 30 minutes'), const Duration(minutes: 90));
    expect(parseIsoDuration('PT0M'), isNull);
    expect(parseIsoDuration('overnight'), isNull);
    expect(parseIsoDuration(null), isNull);
  });
}
