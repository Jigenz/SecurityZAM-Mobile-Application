// lib/features/qr_code_support.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:validators/validators.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:clipboard/clipboard.dart'; // For copying text to clipboard
import 'package:shared_preferences/shared_preferences.dart'; // For scan history and preferences
import 'package:mobile_security_app/features/root_detection.dart'; // Import RootDetection

class QrCodeSupportPage extends StatefulWidget {
  const QrCodeSupportPage({Key? key}) : super(key: key);

  @override
  _QrCodeSupportPageState createState() => _QrCodeSupportPageState();
}

class _QrCodeSupportPageState extends State<QrCodeSupportPage> {
  bool _isScanning = true;
  String? _scanResult;
  bool? _isSafe;
  bool _isLoading = false;
  final String _apiKey =
      'YOUR_GOOGLE_SAFE_BROWSING_API_KEY'; // **Replace with your API key securely**

  @override
  void initState() {
    super.initState();
    _checkRootStatus();
  }

  /// Checks if the device is rooted and handles accordingly
  Future<void> _checkRootStatus() async {
    bool isRooted = await RootDetection.isDeviceRooted;
    if (isRooted) {
      _showRootedAlert();
    } else {
      // No auto-open feature; proceed normally
      // If you have other initializations, add them here
    }
  }

  /// Displays an alert if the device is rooted
  void _showRootedAlert() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Security Alert'),
          content: Text(
              'This device appears to be rooted. For security reasons, QR scanning features are disabled.'),
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

  // Method to validate and analyze the scanned QR data
  Future<void> _analyzeQrData(String data) async {
    setState(() {
      _isLoading = true;
      _isScanning = false;
    });

    // Check if the scanned data is a URL
    if (isURL(data, requireTld: true)) {
      await _analyzeUrl(data);
    } else if (_isEmvCoFormat(data)) {
      // Handle EMVCo data
      Map<String, dynamic> paymentInfo = _parseEmvCoData(data);
      await _saveScanHistory(data, isSafe: null); // isSafe is not applicable
      _showPaymentInfoDialog(paymentInfo);
    } else {
      // Handle other non-URL data
      await _saveScanHistory(data, isSafe: null);
      _showNonUrlDataDialog(data);
    }
  }

  // Method to check if data follows EMVCo format
  bool _isEmvCoFormat(String data) {
    // Simple heuristic for EMVCo format
    // EMVCo QR codes typically start with '000201' and contain specific fields
    return data.startsWith('000201') || data.contains('00A1');
  }

  // Method to parse EMVCo data (simplified example)
  Map<String, dynamic> _parseEmvCoData(String data) {
    // Comprehensive EMVCo parsing is complex and beyond this example's scope
    // This is a simplified placeholder for demonstration purposes
    // In production, implement full EMVCo parsing as per specifications

    // Example: Extract Merchant Name, Amount, Currency
    // This example assumes a specific structure for simplicity
    // Replace with actual parsing logic

    // Mock parsed data
    return {
      'Merchant Name': 'Sample Bank',
      'Amount': '\$100.00',
      'Currency': 'USD',
      'Transaction ID': '1234567890',
    };
  }

  // Method to analyze URLs using Google Safe Browsing API
  Future<void> _analyzeUrl(String url) async {
    Map<String, dynamic> safetyResult = await _checkUrlSafety(url);
    bool safe = safetyResult['safe'];
    List<dynamic> threatDetails = safetyResult['details'];

    setState(() {
      _isSafe = safe;
      _isLoading = false;
    });

    if (safe) {
      _showResultDialog(
          title: 'URL is Safe',
          content:
              'The scanned URL has been verified as safe. Would you like to open it?',
          isSafe: true,
          url: url);
    } else {
      String threatInfo = threatDetails.isNotEmpty
          ? 'Threat Types Detected: ${threatDetails.join(", ")}.'
          : 'The scanned URL is potentially unsafe or malicious.';
      _showResultDialog(
          title: 'Unsafe URL Detected',
          content: '$threatInfo It is recommended not to visit this link.',
          isSafe: false);
    }
  }

