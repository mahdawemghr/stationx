import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/remote/auth_service.dart' show CloudAuthStatus;
import '../../domain/domain.dart' show PasswordPolicy, Username;
import '../cloud/cloud_strings.dart';
import 'auth_widgets.dart';

enum AccountFormMode { create, login }

/// The one account form of the app: a Username field and a Password field, nothing else.
/// Used by Create account and Log in. The host decides what happens next through [onDone] (enter the
/// app, schedule setup). The form only reports success after the server confirmed the account AND the
/// user's data is loaded; every failure keeps the username so the user can simply try again.
class AccountForm extends StatefulWidget {
  const AccountForm({super.key, required this.mode, required this.onDone});
  final AccountFormMode mode;

  /// Called once the account is ready ([AccountResult.entered] is true).
  final void Function(AccountResult result) onDone;

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _submitted = false;
  bool _showPw = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _create => widget.mode == AccountFormMode.create;

  String? get _usernameError =>
      _submitted ? Username.validate(_username.text) : null;

  String? get _passwordError {
    if (!_submitted) return null;
    if (_password.text.isEmpty) return 'Required field';
    if (_create && !PasswordPolicy.isStrong(_password.text)) {
      return passwordRulesMessage;
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_busy || _usernameError != null || _passwordError != null) return;
    final app = context.app;
    setState(() => _busy = true);
    final r = _create
        ? await app.registerAccount(_username.text, _password.text)
        : await app.signInAccount(_username.text, _password.text);
    await _handle(r);
  }

  Future<void> _handle(AccountResult r) async {
    if (!mounted) return;
    switch (r.outcome) {
      case AccountOutcome.failed:
        // Keep the typed password only for a connection problem, so "Log in" can simply be tapped again.
        if (r.status != CloudAuthStatus.network) _password.clear();
        setState(() {
          _busy = false;
          _error = r.message ?? cloudAuthMessage(r.status!);
        });
      case AccountOutcome.signedIn:
        _password.clear();
        setState(() => _busy = false);
        widget.onDone(r);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final items = <Widget>[
      SxTextField(
        label: 'Username',
        controller: _username,
        icon: Icons.person_outline,
        hint: 'e.g. iron_sam',
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType
            .visiblePassword, // no suggestions / auto-capitalisation
        autocorrect: false,
        autofillHints: const [
          AutofillHints.username,
          AutofillHints.newUsername,
        ],
        enabled: !_busy,
        errorText: _usernameError,
        onChanged: (_) => setState(() => _error = null),
      ),
      SxTextField(
        label: 'Password',
        controller: _password,
        icon: Icons.lock_outline,
        hint: _create ? 'Create a strong password' : 'Your password',
        obscureText: !_showPw,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        autofillHints: [
          _create ? AutofillHints.newPassword : AutofillHints.password,
        ],
        enabled: !_busy,
        errorText: _passwordError,
        onChanged: (_) => setState(() => _error = null),
        onSubmitted: (_) => _submit(),
        trailing: VisibilityToggle(
          visible: _showPw,
          onToggle: () => setState(() => _showPw = !_showPw),
        ),
      ),
      if (_create) PasswordRules(password: _password.text),
      if (_create)
        Text(
          noPasswordResetNote,
          style: SxText.bodySm.copyWith(color: c.textBody),
        ),
      if (_error != null)
        _Notice(text: _error!, icon: Icons.error_outline, color: c.danger),
      SxButton(
        label: _create ? 'Create account' : 'Log in',
        icon: _create ? Icons.person_add_alt : Icons.login,
        loading: _busy,
        onPressed: _busy ? null : _submit,
      ),
      Center(
        child: Text(
          'Your password is sent to the server only to ${_create ? 'create the account' : 'sign in'}. StationX never stores it.',
          textAlign: TextAlign.center,
          style: SxText.bodySm.copyWith(color: c.textMuted),
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: SxSpace.md),
          items[i],
        ],
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.icon, required this.color});
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      liveRegion: true,
      child: SxCard(
        color: c.dangerContainer.withValues(alpha: 0.35),
        borderColor: color.withValues(alpha: 0.5),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: SxText.bodyMd.copyWith(color: c.textHigh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live checklist of the password rules.
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final rules = PasswordPolicy.rules(password);
    const labels = [
      'At least 8 characters',
      'One uppercase letter',
      'One number',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  rules[i] ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: rules[i] ? c.primary : c.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labels[i],
                    style: SxText.bodySm.copyWith(
                      color: rules[i] ? c.textHigh : c.textBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
