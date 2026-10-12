import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  group('age', () {
    test('accepts 13..100 whole years', () {
      for (final s in ['13', '28', ' 100 ']) {
        expect(BodyMetrics.validateAge(s), isNull, reason: s);
      }
    });
    test('rejects out of range, empty and garbage', () {
      expect(BodyMetrics.validateAge(''), 'Enter your age');
      expect(BodyMetrics.validateAge(null), 'Enter your age');
      for (final s in [
        '12',
        '101',
        '0',
        '-5',
        '28.5',
        'abc',
        '1e9',
        '1000000000',
        'NaN',
        '12.5.3',
      ]) {
        expect(BodyMetrics.validateAge(s), isNotNull, reason: s);
      }
    });
  });

  group('height', () {
    test('cm range 100..250', () {
      for (final s in ['100', '175', '175.5', '175,5', '250']) {
        expect(BodyMetrics.validateHeight(s), isNull, reason: s);
      }
      for (final s in [
        '',
        '99.9',
        '251',
        '-170',
        '1e9',
        '12.5.3',
        'NaN',
        'Infinity',
        '17 5',
        '999999999',
      ]) {
        expect(BodyMetrics.validateHeight(s), isNotNull, reason: s);
      }
    });
    test('imperial 3\'4" .. 8\'2"', () {
      expect(BodyMetrics.validateHeightImperial('5', '9'), isNull);
      expect(BodyMetrics.validateHeightImperial('5', ''), isNull);
      expect(BodyMetrics.validateHeightImperial('3', '4'), isNull);
      expect(BodyMetrics.validateHeightImperial('8', '2'), isNull);
      for (final p in [
        ('', '3'),
        ('3', '3'),
        ('8', '3'),
        ('5', '12'),
        ('5', '-1'),
        ('x', '1'),
        ('5', '1e9'),
        ('1e9', '0'),
      ]) {
        expect(
          BodyMetrics.validateHeightImperial(p.$1, p.$2),
          isNotNull,
          reason: '$p',
        );
      }
    });
  });

  group('weight', () {
    test('kg range 30..300', () {
      for (final s in ['30', '74', '74.5', '300']) {
        expect(BodyMetrics.validateWeight(s), isNull, reason: s);
      }
      for (final s in [
        '',
        '29',
        '301',
        '-70',
        '1e9',
        '12.5.3',
        'NaN',
        '70kg',
      ]) {
        expect(BodyMetrics.validateWeight(s), isNotNull, reason: s);
      }
    });
    test('lb range 66..660', () {
      expect(BodyMetrics.validateWeight('66', lb: true), isNull);
      expect(BodyMetrics.validateWeight('660', lb: true), isNull);
      expect(BodyMetrics.validateWeight('160', lb: true), isNull);
      expect(BodyMetrics.validateWeight('65', lb: true), isNotNull);
      expect(BodyMetrics.validateWeight('661', lb: true), isNotNull);
      expect(BodyMetrics.validateWeight('abc', lb: true), isNotNull);
    });
  });

  group('conversions', () {
    test('known values', () {
      expect(BodyMetrics.cmFromFeetInches(5, 9), 175.3);
      expect(BodyMetrics.cmFromFeetInches(6, 0), 182.9);
      expect(BodyMetrics.feetInchesFromCm(175), (feet: 5, inches: 9));
      expect(BodyMetrics.kgFromLb(165), 74.8);
      expect(BodyMetrics.lbFromKg(74), 163.1);
    });
    test('round trips', () {
      for (var cm = 100; cm <= 250; cm++) {
        final fi = BodyMetrics.feetInchesFromCm(cm);
        expect(fi.inches, inInclusiveRange(0, 11));
        expect(
          (BodyMetrics.cmFromFeetInches(fi.feet, fi.inches) - cm).abs(),
          lessThanOrEqualTo(1.4),
        );
      }
      for (var ft = 3; ft <= 8; ft++) {
        for (var i = 0; i < 12; i++) {
          final back = BodyMetrics.feetInchesFromCm(
            BodyMetrics.cmFromFeetInches(ft, i),
          );
          expect((back.feet, back.inches), (ft, i));
        }
      }
      for (var lb = 66; lb <= 660; lb++) {
        expect(
          (BodyMetrics.lbFromKg(BodyMetrics.kgFromLb(lb)) - lb).abs(),
          lessThanOrEqualTo(0.2),
        );
      }
    });
    test('parseNumber is strict', () {
      expect(BodyMetrics.parseNumber('72.5'), 72.5);
      expect(BodyMetrics.parseNumber('72,5'), 72.5);
      for (final s in ['', ' ', '-1', '1e9', '12.5.3', '.5', '5.', 'NaN']) {
        expect(BodyMetrics.parseNumber(s), isNull, reason: s);
      }
    });
  });
}
