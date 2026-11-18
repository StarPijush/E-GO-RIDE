import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:e_go/app/theme/index.dart';

/// Reusable Indian phone number input field with flag, country code prefix, and divider.
class AuthPhoneField extends StatefulWidget {
  const AuthPhoneField({
    super.key,
    required this.controller,
    this.label = 'PHONE NUMBER',
    this.placeholder = '98765 43210',
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
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
  State<AuthPhoneField> createState() => _AuthPhoneFieldState();
}

class _AuthPhoneFieldState extends State<AuthPhoneField> {
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

  bool get _isValidIndianNumber {
    final text = widget.controller.text.trim();
    return text.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(text);
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
              // Indian Flag
              const Text('🇮🇳', style: TextStyle(fontSize: 18.0)),
              const SizedBox(width: 8.0),

              // Country Code
              const Text(
                '+91',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: EGoColors.onSurface,
                ),
              ),

              // Hairline Vertical Divider
              Container(
                width: 1.0,
                height: 20.0,
                margin: const EdgeInsets.symmetric(horizontal: 12.0),
                color: EGoColors.outlineVariant,
              ),

              // Editable Phone Field
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.phone,
                  textInputAction: widget.textInputAction,
                  onChanged: (val) {
                    setState(() {});
                    if (widget.onChanged != null) widget.onChanged!(val);
                  },
                  onSubmitted: widget.onSubmitted,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
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
                      letterSpacing: 0.8,
                      color: EGoColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),

              // Valid Checkmark / Clear Suffix
              if (_isValidIndianNumber)
                const Icon(
                  Icons.check_circle_rounded,
                  color: EGoColors.success,
                  size: 20.0,
                )
              else if (widget.controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    widget.controller.clear();
                    setState(() {});
                    if (widget.onChanged != null) widget.onChanged!('');
                  },
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: EGoColors.onSurfaceMuted,
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
