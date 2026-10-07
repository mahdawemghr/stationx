import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import 'auth_widgets.dart';
import 'login_page.dart';

/// Create account (Stitch: register_page). Creates a *local* profile with an
/// empty history. The password only gates the form; it is never stored/logged.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPw = false;
  bool _showConfirm = false;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  List<bool> get _rules => passwordRules(_password.text);
  int get _level => _rules.where((r) => r).length;
  bool get _matches => _confirm.text.isNotEmpty && _confirm.text == _password.text;

  String? get _nameError => _submitted && _name.text.trim().isEmpty ? 'Required field' : null;
  String? get _emailError {
    if (!_submitted) return null;
    if (_email.text.trim().isEmpty) return 'Required field';
    return isValidEmail(_email.text) ? null : 'Invalid format';
  }

  String? get _confirmError => _submitted && !_matches ? 'Passwords do not match' : null;

  double get _progress {
    var n = 0;
    if (_name.text.trim().isNotEmpty) n++;
    if (isValidEmail(_email.text)) n++;
    if (_level == 3) n++;
    if (_matches) n++;
    return n / 4;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_nameError != null || _emailError != null || _level < 3 || !_matches) return;
    final error = await context.app.register(name: _name.text.trim(), email: _email.text.trim());
    _password.clear();
    _confirm.clear();
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
    final rules = _rules;
    const ruleLabels = ['At least 8 characters', 'One uppercase letter', 'One number'];
    return SxScaffold(
      topBar: const AuthTopBar(label: 'Create account'),
      gap: SxSpace.md,
      children: [
        SxLinearMeter(value: _progress, height: 3),
        Row(children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
            child: Icon(Icons.bolt, size: 14, color: c.primary),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text('LOCAL PROFILE SETUP', overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.primary, letterSpacing: 1.4))),
        ]),
        Text('Create Your Account', style: SxText.headlineLg.copyWith(color: c.textHigh)),
        Text('Start tracking your training and building progress, entirely on your device.', style: SxText.bodyLg.copyWith(color: c.textBody)),
        SxTextField(
          label: 'Full name',
          controller: _name,
          icon: Icons.person_outline,
          hint: 'Your name',
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          errorText: _nameError,
          onChanged: (_) => setState(() {}),
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
          hint: 'Create a strong password',
          obscureText: !_showPw,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => setState(() {}),
          trailing: VisibilityToggle(visible: _showPw, onToggle: () => setState(() => _showPw = !_showPw)),
        ),
        SxCard(
          color: c.surface2,
          padding: const EdgeInsets.all(SxSpace.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('PASSWORD STRENGTH', overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody))),
              Text('LEVEL $_level/3', style: SxText.labelCaps.copyWith(color: _level == 3 ? c.primary : c.textBody)),
            ]),
            const SizedBox(height: 10),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(rules[i] ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: rules[i] ? c.primary : c.textMuted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(ruleLabels[i], style: SxText.bodyMd.copyWith(color: rules[i] ? c.textHigh : c.textBody))),
                ]),
              ),
          ]),
        ),
        SxTextField(
          label: 'Confirm password',
          controller: _confirm,
          icon: Icons.lock_outline,
          hint: 'Re-enter your password',
          obscureText: !_showConfirm,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _confirmError,
          valid: false,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          trailing: VisibilityToggle(visible: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm)),
        ),
        if (_matches)
          Row(children: [
            Icon(Icons.check_circle, size: 16, color: c.primary),
            const SizedBox(width: 6),
            Text('Passwords match', style: SxText.bodySm.copyWith(color: c.primary)),
          ]),
        SxCard(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(SxRadius.md)),
              child: Icon(Icons.fitness_center, color: c.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('INITIAL SPLIT', style: SxText.labelCaps.copyWith(color: c.textBody)),
                const SizedBox(height: 2),
                Text('3-day rotation: Chest + Biceps → Back + Triceps → Legs + Shoulders. Editable later in Workouts.',
                    style: SxText.bodySm.copyWith(color: c.textHigh)),
              ]),
            ),
          ]),
        ),
        Text('Your data is stored on this device and works without a connection.',
            textAlign: TextAlign.center, style: SxText.bodySm.copyWith(color: c.textBody)),
        SxButton(label: 'Create account', trailingIcon: Icons.arrow_forward, onPressed: _submit),
        Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Already have an account? ', style: SxText.bodyMd.copyWith(color: c.textBody)),
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const LoginPage())),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text('Log In', style: SxText.headlineSm.copyWith(color: c.primary)),
          ),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.full), border: Border.all(color: c.hairline)),
          child: Row(children: [
            Icon(Icons.offline_bolt_outlined, size: 18, color: c.primary),
            const SizedBox(width: 10),
            Expanded(child: Text('DATA STORED ON THIS DEVICE. OFFLINE FIRST.', style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10))),
          ]),
        ),
      ],
    );
  }
}
