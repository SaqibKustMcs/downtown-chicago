import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/secure_storage_service.dart';

class SecureConfig {
  SecureConfig._();

  static const String _tmdbApiKeyKey = 'tmdb_api_key';

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env', mergeWith: {});

    final hasStoredKey = await SecureStorageService.containsKey(_tmdbApiKeyKey);
    if (!hasStoredKey) {
      final envApiKey = dotenv.get('TMDB_API_KEY', fallback: '');
      if (envApiKey.isNotEmpty) {
        await SecureStorageService.write(_tmdbApiKeyKey, envApiKey);
      }
    }
  }

  static Future<String> get tmdbApiKey async {
    final storedKey = await SecureStorageService.read(_tmdbApiKeyKey);
    if (storedKey != null && storedKey.isNotEmpty) {
      return storedKey;
    }
    return dotenv.get('TMDB_API_KEY', fallback: '');
  }
}
