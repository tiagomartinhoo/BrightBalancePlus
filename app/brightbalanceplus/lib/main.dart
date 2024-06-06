import 'package:brightbalanceplus/route_generator.dart';
import 'package:brightbalanceplus/utils/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  await requestNotificationPermission();
  // exemplifyArduino();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

Future<void> exemplifyArduino() async {
  int lightIndoor = 150, lightOutdoor = 300;
  int tempIndoor = 20, tempOutdoor = 30;
  int aux1 = 0, aux2 = 0;
  while(true){
    await FirebaseFirestore.instance.collection('readingsLight').doc("lighting").update({'indoor': lightIndoor, 'outdoor': lightOutdoor});
    await FirebaseFirestore.instance.collection('readingsTemp').doc("temperature").update({'indoor': tempIndoor, 'outdoor': tempOutdoor});
    aux1 = lightIndoor;
    lightIndoor = lightOutdoor;
    lightOutdoor = aux1;
    aux2 = tempIndoor;
    tempIndoor = tempOutdoor;
    tempOutdoor = aux2;
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    String initialRoute = '/';
    if (box.hasData('email')) {
      initialRoute = '/profiles';
    }
    return MaterialApp(
      title: 'BrightBalance+',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: initialRoute,
      onGenerateRoute: RouteGenerator.generateRoute
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<bool> getAccount(String email, String password) async {
    final QuerySnapshot result = await FirebaseFirestore.instance.collection('accounts').where('email', isEqualTo: email).limit(1).get();
    final List<DocumentSnapshot> documents = result.docs;
    for (var element in documents) {
      String fbKey = element.get('key');
      String fbIv = element.get('iv');
      String fbPw = element.get('password');

      final key = encrypt.Key.fromBase64(fbKey);
      final iv = encrypt.IV.fromBase64(fbIv);

      final encrypter = encrypt.Encrypter(encrypt.Salsa20(key));

      final encrypted = encrypter.encrypt(password, iv: iv);

      if (encrypted.base64 == fbPw){
        final box = GetStorage();
        box.write('email', email);
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
      resizeToAvoidBottomInset : false,
      appBar: AppBar(
        title: const Text("Login Account"),
      ),
      body: Column(
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
            Form(
            key: _formKey,
            child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextFormField(
                  controller:  emailController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email',
                      hintText: 'Enter your email'
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextFormField(
                  controller:  passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                      hintText: 'Enter your password'
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                    "Forgot Password",
                    style: TextStyle(color: Colors.blue, fontSize: 15),
                ),
              ),
              ElevatedButton(
                style: flatButtonStyle,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String email = emailController.text;
                    String password = passwordController.text;
                    await getAccount(email, password).then((value) {
                      if (!value){
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Your credentials are incorrect")));
                      }else{
                        Navigator.of(context).pushReplacementNamed('/profiles');
                      }
                    });
                  }
                },
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
            ),
            ),
            const SizedBox(
              height: 100,
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              child: const Text(
                "New User? Create Account",
                style: TextStyle(color: Colors.black, fontSize: 15),
              ),
            ),
          ],
        ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
