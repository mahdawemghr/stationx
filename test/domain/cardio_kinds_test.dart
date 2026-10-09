import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stationx/core/utils/formatters.dart';
import 'package:stationx/data/isar/isar_store.dart';
import 'package:stationx/data/sync/sync_rows.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/cardio/cardio_home_support.dart';
import 'package:stationx/features/cardio/cardio_manage_helpers.dart' as manage;
import 'package:stationx/features/cardio/backdate_cardio_page.dart';
import 'package:stationx/features/cardio/select_activity_page.dart';

import '../helpers/pump.dart';
import 'package:stationx/features/cardio/cardio_kind_presentation.dart';

CardioSession _s(String id, CardioKind k, int sec, double? km, [DateTime? d]) =>
    CardioSession(
      id: id,
      kind: k,
      workoutDate: d ?? DateTime(2026, 1, 1),
      durationSeconds: sec,
      distanceKm: km,
    );

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await Isar.initializeIsarCore(download: true);
  });

  group('kinds catalogue', () {
    test(
      'labels unique, custom is last, every kind has duration and sensible fields',
      () {
        final labels = CardioKind.values.map((k) => k.label).toList();
        expect(labels.toSet().length, labels.length);
        expect(CardioKind.values.last, CardioKind.custom);
        for (final k in CardioKind.values) {
          expect(k.fields, contains(CardioField.duration), reason: k.name);
          expect(k.fields.toSet().length, k.fields.length, reason: k.name);
          expect(
            k.fields.contains(CardioField.incline) ||
                k.fields.contains(CardioField.speed),
            const {
              CardioKind.treadmill,
              CardioKind.cycling,
              CardioKind.indoorWalk,
              CardioKind.skating,
            }.contains(k),
          );
        }
        expect(
          CardioKind.skiErg.fields,
          containsAll([CardioField.distance, CardioField.resistance]),
        );
        expect(CardioKind.airBike.fields, contains(CardioField.calories));
        expect(
          CardioKind.airBike.fields,
          isNot(contains(CardioField.resistance)),
        );
        expect(CardioKind.hiit.hasDistance, isFalse);
      },
    );

    test('icon, description and group mappings exist for every kind', () {
      for (final k in CardioKind.values) {
        expect(cardioKindIcon(k), isA<IconData>());
        expect(manage.cardioKindIcon(k), isA<IconData>());
        expect(cardioGroups(k), isA<Set<CardioGroup>>());
      }
    });

    test(
      'name round-trips through sync rows; unknown kind falls back to custom',
      () {
        for (final k in CardioKind.values) {
          final c = _s('c-${k.name}', k, 1200, k.hasDistance ? 2 : null);
          expect(cardioFromRow(cardioToRow(c)).kind, k);
        }
        final row = cardioToRow(_s('x', CardioKind.swimming, 600, 0.5))
          ..['kind'] = 'futureKind';
        expect(cardioFromRow(row).kind, CardioKind.custom);
      },
    );
  });

  group('2026-10 kinds', () {
    test('new kinds, labels, pace bases and single-membership sections', () {
      expect(
        CardioKind.values
            .sublist(
              CardioKind.values.length - 14,
              CardioKind.values.length - 1,
            )
            .map((k) => k.name),
        [
          'indoorWalk',
          'nordicWalk',
          'rucking',
          'recumbentBike',
          'indoorTrainer',
          'crossCountrySki',
          'openWaterSwim',
          'outdoorRowing',
          'paddling',
          'danceCardio',
          'skating',
          'climbing',
          'martialArts',
        ],
      );
      expect(CardioKind.treadmill.label, 'Treadmill Run');
      expect(CardioKind.indoorWalk.label, 'Indoor Walk / Walking Pad');
      expect(CardioKind.indoorWalk.paceBasis, CardioPaceBasis.none);
      expect(
        CardioKind.indoorWalk.fields,
        containsAll([CardioField.speed, CardioField.incline]),
      );
      expect(CardioKind.openWaterSwim.paceBasis, CardioPaceBasis.per100m);
      expect(CardioKind.outdoorRowing.paceBasis, CardioPaceBasis.per500m);
      expect(CardioKind.paddling.paceBasis, CardioPaceBasis.per500m);
      expect(CardioKind.nordicWalk.paceBasis, CardioPaceBasis.perKm);
      expect(CardioKind.skating.paceBasis, CardioPaceBasis.none);
      for (final k in CardioKind.values) {
        expect(cardioSections, contains(cardioSection(k)), reason: k.name);
        expect(cardioKindBlurb(k), isNotEmpty);
        expect(cardioSearchTerms(k), isNotEmpty, reason: k.name);
      }
      expect(cardioSection(CardioKind.custom), 'Custom');
      expect(cardioSearchTerms(CardioKind.indoorWalk), contains('12-3-30'));
      expect(cardioSearchTerms(CardioKind.martialArts), contains('muay thai'));
      expect(cardioKindGlyph(CardioKind.rucking), Icons.backpack);
    });

    test(
      'pace PR only for kinds with a pace convention (treadmill run keeps one)',
      () {
        final prs = PrService.cardio([
          _s('bike', CardioKind.cycling, 3600, 30),
          _s('walk', CardioKind.indoorWalk, 3600, 5),
          _s('skate', CardioKind.skating, 3600, 20),
          _s('tm', CardioKind.treadmill, 1800, 5),
          _s('ruck', CardioKind.rucking, 3600, 6),
        ]);
        final pace = prs
            .where((p) => p.type == CardioPrType.fastestPace)
            .map((p) => p.sessionId)
            .toSet();
        expect(pace, {'tm', 'ruck'});
        expect(
          prs.where(
            (p) =>
                p.sessionId == 'walk' && p.type == CardioPrType.longestDistance,
          ),
          hasLength(1),
        );
      },
    );

    test(
      'drift: latest cardio-kinds migration lists exactly the enum names',
      () {
        final files =
            Directory('supabase/migrations')
                .listSync()
                .whereType<File>()
                .where(
                  (f) =>
                      f.path.endsWith('.sql') &&
                      f.path.contains('cardio_kinds'),
                )
                .toList()
              ..sort((a, b) => a.path.compareTo(b.path));
        final sql = files.last.readAsStringSync();
        final list = RegExp(
          r'check \(kind in \(([^)]*)\)',
        ).firstMatch(sql)!.group(1)!;
        final names = RegExp(
          r"'(\w+)'",
        ).allMatches(list).map((m) => m.group(1)!).toList();
        expect(names, CardioKind.values.map((k) => k.name).toList());
      },
    );
  });

  group('pace conventions', () {
    test('rowing / ski erg per 500 m', () {
      // 2000 m in 8:00 -> 2:00 / 500 m
      final r = _s('r', CardioKind.rowing, 480, 2.0);
      expect(r.paceSecPer500m, closeTo(120, 1e-9));
      expect(r.conventionalPaceSec, closeTo(120, 1e-9));
      expect(
        Fmt.paceWithUnit(r.conventionalPaceSec, r.kind.paceBasis),
        '2:00 /500m',
      );
      expect(
        _s('s', CardioKind.skiErg, 300, 1.0).conventionalPaceSec,
        closeTo(150, 1e-9),
      );
    });

    test('swimming per 100 m, running per km, none without pace', () {
      final sw = _s(
        'w',
        CardioKind.swimming,
        1800,
        1.5,
      ); // 1500 m in 30:00 -> 2:00/100m
      expect(sw.paceSecPer100m, closeTo(120, 1e-9));
      expect(
        Fmt.paceWithUnit(sw.conventionalPaceSec, sw.kind.paceBasis),
        '2:00 /100m',
      );
      final run = _s('u', CardioKind.outdoorRun, 1800, 5);
      expect(
        Fmt.paceWithUnit(run.conventionalPaceSec, run.kind.paceBasis),
        '6:00 /km',
      );
      expect(CardioKind.hiit.paceBasis, CardioPaceBasis.none);
      expect(_s('h', CardioKind.hiit, 600, null).conventionalPaceSec, isNull);
      expect(_s('z', CardioKind.rowing, 600, 0).paceSecPer500m, isNull);
    });
  });

  group('PRs stay per kind', () {
    test(
      'a swim and a run never compete; short swims still earn a pace PR',
      () {
        final prs = PrService.cardio([
          _s('run', CardioKind.outdoorRun, 1500, 5, DateTime(2026, 1, 1)),
          _s('swim1', CardioKind.swimming, 360, 0.2, DateTime(2026, 1, 2)),
          _s('swim2', CardioKind.swimming, 330, 0.2, DateTime(2026, 1, 3)),
          _s(
            'row',
            CardioKind.rowing,
            100,
            0.3,
            DateTime(2026, 1, 4),
          ), // < 500 m: no pace PR
        ]);
        final pace = prs
            .where((p) => p.type == CardioPrType.fastestPace)
            .toList();
        expect(pace.map((p) => p.kindLabel).toSet(), {
          'Outdoor Run',
          'Pool Swim',
        });
        expect(
          pace.firstWhere((p) => p.kindLabel == 'Pool Swim').sessionId,
          'swim2',
        );
        final dist = prs.where((p) => p.type == CardioPrType.longestDistance);
        expect(dist.map((p) => p.kindLabel).toSet(), {
          'Outdoor Run',
          'Pool Swim',
          'Rowing Machine',
        });
      },
    );
  });

  test('Isar persists every kind by name across reopen', () async {
    final dir = Directory.systemTemp.createTempSync('stationx_kinds');
    try {
      var s = await IsarStore.open(directory: dir.path, name: 'k');
      for (final k in CardioKind.values) {
        await s.cardio.add(_s('c-${k.name}', k, 600, k.hasDistance ? 1 : null));
      }
      await s.close();
      s = await IsarStore.open(directory: dir.path, name: 'k');
      for (final k in CardioKind.values) {
        expect(s.cardio.byId('c-${k.name}')!.kind, k);
      }
      await s.close();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  testWidgets('select activity lists every kind at 320x568@2x without overflow', (
    t,
  ) async {
    // demo: false -> no RECENT strip, so each label appears exactly once.
    await pumpPage(
      t,
      const SelectCardioActivityPage(),
      size: const Size(320, 568),
      demo: false,
    );
    final list = find.byType(Scrollable).first;
    for (final k in CardioKind.values.where((k) => k != CardioKind.custom)) {
      // Sections are big lazy items: rewind, then scroll down until this label is built.
      await t.drag(list, const Offset(0, 20000));
      await t.pump();
      var steps = 0;
      while (find.text(k.label).evaluate().isEmpty && steps++ < 80) {
        await t.drag(list, const Offset(0, -200));
        await t.pump();
      }
      expect(find.text(k.label), findsOneWidget, reason: k.label);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('backdate form shows only the new kind\'s fields', (t) async {
    await pumpPage(
      t,
      const BackdateCardioPage(kind: CardioKind.hiit),
      size: const Size(390, 1600),
      demo: false,
    );
    expect(find.text('BELT SPEED'), findsNothing);
    expect(find.text('INCLINE'), findsNothing);
    expect(find.text('RESISTANCE LEVEL'), findsNothing);
    expect(find.text('CALCULATED AVG PACE'), findsNothing);
    await t.pumpWidget(const SizedBox());
    await pumpPage(
      t,
      const BackdateCardioPage(kind: CardioKind.skiErg),
      size: const Size(390, 1600),
      demo: false,
    );
    expect(find.text('RESISTANCE LEVEL'), findsOneWidget);
    expect(find.text('BELT SPEED'), findsNothing);
  });
}
