import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_home_app/home.dart';

class WaterLevelApp extends StatelessWidget {
  const WaterLevelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Level Monitor',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        hintColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const WaterLevelHomePage(),
    );
  }
}

class WaterLevelHomePage extends StatefulWidget {
  const WaterLevelHomePage({Key? key}) : super(key: key);

  @override
  _WaterLevelHomePageState createState() => _WaterLevelHomePageState();
}

class _WaterLevelHomePageState extends State<WaterLevelHomePage> {
  DatabaseReference? _waterLevelRef;
  double waterLevel = 0; // Initial water level percentage

  @override
  void initState() {
    super.initState();
    listenToWaterLevel();
  }

  void listenToWaterLevel() {
    _waterLevelRef = FirebaseDatabase.instance.ref().child('percentage');
    _waterLevelRef!.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final value = event.snapshot.value;
        try {
          setState(() {
            waterLevel = double.parse(value.toString());
          });
        } catch (e) {
          print('Error parsing water level: $e');
        }
      }
    });
  }

  String getWaterLevelReport() {
    if (waterLevel >= 80) {
      return 'Water level is high';
    } else if (waterLevel >= 50) {
      return 'Water level is moderate';
    } else if (waterLevel >= 20) {
      return 'Water level is low';
    } else {
      return 'Water level is very low';
    }
  }

  String getSummaryReport() {
    if (waterLevel >= 80) {
      return 'The tank is almost full.';
    } else if (waterLevel >= 50) {
      return 'The tank is about half full.';
    } else if (waterLevel >= 20) {
      return 'The tank is running low.';
    } else {
      return 'The tank is almost empty.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Level Monitor'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeApp()),
            );
          },
        ),
      ),
      body: buildCurrentWaterLevelView(),
    );
  }

  Widget buildCurrentWaterLevelView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Current Water Level:',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 100,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 100,
                height: 3 * waterLevel,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${waterLevel.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Text(
            getWaterLevelReport(),
            style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          Text(
            getSummaryReport(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
