import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schedule replaces by id, cancel removes, cancelAll wipes',
      () async {
    final fake = FakeReminderScheduler();
    await fake.schedule(
        id: 1, title: 'T', body: 'first', at: DateTime(2026, 10, 1));
    await fake.schedule(
        id: 1, title: 'T', body: 'replaced', at: DateTime(2026, 11, 1));
    await fake.schedule(
        id: 2, title: 'T', body: 'other', at: DateTime(2026, 10, 2));
    expect(fake.scheduled, hasLength(2));
    expect(fake.scheduled[1]!.body, 'replaced');

    await fake.cancel(1);
    expect(fake.scheduled.keys, [2]);
    await fake.cancel(99); // unknown: no-op
    await fake.cancelAll();
    expect(fake.scheduled, isEmpty);

    expect(await fake.requestPermission(), isTrue);
    expect(fake.permissionRequests, 1);
  });
}
