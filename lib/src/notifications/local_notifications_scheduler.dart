import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart' as flutter_timezone;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_scheduler.dart';

/// The real scheduler, wrapping flutter_local_notifications. Inexact
/// scheduling (no exact-alarm permission needed — a service reminder
/// landing minutes late is fine). One channel per app, named by the
/// constructor. Tests use [FakeReminderScheduler] instead.
class LocalNotificationsScheduler implements ReminderScheduler {
  /// Creates the scheduler; [channelId]/[channelName] identify the
  /// app's one reminder channel on Android.
  LocalNotificationsScheduler({
    required this.channelId,
    required this.channelName,
  });

  /// Android notification channel id ("backforty_reminders").
  final String channelId;

  /// Channel name shown in system settings ("Service reminders").
  final String channelName;

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final name = await flutter_timezone.FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } on Object {
      // Unknown zone: tz.local stays UTC — reminders still fire, at
      // worst offset by the zone difference.
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureReady();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    await _ensureReady();
    if (!at.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(channelId, channelName),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _ensureReady();
    await _plugin.cancel(id);
  }

  @override
  Future<void> cancelAll() async {
    await _ensureReady();
    await _plugin.cancelAll();
  }
}
