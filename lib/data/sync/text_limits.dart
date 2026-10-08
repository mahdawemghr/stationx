// Defensive limits shared by the importer and the cloud row builders so that no local value can
// ever violate a server CHECK (supabase/migrations) and wedge sync. These only shape what is
// SENT/IMPORTED; they never change data already stored on the device.

/// Truncates [s] to at most [max] UTF-16 units without leaving a half surrogate pair, and removes
/// characters PostgreSQL text/jsonb cannot store (NUL, unpaired surrogates).
String clipText(String s, int max) {
  final units = <int>[];
  final u = s.codeUnits;
  for (var i = 0; i < u.length; i++) {
    final c = u[i];
    if (c == 0) continue;
    if (c >= 0xD800 && c <= 0xDBFF) {
      if (i + 1 < u.length && u[i + 1] >= 0xDC00 && u[i + 1] <= 0xDFFF) {
        if (units.length + 2 > max) break;
        units..add(c)..add(u[i + 1]);
        i++;
      }
      continue; // unpaired high surrogate: drop
    }
    if (c >= 0xDC00 && c <= 0xDFFF) continue; // unpaired low surrogate: drop
    if (units.length + 1 > max) break;
    units.add(c);
  }
  return String.fromCharCodes(units);
}

/// Like [clipText] but never returns an empty string (server columns that require >= 1 char).
String clipNonEmpty(String s, int max, String fallback) {
  final t = clipText(s, max);
  return t.trim().isEmpty ? fallback : t;
}

/// Finite number clamped to [lo]..[hi] (NaN / infinity become [lo]) - JSON cannot carry them.
double clampNum(num v, double lo, double hi) {
  final d = v.toDouble();
  if (d.isNaN) return lo;
  return d < lo ? lo : (d > hi ? hi : d);
}

int clampInt(num v, int lo, int hi) => clampNum(v, lo.toDouble(), hi.toDouble()).round();
