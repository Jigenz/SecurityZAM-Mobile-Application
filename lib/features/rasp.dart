// lib/features/rasp.dart

import 'package:flutter/material.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:validators/validators.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cloud_firestore/cloud_firestore.dart'; // For backend logging
import 'package:permission_handler/permission_handler.dart'; // Ensure correct import
import 'package:flutter/foundation.dart'; // For debug mode detection

// Model to represent each security check
class SecurityCheck {
  final String name;
  final bool status;
  final String details;
  final String? moreDetails; // Optional field for additional information

  SecurityCheck({
    required this.name,
    required this.status,
    required this.details,
    this.moreDetails,
  });
}

class RaspPage extends StatefulWidget {
  const RaspPage({Key? key}) : super(key: key);

  @override
  _RaspPageState createState() => _RaspPageState();
}

class _RaspPageState extends State<RaspPage> {
  List<SecurityCheck> _securityChecks = [];
  int _apiCallCount = 0;
  Timer? _apiCallTimer;
  final _secureStorage = FlutterSecureStorage();
  bool _isDebugMode = false;

  @override
  void initState() {
    super.initState();
    _checkDebugMode();
    _initializeApiCallMonitoring();
    _performSecurityChecks();
  }

  @override
  void dispose() {
    _apiCallTimer?.cancel();
    super.dispose();
  }

  void _checkDebugMode() {
    assert(() {
      _isDebugMode = true;
      return true;
    }());
    if (_isDebugMode) {
      print('App is running in Debug mode.');
      // Add to security checks
      _securityChecks.add(SecurityCheck(
        name: 'Debug Mode',
        status: false,
        details: 'App is running in Debug mode.',
        moreDetails:
            'Running in debug mode may expose the app to security vulnerabilities. It is recommended to run the app in release mode for enhanced security.',
      ));
      _takeMitigationActions(false, false, false, threatName: 'Debug Mode');
    }
  }

  Future<void> _performSecurityChecks() async {
    bool isJailbroken = false;
    bool isInputValid = true;
    bool isInjectionAttempt = false;
    bool isDataSecure = true;
    bool isAppTampered = false;

    // Check if device is rooted/jailbroken
    try {
      isJailbroken = await FlutterJailbreakDetection.jailbroken;
      _securityChecks.add(SecurityCheck(
        name: 'Rooted/Jailbroken Device',
        status: !isJailbroken,
        details: isJailbroken
            ? 'Device is rooted or jailbroken.'
            : 'Device is secure.',
        moreDetails: isJailbroken
            ? 'Rooted or jailbroken devices can compromise app security by bypassing system protections. Consider limiting app functionality or restricting access on such devices.'
            : 'No signs of rooting or jailbreaking detected.',
      ));
    } catch (e) {
      isJailbroken = false;
      print('Error checking jailbreak status: $e');
      _securityChecks.add(SecurityCheck(
        name: 'Rooted/Jailbroken Device',
        status: true,
        details: 'Failed to determine device root status.',
        moreDetails:
            'Unable to verify if the device is rooted or jailbroken. Proceed with caution.',
      ));
    }

    // Validate user inputs (Example)
    isInputValid =
        _validateUserInputs("SampleUser123"); // Replace with actual input
    _securityChecks.add(SecurityCheck(
      name: 'User Input Validation',
      status: isInputValid,
      details: isInputValid
          ? 'User inputs are valid.'
          : 'Invalid user inputs detected.',
      moreDetails: isInputValid
          ? 'All user inputs have passed validation checks.'
          : 'Detected invalid characters or formats in user inputs. Potential injection vectors identified.',
    ));

    // Detect injection attempts (Example)
    isInjectionAttempt =
        _detectInjectionAttempt("SELECT * FROM users WHERE name = 'admin';");
    _securityChecks.add(SecurityCheck(
      name: 'Injection Attack Detection',
      status: !isInjectionAttempt,
      details: isInjectionAttempt
          ? 'Potential injection attack detected.'
          : 'No injection attacks detected.',
      moreDetails: isInjectionAttempt
          ? 'The system detected patterns indicative of SQL injection. Immediate action may be required to secure data endpoints.'
          : 'User inputs do not contain known injection patterns.',
    ));

    // Check data encryption
    isDataSecure = await _checkDataEncryption();
    _securityChecks.add(SecurityCheck(
      name: 'Data Encryption',
      status: isDataSecure,
      details: isDataSecure
          ? 'Data encryption is functioning correctly.'
          : 'Data encryption issues detected.',
      moreDetails: isDataSecure
          ? 'All sensitive data is encrypted both in transit and at rest.'
          : 'Detected problems with data encryption mechanisms. Sensitive data may be at risk.',
    ));

    // Check app tampering
    isAppTampered = _checkAppTampering();
    _securityChecks.add(SecurityCheck(
      name: 'App Tampering',
      status: !isAppTampered,
      details: isAppTampered
          ? 'App code tampering detected.'
          : 'App code integrity verified.',
      moreDetails: isAppTampered
          ? 'Modifications to the app code have been detected. The app may restrict access to prevent further compromise.'
          : 'No tampering with app code detected.',
    ));

    // Check API call count
    _securityChecks.add(SecurityCheck(
      name: 'Excessive API Calls',
      status: _apiCallCount <= 100,
      details: _apiCallCount > 100
          ? 'Exceeded the threshold of 100 API calls per minute.'
          : 'API call rate is within acceptable limits.',
      moreDetails: _apiCallCount > 100
          ? 'The number of API calls exceeded the set threshold, indicating potential abuse or malfunction.'
          : 'API usage is normal and within the defined limits.',
    ));

    // Update UI
    setState(() {});
  }

