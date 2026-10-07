import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import 'auth_widgets.dart';
import 'register_page.dart';

/// Sign in (Stitch: login_page). There is no backend: submitting opens a
/// *local* profile for the email. The password is validated for presence only
/// and is never stored or logged.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPw = false;
  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _emailError {
    if (!_submitted) return null;
    if (_email.text.trim().isEmpty) return 'Required field';
    return isValidEmail(_email.text) ? null : 'Invalid format';
  }

  String? get _pwError => _submitted && _password.text.isEmpty ? 'Required field' : null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_emailError != null || _pwError != null) return;
    final error = await context.app.signInLocal(email: _email.text.trim());
    _password.clear();
    if (!mounted) return;
    if (error != null) {
      showSxSnack(context, error, icon: Icons.error_outline);
      return;
    }
    AppNav.enterApp(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxScaffold(
      topBar: const AuthTopBar(label: 'Sign in'),
      gap: SxSpace.md,
      children: [
        Row(children: const [
          Flexible(child: StatusPill('Local only', dot: true)),
        ]),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(child: Text('Welcome Back', style: SxText.headlineLg.copyWith(color: c.textHigh))),
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
          ),
        ]),
        Text('Log in to continue your training rotation. Your data stays on this device.', style: SxText.bodyLg.copyWith(color: c.textBody)),
        SxCard(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md)),
              child: Icon(Icons.fingerprint, color: c.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Biometric sign-in', style: SxText.headlineSm.copyWith(color: c.textHigh, fontSize: 15)),
                Text('Not available offline', style: SxText.bodySm.copyWith(color: c.textBody)),
              ]),
            ),
            const SizedBox(width: 8),
            Flexible(child: StatusPill('Unavailable', color: c.textMuted)),
          ]),
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
          trailing: _email.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear email',
                  icon: Icon(Icons.cancel_outlined, color: c.textBody),
                  onPressed: () => setState(_email.clear)),
        ),
        SxTextField(
          label: 'Password',
          controller: _password,
          icon: Icons.lock_outline,
          hint: 'Your password',
          obscureText: !_showPw,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: _pwError,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          trailing: VisibilityToggle(visible: _showPw, onToggle: () => setState(() => _showPw = !_showPw)),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => showSxSnack(context, 'No cloud account — nothing to reset. Data is local.', icon: Icons.info_outline),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text('Forgot password?', style: SxText.bodyMd.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
          ),
        ),
        SxButton(label: 'Log in', trailingIcon: Icons.arrow_forward, onPressed: _submit),
        Row(children: [
          Expanded(child: Divider(color: c.hairline)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: SxText.labelCaps.copyWith(color: c.textMuted))),
          Expanded(child: Divider(color: c.hairline)),
        ]),
        SxButton(
          label: 'Continue as Guest',
          icon: Icons.cloud_off_outlined,
          variant: SxButtonVariant.secondary,
          height: 48,
          onPressed: () async {
            await context.app.startGuest();
            if (context.mounted) AppNav.enterApp(context);
          },
        ),
        Center(
          child: Text('Google sign-in needs a connection and is not available offline.',
              textAlign: TextAlign.center, style: SxText.bodySm.copyWith(color: c.textMuted)),
        ),
        Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text("Don't have an account? ", style: SxText.bodyMd.copyWith(color: c.textBody)),
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const RegisterPage())),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text('Create Account', style: SxText.headlineSm.copyWith(color: c.primary)),
          ),
        ]),
      ],
    );
  }
}
