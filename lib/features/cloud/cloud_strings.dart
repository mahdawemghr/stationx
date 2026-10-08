import '../../data/sync/cloud_auth.dart';
import '../../data/sync/cloud_sync_controller.dart';

/// User-facing wording for cloud errors (never raw exception text).
String cloudAuthMessage(CloudAuthStatus s) => switch (s) {
      CloudAuthStatus.ok => '',
      CloudAuthStatus.needsEmailConfirmation => 'Check your email to confirm your account, then sign in.',
      CloudAuthStatus.invalidCredentials => 'Wrong email or password.',
      CloudAuthStatus.emailNotConfirmed => 'Please confirm your email first — open the link we sent you, then sign in.',
      CloudAuthStatus.userExists => 'An account with this email already exists. Try signing in instead.',
      CloudAuthStatus.weakPassword => 'Choose a stronger password (at least 8 characters with a capital letter and a number).',
      CloudAuthStatus.rateLimited => 'Too many attempts. Wait a minute and try again.',
      CloudAuthStatus.network => "Can't reach the server. Check your connection and try again.",
      CloudAuthStatus.unavailable => "Cloud backup isn't set up in this build of the app.",
      CloudAuthStatus.unknown => 'Something went wrong. Please try again.',
    };

String cloudProblemMessage(CloudSyncProblem p) => switch (p) {
      CloudSyncProblem.offline => "Can't reach the server — your changes are safe on this device and will upload when you're back online.",
      CloudSyncProblem.signedOut => 'Your cloud session expired. Sign in again to keep syncing.',
      CloudSyncProblem.server => 'The server had a problem. Your data is safe on this device; we will retry shortly.',
    };

/// "just now", "5 min ago", "3 h ago", "2 d ago".
String timeAgo(DateTime t, [DateTime? now]) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inSeconds < 45) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes < 1 ? 1 : d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}
