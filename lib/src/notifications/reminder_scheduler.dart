/// The local-reminder seam: schedule a notification for a moment,
/// cancel by id, wipe the slate. Local only — nothing here (or in any
/// impl) may touch the network; a reminder is the device talking to
/// its own future self.
abstract class ReminderScheduler {
  /// Asks the OS for notification permission; true when granted (or
  /// already held). Call from a user gesture, not app start.
  Future<bool> requestPermission();

  /// Schedules (or replaces, same [id]) one notification for [at].
  /// A past [at] is the caller's bug; impls may ignore it.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  });

  /// Cancels the notification with [id]; unknown ids are a no-op.
  Future<void> cancel(int id);

  /// Cancels everything this app scheduled.
  Future<void> cancelAll();
}
