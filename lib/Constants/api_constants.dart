class ApiConstants {
  // Base URL - Update this with your backend URL
  static const String baseUrl = 'http://10.192.113.95:3101'; // For same network (physical device/emulator)
  // static const String baseUrl = 'http://10.0.2.2:3101'; // For Android emulator
  // static const String baseUrl = 'YOUR_PRODUCTION_URL'; // For production

  // WebSocket URL - Derived from baseUrl
  static const String wsUrl = '$baseUrl/chat'; // WebSocket connection URL

  // Auth Endpoints
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verifyOtp';
  static const String isEmailExists = '/auth/isEmailExists';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Headers
  static const Map<String, String> headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};

  static Map<String, String> getAuthHeaders(String token) {
    return {...headers, 'Authorization': 'Bearer $token'};
  }
}
