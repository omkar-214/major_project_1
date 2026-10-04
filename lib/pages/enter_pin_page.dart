import 'package:flutter/material.dart';
import 'package:vaultly/pages/home_page.dart';
import 'package:vaultly/widgets/customWidget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EnterPinPage extends StatefulWidget {
  const EnterPinPage({super.key});

  @override
  State<EnterPinPage> createState() => _EnterPinPageState();
}

class _EnterPinPageState extends State<EnterPinPage> {
  final TextEditingController _enterPin = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final storage = const FlutterSecureStorage();

  Future<void> _verifyPin() async {
    if (_formKey.currentState!.validate()) {
      String? savedPin = await storage.read(key: 'user_pin');

      if (savedPin == _enterPin.text.trim()) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PIN matched! Welcome"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Incorrect PIN! Please try again"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _enterPin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center(
          child: Text(
            "Enter Pin",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF541FAF),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 300,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        CustomTextFormField(
                          labelText: "Enter Pin",
                          fontWeight: 300,
                          enabledBorder: const Color(0xFFD6DADD),
                          textColor: const Color(0xFFD6DADD),
                          errorBorder: Colors.red,
                          focusedBorder: const Color(0xFFD6DADD),
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.key,
                          fontSize: 12,
                          controller: _enterPin,
                          borderRadius: 20,
                          iconColor: Colors.white,
                          inputAcction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter Pin";
                            }
                            final numRegExp = RegExp(r'^[0-9]+$');
                            if (!numRegExp.hasMatch(value)) {
                              return "Pin contains numbers only";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 140,
                          child: OutlinedButton(
                            onPressed: () {
                              _verifyPin();
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF541FAF),
                              side: const BorderSide(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              "Unlock",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}