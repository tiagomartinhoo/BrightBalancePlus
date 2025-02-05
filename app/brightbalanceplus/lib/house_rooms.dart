import 'dart:async';

import 'package:flutter/material.dart';

import 'Dao/room.dart';
import 'Server/api.dart';

class HouseRooms extends StatefulWidget {
  final String data;

  const HouseRooms({super.key, required this.data});

  @override
  State<HouseRooms> createState() => _HouseRoomsState();
}

class _HouseRoomsState extends State<HouseRooms> {

  late Future<List<Room>> roomsFuture;
  bool editRooms = false;

  Timer? timer;
  List<Room>? currentRooms;

  @override
  void initState() {
    super.initState();
    roomsFuture = getRooms(widget.data);
    timer = Timer.periodic(const Duration(seconds: 30), (Timer t) => _checkForUpdates());
  }

  Future<void> _checkForUpdates() async {
    List<Room> updatedRooms = await getRooms(widget.data);
    if (currentRooms == null || _hasTemperatureChanged(currentRooms!, updatedRooms)) {
      setState(() {
        currentRooms = updatedRooms;
      });
    }
  }

  bool _hasTemperatureChanged(List<Room> oldRooms, List<Room> newRooms) {
    if (oldRooms.length != newRooms.length) return true;
    for (int i = 0; i < oldRooms.length; i++) {
      if (oldRooms[i].temperature != newRooms[i].temperature) {
        return true;
      }
    }
    return false;
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      color: Colors.white,
                    );
                  } else if (snapshot.hasData){
                    final rooms = currentRooms ?? snapshot.data!;
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
                  if(!editRooms){
                    Navigator.of(context).pushNamed('/profile_room_preferences', arguments: room);
                  }else{
                    Navigator.of(context).pushNamed('/edit_room', arguments: room);
                  }

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
      if(rooms.length > 50)
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