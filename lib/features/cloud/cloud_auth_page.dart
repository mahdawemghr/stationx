import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_colors.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/sync/cloud_auth.dart';
import '../../data/sync/sync_engine.dart';
import '../auth/auth_widgets.dart';
import 'cloud_strings.dart';

/// Optional cloud account: sign in or create one to back up and sync training data.
/// With [restoreOnNewDevice] (opened from the welcome screen) a successful sign-in
/// also enters the app, with the data pulled from the cloud.
class CloudAuthPage extends StatefulWidget {
  const CloudAuthPage({super.key, this.restoreOnNewDevice = false});
  final bool restoreOnNewDevice;

  @override
  State<CloudAuthPage> createState() => _CloudAuthPageState();
}

class _CloudAuthPageState extends State<CloudAuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  int _mode = 0; // 0 sign in · 1 create account
  bool _showPw = false;
  bool _busy = false;
  bool _submitted = false;
  String? _error;
  String? _confirmEmail; // set after sign-up when e-mail confirmation is required

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _signUp => _mode == 1;

  String? get _emailError => _submitted && !isValidEmail(_email.text) ? 'Invalid email' : null;
  String? get _pwError {
    if (!_submitted) return null;
    if (_password.text.isEmpty) return 'Required';
    if (_signUp && passwordRules(_password.text).contains(false)) return 'Too weak';
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_emailError != null || _pwError != null || _busy) return;
    final app = context.app;
    final ctl = app.cloud;
    setState(() => _busy = true);
    final email = _email.text.trim();
    final r = _signUp ? await ctl.signUp(email, _password.text, name: _name.text) : await ctl.signIn(email, _password.text);
    _password.clear(); // never keep the password in memory longer than needed
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.status == CloudAuthStatus.needsEmailConfirmation) {
      setState(() => _confirmEmail = email);
      return;
    }
    if (!r.ok) {
      setState(() => _error = cloudAuthMessage(r.status));
      return;
    }
    if (ctl.needsAccountDecision) {
      final decision = await showAccountDecision(context);
      if (!mounted) return;
      if (decision == null) {
        await ctl.signOut();
        if (mounted) setState(() => _error = 'Cancelled — you are not signed in.');
        return;
      }
      setState(() => _busy = true);
      await ctl.resolveAccountDecision(decision);
      if (!mounted) return;
      setState(() => _busy = false);
    }
    if (widget.restoreOnNewDevice) {
      await app.resumeSession();
      if (mounted) AppNav.enterApp(context);
    } else {
      showSxSnack(context, 'Signed in as $email');
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    if (_confirmEmail != null) return _confirmView(c);
    return SxScaffold(
      topBar: SxTopBar(title: widget.restoreOnNewDevice ? 'Restore from cloud' : 'Cloud backup'),
      gap: SxSpace.md,
      children: [
        SxSegmented(
          labels: const ['Sign in', 'Create account'],
          index: _mode,
          onChanged: (i) => setState(() {
            _mode = i;
            _error = null;
            _submitted = false;
          }),
        ),
        SxCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.cloud_sync_outlined, color: c.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Optional. Back up your training and use StationX on more than one device. Your data is private to your account. '
                'Until you sign in, everything stays on this device and the app makes no network requests.',
                style: SxText.bodySm.copyWith(color: c.textBody),
              ),
            ),
          ]),
        ),
        if (_signUp)
          SxTextField(
            label: 'Name',
            controller: _name,
            icon: Icons.person_outline,
            hint: 'Your name',
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
        SxTextField(
          label: 'Email address',
          controller: _email,
          icon: Icons.mail_outline,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
          onChanged: (_) => setState(() {}),
        ),
        SxTextField(
          label: 'Password',
          controller: _password,
          icon: Icons.lock_outline,
          hint: _signUp ? 'Create a strong password' : 'Your password',
          obscureText: !_showPw,
          textInputAction: TextInputAction.done,
          autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
          errorText: _pwError,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          trailing: VisibilityToggle(visible: _showPw, onToggle: () => setState(() => _showPw = !_showPw)),
        ),
        if (_signUp) _Rules(password: _password.text),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: SxCard(
              color: c.dangerContainer.withValues(alpha: 0.35),
              borderColor: c.danger.withValues(alpha: 0.5),
              child: Row(children: [
                Icon(Icons.error_outline, color: c.danger),
                const SizedBox(width: 12),
                Expanded(child: Text(_error!, style: SxText.bodyMd.copyWith(color: c.textHigh))),
              ]),
            ),
          ),
        SxButton(
          label: _signUp ? 'Create account' : 'Sign in',
          icon: _signUp ? Icons.person_add_alt : Icons.login,
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
        Center(
          child: Text(
            'Your password is sent to the server only to sign in. StationX never stores it.',
            textAlign: TextAlign.center,
            style: SxText.bodySm.copyWith(color: c.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _confirmView(SxColors c) => SxScaffold(
        topBar: const SxTopBar(title: 'Confirm your email'),
        children: [
          EmptyState(
            icon: Icons.mark_email_read_outlined,
            eyebrow: 'One more step',
            title: 'Check your inbox',
            message: 'We sent a confirmation link to $_confirmEmail. Open it, then come back and sign in. '
                'Your data stays on this device until then.',
            actionLabel: 'I confirmed — sign in',
            onAction: () => setState(() {
              _confirmEmail = null;
              _mode = 0;
              _error = null;
              _submitted = false;
            }),
          ),
        ],
      );
}

class _Rules extends StatelessWidget {
  const _Rules({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final rules = passwordRules(password);
    const labels = ['At least 8 characters', 'One uppercase letter', 'One number'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Icon(rules[i] ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: rules[i] ? c.primary : c.textMuted),
            const SizedBox(width: 8),
            Text(labels[i], style: SxText.bodySm.copyWith(color: rules[i] ? c.textHigh : c.textBody)),
          ]),
        ),
    ]);
  }
}

/// Another account's data is on this device: let the user choose. null = cancelled.
Future<AccountSwitch?> showAccountDecision(BuildContext context) {
  return showSxSheet<AccountSwitch>(
    context,
    builder: (ctx) {
      final c = ctx.sx;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(SxSpace.md, 8, SxSpace.md, SxSpace.md),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('This device has other data', style: SxText.headlineMd.copyWith(color: c.textHigh)),
          const SizedBox(height: 8),
          Text(
            'The workouts and history on this device belong to a different (or no) cloud account. What should happen?',
            style: SxText.bodyMd.copyWith(color: c.textBody),
          ),
          const SizedBox(height: SxSpace.md),
          SxButton(
            label: 'Keep it and add it to this account',
            icon: Icons.merge_type,
            onPressed: () => Navigator.pop(ctx, AccountSwitch.merge),
          ),
          const SizedBox(height: 8),
          SxButton(
            label: "Replace with this account's data",
            icon: Icons.cloud_download_outlined,
            variant: SxButtonVariant.danger,
            onPressed: () async {
              final ok = await showSxConfirm(
                ctx,
                title: 'Replace local data?',
                message: 'Everything on this device is deleted and replaced by what is stored in this cloud account. This cannot be undone.',
                confirmLabel: 'Replace',
                destructive: true,
                icon: Icons.delete_forever,
              );
              if (ok && ctx.mounted) Navigator.pop(ctx, AccountSwitch.replaceWithCloud);
            },
          ),
          const SizedBox(height: 8),
          SxButton(label: 'Cancel and sign out', variant: SxButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
        ]),
      );
    },
  );
}
