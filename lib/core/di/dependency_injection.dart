import 'package:food_flow_app/core/firebase/firebase_service.dart';
import 'package:food_flow_app/modules/auth/datasources/auth_remote_datasource.dart';
import 'package:food_flow_app/modules/auth/datasources/auth_local_datasource.dart';
import 'package:food_flow_app/modules/auth/repositories/auth_repository.dart';
import 'package:food_flow_app/modules/auth/services/auth_service.dart';
import 'package:food_flow_app/modules/auth/controllers/auth_controller.dart';
import 'package:food_flow_app/modules/checkout/controllers/cart_controller.dart';
import 'package:food_flow_app/modules/favorites/controllers/favorites_controller.dart';

/// Dependency Injection Container
/// Centralized dependency management
class DependencyInjection {
  static DependencyInjection? _instance;
  DependencyInjection._();
  
  static DependencyInjection get instance {
    _instance ??= DependencyInjection._();
    return _instance!;
  }

  // Auth Dependencies
  late final AuthRemoteDataSource _authRemoteDataSource;
  late final AuthLocalDataSource _authLocalDataSource;
  late final AuthRepository _authRepository;
  late final AuthService _authService;
  late final AuthController _authController;

  // Cart Dependencies
  late final CartController _cartController;

  // Favorites Dependencies
  late final FavoritesController _favoritesController;

  /// Initialize all dependencies
  Future<void> initialize() async {
    // Initialize Firebase
    await FirebaseService.initialize();

    // Initialize Auth dependencies
    _authRemoteDataSource = AuthRemoteDataSource();
    _authLocalDataSource = AuthLocalDataSource();
    _authRepository = AuthRepository(
      remoteDataSource: _authRemoteDataSource,
      localDataSource: _authLocalDataSource,
    );
    _authService = AuthService(_authRepository);
    _authController = AuthController(_authService);
    _authController.initialize();

    // Initialize Cart dependencies
    _cartController = CartController();

    // Initialize Favorites dependencies
    _favoritesController = FavoritesController();
  }

  // Getters for dependencies
  AuthController get authController => _authController;
  AuthService get authService => _authService;
  AuthRepository get authRepository => _authRepository;
  CartController get cartController => _cartController;
  FavoritesController get favoritesController => _favoritesController;
}
