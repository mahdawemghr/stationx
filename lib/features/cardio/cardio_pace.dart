import '../../core/utils/formatters.dart';
import '../../domain/domain.dart';

/// Pace display in each activity's own convention: rowing / ski erg per 500 m,
/// swimming per 100 m, everything else per km or mi following the user's unit.
/// Storage stays sec/km everywhere; this only converts for display.
abstract final class CardioPace {
  static bool has(CardioKind k) => k.paceBasis != CardioPaceBasis.none || k.fields.contains(CardioField.pace);

  /// [secPerKm] converted to the display convention of [k].
  static double? convert(CardioKind k, double? secPerKm, {required bool miles}) {
    if (secPerKm == null) return null;
    return switch (k.paceBasis) {
      CardioPaceBasis.per500m => secPerKm / 2,
      CardioPaceBasis.per100m => secPerKm / 10,
      _ => miles ? secPerKm * 1.609344 : secPerKm,
    };
  }

  static String text(CardioKind k, double? secPerKm, {required bool miles}) => Fmt.pace(convert(k, secPerKm, miles: miles));

  /// '/km', '/mi', '/500m' or '/100m'.
  static String unit(CardioKind k, {required bool miles}) => switch (k.paceBasis) {
        CardioPaceBasis.per500m || CardioPaceBasis.per100m => k.paceBasis.unitLabel,
        _ => miles ? '/mi' : '/km',
      };

  static String withUnit(CardioKind k, double? secPerKm, {required bool miles}) =>
      '${text(k, secPerKm, miles: miles)} ${unit(k, miles: miles)}';
}
