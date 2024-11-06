import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SecureCommunicationsPage extends StatefulWidget {
  @override
  _SecureCommunicationsPageState createState() =>
      _SecureCommunicationsPageState();
}

class _SecureCommunicationsPageState extends State<SecureCommunicationsPage> {
  String _response = '';

  Future<void> _makeSecureRequest() async {
    try {
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
      );
      setState(() {
        _response = response.body;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _makeSecureRequest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Secure Communications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _response,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
