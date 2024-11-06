import 'package:flutter/material.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:geolocator/geolocator.dart';

class RiskScoringPage extends StatefulWidget {
  const RiskScoringPage({Key? key}) : super(key: key);

  @override
  _RiskScoringPageState createState() => _RiskScoringPageState();
}

class _RiskScoringPageState extends State<RiskScoringPage> {
  int _riskScore = 0;
  String _riskLevel = 'Calculating Risk...';

  Future<void> _calculateRiskScore() async {
    int score = 0;

    // Root/Jailbreak Detection
    bool isJailbroken;
    try {
      isJailbroken = await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      isJailbroken = false;
      print('Error checking jailbreak status: $e');
    }

    if (isJailbroken) score += 50;

    // Geolocation (e.g., if outside a certain region)
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Example condition: latitude greater than 50.0
    if (position.latitude > 50.0) score += 50;

    // Update Risk Level
    String level;
    if (score < 50) {
      level = 'Low Risk';
    } else if (score < 100) {
      level = 'Medium Risk';
    } else {
      level = 'High Risk';
    }

    setState(() {
      _riskScore = score;
      _riskLevel = level;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculateRiskScore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Risk-Based Scoring')),
      body: Center(
        child: Text(
          'Risk Score: $_riskScore ($_riskLevel)',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
