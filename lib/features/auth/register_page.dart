import 'package:flutter/material.dart';

import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import 'account_form.dart';
import 'auth_widgets.dart';

/// Create account (Stitch: register_page). Just a username and a password: no e-mail, no name, no
/// confirmation field. Creates the Supabase account, signs in and sets up the account's profile and
/// default routines on the server.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxScaffold(
      topBar: const AuthTopBar(label: 'Create account'),
      gap: SxSpace.md,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: c.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bolt, size: 14, color: c.primary),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'USERNAME & PASSWORD',
                overflow: TextOverflow.ellipsis,
                style: SxText.labelCaps.copyWith(
                  color: c.primary,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Create your account',
          style: SxText.headlineLg.copyWith(color: c.textHigh),
        ),
        Text(
          'Pick a username and a password. Your training is saved to your account, so you need to be online.',
          style: SxText.bodyLg.copyWith(color: c.textBody),
        ),
        AccountForm(
          mode: AccountFormMode.create,
          onDone: (_) => AppNav.aboutYou(context, afterSignup: true),
        ),
        Center(
          child: TextButton(
            onPressed: () => AppNav.switchToLogin(context),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text.rich(
              TextSpan(
                text: 'Already have an account? ',
                style: SxText.bodyMd.copyWith(color: c.textBody),
                children: [
                  TextSpan(
                    text: 'Log in',
                    style: SxText.headlineSm.copyWith(color: c.primary),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(SxRadius.full),
            border: Border.all(color: c.hairline),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_done_outlined, size: 18, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SAVED TO YOUR ACCOUNT. NEEDS A CONNECTION.',
                  style: SxText.labelXs.copyWith(color: c.textBody),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
