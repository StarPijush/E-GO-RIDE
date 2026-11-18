import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/auth/domain/auth_validators.dart';
import '../widgets/auth_password_field.dart';

/// Design tokens and geometry constants for the E-GO Phone Login experience.
abstract class PhoneLoginConstants {
  // Screen Geometry
  static const double canonicalWidth = 393.0;
  static const double canonicalHeight = 852.0;
  static const double horizontalPadding = 24.0;
  static const double headerTopPadding = 16.0;
  static const double headerHeight = 48.0;

  // Component Geometry
  static const double inputHeight = 56.0;
  static const double inputRadius = 16.0;
  static const double ctaHeight = 58.0;
  static const double ctaRadius = 16.0;

  // Typography
  static const String fontFamily = EGoTypography.fontFamilyBody;
  static const String displayFontFamily = EGoTypography.fontFamilyDisplay;
  static const double headingFontSize = 28.0;
  static const double headingLineHeight = 34.0;
  static const double wordmarkFontSize = 24.0;
  static const double descriptionFontSize = 15.0;
  static const double descriptionLineHeight = 22.0;
  static const double inputFontSize = 15.0;
  static const double ctaFontSize = 16.0;
  static const double captionFontSize = 11.0;
  static const double captionLineHeight = 16.0;

  // Colors
  static const Color background = EGoColors.brandBackground;
  static const Color primaryYellow = EGoColors.brandPrimary;
  static const Color primaryBlack = EGoColors.onSurface;
  static const Color secondaryText = EGoColors.onSurfaceVariant;
  static const Color mutedText = EGoColors.onSurfaceMuted;
  static const Color border = EGoColors.outlineVariant;
  static const Color error = EGoColors.error;
  static const Color errorSurface = EGoColors.errorLight;
  static const Color inputBackground = EGoColors.surface;
  static const Color buttonDisabled = EGoColors.disabledBackground;
  static const Color buttonDisabledText = EGoColors.disabledForeground;
  static const Color focusHalo = EGoColors.brandPrimaryHalo;
}

