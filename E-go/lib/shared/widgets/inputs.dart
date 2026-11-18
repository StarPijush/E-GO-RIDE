import 'package:flutter/material.dart';
import 'package:e_go/app/theme/index.dart';

/// E-GO location input field.
/// Designed for pickup/destination with icon, label, and trailing action.
class EGoLocationInput extends StatelessWidget {
  const EGoLocationInput({
    super.key,
    required this.label,
    required this.hint,
    this.value,
    this.icon,
    this.trailingIcon,
    this.onTap,
    this.onChanged,
    this.controller,
    this.readOnly = true,
    this.enabled = true,
    this.errorText,
    this.filled = true,
    this.fillColor,
    this.contentPadding,
  });

  final String label;
  final String hint;
  final String? value;
  final Widget? icon;
  final Widget? trailingIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool readOnly;
  final bool enabled;
  final String? errorText;
  final bool filled;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: EGoTypography.titleSmall),
        const SizedBox(height: EGoSpacing.xs),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: EGoTypography.bodyMedium.copyWith(
              color: value != null && value!.isNotEmpty
                  ? EGoColors.onSurfaceMuted
                  : EGoColors.onSurfaceVariant,
            ),
            prefixIcon: icon != null
                ? Padding(
                    padding: const EdgeInsets.all(EGoSpacing.md),
                    child: icon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: EGoSpacing.iconMedium + EGoSpacing.md * 2,
              minHeight: EGoSpacing.iconMedium + EGoSpacing.md * 2,
            ),
            suffixIcon: trailingIcon != null
                ? Padding(
                    padding: const EdgeInsets.all(EGoSpacing.md),
                    child: trailingIcon,
                  )
                : null,
            filled: filled,
            fillColor: fillColor ?? EGoColors.surface,
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: EGoSpacing.lg,
                  vertical: EGoSpacing.md,
                ),
            errorText: errorText,
          ),
          style: EGoTypography.bodyLarge.copyWith(
            color: value != null && value!.isNotEmpty
                ? EGoColors.onSurface
                : EGoColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// E-GO search input field.
/// Designed for destination search with clear action.
class EGoSearchInput extends StatefulWidget {
  const EGoSearchInput({
    super.key,
    required this.hint,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.controller,
    this.autofocus = false,
    this.prefixIcon,
  });

  final String hint;
  final String? value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final bool autofocus;
  final Widget? prefixIcon;

  @override
  State<EGoSearchInput> createState() => _EGoSearchInputState();
}

class _EGoSearchInputState extends State<EGoSearchInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.value ?? '');
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return TextFormField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: (value) {
        widget.onChanged?.call(value);
        if (hasText != value.isNotEmpty) {
          setState(() {});
        }
      },
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: EGoTypography.bodyMedium.copyWith(
          color: EGoColors.onSurfaceMuted,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.all(EGoSpacing.md),
                child: widget.prefixIcon,
              )
            : Padding(
                padding: const EdgeInsets.all(EGoSpacing.md),
                child: Icon(
                  Icons.search,
                  color: EGoColors.onSurfaceMuted,
                  size: EGoSpacing.iconMedium,
                ),
              ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: EGoSpacing.iconMedium + EGoSpacing.md * 2,
          minHeight: EGoSpacing.iconMedium + EGoSpacing.md * 2,
        ),
        suffixIcon: hasText
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: EGoColors.onSurfaceMuted,
                  size: EGoSpacing.iconMedium,
                ),
                onPressed: () {
                  _controller.clear();
                  widget.onClear?.call();
                  widget.onChanged?.call('');
                  setState(() {});
                },
                tooltip: 'Clear',
              )
            : null,
        filled: true,
        fillColor: EGoColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EGoSpacing.lg,
          vertical: EGoSpacing.md,
        ),
      ),
      style: EGoTypography.bodyLarge,
    );
  }
}
