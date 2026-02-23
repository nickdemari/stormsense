import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Maps storm level integers to notification content.
/// Only levels 3 (Rain) and 4 (Stormy) fire notifications — matches the
/// `stormLevel >= 3` guard in DashboardBloc._fetchStatus.
const _stormNotifications = {
  3: (title: 'Storm Warning', body: 'Rapid pressure drop detected. Rain likely.'),
  4: (title: 'Severe Storm Alert', body: 'Severe pressure drop! Storm approaching — take precautions.'),
};

/// Notification channel ID used for all storm-related alerts on Android.
const _channelId = 'storm_alerts';
const _channelName = 'Storm Alerts';

class StormNotificationService {
  StormNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Initializes the notification plugin with platform-specific settings
  /// and creates the Android notification channel.
  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    // Create the Android notification channel with high importance.
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
        ),
      );
    }
  }

  /// Returns whether notifications are currently enabled.
  ///
  /// On Android, checks the system notification setting.
  /// On iOS/macOS, returns true (permission is requested at init).
  Future<bool> areNotificationsEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Requests notification permission (Android 13+ only).
  ///
  /// Returns true if granted, false otherwise. On iOS this is a no-op
  /// because permission is requested during [init].
  Future<bool> requestNotificationPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  /// Shows a storm alert notification for the given [level].
  ///
  /// Level 0 (clear) is a no-op. Levels 1-3 map to increasingly
  /// urgent notifications via [_stormNotifications].
  Future<void> showStormAlert(int level) async {
    final content = _stormNotifications[level];
    if (content == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      level,
      content.title,
      content.body,
      details,
    );
  }
}
