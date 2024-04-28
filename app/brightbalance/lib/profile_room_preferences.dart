import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'Dao/mood.dart';
import 'Dao/room.dart';

class ProfileRoomPreferences extends StatefulWidget {
  final Room data;

  const ProfileRoomPreferences({Key? key, required this.data})
      : super(key: key);

  @override
  State<ProfileRoomPreferences> createState() => _ProfileRoomPreferencesState();
}

class _ProfileRoomPreferencesState extends State<ProfileRoomPreferences> {
  String dropdownColorValue = '';

  late Mood activeMood;

  List<String> lightColors = ["Blue", "Red", "Green", "Yellow"];

  late Room room;

  int moodIndex = 0;

  bool useFan = false;
  bool useBlinds = false;

  double startValue = 0;
  double endValue = 100;

  late Future<List<Mood>> moodsFuture;

  bool editRooms = false;

  @override
  void initState() {
    super.initState();
    room = widget.data;
    moodsFuture = getMoods(room);
  }

  static Future<List<Mood>> getMoods(Room data) async {
    QuerySnapshot result = await FirebaseFirestore.instance
        .collection('moods')
        .where('roomId', isEqualTo: data.id)
        .get();
    final List<DocumentSnapshot> documents = result.docs.toList();
    List<Mood> moodsList = [];
    for (var element in documents) {
      Mood profile = Mood(
          id: element.id,
          name: element.get("name"),
          lightColor: element.get("lightColor"),
          intensityMin: element.get("intensityMin"),
          intensityMax: element.get("intensityMax"),
          isActive: element.get("isActive"),
          useFan: element.get("useFan"),
          useBlinds: element.get("useBlinds"),
          roomId: element.id);

      moodsList.add(profile);
    }

    Mood profile = Mood(
        id: "add Mood",
        name: "Add Mood",
        lightColor: "Green",
        intensityMin: 0,
        intensityMax: 100,
        isActive: false,
        useFan: false,
        useBlinds: false,
        roomId: "addMood");

    moodsList.add(profile);

    return moodsList;
  }

  final ButtonStyle flatButtonStyle = TextButton.styleFrom(
    foregroundColor: Colors.white,
    minimumSize: const Size(100, 40),
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
        title: const Text("Preferences"),
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<List<Mood>>(
            future: moodsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData) {
                final moods = snapshot.data!;
                activeMood = moods[moodIndex];
                return buildMoods(moods);
              } else {
                return const Text("No moods data");
              }
            }),
      ),
    );
  }

  Widget buildMoods(List<Mood> moods) =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(
          height: 30,
        ),
        Center(
          child: Switch(
            activeColor: Colors.grey,
            activeTrackColor: Colors.greenAccent,
            inactiveThumbColor: Colors.blueGrey.shade600,
            inactiveTrackColor: Colors.grey.shade400,
            splashRadius: 10.0,
            value: activeMood.isActive,
            onChanged: (value) => setState(() => activeMood.isActive = value),
          ),
        ),
        Text(room.name),
        Image.asset(
          'assets/images/${room.roomPicture}.png',
          width: 150,
        ),
        const SizedBox(
          height: 30,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Mood"),
            const SizedBox(width: 50),
            DropdownButton<Mood>(
              value: activeMood,
              items: moods.map((Mood mood) {
                return DropdownMenuItem<Mood>(
                  value: mood,
                  child: Text(mood.name),
                );
              }).toList(),
              onChanged: (Mood? newValue) {
                setState(() {
                  activeMood = newValue!;
                  moodIndex = moods.indexOf(activeMood);
                });
              },
            )
          ],
        ),
        const SizedBox(
          height: 50,
        ),
        const Text("Preferences"),
        const SizedBox(
          height: 25,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Light Color"),
            const SizedBox(width: 50),
            DropdownButton<String>(
              value: activeMood.lightColor,
              items: lightColors.map((String color) {
                return DropdownMenuItem<String>(
                  value: color,
                  child: Text(color),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  activeMood.lightColor = newValue!;
                });
              },
            )
          ],
        ),
        const SizedBox(
          height: 25,
        ),
        const Text("Intensity"),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Min"),
            RangeSlider(
              min: 0.0,
              max: 100.0,
              values: RangeValues(activeMood.intensityMin.toDouble(),
                  activeMood.intensityMax.toDouble()),
              onChanged: (values) {
                setState(() {
                  activeMood.intensityMin = values.start.floor();
                  activeMood.intensityMax = values.end.ceil();
                });
              },
            ),
            const Text("Max"),
          ],
        ),
        const SizedBox(
          height: 25,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Fan"),
            SizedBox(
              width: 30,
              height: 25,
              child: Checkbox(
                value: activeMood.useFan,
                onChanged: (newValue) {
                  setState(() {
                    activeMood.useFan = newValue!;
                  });
                },
              ),
            ),
            const SizedBox(
              width: 50,
            ),
            const Text("Blinds"),
            SizedBox(
              width: 30,
              height: 25,
              child: Checkbox(
                value: activeMood.useBlinds,
                onChanged: (newValue) {
                  setState(() {
                    activeMood.useBlinds = newValue!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(
            style: flatButtonStyle,
            onPressed: () async {},
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(
            width: 50,
          ),
          ElevatedButton(
            style: flatButtonStyle,
            onPressed: () async {},
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ]),
      ]);
}
