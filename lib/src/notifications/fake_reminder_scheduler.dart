import 'reminder_scheduler.dart';

/// One scheduled reminder, for assertions.
typedef ScheduledReminder = ({int id, String title, String body, DateTime at});

/// In-memory scheduler for tests and widget previews.
class FakeReminderScheduler implements ReminderScheduler {
  /// Creates the fake; [permissionGranted] is what [requestPermission]
  /// reports.
  FakeReminderScheduler({this.permissionGranted = true});

  /// Whether the fake "user" grants permission.
  final bool permissionGranted;

  /// Live reminders by id (schedule replaces, cancel removes).
  final Map<int, ScheduledReminder> scheduled = <int, ScheduledReminder>{};

  /// Every requestPermission call, for assertions.
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    scheduled[id] = (id: id, title: title, body: body, at: at);
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    scheduled.clear();
  }
}
