import 'package:brightbalance/Dao/room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HouseRooms extends StatefulWidget {
  final String data;

  const HouseRooms({Key? key, required this.data}) : super(key: key);

  @override
  State<HouseRooms> createState() => _HouseRoomsState();
}

class _HouseRoomsState extends State<HouseRooms> {

  late Future<List<Room>> roomsFuture;

  bool editRooms = false;

  @override
  void initState() {
    super.initState();
    roomsFuture = getRooms(widget.data);
  }

  static Future<List<Room>> getRooms(String profileId) async {
    QuerySnapshot result = await FirebaseFirestore.instance.collection('rooms').where('profileId', isEqualTo: profileId).get();
    final List<DocumentSnapshot> documents = result.docs.toList();
    List<Room> roomsList = <Room>[];
    for (var element in documents) {
      Room room = Room(id: element.id, name: element.get("name"), profileId: element.get("profileId"),
          roomPicture: element.get("roomPicture"), temperature: element.get("temperature"), numberOfPeople: element.get("numberOfPeople"));
      roomsList.add(room);
    }

    Room room = Room(id: "AddProfile", name: "Add Room", profileId: "None", roomPicture: "addprofile", temperature: 0, numberOfPeople: 0);
    roomsList.add(room);

    return roomsList;
  }

  final ButtonStyle flatButtonStyle = TextButton.styleFrom(
    foregroundColor: Colors.white,
    minimumSize: const Size(250, 50),
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20.0)),
    ),
    backgroundColor: Colors.blue,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rooms"),
      ),
      body: Column(
          children: [
            const SizedBox(
              height: 60,
            ),
            FutureBuilder<List<Room>>(
                future: roomsFuture,
                builder: (context, snapshot){
                  if (snapshot.hasData){
                    final rooms = snapshot.data!;

                    return buildRooms(rooms);
                  }else{
                    return const Text("No rooms data");
                  }
                }
            ),
          ],
        ),
    );
  }

  Widget buildRooms(List<Room> rooms) =>  Column(
    children: [
      SizedBox(
    height: 450,
    child: GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.0,
      mainAxisSpacing: 25.0,
      scrollDirection: Axis.vertical,
      children: List.generate(rooms.length, (index) {
        final room = rooms[index];
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: InkWell(
              splashColor: Colors.blue.withAlpha(30),
              onTap: () {
                if (room.profileId == "None") {
                  Navigator.of(context).pushNamed('/create_room', arguments: widget.data);
                } else {
                  Navigator.of(context).pushNamed('/profile_room_preferences', arguments: room);
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Image.asset(
                      'assets/images/${room.roomPicture}.png',
                      width: room.profileId == "None" ? 75 : 150,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if(room.profileId != "None")
                  Text("${room.temperature} ºC",
                      style: TextStyle(fontSize: 12,
                          color: room.temperature < 11 ? Colors.cyan : room.temperature < 31 ? Colors.orange : Colors.red)),
                  const SizedBox(height: 10),
                  Text(room.name),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if(room.profileId != "None")
                        Image.asset(
                          'assets/images/user.png',
                          width: 10,
                        ),
                      const SizedBox(width: 5),
                      if(room.profileId != "None")
                        Text(room.numberOfPeople.toString(), style: const TextStyle(fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }),
    ),
  ),
      const SizedBox(
        height: 50,
      ),
      SizedBox(
        width: 200,
        height: 50,
        child: CheckboxListTile(
          title: const Text("Edit Rooms"),
          value: editRooms,
          onChanged: (newValue) {
            setState(() {
              editRooms = newValue!;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
  ],
  );

}