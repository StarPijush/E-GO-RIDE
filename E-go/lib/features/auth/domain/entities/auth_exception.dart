/// Failure codes returned by an [AuthRepository].
enum AuthErrorCode {
  accountNotFound,
  invalidCredentials,
  duplicatePhone,
  invalidPhone,
  invalidName,
  invalidEmail,
  weakPassword,
  unknown,
}

class AuthException implements Exception {
  const AuthException({required this.code, required this.message});

  final AuthErrorCode code;
  final String message;

  @override
  String toString() => 'AuthException(${code.name}): $message';
}
