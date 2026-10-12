import '../../data/remote/auth_service.dart';

/// User-facing wording for cloud errors (never raw exception text).
String cloudAuthMessage(CloudAuthStatus s) => switch (s) {
  CloudAuthStatus.ok => '',
  CloudAuthStatus.invalidCredentials => 'Wrong username or password',
  CloudAuthStatus.userExists => 'That username is taken. Try another one.',
  CloudAuthStatus.weakPassword => passwordRulesMessage,
  CloudAuthStatus.rateLimited => 'Too many attempts, try again in a minute',
  CloudAuthStatus.network =>
    "Can't reach the server. Check your connection and try again.",
  CloudAuthStatus.unavailable =>
    "The server isn't set up in this build of the app.",
  CloudAuthStatus.signUpIncomplete => "Couldn't finish sign-up, try signing in",
  CloudAuthStatus.unknown => 'Something went wrong. Please try again.',
};

const passwordRulesMessage =
    'Use at least 8 characters, one capital letter and one number';

const noPasswordResetNote =
    "No e-mail is used, so a forgotten password can't be reset. Keep it somewhere safe.";

/// "just now", "5 min ago", "3 h ago", "2 d ago".
String timeAgo(DateTime t, [DateTime? now]) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inSeconds < 45) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes < 1 ? 1 : d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}
