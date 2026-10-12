/// Age / height / weight asked once at sign-up ("About you"). Pure: parsing, friendly validation and
/// unit conversion. The profile always stores centimetres and kilograms.
abstract final class BodyMetrics {
  static const minAge = 13;
  static const maxAge = 100;
  static const minHeightCm = 100.0;
  static const maxHeightCm = 250.0;
  static const minWeightKg = 30.0;
  static const maxWeightKg = 300.0;

  static const _cmPerInch = 2.54;
  static const _lbPerKg = 2.2046226218;

  static final _number = RegExp(r'^\d{1,6}([.,]\d{1,3})?$');
  static final _whole = RegExp(r'^\d{1,4}$');

  /// A plain non-negative decimal ("72", "72.5", "72,5"), else null. No signs, exponents or "12.5.3".
  static double? parseNumber(String? text) {
    final t = (text ?? '').trim();
    if (!_number.hasMatch(t)) return null;
    final v = double.tryParse(t.replaceAll(',', '.'));
    return (v == null || !v.isFinite) ? null : v;
  }

  /// Whole years, else null.
  static int? parseAge(String? text) {
    final t = (text ?? '').trim();
    return _whole.hasMatch(t) ? int.tryParse(t) : null;
  }

  static double _round1(double v) => (v * 10).round() / 10;

  // ── conversions ──
  static double cmFromFeetInches(num feet, num inches) =>
      _round1((feet * 12 + inches) * _cmPerInch);

  /// Whole inches (0..11); 12 rolls over into the next foot.
  static ({int feet, int inches}) feetInchesFromCm(num cm) {
    final total = (cm / _cmPerInch).round();
    return (feet: total ~/ 12, inches: total % 12);
  }

  static double kgFromLb(num lb) => _round1(lb / _lbPerKg);
  static double lbFromKg(num kg) => _round1(kg * _lbPerKg);

  // ── validation: null = valid, otherwise a friendly message ──
  static String? validateAge(String? text) {
    if ((text ?? '').trim().isEmpty) return 'Enter your age';
    final v = parseAge(text);
    if (v == null) return 'Use whole years, like 28';
    if (v < minAge || v > maxAge) {
      return 'Age must be between $minAge and $maxAge';
    }
    return null;
  }

  /// Height in centimetres.
  static String? validateHeight(String? text) {
    if ((text ?? '').trim().isEmpty) return 'Enter your height';
    final v = parseNumber(text);
    if (v == null) return 'Use numbers only, like 175';
    if (v < minHeightCm || v > maxHeightCm) {
      return 'Height must be between ${minHeightCm.round()} and ${maxHeightCm.round()} cm';
    }
    return null;
  }

  /// Height as feet + inches (3'4" to 8'2").
  static String? validateHeightImperial(String? feet, String? inches) {
    if ((feet ?? '').trim().isEmpty) return 'Enter your height';
    final f = parseAge(feet);
    final i = (inches ?? '').trim().isEmpty ? 0.0 : parseNumber(inches);
    if (f == null || i == null) return 'Use numbers only, like 5 ft 9 in';
    if (i >= 12) return 'Inches go from 0 to 11';
    final cm = cmFromFeetInches(f, i);
    if (cm < minHeightCm - 0.5 || cm > maxHeightCm + 0.5) {
      return 'Height must be between 3\'4" and 8\'2"';
    }
    return null;
  }

  /// Weight in kg, or in pounds when [lb] is true.
  static String? validateWeight(String? text, {bool lb = false}) {
    if ((text ?? '').trim().isEmpty) return 'Enter your weight';
    final v = parseNumber(text);
    if (v == null) return 'Use numbers only, like ${lb ? 160 : 72}';
    final lo = lb ? 66.0 : minWeightKg;
    final hi = lb ? 660.0 : maxWeightKg;
    if (v < lo || v > hi) {
      return lb
          ? 'Weight must be between ${lo.round()} and ${hi.round()} lb'
          : 'Weight must be between ${minWeightKg.round()} and ${maxWeightKg.round()} kg';
    }
    return null;
  }
}
