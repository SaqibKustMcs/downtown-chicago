import 'package:flutter/foundation.dart';

class MainContainerViewModel {
  final ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(0);

  int get currentIndex => currentIndexNotifier.value;

  void changeTab(int index) {
    if (index >= 0 && index <= 3) {
      currentIndexNotifier.value = index;
    }
  }

  void dispose() {
    currentIndexNotifier.dispose();
  }
}
