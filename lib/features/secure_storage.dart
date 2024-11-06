import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStoragePage extends StatefulWidget {
  @override
  _SecureStoragePageState createState() => _SecureStoragePageState();
}

class _SecureStoragePageState extends State<SecureStoragePage> {
  final _storage = FlutterSecureStorage();
  String _storedValue = '';

  Future<void> _writeData() async {
    await _storage.write(key: 'secureKey', value: 'SensitiveData123');
    _readData();
  }

  Future<void> _readData() async {
    String? value = await _storage.read(key: 'secureKey');
    setState(() {
      _storedValue = value ?? 'No Data Found';
    });
  }

  @override
  void initState() {
    super.initState();
    _writeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Secure Storage')),
      body: Center(
        child: Text(
          'Stored Value: $_storedValue',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
