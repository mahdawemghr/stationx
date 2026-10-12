import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/utils/remote_ops.dart';
import '../../core/widgets/widgets.dart';

/// Log out from anywhere in the app. The data lives in the account, so nothing is lost; the confirm
/// only warns about an unfinished workout, which is stored on this phone and is discarded. The app
/// then shows the landing page (the root widget reacts to the session ending).
Future<void> confirmAndSignOut(BuildContext context) async {
  final app = context.app;
  final draft = app.hasUnfinishedWorkout;
  final ok = await showSxConfirm(
    context,
    title: 'Log out?',
    message: draft
        ? 'Your unfinished workout is only on this phone and will be discarded. Everything you saved is kept in your account.'
        : 'Everything you saved is kept in your account. Log in again to continue.',
    confirmLabel: 'Log out',
    destructive: draft,
    icon: Icons.logout,
  );
  if (!ok) return;
  await app.signOut();
}

/// Permanently deletes the account and all its data (store policy requires this in-app).
Future<void> confirmAndDeleteAccount(BuildContext context) async {
  final app = context.app;
  final ok = await showSxConfirm(
    context,
    title: 'Delete account?',
    message:
        'This permanently deletes your login and ALL your workouts, sessions, cardio and goals from the server. It cannot be undone.',
    confirmLabel: 'Delete account',
    destructive: true,
    icon: Icons.person_remove_outlined,
  );
  if (!ok || !context.mounted) return;
  await runRemote(
    context,
    () async {
      final r = await app.deleteAccount();
      if (!r.ok) throw Exception('delete failed');
    },
    what: 'delete the account',
    key: 'delete-account',
  );
}
