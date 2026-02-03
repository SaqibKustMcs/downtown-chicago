import 'package:flutter/material.dart';
import 'responsive.dart';
import 'responsive_sizes.dart';

/// Responsive widget that shows different widgets based on device type
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return context.responsiveValue<Widget>(
      mobile: mobile,
      tablet: tablet ?? mobile,
      desktop: desktop ?? tablet ?? mobile,
      largeDesktop: largeDesktop ?? desktop ?? tablet ?? mobile,
    );
  }
}

/// Responsive container with max width constraint
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Decoration? decoration;
  final Alignment? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.decoration,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveSizes.containerMaxWidth(context);
    
    return Container(
      width: double.infinity,
      constraints: maxWidth == double.infinity 
          ? null 
          : BoxConstraints(maxWidth: maxWidth),
      padding: padding ?? ResponsiveSizes.screenPadding(context),
      color: color,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

/// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final EdgeInsets? padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveSizes.gridColumns(context);
    
    return Padding(
      padding: padding ?? ResponsiveSizes.screenPadding(context),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          childAspectRatio: 0.75,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;
  final EdgeInsets? largeDesktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.responsivePadding(
        mobile: mobile ?? ResponsiveSizes.screenPadding(context),
        tablet: tablet,
        desktop: desktop,
        largeDesktop: largeDesktop,
      ),
      child: child,
    );
  }
}

/// Responsive sized box for spacing
class ResponsiveSizedBox extends StatelessWidget {
  final double? mobile;
  final double? tablet;
  final double? desktop;
  final double? largeDesktop;
  final bool isWidth;
  final bool isHeight;

  const ResponsiveSizedBox({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
    this.isWidth = false,
    this.isHeight = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = context.responsiveSize(
      mobile: mobile ?? ResponsiveSizes.spacing(context),
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );

    if (isWidth) {
      return SizedBox(width: size);
    } else if (isHeight) {
      return SizedBox(height: size);
    } else {
      return SizedBox(width: size, height: size);
    }
  }
}

/// Responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final double? largeDesktopFontSize;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.largeDesktopFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = mobileFontSize != null
        ? context.responsiveFontSize(
            mobile: mobileFontSize!,
            tablet: tabletFontSize,
            desktop: desktopFontSize,
            largeDesktop: largeDesktopFontSize,
          )
        : null;

    return Text(
      text,
      style: style?.copyWith(fontSize: fontSize) ?? 
          (fontSize != null ? TextStyle(fontSize: fontSize) : null),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
