import 'dart:convert';

Mood accountFromJson(String str) => Mood.fromJson(json.decode(str));

String accountToJson(Mood data) => json.encode(data.toJson());

class Mood {
  Mood({
    required this.id,
    required this.name,
    required this.roomId,
    required this.lightColor,
    required this.isActive,
    required this.useFan,
    required this.blindsRotation,
  });

  String id;
  String name;
  String roomId;
  List<dynamic> lightColor;
  bool isActive;
  bool useFan;
  int blindsRotation;

  factory Mood.fromJson(Map<String, dynamic> json) => Mood(
      id: json["id"],
      name: json["name"],
      roomId: json["roomId"],
      lightColor: json["lightColor"],
      isActive: json["isActive"],
      useFan: json["useFan"],
      blindsRotation: json["blindsRotation"]);

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "roomId": roomId,
        "lightColor": lightColor,
        "isActive": isActive,
        "useFan": useFan,
        "blindsRotation": blindsRotation
      };
}
