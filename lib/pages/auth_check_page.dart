import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaultly/pages/login_page.dart';
import 'package:vaultly/pages/setpin_page.dart';
import 'package:vaultly/pages/enter_pin_page.dart';

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _navigateTo(const LoginPage());
        return;
      }

      String? savedPin = await storage.read(key: 'user_pin').timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (savedPin == null || savedPin.isEmpty) {
        _navigateTo(const SetpinPage());
      } else {
        _navigateTo(const EnterPinPage());
      }
    } catch (e) {
      _navigateTo(const LoginPage());
    }
  }

  void _navigateTo(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A1020),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF541FAF),
        ),
      ),
    );
  }
}