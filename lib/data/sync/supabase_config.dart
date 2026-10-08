/// Build-time cloud configuration, injected with `--dart-define-from-file=env/supabase.json`
/// (see env/supabase.example.json). Without it the cloud feature is simply absent.
///
/// Only the project URL and the **publishable (anon) key** belong in the app — they are public
/// by design and Row Level Security protects the data. A secret/service-role key or an `sbp_`
/// access token would give full access to everyone's data, so this refuses to use one.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => validate(url, anonKey) == null;

  /// Returns a problem description, or null when [url]/[key] are usable in a client app.
  static String? validate(String url, String key) {
    if (url.isEmpty || key.isEmpty) return 'not configured';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return 'URL must be https';
    if (key.startsWith('sbp_')) return 'a personal access token must never be embedded in the app';
    if (key.startsWith('sb_secret_')) return 'a secret key must never be embedded in the app';
    if (key.startsWith('eyJ') && _looksLikeServiceRole(key)) return 'a service_role key must never be embedded in the app';
    return null;
  }

  static bool _looksLikeServiceRole(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return false;
      var p = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (p.length % 4 != 0) {
        p += '=';
      }
      final json = String.fromCharCodes(_b64(p));
      return json.contains('"service_role"');
    } catch (_) {
      return false;
    }
  }

  static List<int> _b64(String s) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final out = <int>[];
    var buf = 0, bits = 0;
    for (final c in s.split('')) {
      if (c == '=') break;
      buf = (buf << 6) | chars.indexOf(c);
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        out.add((buf >> bits) & 0xFF);
      }
    }
    return out;
  }
}
