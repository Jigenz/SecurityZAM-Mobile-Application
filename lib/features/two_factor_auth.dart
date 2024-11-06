// lib/features/two_factor_auth.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_security_app/authentication.dart';
import 'package:mobile_security_app/home_page.dart';
import 'package:mobile_security_app/authentication.dart';

enum VerificationMethod { phone, email }

class TwoFactorAuthPage extends StatefulWidget {
  @override
  _TwoFactorAuthPageState createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends State<TwoFactorAuthPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  String _verificationId = '';
  String _statusMessage = '';
  bool _isCodeSent = false;
  int? _forceResendingToken;
  VerificationMethod _selectedMethod = VerificationMethod.phone;

  Future<void> _verifyPhoneNumber() async {
    setState(() {
      _statusMessage = 'Sending code...';
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Automatic verification or instant verification on some devices
          try {
            await FirebaseAuth.instance.currentUser
                ?.linkWithCredential(credential);

            // Update Firestore to enable 2FA using set() with merge: true
            await FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .set({'isTwoFactorEnabled': true}, SetOptions(merge: true));

            setState(() {
              _statusMessage =
                  'Phone number automatically verified and 2FA enabled.';
            });

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          } catch (e) {
            setState(() {
              _statusMessage =
                  'Failed to link phone credential: ${e.toString()}';
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _statusMessage = 'Verification failed: ${e.message}';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _forceResendingToken = resendToken;
            _statusMessage = 'Code sent. Please check your phone.';
            _isCodeSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _statusMessage = 'Code auto-retrieval timeout.';
          });
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _forceResendingToken,
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to send code: ${e.toString()}';
      });
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _statusMessage = 'Verifying code...';
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _codeController.text.trim(),
      );

      // Link the phone credential with the current user
      await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);

      // Update Firestore to enable 2FA using set() with merge: true
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({'isTwoFactorEnabled': true}, SetOptions(merge: true));

      setState(() {
        _statusMessage = 'Phone number verified successfully!';
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _statusMessage = 'Failed to verify code: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    }
  }

  Future<void> _sendEmailVerification() async {
    setState(() {
      _statusMessage = 'Sending verification email...';
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      // Update the user's email if necessary
      if (_emailController.text.trim().isNotEmpty &&
          _emailController.text.trim() != user?.email) {
        await user?.updateEmail(_emailController.text.trim());
        await user?.reload();
        user = FirebaseAuth.instance.currentUser;
      }

      // Send verification email
      await user?.sendEmailVerification();

      setState(() {
        _statusMessage = 'Verification email sent. Please check your inbox.';
        _isCodeSent = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _statusMessage = 'Failed to send verification email: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    }
  }

  Future<void> _checkEmailVerification() async {
    setState(() {
      _statusMessage = 'Checking email verification...';
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        // Update Firestore to enable 2FA using set() with merge: true
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'isTwoFactorEnabled': true}, SetOptions(merge: true));

        setState(() {
          _statusMessage = 'Email verified successfully!';
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        setState(() {
          _statusMessage = 'Email not verified yet. Please check your inbox.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  Future<void> _skipTwoFactor() async {
    setState(() {
      _statusMessage = 'Skipping Two-Factor Authentication...';
    });

    try {
      // Update Firestore to indicate that 2FA is not enabled using set() with merge: true
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({'isTwoFactorEnabled': false}, SetOptions(merge: true));

      setState(() {
        _statusMessage = 'Two-Factor Authentication skipped.';
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to skip 2FA: ${e.toString()}';
      });
    }
  }

  // Method to navigate back to Authentication Page
  void _navigateBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthenticationPage()),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select verification method:',
          style: TextStyle(fontSize: 18),
        ),
        ListTile(
          title: Text('Phone'),
          leading: Radio<VerificationMethod>(
            value: VerificationMethod.phone,
            groupValue: _selectedMethod,
            onChanged: (VerificationMethod? value) {
              setState(() {
                _selectedMethod = value!;
                _isCodeSent = false;
                _statusMessage = '';
              });
            },
          ),
        ),
        ListTile(
          title: Text('Email'),
          leading: Radio<VerificationMethod>(
            value: VerificationMethod.email,
            groupValue: _selectedMethod,
            onChanged: (VerificationMethod? value) {
              setState(() {
                _selectedMethod = value!;
                _isCodeSent = false;
                _statusMessage = '';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your phone number for verification:',
          style: TextStyle(fontSize: 18),
        ),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
          ),
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _verifyPhoneNumber,
          child: Text('Send Code'),
        ),
        SizedBox(height: 20),
        Text(
          _statusMessage,
          style: TextStyle(
            fontSize: 18,
            color:
                _statusMessage.contains('Failed') ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your email for verification:',
          style: TextStyle(fontSize: 18),
        ),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'example@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _sendEmailVerification,
          child: Text('Send Verification Email'),
        ),
        SizedBox(height: 20),
        Text(
          _statusMessage,
          style: TextStyle(
            fontSize: 18,
            color:
                _statusMessage.contains('Failed') ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedMethod == VerificationMethod.phone) ...[
          Text(
            'Enter the code sent to your phone:',
            style: TextStyle(fontSize: 18),
          ),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Verification Code',
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _verifyCode,
            child: Text('Verify Code'),
          ),
        ] else ...[
          Text(
            'Please verify your email address by clicking the link sent to your email.',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _checkEmailVerification,
            child: Text('I have verified my email'),
          ),
        ],
        SizedBox(height: 20),
        Text(
          _statusMessage,
          style: TextStyle(
            fontSize: 18,
            color:
                _statusMessage.contains('Failed') ? Colors.red : Colors.green,
          ),
        ),
        SizedBox(height: 20),
        TextButton(
          onPressed: _skipTwoFactor,
          child: Text(
            'Skip for now',
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two-Factor Authentication'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildMethodSelector(),
              SizedBox(height: 20),
              if (_isCodeSent)
                _buildCodeVerification()
              else
                _selectedMethod == VerificationMethod.phone
                    ? _buildPhoneInput()
                    : _buildEmailInput(),
            ],
          ),
        ),
      ),
    );
  }
}
