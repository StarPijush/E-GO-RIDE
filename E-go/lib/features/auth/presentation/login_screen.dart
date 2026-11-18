import 'package:flutter/material.dart';
import 'screens/phone_login_screen.dart';

export 'screens/phone_login_screen.dart';
export 'screens/create_account_screen.dart';

/// E-GO Login screen entry point.
///
/// Wraps [PhoneLoginScreen] for clean integration with existing routes
/// and backwards compatibility with existing test suites.
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    this.onPhoneSubmitted,
    this.onLoginSubmitted,
    this.onHelpPressed,
    this.onCreateAccountPressed,
  });

  final Future<bool> Function(String phone)? onPhoneSubmitted;
  final Future<bool> Function(String phone, String password)? onLoginSubmitted;
  final VoidCallback? onHelpPressed;
  final VoidCallback? onCreateAccountPressed;

  @override
  Widget build(BuildContext context) {
    return PhoneLoginScreen(
      onPhoneSubmitted: onPhoneSubmitted,
      onLoginSubmitted: onLoginSubmitted,
      onHelpPressed: onHelpPressed,
      onCreateAccountPressed: onCreateAccountPressed,
    );
  }
}
