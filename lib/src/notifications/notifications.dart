/// notifications module of cc_core: the local-reminder seam
/// (ReminderScheduler), the flutter_local_notifications impl, and the
/// fake. Local only — a reminder is the device talking to its own
/// future self; nothing here touches the network. Proposed and
/// approved for Back Forty's service intervals.
library;

export 'fake_reminder_scheduler.dart';
export 'local_notifications_scheduler.dart';
export 'reminder_scheduler.dart';
