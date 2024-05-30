import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:math';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {

  final _formKey = GlobalKey<FormState>();

  String getRandString(int len) {
    var random = Random.secure();
    var values = List<int>.generate(len, (i) =>  random.nextInt(255));
    return base64UrlEncode(values);
  }

  Future<bool> checkEmail(String email) async {
    final QuerySnapshot result = await FirebaseFirestore.instance.collection('accounts').where('email', isEqualTo: email).limit(1).get();
    final List<DocumentSnapshot> documents = result.docs;
    return documents.length == 1;
  }

  createAccount(String email, String pw, String key, String iv) async {
    Map<String, String> dataToAdd = { 'email': email, 'password': pw, 'key': key, 'iv': iv };
    await FirebaseFirestore.instance.collection('accounts').add(dataToAdd);
  }

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    emailController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
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
        title: const Text("Create Account"),
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
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Email',
                          hintText: 'Enter your email',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 10) {
                          return 'Enter a valid email!';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Password',
                          hintText: 'Enter your password',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 4) {
                          return 'The password is too short!';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextFormField(
                      controller: repeatPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Repeat Password',
                          hintText: 'This password must be equal to the above',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value != passwordController.text) {
                          return 'The passwords must be the same!';
                        }
                        return null;
                      },
                    ),
                  ),
                  ElevatedButton(
                      style: flatButtonStyle,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          String email = emailController.text;
                          await checkEmail(email).then((value) {
                                String password = passwordController.text;
                                final key = encrypt.Key.fromUtf8(email);
                                final iv = encrypt.IV.fromUtf8(getRandString(4));

                                final encrypter = encrypt.Encrypter(encrypt.Salsa20(key));
                                final encrypted = encrypter.encrypt(password, iv: iv);

                                if (value){
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("$email already taken!")));
                                }else{
                                  createAccount(email, encrypted.base64, key.base64, iv.base64);
                                  Navigator.of(context).pushReplacementNamed('/profiles');
                                }
                          });
                        }
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(color: Colors.white),
                      ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Already have an account? Sign in",
                style: TextStyle(color: Colors.black, fontSize: 15),
              ),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
