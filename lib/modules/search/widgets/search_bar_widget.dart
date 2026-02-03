import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../styles/styles.dart';
import '../../../core/constants/app_icons.dart';
import 'custom_text_field.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0, top: 70),
      child: Container(
        color: CustomColors.appbarColor,
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: CustomTextField(
          onChanged: onChanged,
          controller: controller,
          borderRadius: 999,
          hintText: "TV shows, movies and more",
          suffixWidget: IconButton(
            icon: SvgPicture.asset(AppIcons.close),
            onPressed: onClear,
            focusNode: focusNode,
          ),
          prefixWidget: SvgPicture.asset(AppIcons.search),
        ),
      ),
    );
  }
}
