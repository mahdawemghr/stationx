import 'package:flutter/material.dart';

import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import 'account_form.dart';
import 'auth_widgets.dart';

/// Log in (Stitch: login_page). Username and password; signs in to Supabase and loads the account's data.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxScaffold(
      topBar: const AuthTopBar(label: 'Log in'),
      gap: SxSpace.md,
      children: [
        Row(
          children: [Flexible(child: StatusPill('Online account', dot: true))],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                'Welcome back',
                style: SxText.headlineLg.copyWith(color: c.textHigh),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Log in to continue your training. Your data is loaded from your account.',
          style: SxText.bodyLg.copyWith(color: c.textBody),
        ),
        AccountForm(
          mode: AccountFormMode.login,
          onDone: (_) => AppNav.enterApp(context),
        ),
        Center(
          child: TextButton(
            onPressed: () => AppNav.switchToRegister(context),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text.rich(
              TextSpan(
                text: 'No account yet? ',
                style: SxText.bodyMd.copyWith(color: c.textBody),
                children: [
                  TextSpan(
                    text: 'Create account',
                    style: SxText.headlineSm.copyWith(color: c.primary),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
