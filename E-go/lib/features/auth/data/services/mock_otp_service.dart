/// Development-only OTP service. No SMS is requested or sent.
class MockOtpService {
  const MockOtpService();

  static const String devOtp = '123456';
  static const Duration resendCooldown = Duration(seconds: 30);

  bool verify(String code) => code == devOtp;

  void request(String phone) {
    // Mock only: no SMS gateway is contacted.
  }
}
