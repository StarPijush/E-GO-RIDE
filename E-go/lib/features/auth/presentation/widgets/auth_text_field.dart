import 'package:flutter/material.dart';
import 'package:e_go/app/theme/index.dart';

/// Reusable styled text field for authentication forms (Full Name, Email Address).
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.leadingIcon,
    this.focusNode,
    this.badgeText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData leadingIcon;
  final FocusNode? focusNode;
  final String? badgeText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final bool enabled;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
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
        // Label Row with optional badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
            if (widget.badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: EGoColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(100.0),
                  border: Border.all(
                    color: EGoColors.outlineVariant,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  widget.badgeText!,
                  style: const TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: EGoColors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
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
              // Leading Icon
              Icon(
                widget.leadingIcon,
                size: 20.0,
                color: EGoColors.onSurfaceMuted,
              ),
              const SizedBox(width: 12.0),

              // Text Field
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: const TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
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
