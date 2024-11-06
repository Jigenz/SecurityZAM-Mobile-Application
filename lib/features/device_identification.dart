import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io'; // Import this

class DeviceIdentificationPage extends StatefulWidget {
  const DeviceIdentificationPage({Key? key}) : super(key: key);

  @override
  _DeviceIdentificationPageState createState() =>
      _DeviceIdentificationPageState();
}

class _DeviceIdentificationPageState extends State<DeviceIdentificationPage> {
  String _deviceInfo = '';

  Future<void> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceData;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceData = 'Android ID: ${androidInfo.id}';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceData = 'Identifier for Vendor: ${iosInfo.identifierForVendor}';
    } else {
      deviceData = 'Unsupported Platform';
    }

    setState(() {
      _deviceInfo = deviceData;
    });
  }

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Identification')),
      body: Center(
        child: Text(
          _deviceInfo,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
