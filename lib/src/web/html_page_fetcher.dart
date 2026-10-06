import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of [HtmlPageFetcher.fetch].
sealed class PageFetchOutcome {
  const PageFetchOutcome();
}

/// The page body (UTF-8, malformed bytes tolerated). [truncated] when
/// the byte cap cut it short — the head of the page is still there.
class PageFetched extends PageFetchOutcome {
  /// The page at [uri].
  const PageFetched(this.html, {required this.uri, this.truncated = false});

  /// The body as text.
  final String html;

  /// Where it was fetched from, after normalization.
  final Uri uri;

  /// Whether the byte cap cut the body short.
  final bool truncated;
}

/// Why a page did not come back.
enum PageFetchFailure {
  /// The input was not an http(s) address.
  badUrl,

  /// The connection or the body stalled past the timeout.
  timeout,

  /// DNS, connection or TLS failure.
  network,

  /// 401 or 403: the site refused the request.
  blocked,

  /// 404.
  notFound,

  /// Any other non-2xx status.
  status,
}

/// A failed fetch: the [failure] kind, the HTTP [statusCode] when there
/// was one, and the raw [detail] for logs.
class PageFetchError extends PageFetchOutcome {
  /// A failure of kind [failure].
  const PageFetchError(this.failure, {this.statusCode, this.detail = ''});

  /// What went wrong.
  final PageFetchFailure failure;

  /// The HTTP status, for status failures.
  final int? statusCode;

  /// The underlying error text, not for display.
  final String detail;
}

/// Fetches one web page straight from the device with a timeout, a
/// byte cap and typed failures. User-initiated, one request, no
/// proxy: the site sees the request as it would see any visit.
/// Extracted from Trace Elements' recipe import.
class HtmlPageFetcher {
  /// A fetcher; [client] is injectable for tests.
  HtmlPageFetcher({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.maxBytes = 3 * 1024 * 1024,
    this.userAgent = 'CodeCowboysApp/1 (+https://codecowboys.dev)',
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Connection and per-chunk read timeout.
  final Duration timeout;

  /// Body cap; the head of a longer page is kept and marked truncated.
  final int maxBytes;

  /// Sent as the User-Agent header: name the app honestly.
  final String userAgent;

  /// [input] may be a bare domain, a full URL, or text containing one.
  Future<PageFetchOutcome> fetch(String input) async {
    final uri = normalizeHttpUrl(input);
    if (uri == null) return const PageFetchError(PageFetchFailure.badUrl);

    final http.StreamedResponse response;
    try {
      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/html,application/xhtml+xml'
        ..headers['User-Agent'] = userAgent
        ..followRedirects = true
        ..maxRedirects = 5;
      response = await _client.send(request).timeout(timeout);
    } on TimeoutException {
      return const PageFetchError(PageFetchFailure.timeout);
    } on http.ClientException catch (e) {
      return PageFetchError(PageFetchFailure.network, detail: e.message);
    } catch (e) {
      return PageFetchError(PageFetchFailure.network, detail: e.toString());
    }

    final code = response.statusCode;
    if (code == 401 || code == 403) {
      return PageFetchError(PageFetchFailure.blocked, statusCode: code);
    }
    if (code == 404) {
      return PageFetchError(PageFetchFailure.notFound, statusCode: code);
    }
    if (code < 200 || code >= 300) {
      return PageFetchError(PageFetchFailure.status, statusCode: code);
    }

    final bytes = <int>[];
    var truncated = false;
    try {
      await for (final chunk in response.stream.timeout(timeout)) {
        if (bytes.length + chunk.length > maxBytes) {
          bytes.addAll(chunk.take(maxBytes - bytes.length));
          truncated = true;
          break;
        }
        bytes.addAll(chunk);
      }
    } on TimeoutException {
      return const PageFetchError(PageFetchFailure.timeout);
    } catch (e) {
      return PageFetchError(PageFetchFailure.network, detail: e.toString());
    }
    return PageFetched(
      utf8.decode(bytes, allowMalformed: true),
      uri: uri,
      truncated: truncated,
    );
  }
}

/// The first http(s) URL inside free text (share sheets send "Look at
/// this: https://…"), with trailing punctuation dropped, or null.
String? firstUrlIn(String text) {
  final m = RegExp(
    r'https?://[^\s<>"\x27]+',
    caseSensitive: false,
  ).firstMatch(text);
  if (m == null) return null;
  return m.group(0)!.replaceAll(RegExp(r'[.,;:)\]]+$'), '');
}

/// A usable http(s) [Uri] from user input: trims, pulls the first URL
/// out of surrounding text, adds `https://` to a bare domain. Null
/// when there is no dotted host or the scheme isn't http/https.
Uri? normalizeHttpUrl(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  s = firstUrlIn(s) ?? s;
  if (!RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(s)) {
    if (s.contains(' ')) return null;
    s = 'https://$s';
  }
  final uri = Uri.tryParse(s);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty || !uri.host.contains('.')) return null;
  return uri;
}
