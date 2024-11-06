// feature_list.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/root_detection.dart';

import 'features/secure_storage.dart';
import 'features/geolocation.dart';
import 'features/rasp.dart';
import 'features/risk_scoring.dart';
import 'features/two_factor_auth.dart';
import 'features/transaction_signing.dart';
import 'features/secure_communications.dart';
import 'features/qr_code_support.dart';
import 'features/device_identification.dart';
// Import other feature files as needed

class FeatureList extends StatelessWidget {
  final List<Map<String, dynamic>> features = [
    {
      'title': 'Jailbreak & Root Detection',
      'icon': Icons.security,
      'widget': RootDetectionPage(),
    },

    {
      'title': 'Geolocation',
      'icon': Icons.location_on,
      'widget': GeolocationPage(),
    },
    {
      'title': 'RASP',
      'icon': Icons.shield,
      'widget': RaspPage(),
    },
    {
      'title': 'Risk-Based Scoring',
      'icon': Icons.assessment,
      'widget': RiskScoringPage(),
    },
    {
      'title': 'Two-Factor Authentication',
      'icon': Icons.verified_user,
      'widget': TwoFactorAuthPage(),
    },

    {
      'title': 'QR Code Support',
      'icon': Icons.qr_code,
      'widget': QrCodeSupportPage(),
    },
    {
      'title': 'Device Identification',
      'icon': Icons.devices,
      'widget': DeviceIdentificationPage(),
    },
    // Add more features as needed
  ];

  Future<bool> _isTwoFactorEnabled() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.get('isTwoFactorEnabled') ?? false;
      } else {
        // If the document doesn't exist, consider 2FA as not enabled
        return false;
      }
    } catch (e) {
      print('Error fetching two-factor status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isTwoFactorEnabled(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error fetching two-factor status.'),
          );
        }

        bool isTwoFactorEnabled = snapshot.data ?? false;

        if (!isTwoFactorEnabled) {
          // Redirect to TwoFactorAuthPage
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TwoFactorAuthPage()),
            );
          });

          return Center(
            child: Text('Redirecting to Two-Factor Authentication...'),
          );
        }

        // If 2FA is enabled, display the feature list
        return GridView.builder(
          padding: EdgeInsets.all(16.0),
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Adjust to 2 or 3 depending on screen size
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // Navigate to the selected feature's page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => features[index]['widget'],
                  ),
                );
              },
              child: Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      features[index]['icon'],
                      size: 50,
                      color: Colors.greenAccent,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      features[index]['title'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // You can add a brief description here if desired
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
