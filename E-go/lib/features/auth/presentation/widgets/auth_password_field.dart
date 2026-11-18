import 'package:flutter/material.dart';
import 'package:e_go/app/theme/index.dart';

/// Reusable password field component shared across E-GO Login and Registration screens.
///
/// Features:
/// - Hidden (obscured) password by default
/// - Accessible visibility toggle (eye icon) with tactile feedback
/// - Fixed 56px height and 16px border radius
/// - Focus halo and error highlight states
/// - Secure: Never prints or leaks password text into logs
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    this.label = 'PASSWORD',
    this.placeholder = 'Enter your password',
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
  });

  final TextEditingController controller;
  final String label;
  final String placeholder;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final bool enabled;
  final TextInputAction textInputAction;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscureText = true;
  late final FocusNode _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    const fontFamily = EGoTypography.fontFamilyBody;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    Color containerBg = EGoColors.surface;
    Color borderColor = EGoColors.outlineVariant;
    double borderWidth = 1.5;
    List<BoxShadow> shadows = [];

    if (hasError) {
      containerBg = EGoColors.errorLight;
      borderColor = EGoColors.error;
      borderWidth = 2.0;
    } else if (_isFocused) {
      borderColor = EGoColors.brandNavy;
      borderWidth = 2.0;
      shadows = const [
        BoxShadow(
          color: EGoColors.brandPrimaryHalo,
          blurRadius: 0,
          spreadRadius: 3,
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: EGoColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8.0),

        // 56px Field Box
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56.0,
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: shadows,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lock Icon
              const Icon(
                Icons.lock_outline_rounded,
                size: 20.0,
                color: EGoColors.onSurfaceMuted,
              ),
              const SizedBox(width: 12.0),

              // Password Text Field
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  enabled: widget.enabled,
                  obscureText: _obscureText,
                  enableSuggestions: false,
                  autocorrect: false,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: const TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: EGoColors.onSurface,
                  ),
                  cursorColor: EGoColors.onSurface,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.placeholder,
                    hintStyle: const TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                      color: EGoColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),

              // Visibility Toggle Button
              Semantics(
                button: true,
                label: _obscureText ? 'Show password' : 'Hide password',
                child: IconButton(
                  key: const Key('password_visibility_toggle'),
                  onPressed: widget.enabled ? _toggleVisibility : null,
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20.0,
                    color: EGoColors.onSurfaceMuted,
                  ),
                  splashRadius: 20.0,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32.0,
                    minHeight: 32.0,
                  ),
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
                color: EGoColors.error,
              ),
              const SizedBox(width: 4.0),
              Flexible(
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: EGoColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
