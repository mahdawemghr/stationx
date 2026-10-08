import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/sx_spacing.dart';
import '../theme/sx_theme.dart';
import '../theme/sx_typography.dart';

/// Labelled text field per Stitch: caps mono label, surface-2 well, lime focus
/// border, inline error/valid state.
class SxTextField extends StatelessWidget {
  const SxTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icon,
    this.trailing,
    this.errorText,
    this.valid = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.maxLines = 1,
    this.suffixText,
    this.autofillHints,
    this.mono = false,
    this.focusNode,
    this.textAlign = TextAlign.start,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final Widget? trailing;
  final String? errorText;
  final bool valid;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final String? suffixText;
  final Iterable<String>? autofillHints;
  final bool mono;
  final FocusNode? focusNode;
  final TextAlign textAlign;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final hasError = errorText != null;
    OutlineInputBorder border(Color col) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(SxRadius.md),
      borderSide: BorderSide(color: col),
    );
    // The visible caption is excluded from semantics; the field itself carries
    // the label (and the error, via InputDecoration.errorText) as one node.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label.toUpperCase(),
            style: SxText.labelCaps.copyWith(color: c.textBody),
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: label,
          textField: true,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            inputFormatters: inputFormatters,
            maxLines: obscureText ? 1 : maxLines,
            textAlign: textAlign,
            autofillHints: autofillHints,
            cursorColor: c.primary,
            style: (mono ? SxText.metricMd : SxText.bodyLg).copyWith(
              color: c.textHigh,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: c.surface2,
              hintText: hint,
              hintStyle: SxText.bodyLg.copyWith(color: c.textMuted),
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, size: 20, color: c.textMuted),
              suffixIcon:
                  trailing ??
                  (valid
                      ? Icon(Icons.check_circle, size: 20, color: c.primary)
                      : null),
              suffixText: suffixText,
              suffixStyle: SxText.metricSm.copyWith(color: c.textBody),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: border(hasError ? c.danger : c.hairline),
              focusedBorder: border(hasError ? c.danger : c.primary),
              disabledBorder: border(c.hairline),
              border: border(c.hairline),
              errorText: errorText,
              errorMaxLines: 3,
              errorStyle: SxText.bodySm.copyWith(color: c.danger),
              errorBorder: border(c.danger),
              focusedErrorBorder: border(c.danger),
            ),
          ),
        ),
      ],
    );
  }
}
