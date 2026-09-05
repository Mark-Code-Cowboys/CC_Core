import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryKeyValueStore store;
  late LifetimeTally tally;

  setUp(() {
    store = InMemoryKeyValueStore();
    tally = LifetimeTally(store, key: 'things_created_lifetime');
  });

  tearDown(() => tally.dispose());

  test('starts at zero and counts creations', () async {
    expect(await tally.value(), 0);
    await tally.recordCreated(liveCount: 1);
    await tally.recordCreated(liveCount: 2);
    expect(await tally.value(), 2);
  });

  test('floors at the live row count for pre-tally installs', () async {
    // Install had 7 rows before the tally existed; first recorded
    // creation lands at 8, not 1.
    expect(await tally.recordCreated(liveCount: 8), 8);
    expect(await tally.value(), 8);
  });

  test('deleting rows never lowers it', () async {
    await tally.recordCreated(liveCount: 1);
    await tally.recordCreated(liveCount: 2);
    // Rows deleted; next creation has liveCount 1 but the tally moves on.
    expect(await tally.recordCreated(liveCount: 1), 3);
  });

  test('raiseTo lifts but never lowers', () async {
    await tally.recordCreated(liveCount: 1);
    expect(await tally.raiseTo(5), 5);
    expect(await tally.raiseTo(3), 5);
    expect(await tally.value(), 5);
  });

  test('watch emits the current value, then changes', () async {
    await tally.recordCreated(liveCount: 1);
    final seen = <int>[];
    final sub = tally.watch().listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    await tally.recordCreated(liveCount: 2);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(seen, [1, 2]);
  });
}
