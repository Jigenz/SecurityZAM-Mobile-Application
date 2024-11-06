import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    String? photoURL = user?.photoURL;
    String? username = user?.displayName ?? 'User';
    String? email = user?.email ?? 'No email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
              child:
                  photoURL == null ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 20),
            Text(
              username,
              style: const TextStyle(fontSize: 24, color: Colors.greenAccent),
            ),
            const SizedBox(height: 10),
            Text(
              email,
              style: const TextStyle(fontSize: 18, color: Colors.greenAccent),
            ),
            // Add more profile details or options here
          ],
        ),
      ),
    );
  }
}
