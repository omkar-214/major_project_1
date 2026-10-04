import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final String labelText;
  final int fontWeight;
  final bool isObsecure;
  final TextInputType keyboardType;
  final Color textColor;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final Color focusedBorder;
  final Color errorBorder;
  final Color enabledBorder;
  final double fontSize;
  final TextEditingController controller;
  final double borderRadius;
  final Color iconColor;
  final TextInputAction inputAcction;

  const CustomTextFormField({
    super.key,
    required this.labelText,
    required this.fontWeight,
    this.isObsecure = false,
    required this.enabledBorder,
    required this.textColor,
    required this.errorBorder,
    required this.focusedBorder,
    required this.keyboardType,
    required this.prefixIcon,
    this.validator,
    required this.fontSize,
    required this.controller,
    required this.borderRadius,
    required this.iconColor,
    required this.inputAcction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textInputAction: inputAcction,
      obscureText: isObsecure,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight(fontWeight),
      ),
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: iconColor)
            : null,
        labelText: labelText,
        labelStyle: TextStyle(
          color: textColor,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: enabledBorder,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: enabledBorder,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: enabledBorder,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      validator: validator,
    );
  }
}
