import 'dart:async';

import 'package:brightbalanceplus/Dao/notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Dao/mood.dart';
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

int getIntValue(dynamic value){
  int resValue;
  if (value is double) {
    resValue = value.toInt();
  } else if (value is int) {
    resValue = value;
  } else {
    resValue = 0;
  }

  return resValue;
}

void listenToFirebaseCollection(NotificationService notificationService) {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Timer? timer;
  int variableToUpdate = 0, finishLine = 0;
  List<Notification> notifications = [];
  firestore.collection('readings').snapshots().listen((querySnapshot) async {
    for (var change in querySnapshot.docChanges) {
      if (change.type == DocumentChangeType.modified && finishLine == 0) {
        finishLine++;

        dynamic indoor = change.doc.get("indoor");

        dynamic outdoor = change.doc.get("outdoor");

        int indoorValue = getIntValue(indoor);
        int outdoorValue = getIntValue(outdoor);

        String titleText = "";
        String bodyText = "";
        String payloadText = "";

        Mood? activeMood = await getActiveMood();

        if(activeMood == null){
          return;
        }

        DocumentSnapshot blindsSnapshot = await FirebaseFirestore.instance.collection('devices').doc("blinds").get();
        DocumentSnapshot fanSnapshot = await FirebaseFirestore.instance.collection('devices').doc("fan").get();

        int blindsValue = blindsSnapshot.get("percentage");
        bool fanValue = fanSnapshot.get("state");

        if(activeMood.useBlinds){
          if (outdoorValue < 30 && blindsValue > 0) {
            titleText = "It is getting dark outside. ";
            bodyText = "Want to fully close the blinds?" ;
            payloadText = "Close Blinds ";
          } else if (outdoorValue > 60 && blindsValue < 100) {
            titleText = "It is getting bright outside. ";
            bodyText = "Want to fully open the blinds? ";
            payloadText = "Open Blinds ";
          } else if (change.doc.id.contains("temperature")){
            if(indoorValue > 28 && indoorValue - outdoorValue >= 2 && blindsValue < 100){
              titleText = "It is getting hot inside.";
              bodyText = "Since it is colder outside, want to open the blinds?";
              payloadText = "Open Blinds $blindsValue";
            }else if(outdoorValue > 28 && outdoorValue - indoorValue >= 2 && blindsValue > 0){
              titleText = "It is getting hot outside.";
              bodyText = "Since it is colder inside, want to close the blinds?";
              payloadText = "Close Blinds $blindsValue";
            }
          }
        }

        if(payloadText.isNotEmpty){
          Notification not = Notification(title: titleText, body: bodyText, payload: payloadText);
          notifications.add(not);
        }

        if(activeMood.useFan && change.doc.id.contains("temperature")){
          if(indoorValue < 25 && fanValue){
            titleText = "It is getting cold inside.";
            bodyText = "Want to turn off the fan?";
            payloadText = "Stop Fan ";
          }else if(indoorValue >= 25 && !fanValue){
            titleText = "It is getting hot inside.";
            bodyText = "Want to turn on the fan?";
            payloadText = "Start Fan ";
          }
        }

        bool flag = payloadText.contains("Fan");

        if(change.doc.id.contains("temperature")){
          if(indoorValue < 18){
            titleText += (!flag ? "It is getting cold inside." : "");
            (!flag ? bodyText = "Want to change to a warmer color?" : bodyText = "Want to turn off the fan and change to a warmer color?");
            payloadText += "Warmer Color";
          }else if(indoorValue >= 30){
            titleText += (!flag ? "It is getting hot inside." : "");
            (!flag ? bodyText = "Want to change to a cooler color?" : bodyText = "Want to turn on the fan and change to a cooler color?");
            payloadText += "Cooler Color";
          }
        }

        try {
          if(variableToUpdate == 0){
            variableToUpdate++;
            if(!payloadText.contains("Blinds")){
              Notification not = Notification(title: titleText, body: bodyText, payload: payloadText);
              notifications.add(not);
            }

            for (int i = 0; i < notifications.length; i++) {
              Notification notification = notifications[i];
              await notificationService.showLocalNotification(
                  id: i + 1,
                  title: notification.title,
                  body: notification.body,
                  payload: notification.payload);
            }

            notifications.clear();

          }
        } catch (e) {
          print("Error showing local notification: $e");
        };

        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 30), (timer) {
          variableToUpdate = 0;
          finishLine = 0;
        });

      }
    }
  });
}