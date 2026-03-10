import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class OTPInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autoFocus;
  final ValueChanged<String>? onChanged;

  const OTPInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.autoFocus = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: Sizes.s56,
      height: Sizes.s56,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(Sizes.s12),
        border: Border.all(
          color: Colors.transparent,
          width: 2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autoFocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTextStyles.heading1.copyWith(
          fontSize: Sizes.s24,
          color: isDark
              ? Theme.of(context).colorScheme.onSurface
              : CustomColors.textBoldColor,
        ),
        decoration: InputDecoration(
          counterText: '',
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
          filled: true,
          fillColor: Colors.transparent,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty) {
            FocusScope.of(context).nextFocus();
          } else {
            FocusScope.of(context).previousFocus();
          }
          onChanged?.call(value);
        },
      ),
    );
  }
}
