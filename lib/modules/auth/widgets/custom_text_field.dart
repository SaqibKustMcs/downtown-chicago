import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  /// Custom error text shown below the field (reactive). When set, overrides validator error.
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.maxLines,
    this.inputFormatters,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      validator: errorText != null ? (_) => errorText : validator,
      maxLines: maxLines ?? 1,
      inputFormatters: inputFormatters,
      enabled: enabled,
      style: TextStyle(
        color: isDark
            ? Theme.of(context).colorScheme.onSurface
            : CustomColors.textBoldColor,
        fontSize: Sizes.s14,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
              : CustomColors.secondaryTextColor.withOpacity(0.6),
          fontSize: Sizes.s14,
          fontFamily: 'Poppins',
        ),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade800
            : const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.s16,
          vertical: Sizes.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
          borderSide: const BorderSide(
            color: Color(0xFFFF6B35),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
