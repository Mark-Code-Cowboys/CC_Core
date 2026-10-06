import 'dart:async';

import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('normalizeHttpUrl / firstUrlIn', () {
    test('forms', () {
      expect(
        normalizeHttpUrl('example.com/x').toString(),
        'https://example.com/x',
      );
      expect(
        normalizeHttpUrl('Look: https://ex.com/r?x=1. Yum').toString(),
        'https://ex.com/r?x=1',
      );
      expect(normalizeHttpUrl('ftp://x.com/a'), isNull);
      expect(normalizeHttpUrl('javascript:alert(1)'), isNull);
      expect(normalizeHttpUrl('two words'), isNull);
      expect(normalizeHttpUrl('localhost'), isNull);
      expect(firstUrlIn('(https://ex.com/a)'), 'https://ex.com/a');
      expect(firstUrlIn('none'), isNull);
    });
  });

  group('HtmlPageFetcher', () {
    test('fetched page with user agent, no body, no cookies', () async {
      http.Request? seen;
      final f = HtmlPageFetcher(
        client: MockClient((r) async {
          seen = r;
          return http.Response('<html>hi</html>', 200);
        }),
        userAgent: 'TestApp/1',
      );
      final out = await f.fetch('https://ex.com') as PageFetched;
      expect(out.html, '<html>hi</html>');
      expect(out.uri.toString(), 'https://ex.com');
      expect(out.truncated, isFalse);
      expect(seen!.headers['User-Agent'], 'TestApp/1');
      expect(seen!.body, isEmpty);
    });
    test('failures are typed', () async {
      Future<PageFetchError> err(
        http.Client c, [
        String url = 'https://ex.com',
      ]) async =>
          (await HtmlPageFetcher(
                client: c,
                timeout: const Duration(milliseconds: 50),
              ).fetch(url))
              as PageFetchError;
      expect(
        (await err(MockClient((_) async => http.Response('', 403)))).failure,
        PageFetchFailure.blocked,
      );
      expect(
        (await err(MockClient((_) async => http.Response('', 404)))).failure,
        PageFetchFailure.notFound,
      );
      expect(
        (await err(MockClient((_) async => http.Response('', 500)))).statusCode,
        500,
      );
      expect(
        (await err(
          MockClient(
            (_) async => throw http.ClientException('Failed host lookup'),
          ),
        )).failure,
        PageFetchFailure.network,
      );
      expect(
        (await err(
          MockClient((_) => Completer<http.Response>().future),
        )).failure,
        PageFetchFailure.timeout,
      );
      expect(
        (await err(
          MockClient((_) async => http.Response('', 200)),
          'not a url',
        )).failure,
        PageFetchFailure.badUrl,
      );
    });
    test('byte cap truncates and says so', () async {
      final f = HtmlPageFetcher(
        client: MockClient((_) async => http.Response('x' * 5000, 200)),
        maxBytes: 100,
      );
      final out = await f.fetch('https://ex.com') as PageFetched;
      expect(out.truncated, isTrue);
      expect(out.html.length, 100);
    });
  });
}
