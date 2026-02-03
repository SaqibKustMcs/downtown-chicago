# Responsive Design Usage Examples

This document shows how to use the responsive system in your Flutter app.

## Table of Contents
1. [Basic Usage](#basic-usage)
2. [Device Type Detection](#device-type-detection)
3. [Platform Detection](#platform-detection)
4. [Responsive Sizing](#responsive-sizing)
5. [Responsive Widgets](#responsive-widgets)
6. [Common Patterns](#common-patterns)

---

## Basic Usage

### Import the responsive utilities

```dart
import 'package:flutter/material.dart';
import 'package:flutter_task_app/core/utils/responsive.dart';
import 'package:flutter_task_app/core/utils/responsive_sizes.dart';
import 'package:flutter_task_app/core/utils/responsive_widgets.dart';
```

### Access responsive properties

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Quick access to device type
    if (context.isMobile) {
      // Mobile-specific code
    }
    
    if (context.isTablet) {
      // Tablet-specific code
    }
    
    if (context.isDesktop) {
      // Desktop-specific code
    }
    
    return Scaffold(
      body: Container(),
    );
  }
}
```

---

## Device Type Detection

### Check device type

```dart
Widget build(BuildContext context) {
  final deviceType = context.deviceType;
  
  switch (deviceType) {
    case DeviceType.mobile:
      return MobileLayout();
    case DeviceType.tablet:
      return TabletLayout();
    case DeviceType.desktop:
      return DesktopLayout();
    case DeviceType.largeDesktop:
      return LargeDesktopLayout();
  }
}
```

### Conditional rendering based on device

```dart
Widget build(BuildContext context) {
  return context.responsiveValue<Widget>(
    mobile: MobileView(),
    tablet: TabletView(),
    desktop: DesktopView(),
    largeDesktop: LargeDesktopView(),
  );
}
```

---

## Platform Detection

### Check platform

```dart
Widget build(BuildContext context) {
  if (context.isAndroid) {
    // Android-specific code
  }
  
  if (context.isIOS) {
    // iOS-specific code
  }
  
  if (context.isWeb) {
    // Web-specific code
  }
  
  if (context.isDesktopPlatform) {
    // Desktop platform code (Windows, macOS, Linux)
  }
}
```

### Platform-specific styling

```dart
Widget build(BuildContext context) {
  final buttonColor = context.responsiveValue<Color>(
    mobile: Colors.blue,
    tablet: Colors.green,
    desktop: Colors.purple,
  );
  
  return ElevatedButton(
    style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
    onPressed: () {},
    child: Text('Button'),
  );
}
```

---

## Responsive Sizing

### Responsive padding

```dart
Widget build(BuildContext context) {
  return Padding(
    padding: context.responsivePadding(
      mobile: EdgeInsets.all(16.0),
      tablet: EdgeInsets.all(24.0),
      desktop: EdgeInsets.all(32.0),
    ),
    child: Text('Content'),
  );
}

// Or use predefined sizes
Widget build(BuildContext context) {
  return Padding(
    padding: ResponsiveSizes.screenPadding(context),
    child: Text('Content'),
  );
}
```

### Responsive font size

```dart
Widget build(BuildContext context) {
  return Text(
    'Hello World',
    style: TextStyle(
      fontSize: context.responsiveFontSize(
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
        largeDesktop: 28.0,
      ),
    ),
  );
}

// Or use predefined text styles
Widget build(BuildContext context) {
  return Text(
    'Hello World',
    style: ResponsiveTextStyles.headline(context),
  );
}
```

### Responsive spacing

```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Item 1'),
      SizedBox(height: ResponsiveSizes.spacing(context)),
      Text('Item 2'),
      SizedBox(height: ResponsiveSizes.spacingLarge(context)),
      Text('Item 3'),
    ],
  );
}
```

### Responsive width/height

```dart
Widget build(BuildContext context) {
  return Container(
    width: context.widthPercent(90), // 90% of screen width
    height: context.heightPercent(50), // 50% of screen height
    child: Text('Content'),
  );
}
```

---

## Responsive Widgets

### ResponsiveWidget - Show different widgets

```dart
Widget build(BuildContext context) {
  return ResponsiveWidget(
    mobile: MobileLayout(),
    tablet: TabletLayout(),
    desktop: DesktopLayout(),
  );
}
```

### ResponsiveContainer - Container with max width

```dart
Widget build(BuildContext context) {
  return ResponsiveContainer(
    padding: ResponsiveSizes.screenPadding(context),
    child: Column(
      children: [
        Text('Content'),
      ],
    ),
  );
}
```

### ResponsiveGridView - Grid with responsive columns

```dart
Widget build(BuildContext context) {
  return ResponsiveGridView(
    children: [
      MovieCard(),
      MovieCard(),
      MovieCard(),
      // ... more cards
    ],
    spacing: ResponsiveSizes.spacing(context),
  );
}
```

### ResponsivePadding - Responsive padding wrapper

```dart
Widget build(BuildContext context) {
  return ResponsivePadding(
    child: Column(
      children: [
        Text('Content'),
      ],
    ),
  );
}
```

### ResponsiveSizedBox - Responsive spacing

```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Item 1'),
      ResponsiveSizedBox(), // Default vertical spacing
      Text('Item 2'),
      ResponsiveSizedBox(isWidth: true), // Horizontal spacing
    ],
  );
}
```

### ResponsiveText - Text with responsive font size

```dart
Widget build(BuildContext context) {
  return ResponsiveText(
    'Hello World',
    mobileFontSize: 16.0,
    tabletFontSize: 20.0,
    desktopFontSize: 24.0,
  );
}
```

---

## Common Patterns

### Pattern 1: Responsive Movie Card Grid

```dart
class MovieGridScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movies'),
        toolbarHeight: ResponsiveSizes.appBarHeight(context),
      ),
      body: ResponsiveGridView(
        children: movies.map((movie) => MovieCard(movie: movie)).toList(),
        spacing: ResponsiveSizes.spacing(context),
      ),
    );
  }
}
```

### Pattern 2: Responsive List Item

```dart
class MovieListItem extends StatelessWidget {
  final Movie movie;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveSizes.listItemHeight(context),
      padding: ResponsiveSizes.cardPadding(context),
      margin: EdgeInsets.only(bottom: ResponsiveSizes.spacingSmall(context)),
      child: Row(
        children: [
          Image.network(
            movie.posterUrl,
            width: context.responsiveSize(
              mobile: 60.0,
              tablet: 80.0,
              desktop: 100.0,
            ),
          ),
          ResponsiveSizedBox(isWidth: true),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  movie.title,
                  mobileFontSize: 16.0,
                  tabletFontSize: 18.0,
                  desktopFontSize: 20.0,
                ),
                ResponsiveSizedBox(),
                ResponsiveText(
                  movie.overview,
                  mobileFontSize: 12.0,
                  tabletFontSize: 14.0,
                  desktopFontSize: 16.0,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Pattern 3: Responsive Button

```dart
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: ResponsiveSizes.horizontalPadding(context),
        minimumSize: Size(
          0,
          ResponsiveSizes.buttonHeight(context),
        ),
      ),
      child: ResponsiveText(
        text,
        mobileFontSize: 14.0,
        tabletFontSize: 16.0,
        desktopFontSize: 18.0,
      ),
    );
  }
}
```

### Pattern 4: Responsive App Bar

```dart
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: ResponsiveText(
        title,
        mobileFontSize: 20.0,
        tabletFontSize: 24.0,
        desktopFontSize: 28.0,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          iconSize: ResponsiveSizes.iconSize(context),
          onPressed: () {},
        ),
      ],
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(ResponsiveSizes.appBarHeight(context));
}
```

### Pattern 5: Responsive Layout with Sidebar

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget body;
  
  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      // Desktop: Show sidebar + content
      return Row(
        children: [
          Sidebar(width: 250),
          Expanded(child: body),
        ],
      );
    } else {
      // Mobile/Tablet: Show content only
      return body;
    }
  }
}
```

### Pattern 6: Platform-Specific Styling

```dart
Widget build(BuildContext context) {
  final cardStyle = context.responsiveValue<BoxDecoration>(
    mobile: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.0),
    ),
    tablet: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4.0,
        ),
      ],
    ),
    desktop: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8.0,
        ),
      ],
    ),
  );
  
  return Container(
    decoration: cardStyle,
    child: Text('Card Content'),
  );
}
```

---

## Best Practices

1. **Always use responsive utilities** instead of hardcoded sizes
2. **Test on multiple devices** - mobile, tablet, desktop, web
3. **Use predefined sizes** from `ResponsiveSizes` when possible
4. **Consider orientation** - use `context.isLandscape` or `context.isPortrait`
5. **Platform-specific code** - use platform detection for platform-specific features
6. **Breakpoints** - Follow the defined breakpoints (600, 900, 1200, 1920)

---

## Breakpoints Reference

- **Mobile**: < 600px width
- **Tablet**: 600px - 899px width
- **Desktop**: 900px - 1199px width
- **Large Desktop**: ≥ 1200px width

You can adjust these in `lib/core/utils/responsive.dart`:

```dart
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1920;
}
```
