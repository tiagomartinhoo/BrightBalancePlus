import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

Room accountFromJson(String str) => Room.fromJson(json.decode(str));

String accountToJson(Room data) => json.encode(data.toJson());

class Room {
  Room({
    required this.id,
    required this.name,
    required this.profileId,
    required this.temperature,
    required this.roomPicture,
  });

  String id;
  String name;
  String profileId;
  int temperature;
  String roomPicture;

  factory Room.fromJson(Map<String, dynamic> json) =>
      Room(id: json["id"], name: json["name"], profileId: json["profileId"],
          temperature: json["temperature"], roomPicture: json["roomPicture"]);

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "profileId": profileId,
    "temperature": temperature,
    "roomPicture": roomPicture
  };

  factory Room.fromDocument(DocumentSnapshot doc) {
    return Room(
      id: doc.id,
      name: doc['name'],
      profileId: doc['profileId'],
      temperature: doc['temperature'],
      roomPicture: doc['roomPicture'],
    );
  }

}