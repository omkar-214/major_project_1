import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaultly/pages/setpin_page.dart';
import 'package:vaultly/pages/enter_pin_page.dart';
import 'package:vaultly/pages/signup_page.dart';
import 'package:vaultly/widgets/customWidget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final storage = const FlutterSecureStorage();

  Future<void> _logIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        if (!mounted) return;

        String? savedPin = await storage.read(key: 'user_pin');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful!"),
            backgroundColor: Colors.green,
          ),
        );

        if (savedPin != null && savedPin.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EnterPinPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SetpinPage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;

        String errorMessage = "Login failed!";
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for this email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is invalid.';
        } else if (e.code == 'invalid-credential') {
          errorMessage = 'Invalid email or password.';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'This user account has been disabled.';
        } else {
          errorMessage = e.message ?? errorMessage;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset(
                      "asset/image/loginlogo.png",
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 350,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Column(
                        children: [
                          CustomTextFormField(
                            inputAcction: TextInputAction.next,
                            labelText: "Email",
                            fontWeight: 300,
                            enabledBorder: const Color(0xFFD6DADD),
                            textColor: const Color(0xFFD6DADD),
                            errorBorder: Colors.red,
                            focusedBorder: const Color(0xFFD6DADD),
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email,
                            fontSize: 12,
                            controller: _emailController,
                            borderRadius: 20,
                            iconColor: Colors.white,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter email";
                              }
                              if (!value.contains("@") || !value.contains(".")) {
                                return "Enter valid email";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          CustomTextFormField(
                            inputAcction: TextInputAction.done,
                            labelText: "Password",
                            fontWeight: 300,
                            enabledBorder: const Color(0xFFD6DADD),
                            textColor: const Color(0xFFD6DADD),
                            errorBorder: Colors.red,
                            focusedBorder: const Color(0xFFD6DADD),
                            keyboardType: TextInputType.text,
                            prefixIcon: Icons.lock,
                            fontSize: 12,
                            controller: _passController,
                            borderRadius: 20,
                            iconColor: Colors.white,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter Password";
                              }
                              if (value.length < 6) {
                                return "Minimum six letters required";
                              }
                              return null;
                            },
                            isObsecure: true,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 250,
                            child: OutlinedButton(
                              onPressed: _logIn,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF541FAF),
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                const Text(
                                  "You don't have an account ?",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignupPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    " Signup",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}