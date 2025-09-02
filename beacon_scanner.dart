import 'dart:async';
import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:permission_handler/permission_handler.dart';

// When startScanning is called, it will scan for all beacons it can find. It will then search through the list
// and see if any match the target UUID for the iBeacon provided for the study. The RSSI must also be greater than
// -92. This figure was set after testing the sensitivity of the app. Once the required beacon is found, the scanning 
// will then stop. 

// Print statements left in (but commented out) as they are very useful when tracking what is happening live - 
// remove comment markers to use again if needed

class BeaconScanner {
  StreamSubscription<RangingResult>? _subscription;
  final String targetUUID = "426c7565-4368-6172-6d42-6561636f6e73";
  //DateTime? _scanStartTime;

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
    //_scanStartTime = DateTime.now();
    //print("beacon scan started!!!!!!!!!!!!----------------------------started at: $_scanStartTime------------------------------------");
    _subscription = flutterBeacon.ranging(regions).listen((result) {
    //print("beacon scanning ----------------------------------------------------------------------");
      if (result.beacons.isEmpty) return;
      

      for (final beacon in result.beacons) {
      //print("detected beacon UUID: ${beacon.proximityUUID}, rssi ${beacon.rssi}-----------------------------------------------");
        if (beacon.proximityUUID.toLowerCase() == targetUUID && beacon.rssi > -92) {
          onBeaconFound();
          _subscription?.cancel();
          break;
        }
      }
    });
  }

  // stops the beacon scanning 
  void stopScanning() {

    _subscription?.cancel();
  }
}