  bool _validateUserInputs(String input) {
    // Ensure input is alphanumeric and of expected length
    return isAlphanumeric(input) && input.length >= 5 && input.length <= 20;
  }

  bool _detectInjectionAttempt(String query) {
    // Detect SQL injection patterns
    List<String> injectionPatterns = [
      'SELECT',
      'DROP',
      'INSERT',
      'DELETE',
      'UPDATE',
      '--',
      ';',
      'OR 1=1'
    ];
    for (var pattern in injectionPatterns) {
      if (query.toUpperCase().contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _checkDataEncryption() async {
    try {
      // Example encryption check: Encrypt and decrypt a sample string
      final key =
          encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1'); // 32 chars
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final plainText = 'Sensitive Data';
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      return decrypted == plainText;
    } catch (e) {
      print('Data encryption check failed: $e');
      return false;
    }
  }

  bool _checkAppTampering() {
    // Implement checksum or signature verification
    // Placeholder implementation
    // In production, calculate the checksum of the app's binary and compare with a known value
    return false;
  }

  void _initializeApiCallMonitoring() {
    // Initialize API call monitoring
    _apiCallTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {
        _apiCallCount = 0;
      });
    });
  }

  void _monitorApiCall() {
    // Call this method every time an API call is made
    _apiCallCount += 1;

    // Example threshold: 100 API calls per minute
    if (_apiCallCount > 100) {
      _securityChecks.add(SecurityCheck(
        name: 'Excessive API Calls',
        status: false,
        details: 'Exceeded the threshold of 100 API calls per minute.',
        moreDetails:
            'The number of API calls exceeded the set threshold, indicating potential abuse or malfunction.',
      ));
      _takeMitigationActions(false, false, false,
          threatName: 'Excessive API Calls');
    }

    // Update UI
    setState(() {});
  }

  Future<void> _takeMitigationActions(
      bool isJailbroken, bool isInjectionAttempt, bool isAppTampered,
      {String threatName = 'Unknown Threat'}) async {
    try {
      // Log the event to Firestore
      await FirebaseFirestore.instance.collection('security_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'threat': isAppTampered
            ? 'App Code Tampering'
            : isJailbroken
                ? 'Device Rooted/Jailbroken'
                : isInjectionAttempt
                    ? 'Injection Attack Attempt'
                    : threatName,
        'details': 'Additional threat details here.',
      });

      // Optionally, you can add this threat to the security checks list
      _securityChecks.add(SecurityCheck(
        name: threatName,
        status: false,
        details: 'Additional details about $threatName.',
        moreDetails: 'Detailed explanation about $threatName.',
      ));

      // Update UI
      setState(() {});

      // Optionally, restrict access or disable certain features
    } catch (e) {
      print('Failed to log security event: $e');
      _showLoggingFailedSnackbar();
    }
  }

  void _showLoggingFailedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Failed to log the security event. Please try again later.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Method to show detailed information when a security check is tapped
  void _showDetailedInfo(SecurityCheck check) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${check.name} Details'),
          content: SingleChildScrollView(
            child:
                Text(check.moreDetails ?? 'No additional details available.'),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
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
        title: const Text('RASP - Security Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _securityChecks.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _securityChecks.length,
                itemBuilder: (context, index) {
                  final check = _securityChecks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    color: check.status ? Colors.green[50] : Colors.red[50],
                    child: ListTile(
                      leading: Icon(
                        check.status ? Icons.check_circle : Icons.error,
                        color: check.status ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        check.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: check.status
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                      subtitle: Text(check.details),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Show detailed information when tapped
                        _showDetailedInfo(check);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
