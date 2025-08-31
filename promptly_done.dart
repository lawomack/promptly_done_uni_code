
import 'package:flutter/material.dart';
import 'package:uni_project/beacon_test.dart';
import 'package:uni_project/bouncing_clock_screensaver.dart';
import 'package:uni_project/models/proximity_prompt.dart';
import 'package:uni_project/prompt_form.dart';
import 'package:uni_project/prompts_list.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:uni_project/beacon_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'main.dart';



class PromptlyDone extends StatefulWidget {
  const PromptlyDone({super.key});

  @override
  State<PromptlyDone> createState(){
    return _PromptlyDoneState();
  }
}

class _PromptlyDoneState extends State<PromptlyDone> with WidgetsBindingObserver, RouteAware {
  final List<ProximityPrompt> _enteredPrompts = [];
  final List<ProximityPrompt> _dismissedPrompts = [];

  final Battery _battery = Battery();
  final int _batteryThreshold = 20;
  final BeaconScanner _beaconScanner = BeaconScanner();
  final Set<String> _scheduledPromptsIDs = {};
  final Set<String> _shownPromptIDs = {};
  final Queue<ProximityPrompt> _notificationQueue = Queue();
  final List<ProximityPrompt> _activePrompts = [];

  
  bool _isShowingNotification = false;
  bool _isBatteryDialogShowing = false;
  bool _isScreenSaverVisible = false;
  bool _isScanning = false;
  Timer? _inactivityTimer;

  //
  void _rescheduleAllScans() {
    _activePrompts.clear();
    _shownPromptIDs.clear();
    _beaconScanner.stopScanning();
    _isScanning = false;

    for (final prompt in _enteredPrompts) {
      _evaluatePrompt(prompt);
    }
  }

  // Check battery level every twenty minutes. If Battery is at 20% or lower, this will trigger a warning notification
  void _startBatteryMonitoring() {
    Timer.periodic(Duration(minutes: 20), (timer) async {
      final level = await _battery.batteryLevel;
      if (level <= _batteryThreshold) {
        _showBatteryWarning(level);
      }
    });
  }

