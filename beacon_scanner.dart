import 'dart:async';
import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:permission_handler/permission_handler.dart';

// When startScanning is called, it will scan for all beacons it can find. it will then search through the list
// and see if any match the target UUID for the iBeacon provided for the study. The RSSI must also be greater than
// -92. This figure was set after testing the sensitivity of the app. Once the required beacon is found, the scanning 
// will then stop. 

class BeaconScanner {
  StreamSubscription<RangingResult>? _subscription;
  final String targetUUID = "426c7565-4368-6172-6d42-6561636f6e73";
  DateTime? _scanStartTime;

  Future<void> startScanning(Function onBeaconFound) async {
    // requests runtime permissions so the beacon scanning can work
    await Permission.location.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothAdvertise.request();
    await Permission.nearbyWifiDevices.request();

    try {
      await flutterBeacon.initializeScanning;
    } catch (e) {
      print("Beacon Initialisation FAILED --------------------------------!!!!!!!!!!!!!!!!!!!!!");
    }

    final regions = <Region>[Region(identifier: 'BCPro-189891', proximityUUID: targetUUID)];
    _scanStartTime = DateTime.now();
    //print("beacon scan started!!!!!!!!!!!!----------------------------started at: $_scanStartTime------------------------------------");
    _subscription = flutterBeacon.ranging(regions).listen((result) {
    print("beacon scanning ----------------------------------------------------------------------");
      if (result.beacons.isEmpty) return;
      
      final now = DateTime.now();
      final scanAge = now.difference(_scanStartTime!);
      if (scanAge < Duration(seconds: 2)) {
        //print("ignoring beacon detection - only ${scanAge.inMilliseconds}ms sinc scan started");
        return;
      }
      for (final beacon in result.beacons) {
      print("detected beacon UUID: ${beacon.proximityUUID}, rssi ${beacon.rssi}-----------------------------------------------");
        if (beacon.proximityUUID.toLowerCase() == targetUUID && beacon.rssi > -92) {
          //print("beacon found -------------------------time: ${DateTime.now()}---------------------------------------------");
          //print("detected beacon UUID: ${beacon.proximityUUID}, rssi ${beacon.rssi}-----------------------------------------------");
          onBeaconFound();
          _subscription?.cancel();
          break;
        }
      }
    });
  }

  // stops the beacon scanning 
  void stopScanning() {
    if (_scanStartTime !=null) {
      //final duration = DateTime.now().difference(_scanStartTime!);
      //print("scanning stopped after ${duration.inMinutes} minutes and ${duration.inSeconds % 60}-----------------------------------------------");
      _scanStartTime = null;
    }
    _subscription?.cancel();
  }
}