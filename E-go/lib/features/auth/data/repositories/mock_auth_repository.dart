// E-GO mock authentication repository.
// DEVELOPMENT ONLY — in-memory accounts and sessions, no backend, no SMS.
// Registered accounts and active sessions reset when the app restarts.
// Onboarding completion is the only value persisted, via SharedPreferences.

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/auth_validators.dart';
import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/mock_user_model.dart';
import '../services/mock_otp_service.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    this.latency = const Duration(milliseconds: 600),
    bool seedDemoAccount = true,
  }) {
    if (seedDemoAccount) _seedDemoAccount();
  }

  /// Synthetic development credentials. Never use as real user data.
  static const String demoPhone = '9000000001';
  static const String demoPassword = 'EgoDemo@123';
  static const String demoName = 'E-GO Demo User';
  static const String demoEmail = 'demo@ego.local';
  static const String devMockOtp = MockOtpService.devOtp;

  static const String _demoId = 'demo-ego-001';
  static const String _demoNormalizedPhone = '+919000000001';
  static const String _onboardingKey = 'ego_onboarding_complete';

  final Duration latency;
  final MockOtpService _otpService = const MockOtpService();
  final Map<String, MockUserModel> _accounts = {};
  AuthUser? _session;

  Future<void> _delay() {
    if (latency == Duration.zero) return Future<void>.value();
    return Future<void>.delayed(latency);
  }

  void _seedDemoAccount() {
    _accounts[_demoNormalizedPhone] = MockUserModel(
      user: const AuthUser(
        id: _demoId,
        name: demoName,
        phone: _demoNormalizedPhone,
        email: demoEmail,
        isProfileComplete: true,
        hasCompletedOnboarding: true,
      ),
      password: demoPassword,
    );
  }

  @override
  Future<AuthUser?> restoreSession() async => _session;

  @override
  Future<AuthUser> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    await _delay();

    final normalizedPhone = AuthValidators.normalizePhone(phone);
    if (normalizedPhone == null) {
      throw const AuthException(
        code: AuthErrorCode.invalidPhone,
        message: 'Please enter a valid 10-digit mobile number.',
      );
    }

    final account = _accounts[normalizedPhone];
    if (account == null) {
      throw const AuthException(
        code: AuthErrorCode.accountNotFound,
        message: 'No account found. Please create an account first.',
      );
    }

    if (password.isEmpty || !account.matchesPassword(password)) {
      throw const AuthException(
        code: AuthErrorCode.invalidCredentials,
        message: 'Incorrect phone number or password. Please try again.',
      );
    }

    _session = account.user;
    return account.user;
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    await _delay();

    final normalizedPhone = AuthValidators.normalizePhone(phone);
    if (normalizedPhone == null) {
      throw const AuthException(
        code: AuthErrorCode.invalidPhone,
        message: 'Please enter a valid 10-digit mobile number.',
      );
    }
    if (!AuthValidators.isValidName(name)) {
      throw const AuthException(
        code: AuthErrorCode.invalidName,
        message: 'Please enter your full name.',
      );
    }
    if (!AuthValidators.isValidRegistrationPassword(password)) {
      throw const AuthException(
        code: AuthErrorCode.weakPassword,
        message: 'Password must be at least 8 characters.',
      );
    }

    final cleanEmail = (email == null || email.trim().isEmpty)
        ? null
        : email.trim();
    if (cleanEmail != null && !AuthValidators.isValidEmail(cleanEmail)) {
      throw const AuthException(
        code: AuthErrorCode.invalidEmail,
        message: 'Please enter a valid email address.',
      );
    }

    if (_accounts.containsKey(normalizedPhone)) {
      throw const AuthException(
        code: AuthErrorCode.duplicatePhone,
        message:
            'An account with this phone number already exists. Please log in.',
      );
    }

    final user = AuthUser(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      phone: normalizedPhone,
      email: cleanEmail,
      isProfileComplete: true,
      hasCompletedOnboarding: true,
    );

    // The account exists but stays signed out until OTP verification.
    _accounts[normalizedPhone] = MockUserModel(user: user, password: password);
    return user;
  }

  @override
  Future<void> logout() async {
    _session = null;
  }

  @override
  Future<AuthUser> updateProfile(AuthUser user) async {
    final current = _session;
    if (current == null) {
      throw const AuthException(
        code: AuthErrorCode.accountNotFound,
        message: 'No active session. Please log in again.',
      );
    }

    final account = _accounts[current.phone];
    if (account == null) {
      throw const AuthException(
        code: AuthErrorCode.accountNotFound,
        message: 'No account found. Please create an account first.',
      );
    }

    final updated = account.user.copyWith(
      name: user.name.trim(),
      email: user.email,
      isProfileComplete: user.isProfileComplete,
      hasCompletedOnboarding: user.hasCompletedOnboarding,
    );
    _accounts[current.phone] = account.withUser(updated);
    _session = updated;
    return updated;
  }

  @override
  Future<bool> isPhoneRegistered(String phone) async {
    final normalizedPhone = AuthValidators.normalizePhone(phone);
    return normalizedPhone != null && _accounts.containsKey(normalizedPhone);
  }

  @override
  Future<void> requestOtp(String phone) async {
    await _delay();
    _otpService.request(phone);
  }

  @override
  Future<bool> verifyOtp({required String phone, required String code}) async {
    await _delay();

    if (!_otpService.verify(code)) return false;

    final normalizedPhone = AuthValidators.normalizePhone(phone);
    if (normalizedPhone == null) return false;

    final account = _accounts[normalizedPhone];
    if (account == null) return false;

    _session = account.user;
    return true;
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  @override
  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Synchronous compatibility helper for existing mock OTP tests.
  bool validateOtp(String otp) => _otpService.verify(otp);
}