  // Notification for low battery. Can only be dismissed by clicking ok
  void _showBatteryWarning(int level) {
    if (_isBatteryDialogShowing) return;

    _isBatteryDialogShowing = true;
    
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text('Low Battery'),
        content: Text('Battery is at $level%. Please plug in your device.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), 
          child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // prevents the screen from locking so app can always run in the foreground
    WakelockPlus.enable();
    // reshedule scans for all active prompts
    _loadPrompts().then((_) {
        _scheduleBeaconScans();
    });
    _startBatteryMonitoring();
    _startRestartTimer();
    _resetInactivityTimer();
  }

  // function to ensure the app closes and restarts automatically at 4:45am everyday
  void _startRestartTimer() {
    final now = DateTime.now();
    final nextRestart = DateTime(now.year, now.month, now.day, 4, 45);
    final restartTime = now.isAfter(nextRestart) ? nextRestart.add(Duration(days: 1)) : nextRestart;

    final durationUntilRestart = restartTime.difference(now);

    Timer(durationUntilRestart, () {
      Phoenix.rebirth(context);
    });
  }

  // Calculates the start and end time for the scanning window for each prompt. 
  // Scanning lasts for 2 hours
  // Activates prompt if within the scanning window, or after a delay if not
  // Deactivates prompt at the end of the window
  void _evaluatePrompt(ProximityPrompt prompt) {
    // print("Evaluating prompt: ${prompt.promptID}, scheduled for ${prompt.time}");
    final now = DateTime.now();
    final scheduledTime = prompt.time;
    if (scheduledTime == null) return;

    final endTime = scheduledTime.add(Duration(hours: 2));
    if (now.isBefore(endTime)) {
      if (now.isBefore(scheduledTime)) {
        final delayUntilStart = scheduledTime.difference(now);
        Timer(delayUntilStart, () {
          _activatePrompt(prompt);
        });
      } else {
        _activatePrompt(prompt);
      }

      final delayUntilStop = endTime.difference(now);
      Timer(delayUntilStop, () {
        _deactivatePrompt(prompt);
      });
    }
  }

  // Creates list of all scans that are due to happen
  void _scheduleBeaconScans() {
    // print('running _sechduled beaconscans ----------------------------------------');
    _scheduledPromptsIDs.clear();
    
    for (final prompt in _enteredPrompts) {
      _scheduledPromptsIDs.add(prompt.promptUniqueID);
      _evaluatePrompt(prompt);      
    }
  }

  // Adds prompt to the active list (ie prompts that are currently in their scanning window) and starts beacon scanning 
  void _activatePrompt(ProximityPrompt prompt) {
    // print("Activating prompt ${prompt.promptID}-------------------------------------------");
    _activePrompts.add(prompt);

    if (!_isScanning) {
      _startCentralBeaconScan();
    } 
  }

  // removes prompt from active list and stops the beacon scanning if the active prompt list is empty
  void _deactivatePrompt(ProximityPrompt prompt) {
    print("deactivating prompt: ${prompt.promptID}---------------------------------");
    _activePrompts.removeWhere((p) => p.promptUniqueID == prompt.promptUniqueID);

    if (_activePrompts.isEmpty) {
      _beaconScanner.stopScanning();
      _isScanning = false;
    }
  }

  // Activates the beacon scanner
  // If the beacon is found, it checks if there are any prompts in the active list, 
  // and adds them to the notification queue so a notification can be triggered
  void _startCentralBeaconScan() {

    if (_isScanning) {
      return;
    }

    _isScanning = true;
    //print("starting central beacon scan-----------------------------------------------------");

    _beaconScanner.startScanning(() async {
      //print("beacon call back triggered ------------------------------------------");
      for (final prompt in _activePrompts) {
        //print("checking for prompt: ${prompt.promptID}------------------------------------------");
        if (_shownPromptIDs.contains(prompt.promptUniqueID)) {
          continue;
        }
        _shownPromptIDs.add(prompt.promptUniqueID);
        _notificationQueue.add(prompt);
      }
      _processNotificationQueue();
    });
  }

  // Opens the interface to allow users to input a new prompt
  void _openAddPromptOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context, 
      builder: (cxt) => PromptForm(onSubmit: _addPrompt),
    );
  }

  // Saves the prompt information on the phone, so if the app is closed or restarted, the information can be retrieved and it is not lost
  Future<void> _savePrompts() async {
    final prefs = await SharedPreferences.getInstance();
    final entered = _enteredPrompts.map((p) => p.toStorageString()).toList();
    final dismissed = _dismissedPrompts.map((p) => p.toStorageString()).toList();
    await prefs.setStringList('enteredPrompts', entered);
    await prefs.setStringList('dismissedPrompts', dismissed);
  }

  // Retrieves previously saved prompts from the phone and repopulates the entered and dismissed prompt lists
  Future<void> _loadPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    final entered = prefs.getStringList('enteredPrompts') ?? [];
    final dismissed = prefs.getStringList('dismissedPrompts') ?? [];

    setState(() {
      _enteredPrompts.clear();
      _dismissedPrompts.clear();
      _enteredPrompts.addAll(entered.map((s) => ProximityPrompt.fromStorageString(s)));
      _dismissedPrompts.addAll(dismissed.map((s) => ProximityPrompt.fromStorageString(s)));
    });
  }

  // When a new prompt is made, this function adds it to the entered prompt list
  // If the prompt was previously listed in the dismissed prompt list (as identified by the unique id), it removes it from that
  // list so there is only one entry per unique id
  // The scan schedule is then recalculated
  void _addPrompt(ProximityPrompt prompt) {
    setState(() {
      _enteredPrompts.add(prompt);
      _dismissedPrompts.removeWhere((p) => p.promptUniqueID == prompt.promptUniqueID);
    });
    _savePrompts();
    _rescheduleAllScans();
  }

  // Deletes prompts from entered or dismissed prompt lists and reschedules scans for all remaining prompts
  void _removePrompt(ProximityPrompt prompt) {
    setState(() {
      _enteredPrompts.removeWhere((p) => p.promptUniqueID == prompt.promptUniqueID);
      _dismissedPrompts.removeWhere((p) => p.promptUniqueID == prompt.promptUniqueID);
    });
    _savePrompts();
    _rescheduleAllScans();
  }

  // moves a prompt from the entered prompt lists to the dismissed prompt list
  void _dismissPrompt(ProximityPrompt prompt) {
    setState(() {
      _enteredPrompts.removeWhere((p) => p.promptUniqueID == prompt.promptUniqueID);
      _dismissedPrompts.add(prompt);
    });
    _savePrompts();
    _rescheduleAllScans();
  }

  // this timer is used to initiate the screensaver after 2 minutes of inactivity 
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(minutes: 2), () {
      if (!_isBatteryDialogShowing) {
        setState(() {
          _isScreenSaverVisible = true;
        });
      }
    });
  }

  // This is called by the notification pop up code to ensure that if there is more than one prompt that 
  // needs to be triggered at the same time, a pop up appears for each one once, one after the other
   void _startBeaconMonitoring(ProximityPrompt prompt) {
    if (_isScreenSaverVisible) {
      setState(() {
        _isScreenSaverVisible = false;
      });
    }
     _beaconScanner.startScanning(() async {
      if (_shownPromptIDs.contains(prompt.promptUniqueID)) return;

      _notificationQueue.add(prompt);
      _processNotificationQueue();
     });
  }

  // if a prompt is edited, the old entry is removed and replaced with a new one in the entered prompts list 
  void _editPrompt (ProximityPrompt updatedPrompt) {
    setState(() {
      _dismissedPrompts.removeWhere((p) => p.promptUniqueID == updatedPrompt.promptUniqueID);
      _enteredPrompts.removeWhere((p) => p.promptUniqueID == updatedPrompt.promptUniqueID);
      _enteredPrompts.add(updatedPrompt);
      });
    _savePrompts();
    _rescheduleAllScans();
        
  }

  // this code ensures that a notification pop up is shown for each prompt that has been added to the notification queue
  // The notification will give the option to be dismissed, thus moving the prompt to the dismissed list or snooze, where
  // it will be rescheduled to start scanning in 15 minutes if still within the scanning window
  // Each prompt will play a sound 
  void _processNotificationQueue() async {
    if (_isShowingNotification || _notificationQueue.isEmpty) {
      return;
    }

    _isShowingNotification = true;
    final prompt = _notificationQueue.removeFirst();
    _shownPromptIDs.add(prompt.promptUniqueID);
      

    final player = AudioPlayer();
    await player.play(AssetSource('sounds/notification-9-158194.mp3'));

    if (!mounted) return;

    try {
      await showDialog(
        context: context, 
        useRootNavigator: true,
        builder: (ctx) { 
          return AlertDialog(
            title: Text("You have a reminder!\n\nLocation: ${prompt.promptID}"),
            content: Text("${prompt.promptInfo}"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _dismissPrompt(prompt);
                  _resetInactivityTimer();
                  //_beaconScanner.stopScanning();
                },
                child: Text("Dismiss"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Future.delayed(Duration(minutes: 15), () {
                      if (mounted) {
                        _shownPromptIDs.remove(prompt.promptUniqueID);
                        _startBeaconMonitoring(prompt);
                        _resetInactivityTimer();
                      }
                    });
                  }, 
                child: Text("Snooze for 15 mins"),
            ),
          ],
        );
    });      
    } catch (e, stack) {
      print("---------------error showing dialog: $e");
      print(stack);
    }
    _isShowingNotification = false;
    _processNotificationQueue();
  }


  // created whilst troubleshooting - not sure if still needed. Test in the future but I don't want to risk breaking the app now
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("App resumed - rechecking active prompts and restarting scans----------------------");
    }
  }

  // created whilst troubleshooting - not sure if still needed. Test in the future but I don't want to risk breaking the app now
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    } else {
      print("route is not a page route - skipping subscription");
    }
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }
 
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // reschedules all scans whenever the user returns to the promptly done screen
  @override
  void didPopNext() {
    print("Returned to promptly done screen - rescheduling scans --------------------------------------");
    _rescheduleAllScans();
  }

  // Builds the Interface
  @override
  Widget build(BuildContext context) {

    // This groups the cards into entered and dismissed groups, and then orders them earliet to latest within those groups
    final hasAnyPrompts = _enteredPrompts.isNotEmpty || _dismissedPrompts.isNotEmpty;

    Widget mainContent = hasAnyPrompts
      ? PromptsList(
        enteredPrompts: _enteredPrompts
          .where((p) => p.time != null)
          .toList()
          ..sort((a, b) => a.time!.compareTo(b.time!)),
        dismissedPrompts: _dismissedPrompts, 
        onRemovePrompt: _removePrompt, 
        onEditPrompt: _editPrompt,
      ) : Center(
        child: Text('No Prompts found. Click Plus to add some.'),
      );
        
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetInactivityTimer,
      child: Stack(
        children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Promptly Done!'),
            actions: [
              IconButton(
                onPressed: _openAddPromptOverlay, 
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 20,),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BeaconDetectorScreen()),
                  );
                }, 
                child: Text("Test Beacon Scanner")),
              const SizedBox(height: 10,),
              ElevatedButton(
                onPressed: () => Phoenix.rebirth(context), 
                child: Text("Restart App"),
                ),

              // this code below provides a button to similate the beacon being found. It was created for use in the emulator to assist with 
              // the demonstration for the professionals. Not intended for use on the smartphone app

              //SizedBox(height: 10,),
              //ElevatedButton(
              //  onPressed: () {
              //    if(_activePrompts.isNotEmpty) {
              //      for (final prompt in _activePrompts) {
              //        if (!_shownPromptIDs.contains(prompt.promptUniqueID)) {
              //          _shownPromptIDs.add(prompt.promptUniqueID);
              //          _notificationQueue.add(prompt);
              //        }
              //      }
              //      _processNotificationQueue();
              //    } else {
              //      print("no active prompts to simulate");
              //    }
              //  }, 
              //  child: Text("Simulate Beacon Detection"),
              //  ),

              SizedBox(height: 20,),
              Expanded(
                child: mainContent),
              ],
            ),
          ),
          if (_isScreenSaverVisible)
            BouncingClockScreensaver(
              onDismiss: () {
                setState(() {
                  _isScreenSaverVisible = false;
                });
                _resetInactivityTimer();
              },
            ),
        ],
      ),
    );
  }
}