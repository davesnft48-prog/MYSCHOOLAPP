import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps flutter_local_notifications so the rest of the app can fire a
/// simple "results updated" alert without touching platform code directly.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> notifyResultsPublished({
    required String studentName,
    required String subject,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'results_channel',
      'Results Updates',
      channelDescription: 'Notifies when exam results are entered or updated',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'New Result Published',
      '$subject score has been updated for $studentName.',
      details,
    );
  }

  Future<void> notifyMassUpdate({required String className, required String subject}) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'results_channel',
      'Results Updates',
      channelDescription: 'Notifies when exam results are entered or updated',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Scores Updated',
      '$subject scores were adjusted for the whole $className class.',
      details,
    );
  }
}
