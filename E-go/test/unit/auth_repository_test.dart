import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_go/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:e_go/features/auth/domain/auth_validators.dart';
import 'package:e_go/features/auth/domain/entities/auth_exception.dart';

Future<AuthException> _expectAuthError(
  Future<Object?> Function() action,
) async {
  try {
    await action();
  } on AuthException catch (error) {
    return error;
  }
  fail('Expected an AuthException');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MockAuthRepository — demo login and sessions', () {
    test('demo credentials sign in and restore the session', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      expect(await repo.restoreSession(), isNull);

      final user = await repo.loginWithPassword(
        phone: MockAuthRepository.demoPhone,
        password: MockAuthRepository.demoPassword,
      );

      expect(user.name, MockAuthRepository.demoName);
      expect(user.phone, '+919000000001');
      expect(user.isProfileComplete, isTrue);
      expect((await repo.restoreSession())?.id, user.id);

      await repo.logout();
      expect(await repo.restoreSession(), isNull);
    });

    test('normalizes +91, 91 and leading-zero phone formats', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      for (final phone in const [
        '9000000001',
        '+91 90000 00001',
        '919000000001',
        '09000000001',
      ]) {
        final user = await repo.loginWithPassword(
          phone: phone,
          password: MockAuthRepository.demoPassword,
        );
        expect(user.phone, '+919000000001', reason: phone);
      }
    });

    test('wrong password fails without creating a session', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      final error = await _expectAuthError(
        () => repo.loginWithPassword(
          phone: MockAuthRepository.demoPhone,
          password: 'wrong-password',
        ),
      );

      expect(error.code, AuthErrorCode.invalidCredentials);
      expect(
        error.message,
        'Incorrect phone number or password. Please try again.',
      );
      expect(await repo.restoreSession(), isNull);
    });

    test('unknown phone fails with the account-not-found message', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      final error = await _expectAuthError(
        () =>
            repo.loginWithPassword(phone: '9876543210', password: 'Anything1'),
      );

      expect(error.code, AuthErrorCode.accountNotFound);
      expect(
        error.message,
        'No account found. Please create an account first.',
      );
    });

    test('invalid phone fails with the required validation message', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      for (final phone in const ['', '12345', '3123456789', '98765abcde']) {
        final error = await _expectAuthError(
          () => repo.loginWithPassword(phone: phone, password: 'Anything1'),
        );
        expect(error.code, AuthErrorCode.invalidPhone, reason: phone);
        expect(error.message, 'Please enter a valid 10-digit mobile number.');
      }
    });
  });

  group('MockAuthRepository — registration and OTP', () {
    test('registration is pending until OTP creates the session', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      final registered = await repo.register(
        name: 'Rahul Sen',
        phone: '9876543210',
        password: 'Password123',
        email: 'rahul@example.com',
      );

      expect(registered.name, 'Rahul Sen');
      expect(registered.phone, '+919876543210');
      expect(registered.isProfileComplete, isTrue);
      expect(await repo.restoreSession(), isNull);

      expect(
        await repo.verifyOtp(phone: '9876543210', code: '000000'),
        isFalse,
      );
      expect(await repo.restoreSession(), isNull);

      expect(await repo.verifyOtp(phone: '9876543210', code: '123456'), isTrue);
      expect((await repo.restoreSession())?.phone, '+919876543210');
    });

    test('registered account can log in afterwards', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      await repo.register(
        name: 'Rahul Sen',
        phone: '9876543210',
        password: 'Password123',
      );
      await repo.logout();

      final user = await repo.loginWithPassword(
        phone: '+91 98765 43210',
        password: 'Password123',
      );

      expect(user.name, 'Rahul Sen');
    });

    test('duplicate phone registration is rejected', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      final error = await _expectAuthError(
        () => repo.register(
          name: 'Copy Cat',
          phone: MockAuthRepository.demoPhone,
          password: 'Password123',
        ),
      );

      expect(error.code, AuthErrorCode.duplicatePhone);
      expect(error.message, contains('already exists'));
    });

    test('rejects invalid name, email, password and phone', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      final weakPassword = await _expectAuthError(
        () => repo.register(
          name: 'Rahul Sen',
          phone: '9876543210',
          password: 'short',
        ),
      );
      expect(weakPassword.code, AuthErrorCode.weakPassword);

      final blankPassword = await _expectAuthError(
        () => repo.register(
          name: 'Rahul Sen',
          phone: '9876543210',
          password: '        ',
        ),
      );
      expect(blankPassword.code, AuthErrorCode.weakPassword);

      final blankName = await _expectAuthError(
        () => repo.register(
          name: '   ',
          phone: '9876543210',
          password: 'Password123',
        ),
      );
      expect(blankName.code, AuthErrorCode.invalidName);

      final badEmail = await _expectAuthError(
        () => repo.register(
          name: 'Rahul Sen',
          phone: '9876543210',
          password: 'Password123',
          email: 'not-an-email',
        ),
      );
      expect(badEmail.code, AuthErrorCode.invalidEmail);

      final badPhone = await _expectAuthError(
        () => repo.register(
          name: 'Rahul Sen',
          phone: '12345',
          password: 'Password123',
        ),
      );
      expect(badPhone.code, AuthErrorCode.invalidPhone);
    });

    test('OTP for an unregistered phone is rejected', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      expect(
        await repo.verifyOtp(phone: '9876543210', code: '123456'),
        isFalse,
      );
      expect(await repo.restoreSession(), isNull);
    });
  });

  group('MockAuthRepository — profile and onboarding', () {
    test('profile updates survive logout and a later login', () async {
      final repo = MockAuthRepository(latency: Duration.zero);
      final user = await repo.loginWithPassword(
        phone: MockAuthRepository.demoPhone,
        password: MockAuthRepository.demoPassword,
      );

      await repo.updateProfile(
        user.copyWith(name: 'Updated Name', email: 'updated@example.com'),
      );
      await repo.logout();

      final loggedIn = await repo.loginWithPassword(
        phone: MockAuthRepository.demoPhone,
        password: MockAuthRepository.demoPassword,
      );
      expect(loggedIn.name, 'Updated Name');
      expect(loggedIn.email, 'updated@example.com');
    });

    test('onboarding persists separately from the in-memory session', () async {
      final first = MockAuthRepository(latency: Duration.zero);
      expect(await first.hasCompletedOnboarding(), isFalse);

      await first.markOnboardingComplete();
      expect(await first.hasCompletedOnboarding(), isTrue);

      final second = MockAuthRepository(latency: Duration.zero);
      expect(await second.hasCompletedOnboarding(), isTrue);
      expect(await second.restoreSession(), isNull);
    });

    test('no account credentials are written to SharedPreferences', () async {
      final repo = MockAuthRepository(latency: Duration.zero);

      await repo.register(
        name: 'Rahul Sen',
        phone: '9876543210',
        password: 'Password123',
        email: 'rahul@example.com',
      );
      await repo.verifyOtp(phone: '9876543210', code: '123456');
      await repo.logout();
      await repo.markOnboardingComplete();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'ego_onboarding_complete'});

      final values = prefs.getKeys().map((key) => '${prefs.get(key)}');
      expect(values.any((value) => value.contains('Password123')), isFalse);
      expect(values.any((value) => value.contains('9876543210')), isFalse);
    });
  });

  group('AuthValidators', () {
    test('phone normalization and Indian prefix policy', () {
      expect(AuthValidators.normalizePhone('9876543210'), '+919876543210');
      expect(AuthValidators.normalizePhone('+91 98765 43210'), '+919876543210');
      expect(AuthValidators.normalizePhone('09876543210'), '+919876543210');
      expect(AuthValidators.normalizePhone('3123456789'), isNull);
      expect(AuthValidators.normalizePhone('98765'), isNull);
      expect(AuthValidators.normalizePhone('98765abcde'), isNull);
    });

    test('login and registration password policies differ', () {
      expect(AuthValidators.isValidLoginPassword('x'), isTrue);
      expect(AuthValidators.isValidLoginPassword(''), isFalse);
      expect(AuthValidators.isValidRegistrationPassword('short'), isFalse);
      expect(AuthValidators.isValidRegistrationPassword('12345678'), isTrue);
      expect(AuthValidators.isValidRegistrationPassword('        '), isFalse);
    });

    test('optional email validation', () {
      expect(AuthValidators.isValidEmailOrEmpty(''), isTrue);
      expect(AuthValidators.isValidEmailOrEmpty('a@b.co'), isTrue);
      expect(AuthValidators.isValidEmailOrEmpty('bad-email'), isFalse);
    });
  });
}
