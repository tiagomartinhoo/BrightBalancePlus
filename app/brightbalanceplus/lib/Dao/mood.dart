import 'dart:convert';

Mood accountFromJson(String str) => Mood.fromJson(json.decode(str));

String accountToJson(Mood data) => json.encode(data.toJson());

class Mood {
  Mood({
    required this.id,
    required this.name,
    required this.roomId,
    required this.lightColor,
    required this.blindsRotation,
    required this.isActive,
    required this.useFan,
    required this.useBlinds,
  });

  String id;
  String name;
  String roomId;
  List<dynamic> lightColor;
  int blindsRotation;
  bool isActive;
  bool useFan;
  bool useBlinds;

  factory Mood.fromJson(Map<String, dynamic> json) => Mood(
      id: json["id"],
      name: json["name"],
      roomId: json["roomId"],
      lightColor: json["lightColor"],
      blindsRotation: json["blindsRotation"],
      isActive: json["isActive"],
      useFan: json["useFan"],
      useBlinds: json["useBlinds"]);

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "roomId": roomId,
        "lightColor": lightColor,
        "blindsRotation": blindsRotation,
        "isActive": isActive,
        "useFan": useFan,
        "useBlinds": useBlinds
      };
}
