/// Account usernames. The cloud backend wants an e-mail-shaped identifier, so a username is mapped
/// to a private `<username>@stationx.local` address. That address can never receive mail and is
/// never shown to the user. Pure Dart: no Flutter, no I/O.
abstract final class Username {
  static const int minLength = 3;
  static const int maxLength = 24;

  /// Private domain used for the backend identifier (`.local` can never receive mail).
  static const String identifierDomain = 'stationx.local';

  /// Names that could be mistaken for the app, staff or a system value.
  static const Set<String> reserved = {
    'admin',
    'administrator',
    'root',
    'support',
    'stationx',
    'null',
    'undefined',
    'system',
    'staff',
    'moderator',
    'official',
    'help',
    'guest',
    'anonymous',
    'postmaster',
    'webmaster',
  };

  static final RegExp _allowed = RegExp(r'^[A-Za-z0-9_.\-]+$');
  static final RegExp _alnum = RegExp(r'^[a-z0-9]$');

  /// Trimmed and lowercased: the one canonical form used everywhere (storage, comparison, identifier).
  static String normalize(String input) => input.trim().toLowerCase();

  /// Returns a friendly message when [input] is not an acceptable username, else null.
  static String? validate(String input) {
    final u = normalize(input);
    if (u.isEmpty) return 'Choose a username';
    if (u.length < minLength) return 'Use at least $minLength characters';
    if (u.length > maxLength) return 'Use at most $maxLength characters';
    // Checked on the raw text: some non-ASCII letters (e.g. a dotted capital I) lowercase into ASCII.
    if (!_allowed.hasMatch(input.trim())) {
      return 'Use only letters a–z, numbers, "_", "." and "-" (no spaces)';
    }
    if (!_alnum.hasMatch(u[0]) || !_alnum.hasMatch(u[u.length - 1])) {
      return 'Start and end with a letter or number';
    }
    if (u.contains('..')) return 'No two dots in a row';
    if (reserved.contains(u)) return 'That username is reserved';
    return null;
  }

  /// `<normalized>@stationx.local`. Callers validate first; this never validates.
  static String toIdentifier(String input) =>
      '${normalize(input)}@$identifierDomain';

  /// Inverse of [toIdentifier]; null when [identifier] is not one of ours.
  static String? fromIdentifier(String identifier) {
    final id = identifier.trim().toLowerCase();
    const suffix = '@$identifierDomain';
    if (!id.endsWith(suffix)) return null;
    final name = id.substring(0, id.length - suffix.length);
    return name.isEmpty ? null : name;
  }
}

/// Password rules shown while creating an account: at least 8 characters, an uppercase letter and
/// a digit. The server enforces its own minimum (8); the extra rules are guidance for stronger passwords.
abstract final class PasswordPolicy {
  static const int minLength = 8;

  /// [length >= 8, has uppercase, has digit]
  static List<bool> rules(String p) => [
    p.length >= minLength,
    RegExp(r'[A-Z]').hasMatch(p),
    RegExp(r'\d').hasMatch(p),
  ];

  static bool isStrong(String p) => !rules(p).contains(false);
}
