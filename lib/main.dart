import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_home_app/Login%20Signup/Screen/login.dart';
import 'package:smart_home_app/door_lock.dart';
import 'package:smart_home_app/home.dart';

Future<void> main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: 'AIzaSyCGHLVpDXNKIs16xaetKOurt0vUqplmuJ4',
          appId: '1:400309373110:android:1a8edf95d694a7c385be17',
          messagingSenderId: '400309373110',
          projectId: 'smart-home-224ab',
          databaseURL: "https://smart-home-224ab-default-rtdb.firebaseio.com"));
  // Run your app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomeApp();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}
