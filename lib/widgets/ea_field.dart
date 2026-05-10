import 'package:flutter/material.dart';

class EAField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? autofillHint;
  final String? errorText;
  final Color accent;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;

  const EAField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.accent,
    this.keyboardType,
    this.obscure = false,
    this.autofillHint,
    this.errorText,
    this.onChanged,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      autofillHints: autofillHint == null ? null : [autofillHint!],
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(
        color: Color(0xCCFFFFFF),
        fontSize: 12,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0x55FFFFFF),
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0x28FFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.5,
        ),
        errorText: errorText,
        errorStyle: const TextStyle(
          color: Color(0xAAFF5555),
          fontSize: 10,
          letterSpacing: 0.5,
        ),
        suffixIcon: suffix,
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0x18FFFFFF)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0x18FFFFFF)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent.withOpacity(0.5)),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0x88FF5555)),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xAAFF5555)),
        ),
        contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
      ),
    );
  }
}