/// E-GO Phone Number Login Screen with Password Authentication.
///
/// Pixel-accurate native Flutter implementation reproducing the approved
/// E-GO design specification with brand-consistent typography, 56px input
/// geometry, shared password component, validation states, and full responsive
/// support across mobile viewports.
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({
    super.key,
    this.onPhoneSubmitted,
    this.onLoginSubmitted,
    this.onHelpPressed,
    this.onCreateAccountPressed,
  });

  /// Optional override callback for testing phone submission without Provider.
  final Future<bool> Function(String phone)? onPhoneSubmitted;

  /// Optional override callback for testing phone + password submission without Provider.
  final Future<bool> Function(String phone, String password)? onLoginSubmitted;

  /// Optional override callback for help action.
  final VoidCallback? onHelpPressed;

  /// Optional override callback for create account navigation.
  final VoidCallback? onCreateAccountPressed;

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  String? _passwordError;
  String? _generalError;
  bool _isPhoneFocused = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_handlePhoneFocusChange);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_handlePhoneFocusChange);
    _passwordController.removeListener(_onFieldChanged);
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handlePhoneFocusChange() {
    if (mounted) {
      setState(() {
        _isPhoneFocused = _phoneFocusNode.hasFocus;
      });
    }
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {
        _passwordError = null;
        _generalError = null;
      });
    }
  }

  /// Indian mobile number format validation:
  /// Exactly 10 digits, starting with 6, 7, 8, or 9.
  bool get _isValidPhoneNumber =>
      AuthValidators.isValidPhone(_phoneController.text.trim());

  /// Login accepts any non-empty password; the repository checks the match.
  bool get _isValidPassword =>
      AuthValidators.isValidLoginPassword(_passwordController.text);

  bool get _canSubmit {
    if (_isLoading) return false;
    // If only onPhoneSubmitted was passed in legacy tests, allow with phone only
    if (widget.onPhoneSubmitted != null && widget.onLoginSubmitted == null) {
      return _isValidPhoneNumber;
    }
    return _isValidPhoneNumber && _isValidPassword;
  }

  void _onPhoneChanged(String value) {
    setState(() {
      _errorMessage = null;
      _generalError = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    bool hasError = false;
    setState(() {
      _errorMessage = null;
      _passwordError = null;
      _generalError = null;

      if (!_isValidPhoneNumber) {
        _errorMessage = 'Please enter a valid 10-digit mobile number.';
        hasError = true;
      }
      if (widget.onPhoneSubmitted == null || widget.onLoginSubmitted != null) {
        if (password.isEmpty) {
          _passwordError = 'Please enter your password.';
          hasError = true;
        }
      }
    });

    if (hasError) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _passwordError = null;
      _generalError = null;
    });

    try {
      bool success = false;
      String? failureMessage;
      if (widget.onLoginSubmitted != null) {
        success = await widget.onLoginSubmitted!(phone, password);
      } else if (widget.onPhoneSubmitted != null) {
        success = await widget.onPhoneSubmitted!(phone);
      } else {
        final appState = context.read<AppState>();
        success = await appState.loginWithPassword(
          phone: phone,
          password: password,
        );
        failureMessage = appState.error;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          EGoRouter.home,
          (_) => false,
        );
      } else {
        setState(() {
          _generalError =
              failureMessage ?? 'Invalid credentials. Please retry.';
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

  void _handleHelp() {
    if (widget.onHelpPressed != null) {
      widget.onHelpPressed!();
    } else {
      Navigator.pushNamed(context, EGoRouter.helpSupport);
    }
  }

  void _handleCreateAccount() {
    if (widget.onCreateAccountPressed != null) {
      widget.onCreateAccountPressed!();
    } else {
      Navigator.pushNamed(context, EGoRouter.createAccount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: PhoneLoginConstants.background,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: PhoneLoginConstants.horizontalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(
                            height: PhoneLoginConstants.headerTopPadding,
                          ),

                          // 1. Header (Brand Wordmark + Help action)
                          _buildHeader(),

                          const SizedBox(height: 28.0),

                          // 2. Heading Section
                          _buildHeadingSection(),

                          const SizedBox(height: 28.0),

                          // 3. Phone Input Section
                          _buildPhoneInputSection(),

                          const SizedBox(height: 16.0),

                          // 4. Password Input Section (Shared Reusable Component)
                          AuthPasswordField(
                            key: const Key('login_password_field'),
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            label: 'PASSWORD',
                            placeholder: 'Enter your password',
                            errorText: _passwordError,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => _onFieldChanged(),
                            onSubmitted: (_) => _handleSubmit(),
                          ),

                          const SizedBox(height: 14.0),

                          // 5. Security Microcopy
                          _buildSecurityNote(),

                          if (_generalError != null) ...[
                            const SizedBox(height: 12.0),
                            _buildGeneralError(),
                          ],

                          // 6. Flexible Spacer (pushes footer to bottom)
                          const Spacer(),
                          const SizedBox(height: 24.0),

                          // 7. Bottom Action Group (CTA, Secondary Nav, Legal)
                          _buildBottomActionGroup(),

                          SizedBox(
                            height: bottomInset > 0 ? bottomInset + 12.0 : 20.0,
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

  /// Top navigation bar with signature E-GO wordmark and Help link.
  Widget _buildHeader() {
    return SizedBox(
      height: PhoneLoginConstants.headerHeight,
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
                  fontFamily: PhoneLoginConstants.displayFontFamily,
                  fontSize: PhoneLoginConstants.wordmarkFontSize,
                  height: 32 / 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.015 * 24,
                  color: PhoneLoginConstants.primaryBlack,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  color: PhoneLoginConstants.primaryYellow,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          // Help / Support action button
          Semantics(
            button: true,
            label: 'Help and support',
            child: Material(
              color: EGoColors.transparent,
              child: InkWell(
                onTap: _handleHelp,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: EGoColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: PhoneLoginConstants.secondaryText,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Help',
                        style: TextStyle(
                          fontFamily: PhoneLoginConstants.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PhoneLoginConstants.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Two-line heading and supporting description.
  Widget _buildHeadingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your\nphone number',
          style: TextStyle(
            fontFamily: PhoneLoginConstants.displayFontFamily,
            fontSize: PhoneLoginConstants.headingFontSize,
            height:
                PhoneLoginConstants.headingLineHeight /
                PhoneLoginConstants.headingFontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02 * PhoneLoginConstants.headingFontSize,
            color: PhoneLoginConstants.primaryBlack,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "We'll send a 6-digit verification code via SMS.",
          style: TextStyle(
            fontFamily: PhoneLoginConstants.fontFamily,
            fontSize: PhoneLoginConstants.descriptionFontSize,
            height:
                PhoneLoginConstants.descriptionLineHeight /
                PhoneLoginConstants.descriptionFontSize,
            fontWeight: FontWeight.w500,
            color: PhoneLoginConstants.secondaryText,
          ),
        ),
      ],
    );
  }

  /// 56px phone number input container with flag, prefix, divider and validation states.
  Widget _buildPhoneInputSection() {
    final hasError = _errorMessage != null;

    Color containerBg = PhoneLoginConstants.inputBackground;
    Color borderColor = PhoneLoginConstants.border;
    double borderWidth = 1.5;
    List<BoxShadow> shadows = [];

    if (hasError) {
      containerBg = PhoneLoginConstants.errorSurface;
      borderColor = PhoneLoginConstants.error;
      borderWidth = 2.0;
    } else if (_isPhoneFocused) {
      borderColor = PhoneLoginConstants.primaryBlack;
      borderWidth = 2.0;
      shadows = const [
        BoxShadow(
          color: PhoneLoginConstants.focusHalo,
          blurRadius: 0,
          spreadRadius: 3,
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small Section Label
        const Text(
          'PHONE NUMBER',
          style: TextStyle(
            fontFamily: PhoneLoginConstants.fontFamily,
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: PhoneLoginConstants.secondaryText,
          ),
        ),
        const SizedBox(height: 8.0),

        // 56px Input Box
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: PhoneLoginConstants.inputHeight,
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: BorderRadius.circular(
              PhoneLoginConstants.inputRadius,
            ),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: shadows,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Indian Flag
              const Text('🇮🇳', style: TextStyle(fontSize: 18.0)),
              const SizedBox(width: 8.0),

              // Country Dialing Code
              const Text(
                '+91',
                style: TextStyle(
                  fontFamily: PhoneLoginConstants.fontFamily,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: PhoneLoginConstants.primaryBlack,
                ),
              ),

              // Hairline Vertical Divider
              Container(
                width: 1.0,
                height: 20.0,
                margin: const EdgeInsets.symmetric(horizontal: 12.0),
                color: PhoneLoginConstants.border,
              ),

              // Editable 10-digit Phone TextField
              Expanded(
                child: TextField(
                  key: const Key('login_phone_input'),
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  onChanged: _onPhoneChanged,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontFamily: PhoneLoginConstants.fontFamily,
                    fontSize: PhoneLoginConstants.inputFontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: PhoneLoginConstants.primaryBlack,
                  ),
                  cursorColor: PhoneLoginConstants.primaryBlack,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '98765 43210',
                    hintStyle: TextStyle(
                      fontFamily: PhoneLoginConstants.fontFamily,
                      fontSize: PhoneLoginConstants.inputFontSize,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.8,
                      color: PhoneLoginConstants.mutedText,
                    ),
                  ),
                ),
              ),

              // Valid Checkmark / Clear Suffix
              if (_isValidPhoneNumber)
                const Icon(
                  Icons.check_circle_rounded,
                  color: EGoColors.success,
                  size: 20.0,
                )
              else if (_phoneController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _phoneController.clear();
                    _onPhoneChanged('');
                  },
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: PhoneLoginConstants.mutedText,
                    size: 18.0,
                  ),
                ),
            ],
          ),
        ),

        // Inline Validation Error Feedback
        if (hasError) ...[
          const SizedBox(height: 6.0),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14.0,
                color: PhoneLoginConstants.error,
              ),
              const SizedBox(width: 4.0),
              Flexible(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: PhoneLoginConstants.fontFamily,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: PhoneLoginConstants.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Security reassurance microcopy.
  Widget _buildSecurityNote() {
    return const Row(
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 15.0,
          color: PhoneLoginConstants.mutedText,
        ),
        SizedBox(width: 6.0),
        Expanded(
          child: Text(
            'Your number is kept secure & encrypted',
            style: TextStyle(
              fontFamily: PhoneLoginConstants.fontFamily,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: PhoneLoginConstants.mutedText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralError() {
    return Container(
      key: const Key('login_error_message'),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: PhoneLoginConstants.errorSurface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: PhoneLoginConstants.error, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16.0,
            color: PhoneLoginConstants.error,
          ),
          const SizedBox(width: 6.0),
          Expanded(
            child: Text(
              _generalError!,
              style: const TextStyle(
                fontFamily: PhoneLoginConstants.fontFamily,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: PhoneLoginConstants.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom action grouping: 58px CTA button, secondary nav, and legal disclaimer.
  Widget _buildBottomActionGroup() {
    final isEnabled = _canSubmit;

    return Column(
      children: [
        // Primary 58px CTA Button
        Semantics(
          button: true,
          enabled: isEnabled,
          label: 'Continue',
          child: Material(
            color: isEnabled
                ? PhoneLoginConstants.primaryYellow
                : PhoneLoginConstants.buttonDisabled,
            borderRadius: BorderRadius.circular(PhoneLoginConstants.ctaRadius),
            child: InkWell(
              key: const Key('continue_button'),
              onTap: isEnabled ? _handleSubmit : null,
              borderRadius: BorderRadius.circular(
                PhoneLoginConstants.ctaRadius,
              ),
              child: Container(
                height: PhoneLoginConstants.ctaHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    PhoneLoginConstants.ctaRadius,
                  ),
                  boxShadow: isEnabled
                      ? const [
                          BoxShadow(
                            color: EGoColors.shadow,
                            blurRadius: 16.0,
                            offset: Offset(0, 4),
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
                            PhoneLoginConstants.primaryBlack,
                          ),
                        ),
                      )
                    : Text(
                        'Continue',
                        style: TextStyle(
                          fontFamily: PhoneLoginConstants.fontFamily,
                          fontSize: PhoneLoginConstants.ctaFontSize,
                          fontWeight: FontWeight.w700,
                          color: isEnabled
                              ? PhoneLoginConstants.primaryBlack
                              : PhoneLoginConstants.buttonDisabledText,
                        ),
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // Secondary Navigation: Create Account Link
        Semantics(
          button: true,
          label: 'New to E-GO? Create account',
          child: GestureDetector(
            onTap: _handleCreateAccount,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text.rich(
                TextSpan(
                  text: 'New to E-GO? ',
                  style: const TextStyle(
                    fontFamily: PhoneLoginConstants.fontFamily,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: PhoneLoginConstants.secondaryText,
                  ),
                  children: [
                    TextSpan(
                      text: 'Create account',
                      style: const TextStyle(
                        fontFamily: PhoneLoginConstants.fontFamily,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: PhoneLoginConstants.primaryBlack,
                        decoration: TextDecoration.underline,
                        decorationColor: PhoneLoginConstants.primaryBlack,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14.0),

        // Legal Footnote
        const Text(
          'By continuing, you agree to the Terms of Service and Privacy Policy of E-GO.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: PhoneLoginConstants.fontFamily,
            fontSize: PhoneLoginConstants.captionFontSize,
            height:
                PhoneLoginConstants.captionLineHeight /
                PhoneLoginConstants.captionFontSize,
            fontWeight: FontWeight.w400,
            color: PhoneLoginConstants.mutedText,
          ),
        ),
      ],
    );
  }
}
