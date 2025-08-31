import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// This class creates a screensaver which has a bouncing clock showing the actual time. 

class BouncingClockScreensaver extends StatefulWidget {
  final VoidCallback onDismiss;

  const BouncingClockScreensaver({super.key, required this.onDismiss});

  @override
  State<BouncingClockScreensaver> createState() => _BouncingClockScreenSaverState();
}

class _BouncingClockScreenSaverState extends State<BouncingClockScreensaver> {
  late Timer _movementTimer;
  late Timer _clockTimer;
  double _top = 100;
  double _left = 100;
  String _currentTime = DateFormat.Hms().format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _startTimers();
    _enterImmersiveMode();
  }

  void _startTimers() {
    _movementTimer = Timer.periodic(Duration(seconds: 3), (_) => _moveClock());
    _clockTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateFormat.Hms().format(DateTime.now());
      });
    });
  }

  void _moveClock() {
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final newLeft = random.nextDouble() * (screenWidth - 200);
    final newTop = random.nextDouble() * (screenHeight - 100);

    setState(() {
      _left = newLeft;
      _top = newTop;
    });
  }

  void _enterImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode((SystemUiMode.immersiveSticky));
  }

  void _exitImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode((SystemUiMode.edgeToEdge));
  }

  @override
  void dispose() {
    _movementTimer.cancel();
    _clockTimer.cancel();
    _exitImmersiveMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(seconds: 2),
              top: _top,
              left: _left,
              child: Text(
                _currentTime,
                style: TextStyle(
                  fontSize: 48,
                  color: const Color.fromARGB(255, 125, 194, 226),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],),
      ),
    );
  }
}




