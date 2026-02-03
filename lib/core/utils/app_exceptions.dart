class AppException implements Exception {
  AppException([this._message, this._prefix]);

  final String? _message;
  final dynamic _prefix;

  @override
  String toString() {
    return '$_prefix$_message';
  }

  String toMessage() {
    return '$_message';
  }
}

class AuthException extends AppException {
  AuthException([String? message]) : super(message, 'Authentication Error: ');
}

class FetchDataException extends AppException {
  FetchDataException([String? message]) : super(message, 'Error During Communication: ');
}

class BadRequestException extends AppException {
  BadRequestException([message]) : super(message, 'Invalid Request: ');
}

class UnauthorisedException extends AppException {
  UnauthorisedException([message]) : super(message, 'Unauthorised: ');
}

class InvalidInputException extends AppException {
  InvalidInputException([String? message]) : super(message, 'Invalid Input: ');
}

class SyncException extends AppException {
  SyncException([String? message]) : super(message, 'Sync: ');
}

class LogoutException extends AppException {
  LogoutException([message]) : super(message);
}

class NetworkException extends AppException {
  NetworkException([message]) : super(message);
}

class AuthTokenException extends AppException {
  AuthTokenException([message]) : super(message);
}

class UserNotFoundException extends AppException {
  UserNotFoundException([message]) : super(message);
}

class SchoolNotFoundException extends AppException {
  SchoolNotFoundException([message]) : super(message);
}
