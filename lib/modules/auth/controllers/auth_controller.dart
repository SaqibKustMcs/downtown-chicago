import 'package:food_flow_app/core/base/base_controller.dart';
import 'package:food_flow_app/modules/auth/models/user_model.dart';
import 'package:food_flow_app/modules/auth/services/auth_service.dart';

/// Auth Controller - Manages authentication state and UI logic
class AuthController extends BaseController {
  final AuthService _authService;
  UserModel? _currentUser;

  AuthController(this._authService);

  UserModel? get currentUser => _currentUser;

  /// Initialize - Listen to auth state changes
  void initialize() {
    // Load initial user data
    _loadInitialUser();
    
    _authService.authStateChanges().listen((user) async {
      if (user != null) {
        // Fetch full user data from Firestore when auth state changes
        _currentUser = await _authService.getCurrentUser();
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }
  
  /// Load initial user data
  Future<void> _loadInitialUser() async {
    if (_authService.isAuthenticated()) {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return await execute(() async {
      await _authService.signIn(email: email, password: password);
      _currentUser = await _authService.getCurrentUser();
      return true;
    }) ?? false;
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    UserType userType = UserType.customer,
  }) async {
    return await execute(() async {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        userType: userType,
      );
      _currentUser = await _authService.getCurrentUser();
      return true;
    }) ?? false;
  }
  
  /// Refresh current user data from Firestore
  Future<void> refreshUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    return await execute(() async {
      await _authService.sendEmailVerification();
      return true;
    }) ?? false;
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    return await execute(() async {
      await _authService.sendPasswordResetEmail(email);
      return true;
    }) ?? false;
  }

  /// Confirm password reset with code
  Future<bool> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    return await execute(() async {
      await _authService.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      return true;
    }) ?? false;
  }

  /// Update password
  Future<bool> updatePassword(String newPassword) async {
    return await execute(() async {
      await _authService.updatePassword(newPassword);
      return true;
    }) ?? false;
  }

  /// Sign out - optimized for faster execution
  Future<bool> signOut() async {
    try {
      // Don't use execute wrapper to avoid unnecessary loading state overhead
      await _authService.signOut();
      _currentUser = null;
      clearError();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    return await execute(() async {
      await _authService.deleteAccount();
      _currentUser = null;
      return true;
    }) ?? false;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _authService.isAuthenticated();
  }
}
