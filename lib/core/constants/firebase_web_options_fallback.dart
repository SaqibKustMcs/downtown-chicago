import 'package:firebase_core/firebase_core.dart';

/// Fallback Firebase web config when .env is not available (e.g. production deploy).
/// Ensures the app works at https://food-restaurant-app-1ea6e.web.app
/// Primary config is still from .env (EnvConfig.firebaseWebOptions) when loaded.
class FirebaseWebOptionsFallback {
  FirebaseWebOptionsFallback._();

  static FirebaseOptions get options => FirebaseOptions(
        apiKey: 'AIzaSyDM4IvQZtyoHwI_0lYcSSxqzax5xkJ2Bz4',
        authDomain: 'food-restaurant-app-1ea6e.firebaseapp.com',
        projectId: 'food-restaurant-app-1ea6e',
        storageBucket: 'food-restaurant-app-1ea6e.firebasestorage.app',
        messagingSenderId: '5238107802',
        appId: '1:5238107802:web:aa7721dab6b530c233b923',
        measurementId: 'G-HJGJ9M19T8',
      );
}
