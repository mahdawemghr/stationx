import '../../domain/domain.dart';

/// Display formatting helpers. Storage is always kg / km / seconds.
abstract final class Fmt {
  static String _two(int n) => n.toString().padLeft(2, '0');

  /// 75 → "01:15", 3725 → "1:02:05"
  static String clock(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    return h > 0 ? '$h:${_two(m)}:${_two(sec)}' : '${_two(m)}:${_two(sec)}';
  }

  /// Always HH:MM:SS (live cardio clocks).
  static String clockHms(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    return '${_two(s ~/ 3600)}:${_two((s % 3600) ~/ 60)}:${_two(s % 60)}';
  }

  /// 3725 → "1h 2m", 1938 → "32m"
  static String durationShort(int seconds) {
    final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60;
    if (h > 0) return m == 0 ? '${h}h' : '${h}h ${m}m';
    return '${m}m';
  }

  /// Pace (sec/km) → "6:12". Null → "—".
  static String pace(double? secPerKm) {
    if (secPerKm == null || secPerKm.isNaN || secPerKm.isInfinite) return '—';
    final t = secPerKm.round();
    return '${t ~/ 60}:${_two(t % 60)}';
  }

  /// Pace per 500 m (rowing, ski erg) → "2:05". Same m:ss shape as [pace].
  static String pace500(double? secPer500m) => pace(secPer500m);

  /// Pace per 100 m (swimming) → "1:48".
  static String pace100(double? secPer100m) => pace(secPer100m);

  /// Pace [sec] in the [basis] convention → "2:05 /500m". Null/none → "—".
  static String paceWithUnit(double? sec, CardioPaceBasis basis) =>
      (sec == null || basis == CardioPaceBasis.none) ? '—' : '${pace(sec)} ${basis.unitLabel}';

  static String number(num v, {int decimals = 1}) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(decimals);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// 4250 → "4,250"
  static String thousands(num v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0 && s[i - 1] != '-') b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static const _lbPerKg = 2.2046226218;

  static double toDisplayWeight(double kg, WeightUnit u) =>
      u == WeightUnit.kg ? kg : kg * _lbPerKg;
  static double fromDisplayWeight(double v, WeightUnit u) =>
      u == WeightUnit.kg ? v : v / _lbPerKg;

  /// "47.5" (no unit) in the user's unit.
  static String weight(double kg, [WeightUnit u = WeightUnit.kg]) => number(
    u == WeightUnit.kg ? kg : (toDisplayWeight(kg, u) * 2).round() / 2,
  );

  static String unit(WeightUnit u) => u == WeightUnit.kg ? 'kg' : 'lb';

  /// "50 kg × 8"
  static String setLabel(double kg, int reps, [WeightUnit u = WeightUnit.kg]) =>
      '${weight(kg, u)} ${unit(u)} × $reps';

  /// Volume: <10 000 kg → "4,250 kg"; ≥ 1000 shown as tonnes when [tonnes].
  static String volume(
    double kg, {
    bool tonnes = false,
    WeightUnit u = WeightUnit.kg,
  }) {
    if (tonnes && u == WeightUnit.kg) return '${number(kg / 1000)} t';
    return '${thousands(toDisplayWeight(kg, u))} ${unit(u)}';
  }

  static String km(double? v, {bool miles = false}) =>
      v == null ? '—' : number(miles ? v * 0.621371 : v, decimals: 2);

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String monthName(int m) => _months[m - 1];
  static String monthShort(int m) => _months[m - 1].substring(0, 3);
  static String dayName(int weekday) => _days[weekday - 1];
  static String dayShort(int weekday) => _days[weekday - 1].substring(0, 3);

  /// "Sep 14"
  static String dateShort(DateTime d) => '${monthShort(d.month)} ${d.day}';

  /// "Sep 14, 2026"
  static String dateMedium(DateTime d) =>
      '${monthShort(d.month)} ${d.day}, ${d.year}';

  /// "Monday, September 14"
  static String dateLong(DateTime d) =>
      '${dayName(d.weekday)}, ${monthName(d.month)} ${d.day}';

  /// "10:45 AM"
  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${_two(d.minute)} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Today" / "Yesterday" / "Sep 12"
  static String relativeDay(DateTime d, [DateTime? now]) {
    now ??= DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return dateShort(d);
  }

  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    return h < 12
        ? 'Good morning'
        : (h < 18 ? 'Good afternoon' : 'Good evening');
  }
}
