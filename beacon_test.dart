import 'package:flutter/material.dart';
import 'beacon_scanner.dart';

// This is a screen that whilst open will scan for the required beacon. If it is found, the screen will
// change to green, and scanning will stop. 

class BeaconDetectorScreen extends StatefulWidget {
  const BeaconDetectorScreen({super.key});

  @override
  BeaconDetectorScreenState createState() => BeaconDetectorScreenState();
}

class BeaconDetectorScreenState extends State<BeaconDetectorScreen> {
  String _beaconStatus = 'Searching...';
  bool _beaconDetected = false;
  final BeaconScanner _scanner = BeaconScanner();
  


  @override
  void initState() {
    super.initState();
    _startBeaconScan();
  }

  _startBeaconScan () {
    _scanner.startScanning(() {
      setState(() {
        _beaconDetected = true;
        _beaconStatus = "Beacon has been found!";
      });
      _scanner.stopScanning();
    });
  }

  @override
  void dispose(){
    _scanner.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _beaconDetected ? Colors.green : Colors.white,
      appBar: AppBar(title: Text("Beacon Test")),
      body: Center(
        child: Text(
          _beaconStatus, 
          style: TextStyle(fontSize: 24)
        ),
      ),
    );
  }
}