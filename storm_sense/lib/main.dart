import 'package:flutter/material.dart';
import 'package:storm_sense/app/storm_sense_app.dart';
import 'package:storm_sense/notifications/storm_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = StormNotificationService();
  await notificationService.init();

  runApp(StormSenseApp(notificationService: notificationService));
}
