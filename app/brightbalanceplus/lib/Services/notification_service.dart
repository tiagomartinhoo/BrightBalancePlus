import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {

  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings, onDidReceiveNotificationResponse: onSelectNotification);
  }

  Future<NotificationDetails> _notificationDetails() async {

    AndroidNotificationDetails androidPlatformChannelSpecifics =
    const AndroidNotificationDetails(
      'SCMU_NOTIFY',
      'Notifications',
      channelDescription: 'Notification when something changes',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      color: Color(0xff2196f3),
      timeoutAfter: 10000,
      actions: [
        AndroidNotificationAction(
          'accept',
          'Accept',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'decline',
          'Decline',
          showsUserInterface: true,
        ),
      ],
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    return platformChannelSpecifics;
  }

  Future<void> onSelectNotification(NotificationResponse notificationResponse) async {
    switch (notificationResponse.actionId) {
      case 'accept':
        // Notification Accepted
        break;
      case 'decline':
      // Notification Declined
        break;
      default:
      // Notification Expired
        break;
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    final platformChannelSpecifics = await _notificationDetails();
    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

}