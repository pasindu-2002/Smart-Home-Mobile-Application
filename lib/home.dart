import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; // Add this import
import 'package:smart_home_app/Login%20Signup/Screen/login.dart';
import 'package:smart_home_app/report.dart';
import 'package:smart_home_app/water_level.dart';
import 'door_lock.dart';

class HomeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF1D1E33),
        scaffoldBackgroundColor: Color(0xFF1D1E33),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String userName = "Loading...";
  late String weatherDescription = "Weather data";
  late double temperature = 0.0;
  late int humidity = 0;
  late double windSpeed = 0.0;
  int isBulbOn = 0; // Change to int
  bool isFanOn = false;

  DatabaseReference? _databaseRef; // Declare the database reference

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchWeather();
    _initializeBulbState(); // Fetch initial bulb state
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          userName = userDoc['name'] ?? 'No Name';
        });
      } else {
        setState(() {
          userName = 'Guest';
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Error fetching name';
      });
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=Galle,au&units=metric&appid=1bc5ed81e0532d0c9cab6721f72f530d'));

      if (response.statusCode == 200) {
        Map<String, dynamic> weatherData = jsonDecode(response.body);
        setState(() {
          weatherDescription = weatherData['weather'][0]['main'];
          temperature = weatherData['main']['temp'].toDouble();
          humidity = weatherData['main']['humidity'];
          windSpeed = weatherData['wind']['speed'].toDouble();
        });
      } else {
        setState(() {
          weatherDescription = 'Weather data unavailable';
          temperature = 0.0;
          humidity = 0;
          windSpeed = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        weatherDescription = 'Failed to fetch weather';
        temperature = 0.0;
        humidity = 0;
        windSpeed = 0.0;
      });
    }
  }

  void _initializeBulbState() {
    _databaseRef = FirebaseDatabase.instance.ref().child('bulb');
    _databaseRef!.onValue.listen((event) {
      final int value = event.snapshot.value as int;
      setState(() {
        isBulbOn = value;
      });
    });
  }

  Future<void> _updateBulbState(int state) async {
    try {
      await _databaseRef?.set(state);
    } catch (e) {
      print('Error updating bulb state: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()));
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello $userName 👋'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF1D1E33),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: CircleAvatar(
              backgroundImage:
                  AssetImage('assets/profile.jpg'), // Your profile image here
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Home',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 20.0),
            WeatherWidget(
              weatherDescription: weatherDescription,
              temperature: temperature,
              humidity: humidity,
              windSpeed: windSpeed,
            ),
            SizedBox(height: 20.0),
            RoomsWidget(),
            SizedBox(height: 20.0),
            _buildSwitchTile(
              context: context,
              title: 'Bulb',
              subtitle: isBulbOn == 1 ? 'Bulb is ON' : 'Bulb is OFF',
              value: isBulbOn == 1,
              onChanged: (value) {
                setState(() {
                  isBulbOn = value ? 1 : 0;
                });
                _updateBulbState(isBulbOn);
              },
            ),
            SizedBox(height: 20),
            _buildSwitchTile(
              context: context,
              title: 'Fan',
              subtitle: isFanOn ? 'Fan is ON' : 'Fan is OFF',
              value: isFanOn,
              onChanged: (value) {
                setState(() {
                  isFanOn = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.secondary,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      tileColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class WeatherWidget extends StatelessWidget {
  final String weatherDescription;
  final double temperature;
  final int humidity;
  final double windSpeed;

  WeatherWidget({
    required this.weatherDescription,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Color(0xFF111328),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weatherDescription,
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              Text(
                'Galle, Sri Lanka',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              SizedBox(height: 10.0),
              Text(
                '${temperature.toStringAsFixed(1)}°C',
                style: TextStyle(color: Colors.white54),
              ),
              Text(
                '$humidity% Humidity',
                style: TextStyle(color: Colors.white54),
              ),
              Text(
                '${windSpeed.toStringAsFixed(1)} km/h Wind',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
          Text(
            '${temperature.toStringAsFixed(0)}°',
            style: TextStyle(color: Colors.white, fontSize: 48),
          ),
        ],
      ),
    );
  }
}

class RoomsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> rooms = [
    {
      'name': 'Water Level',
      'devices': '07 Devices',
      'icon': Icons.water_drop_outlined,
      'route': WaterLevelApp(),
    },
    {
      'name': 'Door Lock',
      'devices': '06 Devices',
      'icon': Icons.lock,
      'route': DoorLockApp(),
    },
    {
      'name': 'Security ',
      'devices': 'View Report',
      'icon': Icons.security,
      'route': DoorEventsScreen(),
    },
    {
      'name': 'Kitchen',
      'devices': '08 Devices',
      'icon': Icons.kitchen,
      'route': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: 1.0,
        ),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          return RoomCard(
            name: rooms[index]['name'],
            devices: rooms[index]['devices'],
            icon: rooms[index]['icon'],
            route: rooms[index]['route'],
          );
        },
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final String name;
  final String devices;
  final IconData icon;
  final Widget? route;

  RoomCard({
    required this.name,
    required this.devices,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (route != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => route!),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF111328),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              devices,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
