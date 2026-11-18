/// Authenticated E-GO customer.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.isProfileComplete = false,
    this.hasCompletedOnboarding = false,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final bool isProfileComplete;
  final bool hasCompletedOnboarding;

  AuthUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    bool? isProfileComplete,
    bool? hasCompletedOnboarding,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  static const AuthUser empty = AuthUser(id: '', name: '', phone: '');
}
