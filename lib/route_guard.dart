// route_guard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/two_factor_auth.dart';

class RouteGuard extends StatefulWidget {
  final Widget child;

  RouteGuard({required this.child});

  @override
  _RouteGuardState createState() => _RouteGuardState();
}

class _RouteGuardState extends State<RouteGuard> {
  bool _isLoading = true;
  bool _isTwoFactorEnabled = false;

  Future<void> _checkTwoFactor() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        _isTwoFactorEnabled = userDoc.get('isTwoFactorEnabled') ?? false;
      } else {
        // If the document doesn't exist, create it with isTwoFactorEnabled = false
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'isTwoFactorEnabled': false, 'email': user.email ?? ''});
        _isTwoFactorEnabled = false;
      }
    } catch (e) {
      // Handle any errors during Firestore access
      print('Error checking two-factor status: $e');
      _isTwoFactorEnabled = false;
    }

    setState(() {
      _isLoading = false;
    });

    if (!_isTwoFactorEnabled) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TwoFactorAuthPage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkTwoFactor();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}
