import 'package:brightbalance/Dao/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class Profiles extends StatefulWidget {
  const Profiles({super.key});

  @override
  State<Profiles> createState() => _ProfilesState();
}

class _ProfilesState extends State<Profiles> {

  bool editProfiles = false;

  final ButtonStyle flatButtonStyle = TextButton.styleFrom(
    foregroundColor: Colors.white,
    minimumSize: const Size(250, 50),
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20.0)),
    ),
    backgroundColor: Colors.blue,
  );

  Future<List<Profile>> profilesFuture = getProfiles();

  static Future<List<Profile>> getProfiles() async {
    final box = GetStorage();
    String email = box.read('email');
    QuerySnapshot result = await FirebaseFirestore.instance.collection('accounts').where('email', isEqualTo: email).limit(1).get();
    String id = result.docs.first.id;
    result = await FirebaseFirestore.instance.collection('profiles').where('accountId', isEqualTo: id).get();
    final List<DocumentSnapshot> documents = result.docs.toList();
    List<Profile> profilesList = <Profile>[];
    for (var element in documents) {
      Profile profile = Profile(id: element.id, name: element.get("name"), priority: element.get("priority"), accountId: element.get("accountId"), profilePicture: element.get("profilePicture"));
      profilesList.add(profile);
    }

    Profile profile = Profile(id: "AddProfile", name: "Add Profile", priority: 0, accountId: "None", profilePicture: "addprofile");
    profilesList.add(profile);

    return profilesList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profiles"),
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
            FutureBuilder<List<Profile>>(
                future: profilesFuture,
                builder: (context, snapshot){
                  if (snapshot.hasData){
                    final profiles = snapshot.data!;
                    return buildProfiles(profiles);
                  }else{
                    return const Text("No profiles data");
                  }
                }
            ),
            const SizedBox(
              height: 100,
            ),
            ElevatedButton(
              style: flatButtonStyle,
              onPressed: () {
                final box = GetStorage();
                box.remove('email');
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: const Text(
                "Sign Out",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfiles(List<Profile> profiles) => Column(
    children: [
      SizedBox(
        height: 110,
        width: 330,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return Column(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: InkWell(
                          splashColor: Colors.blue.withAlpha(30),
                          onTap: () {
                            if(profile.accountId == "None"){
                              Navigator.of(context).pushNamed('/create_profile');
                            }else{
                              if(!editProfiles) {
                                Navigator.of(context).pushNamed('/house_rooms', arguments: profile.id);
                              }else{
                                Navigator.of(context).pushNamed('/edit_profile', arguments: profile);
                              }
                            }
                          },
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundImage: ExactAssetImage('assets/images/${profile.profilePicture}.png'),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(profile.name)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]
              );
            }
        ),
      ),
      SizedBox(
        width: 200,
        height: 50,
        child: CheckboxListTile(
          title: const Text("Edit Profiles"),
          value: editProfiles,
          onChanged: (newValue) {
            setState(() {
              editProfiles = newValue!;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    ],
  );

}
