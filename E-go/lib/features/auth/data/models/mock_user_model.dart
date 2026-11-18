import '../../domain/entities/auth_user.dart';

/// Development-only in-memory account record.
///
/// The password is never serialized, persisted or logged. It exists only for
/// the lifetime of the mock repository instance.
class MockUserModel {
  MockUserModel({required this.user, required String password})
    : _password = password;

  final AuthUser user;
  final String _password;

  bool matchesPassword(String candidate) => candidate == _password;

  MockUserModel withUser(AuthUser updated) {
    return MockUserModel(user: updated, password: _password);
  }
}
