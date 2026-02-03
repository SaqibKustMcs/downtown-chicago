import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/styles.dart';
import '../../styles/typography/app_text_styles.dart';
import '../../core/constants/app_icons.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearchIcon;
  final VoidCallback? onSearchPressed;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showSearchIcon = false,
    this.onSearchPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: CustomColors.appbarColor,
      elevation: 0,
      title: Text(title, style: AppTextStyles.appBarTitle),
      actions: [
        if (showSearchIcon)
          IconButton(
            icon: SvgPicture.asset(AppIcons.search),
            onPressed: onSearchPressed ?? () => Navigator.pushNamed(context, '/search'),
          ),
        if (actions != null) ...actions!,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEFEFEF), width: 1)),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
