import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/auth/domain/auth_validators.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_password_field.dart';

/// E-GO Create Account / Registration Screen.
///
/// Pixel-accurate implementation reproducing the approved E-GO registration design.
/// Contains Full Name, Indian Phone Number, Password with visibility toggle,
/// and optional Email Address, matching the canonical 393x852 viewport and adapting
/// smoothly across all mobile form factors.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    this.onRegistrationSubmitted,
    this.onLoginPressed,
  });

  /// Optional override callback for testing registration without Provider.
  final Future<bool> Function({
    required String name,
    required String phone,
    required String password,
    String? email,
  })?
  onRegistrationSubmitted;

  /// Optional override callback for navigation to Login.
  final VoidCallback? onLoginPressed;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

  bool _isLoading = false;
  String? _generalError;
  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);

    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailController.dispose();

    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {
        _generalError = null;
      });
    }
  }

  bool get _isNameValid =>
      AuthValidators.isValidName(_nameController.text.trim());

  bool get _isPhoneValid =>
      AuthValidators.isValidPhone(_phoneController.text.trim());

  /// Password policy: minimum 8 characters and not whitespace-only.
  bool get _isPasswordValid =>
      AuthValidators.isValidRegistrationPassword(_passwordController.text);

  /// Optional email: valid if empty or a plausible email address.
  bool get _isEmailValid =>
      AuthValidators.isValidEmailOrEmpty(_emailController.text);

  bool get _canSubmit =>
      _isNameValid &&
      _isPhoneValid &&
      _isPasswordValid &&
      _isEmailValid &&
      !_isLoading;

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    // Validate fields and set specific error messages
    bool hasError = false;
    setState(() {
      _nameError = null;
      _phoneError = null;
      _passwordError = null;
      _emailError = null;
      _generalError = null;

      if (!_isNameValid) {
        _nameError = 'Please enter your full name.';
        hasError = true;
      }
      if (!_isPhoneValid) {
        _phoneError = 'Please enter a valid 10-digit mobile number.';
        hasError = true;
      }
      if (!_isPasswordValid) {
        _passwordError = 'Password must be at least 8 characters.';
        hasError = true;
      }
      if (!_isEmailValid) {
        _emailError = 'Please enter a valid email address.';
        hasError = true;
      }
    });

    if (hasError) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final email = _emailController.text.trim().isEmpty
        ? null
        : _emailController.text.trim();

    try {
      bool success = false;
      String? failureMessage;
      if (widget.onRegistrationSubmitted != null) {
        success = await widget.onRegistrationSubmitted!(
          name: name,
          phone: phone,
          password: password,
          email: email,
        );
      } else {
        final appState = context.read<AppState>();
        success = await appState.registerAccount(
          name: name,
          phone: phone,
          password: password,
          email: email,
        );
        failureMessage = appState.error;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        // New accounts must verify their phone number via mock OTP.
        Navigator.pushNamed(context, EGoRouter.otp, arguments: phone);
      } else {
        setState(() {
          _generalError =
              failureMessage ?? 'Registration failed. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _generalError = 'Network error. Please check your connection.';
        });
      }
    }
  }

  void _handleNavigateToLogin() {
    if (widget.onLoginPressed != null) {
      widget.onLoginPressed!();
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, EGoRouter.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    const fontFamily = EGoTypography.fontFamilyBody;

    return Scaffold(
      backgroundColor: EGoColors.brandBackground,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12.0),

                          // Header: Brand Mark
                          _buildHeader(),

                          const SizedBox(height: 20.0),

                          // Heading & Description
                          _buildHeading(),

                          const SizedBox(height: 24.0),

                          // Registration Form Fields
                          AuthTextField(
                            key: const Key('register_name_field'),
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            label: 'FULL NAME',
                            placeholder: 'Rahul Sen',
                            leadingIcon: Icons.person_outline_rounded,
                            errorText: _nameError,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                          ),

                          const SizedBox(height: 16.0),

                          AuthPhoneField(
                            key: const Key('register_phone_field'),
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            label: 'PHONE NUMBER',
                            placeholder: '98765 43210',
                            errorText: _phoneError,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) =>
                                _passwordFocusNode.requestFocus(),
                          ),

                          const SizedBox(height: 16.0),

                          AuthPasswordField(
                            key: const Key('register_password_field'),
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            label: 'PASSWORD',
                            placeholder: 'Enter your password',
                            errorText: _passwordError,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _emailFocusNode.requestFocus(),
                          ),

                          const SizedBox(height: 16.0),

                          AuthTextField(
                            key: const Key('register_email_field'),
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            label: 'EMAIL ADDRESS',
                            badgeText: 'OPTIONAL',
                            placeholder: 'rahul@example.com',
                            leadingIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _emailError,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleSubmit(),
                          ),

                          // General Error Feedback
                          if (_generalError != null) ...[
                            const SizedBox(height: 12.0),
                            Text(
                              _generalError!,
                              style: const TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: EGoColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 24.0),

                          // Primary CTA Button
                          _buildSubmitButton(),

                          // Spacer pushes bottom navigation and footer down
                          const Spacer(),
                          const SizedBox(height: 24.0),

                          // Bottom Area: Log in link & Legal Footnote
                          _buildFooter(),

                          SizedBox(
                            height: bottomInset > 0 ? bottomInset + 12.0 : 16.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 44.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // E-GO wordmark + yellow accent dot
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'E-GO',
                style: TextStyle(
                  fontFamily: EGoTypography.fontFamilyDisplay,
                  fontSize: 22.0,
                  height: 30 / 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.015 * 22,
                  color: EGoColors.onSurface,
                ),
              ),
              const SizedBox(width: 6.0),
              Container(
                width: 6.0,
                height: 6.0,
                margin: const EdgeInsets.only(top: 2.0),
                decoration: const BoxDecoration(
                  color: EGoColors.brandPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 40.0),
        ],
      ),
    );
  }

  Widget _buildHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create your account',
          style: TextStyle(
            fontFamily: EGoTypography.fontFamilyDisplay,
            fontSize: 30.0,
            height: 36.0 / 30.0,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02 * 30.0,
            color: EGoColors.onSurface,
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          'Sign up to start booking TOTO & fast bike rides across India in seconds.',
          style: TextStyle(
            fontFamily: EGoTypography.fontFamilyBody,
            fontSize: 14.0,
            height: 20.0 / 14.0,
            fontWeight: FontWeight.w500,
            color: EGoColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isEnabled = _canSubmit;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: 'Create account',
      child: Material(
        color: isEnabled
            ? EGoColors.brandPrimary
            : EGoColors.disabledBackground,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          key: const Key('create_account_button'),
          onTap: isEnabled ? _handleSubmit : null,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            height: 56.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: isEnabled
                  ? const [
                      BoxShadow(
                        color: EGoColors.shadow,
                        blurRadius: 20.0,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22.0,
                    height: 22.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        EGoColors.onSurface,
                      ),
                    ),
                  )
                : const Text(
                    'Create account',
                    style: TextStyle(
                      fontFamily: EGoTypography.fontFamilyBody,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: EGoColors.onSurface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // "Already have an account? Log in"
        GestureDetector(
          onTap: _handleNavigateToLogin,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text.rich(
              const TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(
                  fontFamily: EGoTypography.fontFamilyBody,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: EGoColors.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: 'Log in',
                    style: TextStyle(
                      fontFamily: EGoTypography.fontFamilyBody,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: EGoColors.onSurface,
                      decoration: TextDecoration.underline,
                      decorationColor: EGoColors.brandPrimary,
                      decorationThickness: 3.0,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // Legal footnote with subtle top divider
        Container(
          padding: const EdgeInsets.only(top: 12.0),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: EGoColors.divider, width: 1.0),
            ),
          ),
          child: const Text(
            'By continuing, you agree to our Terms of Service & Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: EGoTypography.fontFamilyBody,
              fontSize: 12.0,
              height: 18.0 / 12.0,
              fontWeight: FontWeight.w400,
              color: EGoColors.onSurfaceMuted,
            ),
          ),
        ),
      ],
    );
  }
}
