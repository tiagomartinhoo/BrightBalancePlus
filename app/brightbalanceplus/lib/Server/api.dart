import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';

import '../Dao/profile.dart';
import '../Dao/room.dart';

Future<List<Profile>> getProfilesByAccountId(String accountId) async {
  QuerySnapshot result = await FirebaseFirestore.instance
      .collection('profiles')
      .where('accountId', isEqualTo: accountId)
      .get();

  return result.docs.map((doc) => Profile.fromDocument(doc)).toList();
}

Future<List<Room>> getRoomsByProfileIds(List<String> profileIds) async {
  QuerySnapshot result = await FirebaseFirestore.instance
      .collection('rooms')
      .where('profileId', whereIn: profileIds)
      .get();

  return result.docs.map((doc) => Room.fromDocument(doc)).toList();
}

Future<List<Room>> getRooms(String profileId) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentSnapshot profile = await firestore.collection('profiles').doc(profileId).get();
  String accountId = profile.get("accountId");

  List<Profile> profiles = await getProfilesByAccountId(accountId);
  List<String> profileIds = profiles.map((profile) => profile.id).toList();

  List<Room> rooms = await getRoomsByProfileIds(profileIds);

  Room room = Room(id: "AddProfile", name: "Add Room", profileId: "None", roomPicture: "add", temperature: 0);
  rooms.add(room);

  return rooms;

}

Future<int> getActiveMoodBlindsValue() async {
  final box = GetStorage();
  String userEmail = box.read('email');

  QuerySnapshot result = await FirebaseFirestore.instance
      .collection('accounts')
      .where('email', isEqualTo: userEmail)
      .get();

  String accountId = result.docs.first.id;

  List<Profile> profiles = await getProfilesByAccountId(accountId);
  List<String> profileIds = profiles.map((profile) => profile.id).toList();

  List<Room> rooms = await getRoomsByProfileIds(profileIds);

  for (Room room in rooms) {
    result = await FirebaseFirestore.instance
        .collection('moods')
        .where('roomId', isEqualTo: room.id)
        .get();

    final List<DocumentSnapshot> documents = result.docs.toList();
    for (var element in documents) {
      if(element.get("isActive") == true){
        return element.get("blindsRotation");
      }
    }

  }

  return -1;

}