// lib/features/root_detection.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for MethodChannel and PlatformException
import 'package:mobile_security_app/permission_handler.dart'; // Import your renamed PermissionHandlerUtil
import 'dart:async';

class RootDetection {
  static const MethodChannel _channel =
      MethodChannel('mobile_security_app/root_detection');

  /// Checks if the device is rooted.
  static Future<bool> get isDeviceRooted async {
    try {
      final bool result = await _channel.invokeMethod('isDeviceRooted');
      return result;
    } on PlatformException catch (e) {
      print("Failed to detect root: '${e.message}'.");
      return false;
    }
  }

  // Additional methods for more granular checks can be added here.
}

class RootDetectionPage extends StatefulWidget {
  @override
  _RootDetectionPageState createState() => _RootDetectionPageState();
}

class _RootDetectionPageState extends State<RootDetectionPage> {
  bool _isRooted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performRootCheck();
  }

  Future<void> _performRootCheck() async {
    bool permissionsGranted = await PermissionHandlerUtil.requestPermissions();
    if (!permissionsGranted) {
      setState(() {
        _isLoading = false;
      });
      _showPermissionDeniedAlert();
      return;
    }

    bool isRooted = await RootDetection.isDeviceRooted;
    setState(() {
      _isRooted = isRooted;
      _isLoading = false;
    });

    if (isRooted) {
      _showRootedAlert();
    } else {
      _showNotRootedAlert();
    }
  }

  void _showRootedAlert() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Security Alert'),
          content: Text(
              'This device appears to be rooted. For security reasons, certain features may not function properly.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally, navigate away or disable specific features
              },
            ),
          ],
        );
      },
    );
  }

  void _showNotRootedAlert() {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissal
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Security Check Passed'),
          content:
              Text('This device is secure. You can use all features safely.'),
          actions: [
            TextButton(
              child: Text('Great!'),
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally, navigate to a specific feature
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedAlert() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permissions Required'),
          content: Text(
              'The app requires storage permissions to perform root detection. Please grant the necessary permissions and try again.'),
          actions: [
            TextButton(
              child: Text('Retry'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _performRootCheck();
              },
            ),
            TextButton(
              child: Text('Exit'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Navigate back to previous screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Root Detection'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _isRooted
                ? Text(
                    'Rooted device detected. Certain features are disabled.',
                    style: TextStyle(color: Colors.red, fontSize: 18),
                  )
                : Text(
                    'Device is secure.',
                    style: TextStyle(color: Colors.green, fontSize: 18),
                  ),
      ),
    );
  }
}
