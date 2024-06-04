import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Server/api.dart';
import '../Services/notification_service.dart';

Future<void> requestNotificationPermission() async {
  // Request notification permission
  var status = await Permission.notification.request();
  if (status.isGranted) {
    // Permission granted, you can now proceed to show notifications
    final notificationService = NotificationService();
    await notificationService.initialize();
    listenToFirebaseCollection(notificationService);
  } else if (status.isDenied) {
    // Permission denied, you can prompt the user to manually enable it
  } else if (status.isPermanentlyDenied) {
    // Permission permanently denied, open app settings so user can enable it
    openAppSettings();
  }
}

void listenToFirebaseCollection(NotificationService notificationService) {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Timer? timer;
  int variableToUpdate = 0;
  firestore.collection('readings').snapshots().listen((querySnapshot) async {
    for (var change in querySnapshot.docChanges) {
      if (change.type == DocumentChangeType.modified) {

        int value = change.doc.get("outdoor");

        String titleText = "Title";
        String bodyText = "Body";

        switch (value) {
          case < 35:
            titleText = "It is getting dark outside.";
            bodyText = "Want to close the blinds?";
            break;
          case > 60:
            // Maybe Open
            break;
          default:
          // Do something or not
        }

        try {
          // Display the in-app notification
          if(variableToUpdate == 0 && await getActiveMoodBlindsValue() > 0){
            variableToUpdate++;
            notificationService.showLocalNotification(
                id: 1,
                title: titleText,
                body: bodyText,
                payload: "Time to close the blinds?");
          }

          timer?.cancel();
          timer = Timer.periodic(const Duration(seconds: 5), (timer) {
            variableToUpdate = 0;
          });
        } catch (e) {
          // Handle any errors
          print("Error showing local notification: $e");
        }
      }
    }
  });
}