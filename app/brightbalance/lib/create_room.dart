import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Dao/mood.dart';

class CreateRoom extends StatefulWidget {

  final String data;

  const CreateRoom({Key? key, required this.data}) : super(key: key);

  @override
  State<CreateRoom> createState() => _CreateRoomState();
}

class _CreateRoomState extends State<CreateRoom> {

  Future<List<String>> imagesFuture = getImages();

  List<bool> isSelected = [];

  String profilePic = "";

  static Future<List<String>> getImages() async {

    String assetsPath = await rootBundle.loadString('AssetManifest.json');
    Map<String, dynamic> manifestMap = json.decode(assetsPath);
    List<String> assetPaths = manifestMap.keys.toList();

    List<String> fileNames = assetPaths
        .where((path) => path.startsWith('assets/images/roompic'))
        .map((path) => path.split('/').last)
        .toList();

    return fileNames;

  }

  Future<bool> addRoom(String name, String profilePic) async {
    String profileId = widget.data;
    QuerySnapshot result = await FirebaseFirestore.instance.collection('rooms').where('profileId', isEqualTo: profileId).get();
    final List<DocumentSnapshot> documents = result.docs.toList();
    for (var element in documents) {
      if(element.get("name") == name){
        return false;
      }
    }

    var roomToAdd = { "name": name, "roomPicture": profilePic, "profileId": profileId, "temperature": 0, "numberOfPeople" : 0};

    DocumentReference doc = await FirebaseFirestore.instance.collection('rooms').add(roomToAdd);

    var moodDefault = {
        "name": "Default",
        "lightColor": "Yellow",
        "intensityMin": 0,
        "intensityMax": 100,
        "isActive": false,
        "useFan": false,
        "useBlinds": false,
        "roomId": doc.id};

    await FirebaseFirestore.instance.collection('moods').add(moodDefault);

    return true;

  }

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();

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
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Room"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextFormField(
                      controller:  nameController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Name',
                          hintText: 'Enter a name for the room'
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 4) {
                          return 'The name of the room is too short!';
                        }
                        return null;
                      },
                    ),
                  ),
                  FutureBuilder<List<String>>(
                      future: imagesFuture,
                      builder: (context, snapshot){
                        if (snapshot.hasData){
                          final images = snapshot.data!;

                          for (var i = 0; i < images.length; i++) {
                            isSelected.add(false);
                          }

                          return buildImages(images);
                        }else{
                          return const Text("No images data");
                        }
                      }
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    style: flatButtonStyle,
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await addRoom(nameController.text, profilePic).then((value){
                          if(value){
                            Navigator.of(context).pop();
                          }else{
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("This room name already exists!")));
                          }
                        });
                      }
                    },
                    child: const Text(
                      "Create",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 70,
            ),
            ElevatedButton(
              style: flatButtonStyle,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
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
              children: [
                Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if(isSelected.contains(true)){
                            isSelected = List<bool>.generate(isSelected.length, (_) => false);
                          }
                          isSelected[index] = !isSelected[index];
                          profilePic = image.split(".")[0];
                        });
                      },
                      child: Image.asset('assets/images/$image', width: isSelectedImage ? 100 : 75),
                          ),
                      ),
              ]
          );
        }
    ),
  );

}
