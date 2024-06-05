import 'dart:math';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../Server/api.dart';

class NotificationService {

  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings, onDidReceiveNotificationResponse: onSelectNotification);
  }

  Future<NotificationDetails> _notificationDetails(String expandedText, int channel) async {

    AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'SCMU_NOTIFY $channel',
      'Notifications',
      channelDescription: 'Notification when something changes',
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: BigTextStyleInformation(expandedText),
      playSound: true,
      color: const Color(0xff2196f3),
      timeoutAfter: 20000,
      autoCancel: false,
      actions: [
        AndroidNotificationAction(
        (!expandedText.contains("Since") ? 'yes' : 'a bit'),
          (!expandedText.contains("Since") ? 'Yes' : 'A bit'),
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          (!expandedText.contains("Since") ? 'no' : 'fully'),
          (!expandedText.contains("Since") ? 'No' : 'Fully'),
          showsUserInterface: true,
        ),
      ],
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    return platformChannelSpecifics;
  }

  Future<void> onSelectNotification(NotificationResponse notificationResponse) async {
    switch (notificationResponse.actionId) {
      case 'yes' || 'fully':
        if(notificationResponse.payload!.contains("Blinds")){
          updateBlindStatusOnDevice((notificationResponse.payload!.contains("Close Blinds") ? 0 : 100));
        }
        if(notificationResponse.payload!.contains("Fan")){
          updateFanStatusOnDevice((notificationResponse.payload!.contains("Start Fan") ? true : false));
        }
        if(notificationResponse.payload!.contains("Color")){
          updateColorOnDevice((notificationResponse.payload!.contains("Cooler Color") ? true : false));
        }
        break;
      case 'no':
      // Notification Declined
        break;
      case 'a bit':
        int number = int.parse(notificationResponse.payload!.split(" ").elementAt(2));
        Random random = Random();
        bool which = notificationResponse.payload!.contains("Close Blinds");
        int min = (which ? 0 : number + 1);
        int max = (which ? number - 1 : 100);
        int randomNumber = min + random.nextInt(max - min + 1);
        updateBlindStatusOnDevice(randomNumber);
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
    final platformChannelSpecifics = await _notificationDetails(body, id);
    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

}