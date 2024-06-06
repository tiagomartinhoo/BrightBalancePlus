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

void readingsLightListener(NotificationService notificationService, FirebaseFirestore firestore){
  List<Notification> notifications = [];
  int variableToUpdate = 0;
  firestore.collection('readingsLight').snapshots().listen((querySnapshot) async {
    for (var change in querySnapshot.docChanges) {
      if (change.type == DocumentChangeType.modified) {

        dynamic outdoor = change.doc.get("outdoor");

        int outdoorValue = getIntValue(outdoor);

        String titleText = "";
        String bodyText = "";
        String payloadText = "";

        Mood? activeMood = await getActiveMood();

        if(activeMood == null){
          return;
        }

        DocumentSnapshot blindsSnapshot = await FirebaseFirestore.instance.collection('devices').doc("blinds").get();

        int blindsValue = blindsSnapshot.get("percentage");

        if(activeMood.useBlinds){
            if (outdoorValue < 1250 && blindsValue > 0) {
              titleText = "Lighting: Getting dark outside ";
              bodyText = "Want to fully close the blinds?" ;
              payloadText = "Close Blinds ";
            } else if (outdoorValue > 1250 && blindsValue == 0) {
              titleText = "Lighting: Getting bright outside ";
              bodyText = "Want to fully open the blinds? ";
              payloadText = "Open Blinds ";
            }
        }

        if(payloadText.isNotEmpty && notifications.isEmpty && variableToUpdate == 0){
          Notification not = Notification(id: 1, title: titleText, body: bodyText, payload: payloadText);
          notifications.add(not);
        }
      }
    }

    if(notifications.isNotEmpty && variableToUpdate == 0){
      variableToUpdate++;
      Future.delayed(const Duration(seconds: 20), () {
        notifications.clear();
        variableToUpdate = 0;
      });
      for (int i = 0; i < notifications.length; i++) {
        Notification notification = notifications[i];
        await notificationService.showLocalNotification(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            payload: notification.payload);
      }
    }

  });
}

void readingsTempListener(NotificationService notificationService, FirebaseFirestore firestore){
  List<Notification> notifications = [];
  int variableToUpdate = 0;
  firestore.collection('readingsTemp').snapshots().listen((querySnapshot) async {
    for (var change in querySnapshot.docChanges) {
      if (change.type == DocumentChangeType.modified) {

        dynamic indoor = change.doc.get("indoor");

        dynamic outdoor = change.doc.get("outdoor");

        int indoorValue = getIntValue(indoor);
        int outdoorValue = getIntValue(outdoor);

        QuerySnapshot result = await FirebaseFirestore.instance.collection('rooms').where('name', isEqualTo: "Demo Room").get();

        await FirebaseFirestore.instance.collection('rooms').doc(result.docs.first.id).update({'temperature': indoorValue});

        String titleText = "";
        String bodyText = "";
        String payloadText = "";

        Mood? activeMood = await getActiveMood();

        if(activeMood == null){
          return;
        }

        if(activeMood.useBlinds){
          DocumentSnapshot blindsSnapshot = await FirebaseFirestore.instance.collection('devices').doc("blinds").get();
          int blindsValue = blindsSnapshot.get("percentage");
          if(indoorValue > 28 && indoorValue - outdoorValue >= 2 && blindsValue == 0){
            titleText = "Climate: Getting hot inside";
            bodyText = "Since it is cooler outside, want to open the blinds?";
            payloadText = "Open Blinds $blindsValue";
          }else if(outdoorValue > 28 && outdoorValue - indoorValue >= 2 && blindsValue > 0){
            titleText = "Climate: Getting hot outside";
            bodyText = "Since it is cooler inside, want to close the blinds?";
            payloadText = "Close Blinds $blindsValue";
          }
        }

        if(payloadText.isNotEmpty && notifications.isEmpty){
          Notification not = Notification(id: 1, title: titleText, body: bodyText, payload: payloadText);
          notifications.add(not);
        }

        if(activeMood.useFan){
          DocumentSnapshot fanSnapshot = await FirebaseFirestore.instance.collection('devices').doc("fan").get();
          bool fanValue = fanSnapshot.get("state");
          if(indoorValue < 25 && fanValue){
            titleText = "Climate: Getting cool inside";
            bodyText = "Want to turn off the fan?";
            payloadText = "Stop Fan ";
          }else if(indoorValue >= 25 && !fanValue){
            titleText = "Climate: Getting hot inside";
            bodyText = "Want to turn on the fan?";
            payloadText = "Start Fan ";
          }
        }

        bool flag = payloadText.contains("Fan");

        DocumentSnapshot rgbSnapshot = await FirebaseFirestore.instance.collection('devices').doc("rgb").get();

        int r = rgbSnapshot.get("red"), b = rgbSnapshot.get("blue"), g = rgbSnapshot.get("green");

        if(indoorValue < 18 && (r != 255 && g != 120 && b != 0)){
          titleText += (!flag ? "Ambience: Getting cold inside" : "");
          (!flag ? bodyText = "Want to change to a warmer color?" : bodyText = "Want to turn off the fan and change to a warmer color?");
          payloadText += "Warmer Color";
        }else if(indoorValue >= 30 && (r != 0 && g != 0 && b != 150)){
          titleText += (!flag ? "Ambience: Getting hot inside" : "");
          (!flag ? bodyText = "Want to change to a cooler color?" : bodyText = "Want to turn on the fan and change to a cooler color?");
          payloadText += "Cooler Color";
        }

        if(!payloadText.contains("Blinds") && payloadText.isNotEmpty){
          Notification not = Notification(id: 2, title: titleText, body: bodyText, payload: payloadText);
          notifications.add(not);
        }
      }
    }

    if(notifications.isNotEmpty && variableToUpdate == 0){
      variableToUpdate++;
      Future.delayed(const Duration(seconds: 20), () {
        notifications.clear();
        variableToUpdate = 0;
      });
      for (int i = 0; i < notifications.length; i++) {
        Notification notification = notifications[i];
        await notificationService.showLocalNotification(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            payload: notification.payload);
      }
    }

  });
}

void listenToFirebaseCollection(NotificationService notificationService) {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  readingsLightListener(notificationService, firestore);
  readingsTempListener(notificationService, firestore);
}