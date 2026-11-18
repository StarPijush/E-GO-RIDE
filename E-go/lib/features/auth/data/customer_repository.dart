// Backwards-compatible facade.
//
// The real mock implementation now lives in
// features/auth/data/repositories/mock_auth_repository.dart and is exposed
// through the AuthRepository interface.

import '../domain/entities/auth_user.dart';
import 'repositories/mock_auth_repository.dart';
import 'services/mock_otp_service.dart';

export '../domain/auth_validators.dart';
export '../domain/entities/auth_exception.dart';
export '../domain/entities/auth_user.dart';
export '../domain/repositories/auth_repository.dart';
export 'repositories/mock_auth_repository.dart' show MockAuthRepository;

class MockCustomerRepository extends MockAuthRepository {
  MockCustomerRepository({super.latency});

  static const String devMockOtp = MockOtpService.devOtp;
}

typedef CustomerProfile = AuthUser;
