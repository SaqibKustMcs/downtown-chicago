import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that dismisses the keyboard when tapping outside of input fields
class KeyboardDismisser extends StatelessWidget {
  final Widget child;

  const KeyboardDismisser({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard by removing focus from any focused node
        final currentFocus = FocusScope.of(context);
        if (currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// Extension to easily dismiss keyboard
extension DismissKeyboard on BuildContext {
  void dismissKeyboard() {
    FocusScope.of(this).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
}
