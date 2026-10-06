import 'package:flutter/material.dart';

/// A reusable outlined text field matching the Figma "TextField" style.
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final bool enabled;
  final String? errorText;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.errorText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixIcon: !enabled ? const Icon(Icons.lock_outline, size: 18) : null,
      ),
    );
  }
}
