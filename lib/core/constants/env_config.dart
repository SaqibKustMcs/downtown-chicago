import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env', mergeWith: {});
  }

  static String get tmdbBaseUrl => dotenv.get('TMDB_BASE_URL', fallback: 'https://api.themoviedb.org/3/');
}
