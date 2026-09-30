import 'location_source.dart';

/// Scripted [LocationSource] for tests and demo builds.
///
/// Hands out [results] in order and repeats the last one once the
/// script runs dry (so a single result behaves like a constant). Every
/// call is recorded in [requestedMaxAges].
class FakeLocationSource implements LocationSource {
  /// Creates a source that answers with [results] in turn.
  FakeLocationSource(List<LocationResult> results)
    : assert(results.isNotEmpty, 'Script at least one result'),
      _results = List.of(results);

  /// A source that always answers [result].
  FakeLocationSource.constant(LocationResult result) : this([result]);

  final List<LocationResult> _results;

  /// The [maxAge] of every call so far, oldest first.
  final List<Duration> requestedMaxAges = [];

  /// How many times [currentFix] has been called.
  int get callCount => requestedMaxAges.length;

  @override
  Future<LocationResult> currentFix({required Duration maxAge}) async {
    requestedMaxAges.add(maxAge);
    return _results.length > 1 ? _results.removeAt(0) : _results.first;
  }
}
