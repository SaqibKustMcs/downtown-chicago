import 'package:dio/dio.dart';
import '../../constants/secure_config.dart';

class AuthInterceptor extends Interceptor {
  String? _cachedApiKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    _cachedApiKey ??= await SecureConfig.tmdbApiKey;
    options.queryParameters['api_key'] = _cachedApiKey ?? '';
    
    if (!options.queryParameters.containsKey('language')) {
      options.queryParameters['language'] = 'en-US';
    }

    super.onRequest(options, handler);
  }
}
