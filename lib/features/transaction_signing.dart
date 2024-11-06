import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';

class TransactionSigningPage extends StatefulWidget {
  @override
  _TransactionSigningPageState createState() => _TransactionSigningPageState();
}

class _TransactionSigningPageState extends State<TransactionSigningPage> {
  String _signature = '';

  Future<void> _signTransaction() async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final message = utf8.encode('Sample Transaction Data');

    final signature = await algorithm.sign(
      message,
      keyPair: keyPair,
    );

    setState(() {
      _signature = base64Encode(signature.bytes);
    });
  }

  @override
  void initState() {
    super.initState();
    _signTransaction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction Signing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Signature:\n$_signature',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
