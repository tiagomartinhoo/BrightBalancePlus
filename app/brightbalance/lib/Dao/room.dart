import 'dart:convert';

Room accountFromJson(String str) => Room.fromJson(json.decode(str));

String accountToJson(Room data) => json.encode(data.toJson());

class Room {
  Room({
    required this.id,
    required this.name,
    required this.profileId,
    required this.temperature,
    required this.numberOfPeople,
    required this.roomPicture,
  });

  String id;
  String name;
  String profileId;
  int temperature;
  int numberOfPeople;
  String roomPicture;

  factory Room.fromJson(Map<String, dynamic> json) =>
      Room(id: json["id"], name: json["name"], profileId: json["profileId"],
          temperature: json["temperature"], numberOfPeople: json["numberOfPeople"], roomPicture: json["roomPicture"]);

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "profileId": profileId,
    "temperature": temperature,
    "numberOfPeople": numberOfPeople,
    "roomPicture": roomPicture
  };

}