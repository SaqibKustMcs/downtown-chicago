import 'package:flutter/material.dart';
import '../../../styles/styles.dart';
import '../../../styles/layouts/sizes.dart';
import '../../../styles/typography/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final Color? backgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final String? Function(String?)? validator;
  final bool enabled;
  final Color? borderColor;
  final double? borderWidth;

  const CustomTextField({
    Key? key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.hintStyle,
    this.textStyle,
    this.prefixWidget,
    this.suffixWidget,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.contentPadding,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.validator,
    this.enabled = true,
    this.borderColor,
    this.borderWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? CustomColors.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? const Color(0xFFF2F2F6), width: borderWidth ?? 1.0),
      ),
      child: Row(
        children: [
          if (prefixWidget != null) ...[Padding(padding: const EdgeInsets.only(left: 16), child: prefixWidget!), const SizedBox(width: 12)],
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              style: textStyle ?? AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: hintStyle ?? AppTextStyles.bodyLargeSecondary,
                border: OutlineInputBorder(borderSide: BorderSide(width: 1, color: Color(0xffF2F2F6))),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: contentPadding ?? EdgeInsets.symmetric(horizontal: prefixWidget == null ? 16 : 0, vertical: 16),
              ),
              onChanged: onChanged,
              onTap: onTap,
              readOnly: readOnly,
              keyboardType: keyboardType,
              maxLines: maxLines,
              minLines: minLines,
              obscureText: obscureText,
              validator: validator,
              enabled: enabled,
            ),
          ),
          if (suffixWidget != null) ...[const SizedBox(width: 8), Padding(padding: const EdgeInsets.only(right: 8), child: suffixWidget!)],
        ],
      ),
    );
  }
}
