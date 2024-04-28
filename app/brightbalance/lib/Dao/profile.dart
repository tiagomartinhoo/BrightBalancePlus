import 'dart:convert';

Profile accountFromJson(String str) => Profile.fromJson(json.decode(str));

String accountToJson(Profile data) => json.encode(data.toJson());

class Profile {
  Profile({
    required this.id,
    required this.name,
    required this.priority,
    required this.accountId,
    required this.profilePicture,
  });

  String id;
  String name;
  int priority;
  String accountId;
  String profilePicture;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      Profile(id: json["id"], name: json["name"], priority: json["priority"], accountId: json["accountId"], profilePicture: json["profilePicture"]);

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "priority": priority,
    "accountId": accountId,
    "profilePicture": profilePicture
  };

}