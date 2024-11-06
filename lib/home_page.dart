// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'feature_list.dart';
import 'authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/two_factor_auth.dart';
import 'terms_of_service.dart'; // Import the ToS page

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  Future<bool> _isTwoFactorEnabled() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return false;

    return userDoc.get('isTwoFactorEnabled') ?? false;
  }

  Widget _buildDrawerHeader(User? user) {
    return UserAccountsDrawerHeader(
      accountName: Text(user?.displayName ?? 'Guest User'),
      accountEmail: Text(user?.email ?? ''),
      currentAccountPicture: CircleAvatar(
        backgroundImage: user?.photoURL != null && user!.photoURL!.isNotEmpty
            ? NetworkImage(user.photoURL!)
            : const AssetImage('assets/bb3.png') as ImageProvider,
      ),
      decoration: BoxDecoration(
        color: Colors.green,
        image: DecorationImage(
          image: const AssetImage('assets/bb5.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, User? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(user),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              // Close the drawer and stay on Home
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () async {
              // Check 2FA status before navigating
              bool isTwoFactorEnabled = await _isTwoFactorEnabled();
              if (!isTwoFactorEnabled) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TwoFactorAuthPage()),
                );
              } else {
                // Navigate to Profile page
                Navigator.pop(context);
                // Implement navigation to ProfilePage if available
                // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () async {
              // Check 2FA status before navigating
              bool isTwoFactorEnabled = await _isTwoFactorEnabled();
              if (!isTwoFactorEnabled) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TwoFactorAuthPage()),
                );
              } else {
                // Navigate to Settings page
                Navigator.pop(context);
                // Implement navigation to SettingsPage if available
                // Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TermsOfServicePage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              // Handle logout
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthenticationPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String? photoURL = currentUser?.photoURL;
    String? username = currentUser?.displayName ?? 'User';
    String? email = currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Features'),
      ),
      drawer: _buildDrawer(context, currentUser),
      body: FeatureList(),
    );
  }
}
