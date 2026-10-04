import 'package:flutter/material.dart';
import 'package:vaultly/theme/app_colors.dart';
import 'package:vaultly/utils/format.dart';

OutlineInputBorder _border(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color),
  );
}

InputDecoration inputDeco(String label, {String? hint, IconData? icon}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: AppColors.text),
    hintStyle: const TextStyle(color: Colors.white38),
    prefixIcon: icon == null ? null : Icon(icon, color: Colors.white54),
    filled: true,
    fillColor: AppColors.card,
    enabledBorder: _border(Colors.white24),
    border: _border(Colors.white24),
    focusedBorder: _border(AppColors.accent),
    errorBorder: _border(AppColors.red),
    focusedErrorBorder: _border(AppColors.red),
  );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final EdgeInsets margin;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor ?? Colors.white24),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

Widget choiceChip(String label, bool selected, VoidCallback onTap) {
  return ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    selectedColor: AppColors.primary,
    backgroundColor: AppColors.card,
    labelStyle: const TextStyle(color: Colors.white),
    side: const BorderSide(color: Colors.white24),
  );
}

class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    Widget? clearButton;
    if (onClear != null && value != null) {
      clearButton = IconButton(
        icon: const Icon(Icons.close, color: Colors.white54),
        onPressed: onClear,
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: inputDeco(label, icon: Icons.calendar_today).copyWith(
          suffixIcon: clearButton,
        ),
        child: Text(
          value == null ? "Not set" : fmtDate(value!),
          style: TextStyle(
            color: value == null ? Colors.white38 : Colors.white,
          ),
        ),
      ),
    );
  }
}

void showMsg(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<bool> confirmDialog(
    BuildContext context,
    String title,
    String message,
    ) async {
  bool? result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(message, style: const TextStyle(color: AppColors.text)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            "Confirm",
            style: TextStyle(color: AppColors.red),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

AppBar pageBar(String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: AppColors.primary,
    iconTheme: const IconThemeData(color: Colors.white),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w400,
      ),
    ),
    actions: actions,
  );
}