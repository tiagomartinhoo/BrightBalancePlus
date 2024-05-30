import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

class CreateProfile extends StatefulWidget {
  const CreateProfile({super.key});

  @override
  State<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {

  Future<List<String>> imagesFuture = getImages();

  List<bool> isSelected = [];

  String profilePic = "";

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

  Future<bool> addProfile(String name, String profilePic) async {
    final box = GetStorage();
    String email = box.read('email');
    QuerySnapshot result = await FirebaseFirestore.instance.collection('accounts').where('email', isEqualTo: email).limit(1).get();
    String id = result.docs.first.id;
    result = await FirebaseFirestore.instance.collection('profiles').where('accountId', isEqualTo: id).get();
    final List<DocumentSnapshot> documents = result.docs.toList();
    int maxProfilePriority = 0;
    for (var element in documents) {
      int priority = element.get("priority");
      if(priority > maxProfilePriority){
        maxProfilePriority = priority;
      }

      if(element.get("name") == name){
        return false;
      }

    }

    var profileToAdd = { "name": name, "priority": maxProfilePriority + 1, "accountId": id, "profilePicture": profilePic};

    await FirebaseFirestore.instance.collection('profiles').add(profileToAdd);

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
        title: const Text("Create Profile"),
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
                  ElevatedButton(
                    style: flatButtonStyle,
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await addProfile(nameController.text, profilePic).then((value){
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
                      "Create",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 100,
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
    height: 110,
    width: 330,
    child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          final isSelectedImage = isSelected[index];
          return Column(
              children: [
                SizedBox(
                  width: 110,
                  child: Padding(
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
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              radius: isSelectedImage ? 28 : 22,
                              backgroundImage: ExactAssetImage('assets/images/$image'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
          );
        }
    ),
  );

}
