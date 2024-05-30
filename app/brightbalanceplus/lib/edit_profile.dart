import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Dao/profile.dart';

class EditProfile extends StatefulWidget {

  final Profile data;

  const EditProfile({super.key, required this.data});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {

  final ButtonStyle flatButtonStyle = TextButton.styleFrom(
    foregroundColor: Colors.white,
    minimumSize: const Size(250, 50),
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20.0)),
    ),
    backgroundColor: Colors.blue,
  );

  late Profile profile;

  final nameController = TextEditingController();

  Future<List<String>> imagesFuture = getImages();

  List<bool> isSelected = [];

  String profilePic = "";

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

  Future<bool> updateProfile(Profile profile, String name, String profilePic) async {
    QuerySnapshot result = await FirebaseFirestore.instance.collection('profiles').where('accountId', isEqualTo: profile.accountId).get();
    final List<DocumentSnapshot> documents = result.docs.toList();
    for (var element in documents) {
      if(element.get("name") == name){
        return false;
      }
    }

    var profileToUpdate = { "name": name, "priority": profile.priority, "accountId": profile.accountId, "profilePicture": profilePic};

    await FirebaseFirestore.instance.collection('profiles').doc(profile.id).update(profileToUpdate);

    return true;
  }

  Future removeProfile(Profile profile) async {
    await FirebaseFirestore.instance.collection('profiles').doc(profile.id).delete();
  }

  @override
  void initState() {
    super.initState();
    profile = widget.data;
    profilePic = profile.profilePicture;
    nameController.text = profile.name;
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
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        child:
        Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                height: 200.0,
                width: 250.0,
                padding: const EdgeInsets.only(top: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                ),
                child: Center(
                  child: Image.asset('assets/images/${profile.profilePicture}.png', width: 100),
                ),
              ),
              FutureBuilder<List<String>>(
                  future: imagesFuture,
                  builder: (context, snapshot){
                    if (snapshot.hasData){
                      final images = snapshot.data!;
                      images.remove("${profile.profilePicture}.png");


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
                    await updateProfile(profile, nameController.text, profilePic).then((value){
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
                  await removeProfile(profile).then((value) => Navigator.of(context).pushReplacementNamed("/profiles"));
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
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
                      profilePic = image.split(".")[0];
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
