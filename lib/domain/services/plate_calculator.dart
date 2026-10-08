/// Per-side plate breakdown for a target barbell weight.
abstract final class PlateCalculator {
  static const defaultPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

  /// Returns plates for ONE side (greedy), and the unreachable remainder (kg, total).
  static ({List<double> perSide, double remainderKg}) plan({
    required double targetKg,
    double barKg = 20,
    List<double> plates = defaultPlates,
  }) {
    var perSideKg = (targetKg - barKg) / 2;
    final out = <double>[];
    if (perSideKg <= 0) return (perSide: out, remainderKg: 0);
    for (final p in plates) {
      while (perSideKg + 1e-9 >= p) {
        out.add(p);
        perSideKg -= p;
      }
    }
    return (
      perSide: out,
      remainderKg: double.parse((perSideKg * 2).toStringAsFixed(2)),
    );
  }
}
