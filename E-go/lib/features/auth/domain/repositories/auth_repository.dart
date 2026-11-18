import '../entities/auth_user.dart';

/// Authentication boundary. The UI and application state depend only on this
/// interface so the mock implementation can be replaced by a real API client.
abstract interface class AuthRepository {
  Future<AuthUser?> restoreSession();

  Future<AuthUser> loginWithPassword({
    required String phone,
    required String password,
  });

  Future<AuthUser> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  });

  Future<void> logout();

  Future<AuthUser> updateProfile(AuthUser user);

  Future<bool> isPhoneRegistered(String phone);

  Future<void> requestOtp(String phone);

  Future<bool> verifyOtp({required String phone, required String code});

  Future<bool> hasCompletedOnboarding();

  Future<void> markOnboardingComplete();
}
