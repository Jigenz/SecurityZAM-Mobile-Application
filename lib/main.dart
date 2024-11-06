// lib/main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'authentication.dart';
import 'route_guard.dart'; // Import the RouteGuard
import 'features/root_detection.dart'; // Import RootDetectionPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        AndroidProvider.playIntegrity, // Use PlayIntegrity for production
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Set up a dark theme with a hacking theme feel
  final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: Colors.black,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.greenAccent),
      bodyMedium: TextStyle(color: Colors.greenAccent),
    ),
    appBarTheme: const AppBarTheme(
      color: Colors.black,
      iconTheme: IconThemeData(color: Colors.greenAccent),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Security App',
      theme: theme,
      home: AuthenticationWrapper(), // Set AuthenticationWrapper as home
      routes: {
        '/home': (context) => HomePage(),
        '/authentication': (context) => AuthenticationPage(),
        '/rootDetection': (context) =>
            RootDetectionPage(), // Define RootDetectionPage
        // Add other routes as necessary
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is logged in, show the HomePage
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return AuthenticationPage();
          } else {
            return HomePage();
          }
        }

        // Otherwise, show a loading indicator
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
