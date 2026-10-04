import 'package:flutter/material.dart';
import 'package:vaultly/pages/home_page.dart';
import 'package:vaultly/widgets/customWidget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SetpinPage extends StatefulWidget {
  const SetpinPage({super.key});

  @override
  State<SetpinPage> createState() => _SetpinPageState();
}

class _SetpinPageState extends State<SetpinPage> {
  final TextEditingController _setPin = TextEditingController();
  final TextEditingController _confrmPin = TextEditingController();

  final GlobalKey<FormState> _fomrKey = GlobalKey<FormState>();
  final storage = const FlutterSecureStorage();

  Future<void> _savePin() async {
    if (_fomrKey.currentState!.validate()) {
      await storage.write(key: 'user_pin', value: _setPin.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pin set successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong!")),
      );
    }
  }

  @override
  void dispose() {
    _setPin.dispose();
    _confrmPin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: AppBar(
        title: const Center(
          child: Text(
            "Set Pin",
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
                    key: _fomrKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        CustomTextFormField(
                          labelText: "Set Pin",
                          fontWeight: 300,
                          enabledBorder: const Color(0xFFD6DADD),
                          textColor: const Color(0xFFD6DADD),
                          errorBorder: Colors.red,
                          focusedBorder: const Color(0xFFD6DADD),
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.key,
                          fontSize: 12,
                          controller: _setPin,
                          borderRadius: 20,
                          iconColor: Colors.white,
                          inputAcction: TextInputAction.next,
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
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          labelText: "Confirm Pin",
                          fontWeight: 300,
                          enabledBorder: const Color(0xFFD6DADD),
                          textColor: const Color(0xFFD6DADD),
                          errorBorder: Colors.red,
                          focusedBorder: const Color(0xFFD6DADD),
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.key,
                          fontSize: 12,
                          controller: _confrmPin,
                          borderRadius: 20,
                          iconColor: Colors.white,
                          inputAcction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter Pin";
                            }
                            if (value != _setPin.text) {
                              return "Pin not match";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 60),
                        Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  "back",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 50),
                            SizedBox(
                              width: 100,
                              child: OutlinedButton(
                                onPressed: _savePin,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFF541FAF),
                                ),
                                child: const Text(
                                  "Set pin",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
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