import 'package:flutter/foundation.dart';

class MainContainerViewModel {
  final ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(0);

  int get currentIndex => currentIndexNotifier.value;

  void changeTab(int index) {
    // Allow indices 0-4 for customer (5 screens: Home, Search, Cart, Orders, Profile)
    // Admin has 5 screens, Rider has 3 screens
    // Maximum is 5 screens, so allow 0-4
    if (index >= 0 && index <= 4) {
      currentIndexNotifier.value = index;
    }
  }

  void dispose() {
    currentIndexNotifier.dispose();
  }
}
