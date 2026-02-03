import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      if (options.queryParameters.isNotEmpty) {
        final params = Map<String, dynamic>.from(options.queryParameters);
        if (params.containsKey('api_key')) {
          params['api_key'] = '***HIDDEN***';
        }
        print('│ Query Parameters: $params');
      }

      if (options.headers.isNotEmpty) {
        print('│ Headers: ${options.headers}');
      }

      if (options.data != null) {
        print('│ Body: ${options.data}');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      // print('┌─────────────────────────────────────────────────────────────');
      // print('│ ✅ RESPONSE');
      // print('├─────────────────────────────────────────────────────────────');
      // print('│ Status Code: ${response.statusCode}');
      // print('│ URL: ${response.requestOptions.uri}');
      // print('│ Duration: ${response.requestOptions.headers}');

      if (response.data != null) {
        final String dataStr = response.data.toString();
        if (dataStr.length > 500) {
          print('│ Data: ${dataStr.substring(0, 500)}... (truncated)');
        } else {
          print('│ Data: $dataStr');
        }
      }
      // print('└─────────────────────────────────────────────────────────────');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────────────────────────────────────────────────');
      print('│ ❌ ERROR');
      print('├─────────────────────────────────────────────────────────────');
      print('│ Type: ${err.type}');
      print('│ Message: ${err.message}');
      print('│ URL: ${err.requestOptions.uri}');
      if (err.response != null) {
        print('│ Status Code: ${err.response?.statusCode}');
        print('│ Response: ${err.response?.data}');
      }
      print('└─────────────────────────────────────────────────────────────');
    }
    super.onError(err, handler);
  }
}
