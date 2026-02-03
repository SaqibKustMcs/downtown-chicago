import 'package:flutter/foundation.dart';

/// Base Controller with ChangeNotifier
/// All controllers should extend this class
abstract class BaseController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Set loading state
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error state
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Execute async operation with loading and error handling
  Future<T?> execute<T>(Future<T> Function() operation) async {
    try {
      setLoading(true);
      clearError();
      final result = await operation();
      setLoading(false);
      return result;
    } catch (e) {
      setLoading(false);
      setError(e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    clearError();
    super.dispose();
  }
}
