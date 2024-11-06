// authentication.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'features/two_factor_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:clipboard/clipboard.dart'; // For copying text to clipboard
import 'package:shared_preferences/shared_preferences.dart'; // For scan history and preferences

class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage>
    with SingleTickerProviderStateMixin {
  // Controllers for Sign-In
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  // Controllers for Sign-Up
  final _signUpUsernameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  // Form keys for validation
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // Status messages
  String _signInStatusMessage = '';
  String _signUpStatusMessage = '';

  // Loading flags
  bool _isSigningIn = false;
  bool _isSigningUp = false;

  // Tab Controller
  late TabController _tabController;

  // Password visibility flags
  bool _isSignInPasswordVisible = false;
  bool _isSignUpPasswordVisible = false;
  bool _isSignUpConfirmPasswordVisible = false;

  // Profile Image for Sign-Up
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // API Key (Ensure to secure this as per Additional Recommendations)
  final String _apiKey =
      'YOUR_GOOGLE_SAFE_BROWSING_API_KEY'; // Replace with your API key securely

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  // Dispose controllers when not needed
  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpUsernameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Method to pick profile image from gallery
  Future<void> _pickProfileImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Method to check if username is taken
  Future<bool> _isUsernameTaken(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Method to upload profile image to Firebase Storage and get the download URL
  Future<String?> _uploadProfileImage(String uid) async {
    if (_profileImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      UploadTask uploadTask = storageRef.putFile(_profileImage!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Method to sign up a new user
  Future<void> _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) {
      // If the form is not valid, do not proceed
      return;
    }

    setState(() {
      _isSigningUp = true;
      _signUpStatusMessage = 'Signing up...';
    });

    String username = _signUpUsernameController.text.trim();

    try {
      // Check if the username is already taken
      bool usernameTaken = await _isUsernameTaken(username);
      if (usernameTaken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username is already taken.'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _signUpStatusMessage = 'Signup failed: Username is already taken.';
        });

        return;
      }

      // Create a new user with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _signUpEmailController.text.trim(),
        password: _signUpPasswordController.text.trim(),
      );

      // Upload profile image and get download URL
      String? photoURL = await _uploadProfileImage(userCredential.user!.uid);

      // Update the FirebaseAuth user profile with the displayName and photoURL
      await userCredential.user?.updateDisplayName(username);
      if (photoURL != null) {
        await userCredential.user?.updatePhotoURL(photoURL);
      }

      // Create a Firestore document for the user with isTwoFactorEnabled set to false
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'isTwoFactorEnabled': false,
        'email': _signUpEmailController.text.trim(),
        'username': username,
        'photoURL': photoURL ?? '',
        // Add other user fields as needed
      });

      setState(() {
        _signUpStatusMessage = 'Signup successful!';
      });

      // Navigate to Two-Factor Authentication page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TwoFactorAuthPage()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      String error = '';
      switch (e.code) {
        case 'email-already-in-use':
          error = 'The email address is already in use.';
          break;
        case 'invalid-email':
          error = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          error = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          error = 'The password is too weak.';
          break;
        default:
          error = 'An undefined Error happened.';
      }

      setState(() {
        _signUpStatusMessage = 'Signup failed: $error';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Handle any other errors
      setState(() {
        _signUpStatusMessage = 'Signup failed: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSigningUp = false;
      });
    }
  }

  // Method to sign in an existing user
  Future<void> _signIn() async {
    if (!_signInFormKey.currentState!.validate()) {
      // If the form is not valid, do not proceed
      return;
    }

    setState(() {
      _isSigningIn = true;
      _signInStatusMessage = 'Signing in...';
    });

    try {
      // Sign in the user with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _signInEmailController.text.trim(),
        password: _signInPasswordController.text.trim(),
      );

      // Fetch the user's Firestore document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        bool isTwoFactorEnabled = userDoc.get('isTwoFactorEnabled') ?? false;

        if (isTwoFactorEnabled) {
          // If 2FA is enabled, navigate to HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          // If 2FA is not enabled, navigate to TwoFactorAuthPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TwoFactorAuthPage()),
          );
        }
      } else {
        // If the user document does not exist, create it and navigate to 2FA
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'isTwoFactorEnabled': false,
          'email': _signInEmailController.text.trim(),
          'username':
              userCredential.user?.displayName ?? '', // Retrieve displayName
          'photoURL': userCredential.user?.photoURL ?? '',
          // Add other user fields as needed
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TwoFactorAuthPage()),
        );
      }

      setState(() {
        _signInStatusMessage = 'Sign-in successful!';
      });
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      String error = '';
      switch (e.code) {
        case 'invalid-email':
          error = 'The email address is not valid.';
          break;
        case 'user-disabled':
          error = 'This user has been disabled.';
          break;
        case 'user-not-found':
          error = 'No user found for this email.';
          break;
        case 'wrong-password':
          error = 'Incorrect password.';
          break;
        default:
          error = 'An undefined Error happened.';
      }

      setState(() {
        _signInStatusMessage = 'Sign-in failed: $error';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Handle any other errors
      setState(() {
        _signInStatusMessage = 'Sign-in failed: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSigningIn = false;
      });
    }
  }

  // Method to reset password
  Future<void> _resetPassword() async {
    String email = _signInEmailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email to reset password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent.'),
          backgroundColor: Colors.greenAccent,
        ),
      );
      setState(() {
        _signInStatusMessage = 'Password reset email sent.';
      });
    } on FirebaseAuthException catch (e) {
      String error = '';
      switch (e.code) {
        case 'invalid-email':
          error = 'The email address is not valid.';
          break;
        case 'user-not-found':
          error = 'No user found for this email.';
          break;
        default:
          error = 'An undefined Error happened.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset failed: $error'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _signInStatusMessage = 'Password reset failed: $error';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _signInStatusMessage = 'Password reset failed: ${e.toString()}';
      });
    }
  }

  // Build the Sign-In Form
  Widget _buildSignInForm() {
    return SingleChildScrollView(
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email TextField
            TextFormField(
              controller: _signInEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                // Basic email validation
                if (value == null || value.isEmpty) {
                  return 'Please enter your email.';
                }
                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // Password TextField with visibility toggle
            TextFormField(
              controller: _signInPasswordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isSignInPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSignInPasswordVisible = !_isSignInPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isSignInPasswordVisible,
              validator: (value) {
                // Basic password validation
                if (value == null || value.isEmpty) {
                  return 'Please enter your password.';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters long.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),

            // Sign In Button
            ElevatedButton(
              onPressed: _isSigningIn ? null : _signIn,
              child: _isSigningIn
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            const SizedBox(height: 24.0),

            // Status Message
            Center(
              child: Text(
                _signInStatusMessage,
                style: TextStyle(
                  color: _signInStatusMessage.contains('failed')
                      ? Colors.red
                      : Colors.greenAccent,
                  fontSize: 16.0,
                ),
              ),
            ),

            const SizedBox(height: 16.0),

            // Forgot Password Button
            TextButton(
              onPressed: () {
                _resetPassword();
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the Sign-Up Form
  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      child: Form(
        key: _signUpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Picture Selector
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.add_a_photo,
                          size: 50, color: Colors.white)
                      : null,
                  backgroundColor: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Username TextField
            TextFormField(
              controller: _signUpUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a username.';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters long.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // Email TextField
            TextFormField(
              controller: _signUpEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                // Basic email validation
                if (value == null || value.isEmpty) {
                  return 'Please enter your email.';
                }
                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // Password TextField with visibility toggle
            TextFormField(
              controller: _signUpPasswordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isSignUpPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSignUpPasswordVisible = !_isSignUpPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isSignUpPasswordVisible,
              validator: (value) {
                // Basic password validation
                if (value == null || value.isEmpty) {
                  return 'Please enter your password.';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters long.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // Confirm Password TextField with visibility toggle
            TextFormField(
              controller: _signUpConfirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isSignUpConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSignUpConfirmPasswordVisible =
                          !_isSignUpConfirmPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isSignUpConfirmPasswordVisible,
              validator: (value) {
                // Confirm password validation
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password.';
                }
                if (value != _signUpPasswordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),

            // Sign Up Button
            ElevatedButton(
              onPressed: _isSigningUp ? null : _signUp,
              child: _isSigningUp
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Sign Up'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            const SizedBox(height: 24.0),

            // Status Message
            Center(
              child: Text(
                _signUpStatusMessage,
                style: TextStyle(
                  color: _signUpStatusMessage.contains('failed')
                      ? Colors.red
                      : Colors.greenAccent,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the TabBar and TabBarView
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SecurityZAM',
          style: TextStyle(
            color: Colors.greenAccent, // Set the color to greenAccent
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Sign Up'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Sign In Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSignInForm(),
          ),

          // Sign Up Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSignUpForm(),
          ),
        ],
      ),
    );
  }
}
