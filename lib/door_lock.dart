import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smart_home_app/home.dart';
import 'Login Signup/Screen/login.dart';

class DoorLockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Lock App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LockScreen(),
    );
  }
}

class LockScreen extends StatefulWidget {
  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool isLocked = true;
  String? userName;
  DatabaseReference? doorSensorRef;
  DatabaseReference? doorLockRef;
  int? doorSensorValue;

  @override
  void initState() {
    super.initState();
    fetchUserName();
    listenToDoorSensor();
    listenToDoorLock();
  }

  void listenToDoorSensor() {
    doorSensorRef = FirebaseDatabase.instance.ref().child('door_sensor');
    doorSensorRef!.onValue.listen((event) {
      final int value = event.snapshot.value as int;

      setState(() {
        doorSensorValue = value;
      });
    });
  }

  void listenToDoorLock() {
    doorLockRef = FirebaseDatabase.instance.ref().child('door_lock');
    doorLockRef!.onValue.listen((event) {
      final int value = event.snapshot.value as int;

      setState(() {
        isLocked = (value == 1);
      });
    });
  }

  Future<void> fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        userName = userDoc['name'];
      });
    }
  }

  Future<void> toggleLock() async {
    setState(() {
      isLocked = !isLocked;
    });
    doorLockRef?.set(isLocked ? 1 : 0);

    // Log the event in Firestore
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && userName != null) {
      await FirebaseFirestore.instance.collection('door_events').add({
        'userId': user.uid,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'action': isLocked ? 'locked' : 'unlocked',
      });
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF1D1E33),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeApp()),
            );
          },
        ),
        actions: <Widget>[
          if (userName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  '$userName',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.account_circle),
            color: Colors.white,
            onPressed: () {
              // Navigate to profile page or show a dialog with user details
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E33), Color(0xFF1D1E33)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0), // Add padding at the top
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  size: 100,
                  color: Colors.white,
                ),
                SizedBox(height: 20),
                Text(
                  isLocked ? 'Door is Locked' : 'Door is Unlocked',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: toggleLock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLocked ? Colors.red : Colors.green,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(30),
                    shadowColor: Colors.black,
                    elevation: 10,
                  ),
                  child: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  'Tap the button to toggle the lock state',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Divider(color: Colors.white30),
                SizedBox(height: 20),
                Text(
                  'Door Status',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: doorSensorValue == 1 ? Colors.red : Colors.white,
                      size: 50,
                    ),
                    SizedBox(width: 30),
                    Icon(
                      Icons.lock_open,
                      color: doorSensorValue == 0 ? Colors.green : Colors.white,
                      size: 50,
                    ),
                  ],
                ),
                Text(
                  doorSensorValue == 0 ? 'Door is Open' : 'Door is Close',
                  style: TextStyle(
                    fontSize: 18,
                    height: 3,
                    color: Colors.white70,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.logout),
                  color: Colors.white,
                  iconSize: 35,
                  onPressed: () async {
                    await signOut();
                  },
                ),
                SizedBox(height: 10), // Add some spacing at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
