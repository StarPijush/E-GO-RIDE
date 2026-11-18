/// Shared validation policy for login and registration.
abstract final class AuthValidators {
  static const int minPasswordLength = 8;

  static final RegExp _nationalMobile = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Returns an E.164 Indian mobile number, or null when invalid.
  static String? normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    var national = digits;

    if (digits.length == 12 && digits.startsWith('91')) {
      national = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      national = digits.substring(1);
    }

    if (!_nationalMobile.hasMatch(national)) return null;
    return '+91$national';
  }

  static bool isValidPhone(String input) => normalizePhone(input) != null;

  static bool isValidName(String input) => input.trim().isNotEmpty;

  static bool isValidEmail(String input) => _email.hasMatch(input.trim());

  static bool isValidEmailOrEmpty(String input) =>
      input.trim().isEmpty || isValidEmail(input);

  /// Registration policy: at least 8 characters and not whitespace-only.
  static bool isValidRegistrationPassword(String password) =>
      password.length >= minPasswordLength && password.trim().isNotEmpty;

  /// Login accepts any non-empty password and lets the repository decide.
  static bool isValidLoginPassword(String password) => password.isNotEmpty;
}