  // Method to check URL safety using Google Safe Browsing API
  Future<Map<String, dynamic>> _checkUrlSafety(String url) async {
    final String apiUrl =
        'https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$_apiKey';

    final Map<String, dynamic> requestBody = {
      "client": {"clientId": "yourcompanyname", "clientVersion": "1.5.2"},
      "threatInfo": {
        "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING"],
        "platformTypes": ["ANY_PLATFORM"],
        "threatEntryTypes": ["URL"],
        "threatEntries": [
          {"url": url}
        ]
      }
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('matches')) {
          // Extract threat details
          final threats = responseData['matches'] as List<dynamic>;
          List<String> threatTypes =
              threats.map((threat) => threat['threatType'].toString()).toList();
          return {'safe': false, 'details': threatTypes};
        } else {
          // URL is safe
          return {'safe': true, 'details': []};
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        // In case of API error, assume unsafe for safety
        return {
          'safe': false,
          'details': ['API Error']
        };
      }
    } catch (e) {
      print('Exception during URL safety check: $e');
      // In case of exception, assume unsafe for safety
      return {
        'safe': false,
        'details': ['Exception']
      };
    }
  }

  // Method to display results in a dialog
  void _showResultDialog(
      {required String title,
      required String content,
      bool isSafe = false,
      String? url}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (isSafe && url != null)
              TextButton(
                child: Text('Open'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _launchURL(url);
                },
              ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                // Restart scanning
                setState(() {
                  _isScanning = true;
                  _scanResult = null;
                  _isSafe = null;
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Method to display non-URL QR data in a dialog
  void _showNonUrlDataDialog(String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('QR Code Data'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The scanned QR code contains the following data:'),
                SizedBox(height: 10),
                Text(
                  data,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text('Would you like to copy this data?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Copy'),
              onPressed: () {
                FlutterClipboard.copy(data).then((value) => {
                      Navigator.of(context).pop(),
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Data copied to clipboard.'))),
                      // Restart scanning
                      setState(() {
                        _isScanning = true;
                        _scanResult = null;
                        _isSafe = null;
                      }),
                    });
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                // Restart scanning
                setState(() {
                  _isScanning = true;
                  _scanResult = null;
                  _isSafe = null;
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Method to display payment information from EMVCo QR codes
  void _showPaymentInfoDialog(Map<String, dynamic> paymentInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment QR Code'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Merchant Name: ${paymentInfo['Merchant Name']}'),
                Text('Amount: ${paymentInfo['Amount']}'),
                Text('Currency: ${paymentInfo['Currency']}'),
                Text('Transaction ID: ${paymentInfo['Transaction ID']}'),
                const SizedBox(height: 20),
                Text('Do you want to proceed with this payment?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Proceed'),
              onPressed: () {
                // Implement payment processing logic here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Payment processing is not implemented.')));
                setState(() {
                  _isScanning = true;
                  _scanResult = null;
                  _isSafe = null;
                });
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isScanning = true;
                  _scanResult = null;
                  _isSafe = null;
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Method to launch URLs
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      _showResultDialog(
          title: 'Cannot Open URL',
          content: 'Failed to open the URL. Please try again later.');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    // Optionally, save the scan history after opening
    await _saveScanHistory(url, isSafe: true);
  }

  // Method to save scan history
  Future<void> _saveScanHistory(String data, {bool? isSafe}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('scan_history') ?? [];
    String entry = isSafe != null
        ? '$data|${isSafe ? "Safe" : "Unsafe"}'
        : '$data|Unknown';
    history.add(entry);
    await prefs.setStringList('scan_history', history);
  }

  // Method to display scan history
  void _showScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('scan_history') ?? [];

    List<Map<String, dynamic>> parsedHistory = history.map((entry) {
      List<String> parts = entry.split('|');
      return {
        'data': parts[0],
        'status': parts.length > 1 ? parts[1] : 'Unknown',
      };
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Scan History'),
          content: parsedHistory.isEmpty
              ? Text('No scans recorded yet.')
              : Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: parsedHistory.length,
                    itemBuilder: (context, index) {
                      final scan = parsedHistory[index];
                      return ListTile(
                        leading: Icon(
                          scan['status'] == 'Safe'
                              ? Icons.check_circle
                              : scan['status'] == 'Unsafe'
                                  ? Icons.error
                                  : Icons.help,
                          color: scan['status'] == 'Safe'
                              ? Colors.green
                              : scan['status'] == 'Unsafe'
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                        title: Text(scan['data']),
                        subtitle: Text('Status: ${scan['status']}'),
                        onTap: () {
                          // Optionally, handle tap on history items
                          // For example, open URLs if safe
                          if (scan['status'] == 'Safe' &&
                              isURL(scan['data'], requireTld: true)) {
                            _launchURL(scan['data']);
                          }
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              child: Text('Clear History'),
              onPressed: () async {
                await prefs.remove('scan_history');
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Scan history cleared.')));
              },
            ),
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
        title: const Text('QR Code OSINT Scanner'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'View Scan History',
            onPressed: _showScanHistory,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isScanning
              ? MobileScanner(
                  onDetect: (BarcodeCapture barcodeCapture) {
                    final List<Barcode> barcodes = barcodeCapture.barcodes;
                    for (final barcode in barcodes) {
                      final String? code = barcode.rawValue;
                      if (code == null) continue;
                      print('Scanned Code: $code');
                      _scanResult = code;
                      _analyzeQrData(code);
                      break; // Stop after first valid scan
                    }
                  },
                )
              : Container(),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: SpinKitCircle(
                  color: Colors.white,
                  size: 80.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
