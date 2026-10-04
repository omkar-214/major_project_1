import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vaultly/pages/login_page.dart';
import 'package:vaultly/pages/setpin_page.dart';
import 'package:vaultly/widgets/customWidget.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _conformpassController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isAgreed = false;

  Future<void> _signUp() async {
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please agree to terms and conditions"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          await user.updateDisplayName(_nameController.text.trim());

          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SetpinPage()),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;

        String errorMessage = "Something went wrong";
        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'The account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
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
    _nameController.dispose();
    _conformpassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                    const SizedBox(height: 10),
                    Container(
                      width: 300,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Column(
                        children: [
                          CustomTextFormField(
                            labelText: "Name",
                            fontWeight: 300,
                            enabledBorder: const Color(0xFFD6DADD),
                            textColor: const Color(0xFFD6DADD),
                            errorBorder: Colors.red,
                            focusedBorder: const Color(0xFFD6DADD),
                            keyboardType: TextInputType.text,
                            prefixIcon: Icons.person,
                            fontSize: 15,
                            controller: _nameController,
                            borderRadius: 20,
                            iconColor: Colors.white,
                            inputAcction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter name";
                              }
                              if (value.contains("@") || value.contains(".")) {
                                return "Name contains alphabets, _, -, numbers";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
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
                                return "Enter Email";
                              }
                              if (!value.contains("@") || !value.contains(".")) {
                                return "Enter valid email";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            labelText: "Password",
                            fontWeight: 300,
                            enabledBorder: const Color(0xFFD6DADD),
                            textColor: const Color(0xFFD6DADD),
                            errorBorder: Colors.red,
                            focusedBorder: const Color(0xFFD6DADD),
                            keyboardType: TextInputType.text,
                            prefixIcon: Icons.lock,
                            fontSize: 15,
                            controller: _passController,
                            borderRadius: 20,
                            iconColor: Colors.white,
                            inputAcction: TextInputAction.next,
                            isObsecure: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter password";
                              }
                              if (value.length < 6) {
                                return "Password contains minimum 6 charecters";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            labelText: "Confrm password",
                            fontWeight: 300,
                            enabledBorder: const Color(0xFFD6DADD),
                            textColor: const Color(0xFFD6DADD),
                            errorBorder: Colors.red,
                            focusedBorder: const Color(0xFFD6DADD),
                            keyboardType: TextInputType.text,
                            prefixIcon: Icons.lock,
                            fontSize: 12,
                            controller: _conformpassController,
                            borderRadius: 20,
                            iconColor: Colors.white,
                            inputAcction: TextInputAction.done,
                            isObsecure: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Confrm password";
                              }
                              if (value != _passController.text) {
                                return "password not match";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Checkbox(
                                value: _isAgreed,
                                activeColor: const Color(0xFF541FAF),
                                checkColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    _isAgreed = newValue ?? false;
                                  });
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  "I agree terms and conditions",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: 250,
                            child: OutlinedButton(
                              onPressed: _signUp,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF541FAF),
                                side: const BorderSide(color: Colors.white, width: 1),
                              ),
                              child: const Text(
                                "Signup",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              const Text(
                                "You alredy hav an account ?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
                                child: const Text(
                                  " Login",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              )
                            ],
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