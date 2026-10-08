import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import 'auth_widgets.dart';
import 'register_page.dart';

/// Sign in (Stitch: login_page). There is no backend and NO password: submitting opens the
/// *local* profile whose email matches. The local profile is stored on this device and is not
/// password protected, so this screen deliberately has no password field. (Cloud sign-in, which
/// does use a password, lives in Profile > Cloud backup & sync.)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  String? get _emailError {
    if (!_submitted) return null;
    if (_email.text.trim().isEmpty) return 'Required field';
    return isValidEmail(_email.text) ? null : 'Invalid format';
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_emailError != null) return;
    final error = await context.app.signInLocal(email: _email.text.trim());
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
        Text('Open the local profile on this device to continue your training rotation.', style: SxText.bodyLg.copyWith(color: c.textBody)),
        Semantics(
          container: true,
          child: Text(
            'Local profile — stored on this device, not password protected.',
            style: SxText.bodyMd.copyWith(color: c.textHigh, fontWeight: FontWeight.w600),
          ),
        ),
        SxTextField(
          label: 'Email address',
          controller: _email,
          icon: Icons.mail_outline,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          trailing: _email.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear email',
                  icon: Icon(Icons.cancel_outlined, color: c.textBody),
                  onPressed: () => setState(_email.clear)),
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
          child: Text('Want a cloud backup? Create a cloud account later in Profile › Cloud backup & sync.',
              textAlign: TextAlign.center, style: SxText.bodySm.copyWith(color: c.textMuted)),
        ),
        Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text("No local profile yet? ", style: SxText.bodyMd.copyWith(color: c.textBody)),
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const RegisterPage())),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text('Create profile', style: SxText.headlineSm.copyWith(color: c.primary)),
          ),
        ]),
      ],
    );
  }
}
