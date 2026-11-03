import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
    this.enabled = true,
    this.prefixIcon,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final IconData? prefixIcon;
  final String? helperText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscured,
          enabled: widget.enabled,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          autofillHints: widget.autofillHints,
          style: const TextStyle(color: Colors.white, fontSize: 15.5),
          cursorColor: AppColors.red,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            helperMaxLines: 2,
            helperStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
            ),
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 20, color: AppColors.textMuted),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
