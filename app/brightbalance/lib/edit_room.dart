import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Dao/room.dart';

class EditRoom extends StatefulWidget {

  final Room data;

  const EditRoom({Key? key, required this.data}) : super(key: key);

  @override
  State<EditRoom> createState() => _EditRoomState();
}

class _EditRoomState extends State<EditRoom> {

  final ButtonStyle flatButtonStyle = TextButton.styleFrom(
    foregroundColor: Colors.white,
    minimumSize: const Size(250, 50),
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20.0)),
    ),
    backgroundColor: Colors.blue,
  );

  late Room room;

  final nameController = TextEditingController();

  Future<List<String>> imagesFuture = getImages();

  List<bool> isSelected = [];

  String roomPic = "";

  final _formKey = GlobalKey<FormState>();

  static Future<List<String>> getImages() async {

    String assetsPath = await rootBundle.loadString('AssetManifest.json');
    Map<String, dynamic> manifestMap = json.decode(assetsPath);
    List<String> assetPaths = manifestMap.keys.toList();

    List<String> fileNames = assetPaths
        .where((path) => path.startsWith('assets/images/profilepic'))
        .map((path) => path.split('/').last)
        .toList();

    return fileNames;

  }

  Future<bool> updateRoom(Room room, String name, String profilePic) async {
    QuerySnapshot result = await FirebaseFirestore.instance.collection('profiles').where('accountId', isEqualTo: room.profileId).get();
    final List<DocumentSnapshot> documents = result.docs.toList();
    for (var element in documents) {
      if(element.get("name") == name){
        return false;
      }
    }

    var roomToUpdate = { "name": name, "roomPicture": profilePic, "profileId": room.profileId, "temperature": room.temperature, "numberOfPeople" : room.numberOfPeople};

    await FirebaseFirestore.instance.collection('profiles').doc(room.id).update(roomToUpdate);

    return true;
  }

  Future removeProfile(Room room) async {
    await FirebaseFirestore.instance.collection('rooms').doc(room.id).delete();
  }

  @override
  void initState() {
    super.initState();
    room = widget.data;
    roomPic = room.roomPicture;
    nameController.text = room.name;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Room"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 200.0,
              width: 250.0,
              padding: const EdgeInsets.only(top: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
              ),
              child: Center(
                child: Image.asset('assets/images/logo.png'),
              ),
            ),
            FutureBuilder<List<String>>(
                future: imagesFuture,
                builder: (context, snapshot){
                  if (snapshot.hasData){
                    final images = snapshot.data!;
                    images.remove("${room.roomPicture}.png");


                    for (var i = 0; i < images.length; i++) {
                      isSelected.add(false);
                    }

                    return buildImages(images);
                  }else{
                    return const Text("No images data");
                  }
                }
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextFormField(
                controller:  nameController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                    hintText: 'Enter a name for the profile'
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 4) {
                    return 'The name is too short!';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              style: flatButtonStyle,
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await updateRoom(room, nameController.text, roomPic).then((value){
                    if(value){
                      Navigator.of(context).pushReplacementNamed("/profiles");
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("This profile name already exists!")));
                    }
                  });
                }
              },
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            ElevatedButton(
              style: flatButtonStyle,
              onPressed: () async{
                await removeProfile(room).then((value) => Navigator.of(context).pushReplacementNamed("/profiles"));
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildImages(List<String> images) => SizedBox(
    height: 150,
    width: 330,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        final isSelectedImage = isSelected[index];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 110,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected.contains(true)) {
                        isSelected = List<bool>.generate(isSelected.length, (_) => false);
                      }
                      isSelected[index] = !isSelected[index];
                      roomPic = image.split(".")[0];
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: isSelectedImage ? 72 : 52,
                        height: isSelectedImage ? 72 : 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: ExactAssetImage('assets/images/$image'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

}
