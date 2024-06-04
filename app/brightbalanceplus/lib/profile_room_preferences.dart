import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get_storage/get_storage.dart';

import 'Dao/mood.dart';
import 'Dao/room.dart';

class ProfileRoomPreferences extends StatefulWidget {
  final Room data;

  const ProfileRoomPreferences({super.key, required this.data});

  @override
  State<ProfileRoomPreferences> createState() => _ProfileRoomPreferencesState();
}

class _ProfileRoomPreferencesState extends State<ProfileRoomPreferences> {
  String dropdownColorValue = '';

  late Mood activeMood;

  late Room room;

  int moodIndex = 0;

  double sliderValue = 0.0;

  late Future<List<Mood>> moodsFuture;

  Color pickerColor = const Color(0xff443a49);
  Color currentColor = const Color(0xff443a49);

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  void initState() {
    super.initState();
    room = widget.data;
    moodsFuture = getMoods(room);
  }

  Color convertRGBToColor(int red, int green, int blue) {
    return Color(0xff000000 + (red << 16) + (green << 8) + blue);
  }

  Future<List<Mood>> getMoods(Room data) async {
    QuerySnapshot result = await FirebaseFirestore.instance
        .collection('moods')
        .where('roomId', isEqualTo: data.id)
        .get();
    final List<DocumentSnapshot> documents = result.docs.toList();
    List<Mood> moodsList = [];
    for (var element in documents) {
      Mood mood = Mood(
          id: element.id,
          name: element.get("name"),
          lightColor: element.get("lightColor"),
          isActive: element.get("isActive"),
          useFan: element.get("useFan"),
          blindsRotation: element.get("blindsRotation"),
          roomId: element.id);

      if (moodsList.isEmpty) {
        activeMood = mood;
        Color convertedColor = convertRGBToColor(mood.lightColor[0], mood.lightColor[1], mood.lightColor[2]);
        currentColor = convertedColor;
        sliderValue = activeMood.blindsRotation.toDouble();
      }

      moodsList.add(mood);
    }

    Mood mood = Mood(
        id: "add Mood",
        name: "Add Mood",
        lightColor: [255, 255, 255],
        isActive: false,
        useFan: false,
        blindsRotation: 0,
        roomId: "addMood");

    moodsList.add(mood);

    return moodsList;
  }

  Future<bool> updateActiveMood(bool active) async {
    QuerySnapshot result = await FirebaseFirestore.instance
        .collection('moods')
        .where('roomId', isEqualTo: room.id)
        .get();

    final List<DocumentSnapshot> documents = result.docs.toList();
    for (var doc in documents) {
      if (doc.get("isActive")) {
        await FirebaseFirestore.instance
            .collection('moods')
            .doc(doc.id)
            .update({'isActive': false});
        List<Mood> moods = await moodsFuture;
        int index = moods.indexWhere((mood) => mood.id == doc.id);
        moods[index].isActive = false;
      }
    }

    result = await FirebaseFirestore.instance
        .collection('moods')
        .where('roomId', isEqualTo: room.id)
        .where('name', isEqualTo: activeMood.name)
        .get();

    if (result.docs.isNotEmpty) {
      DocumentSnapshot doc = result.docs.first;

      await FirebaseFirestore.instance
          .collection('moods')
          .doc(doc.id)
          .update({'isActive': active});

      return true;
    }

    return false;
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

  void showInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String inputText = '';
        return AlertDialog(
          title: const Text('Enter mood name'),
          content: TextField(
            onChanged: (value) {
              setState(() {
                inputText = value;
              });
            },
            decoration: const InputDecoration(hintText: "Enter name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  activeMood.name = inputText;
                  currentColor = convertRGBToColor(activeMood.lightColor[0],
                      activeMood.lightColor[1], activeMood.lightColor[2]);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> updateMoodPreferences(int red, int green, int blue) async {
    if (!activeMood.roomId.contains("addMood")) {
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('moods')
          .where('roomId', isEqualTo: room.id)
          .where('name', isEqualTo: activeMood.name)
          .get();

      if (result.docs.isNotEmpty) {
        DocumentSnapshot doc = result.docs.first;

        await FirebaseFirestore.instance
            .collection('moods')
            .doc(doc.id)
            .update({
          'lightColor': [red, green, blue],
          'blindsRotation': sliderValue.round(),
          'useFan': activeMood.useFan,
        });

        return true;
      }
    } else {
      var moodToAdd = {
        "name": activeMood.name,
        "lightColor": [red, green, blue],
        "isActive": activeMood.isActive,
        "useFan": activeMood.useFan,
        "useBlinds": activeMood.blindsRotation,
        "roomId": room.id
      };

      await FirebaseFirestore.instance.collection('moods').add(moodToAdd);

      return true;
    }

    return false;
  }

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

  Widget buildMoods(List<Mood> moods) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
          onChanged: (value) {
            setState(() => activeMood.isActive = value);
            updateActiveMood(value);
          },
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
                if (activeMood.name == 'Add Mood') {
                  showInputDialog();
                } else {
                  currentColor = convertRGBToColor(activeMood.lightColor[0],
                      activeMood.lightColor[1], activeMood.lightColor[2]);
                }
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
          const SizedBox(width: 40),
          Container(
            width: 100,
            height: 30,
            color: currentColor,
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Pick a color!'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: pickerColor,
                          onColorChanged: changeColor,
                        ),
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          child: const Text('Got it'),
                          onPressed: () {
                            setState(() => currentColor = pickerColor);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  });
            },
            child: Image.asset(
              'assets/images/colorpicker.png',
              width: 50,
              height: 50,
            ),
          ),
        ],
      ),
      const SizedBox(
        height: 25,
      ),
      const Text("Blinds Rotation"),
      const SizedBox(
        height: 20,
      ),
      Column(
        children: [
          Text(
            "${sliderValue.toInt()}%",
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 300.0,
            child: Slider(
              min: 0.0,
              max: 100.0,
              value: sliderValue,
              onChanged: (value) {
                setState(() {
                  sliderValue = value;
                });
              },
            ),
          ),
        ],
      ),
      Column(
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
          onPressed: () async {
            await updateMoodPreferences(
                    pickerColor.red, pickerColor.green, pickerColor.blue)
                .then((value) {
              if (value) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Update was successful'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            });
          },
          child: const Text(
            "Save",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ]),
    ]);
  }
}
