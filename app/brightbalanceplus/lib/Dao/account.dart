import 'dart:convert';

Account accountFromJson(String str) => Account.fromJson(json.decode(str));

String accountToJson(Account data) => json.encode(data.toJson());

class Account {
  Account({
    required this.id,
    required this.email,
    required this.pw,
    required this.key,
    required this.iv
  });

  String id;
  String email;
  String pw;
  String key;
  String iv;

  factory Account.fromJson(Map<String, dynamic> json) =>
      Account(id: json["id"], email: json["email"], pw: json["password"], key: json["key"], iv: json["iv"]);

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "password": pw,
    "key": key,
    "iv": iv
  };

}