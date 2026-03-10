import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env', mergeWith: {});
    } catch (_) {
      // .env may be missing in production web deploy; Firebase web uses fallback options
    }
  }

  static String get tmdbBaseUrl => dotenv.get('TMDB_BASE_URL', fallback: 'https://api.themoviedb.org/3/');

  /// Firebase web config (required for running on Chrome/web).
  /// Add these to your .env from Firebase Console > Project settings > Your apps > Web app.
  static FirebaseOptions? get firebaseWebOptions {
    final apiKey = dotenv.get('FIREBASE_WEB_API_KEY', fallback: '');
    final appId = dotenv.get('FIREBASE_WEB_APP_ID', fallback: '');
    final messagingSenderId = dotenv.get('FIREBASE_WEB_MESSAGING_SENDER_ID', fallback: '');
    final projectId = dotenv.get('FIREBASE_WEB_PROJECT_ID', fallback: '');
    if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: dotenv.get('FIREBASE_WEB_AUTH_DOMAIN', fallback: '${projectId}.firebaseapp.com'),
      storageBucket: dotenv.get('FIREBASE_WEB_STORAGE_BUCKET', fallback: '$projectId.appspot.com'),
      measurementId: dotenv.get('FIREBASE_WEB_MEASUREMENT_ID', fallback: ''),
    );
  }
}
