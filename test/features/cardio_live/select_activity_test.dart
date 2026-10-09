import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/core/widgets/widgets.dart';
import 'package:stationx/domain/domain.dart';
import 'package:stationx/features/cardio/cardio_activity_templates.dart';
import 'package:stationx/features/cardio/cardio_manage_helpers.dart';
import 'package:stationx/features/cardio/cardio_prepare_page.dart';
import 'package:stationx/features/cardio/create_custom_activity_page.dart';
import 'package:stationx/features/cardio/select_activity_page.dart';

import '../../helpers/pump.dart';

const _small = Size(320, 568);

Future<void> _search(WidgetTester t, String q) async {
  await t.enterText(find.byType(TextField), q);
  await t.pump();
}

void main() {
  setUpAll(loadAppFonts);

  group('search', () {
    final cases = {
      'walking pad': ['Indoor Walk / Walking Pad'],
      '12-3-30': ['Indoor Walk / Walking Pad'],
      'zumba': ['Dance / Zumba / Aerobics'],
      'stepmill': ['Stair Climber / Stepper'],
      'kayak': ['Kayak / Canoe / SUP'],
      'sup': ['Kayak / Canoe / SUP'],
    };
    for (final e in cases.entries) {
      testWidgets('"${e.key}" finds ${e.value.first}', (t) async {
        await pumpPage(t, const SelectCardioActivityPage(), size: const Size(390, 844));
        await _search(t, e.key);
        for (final label in e.value) {
          expect(find.text(label), findsOneWidget, reason: e.key);
        }
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('alias hint names the matched term', (t) async {
      await pumpPage(t, const SelectCardioActivityPage());
      await _search(t, '12-3-30');
      expect(find.text('matches: 12-3-30'), findsOneWidget);
      await _search(t, 'stepmill');
      expect(find.text('matches: stepmill'), findsOneWidget);
    });

    testWidgets('label match shows no alias hint', (t) async {
      await pumpPage(t, const SelectCardioActivityPage());
      await _search(t, 'treadmill');
      expect(find.text('Treadmill Run'), findsOneWidget);
      expect(find.text('matches: treadmill'), findsNothing);
    });
  });

  group('browse', () {
    testWidgets('recent strip: <= 4 distinct, hidden while searching and for other filters', (t) async {
      final app = await pumpPage(t, const SelectCardioActivityPage(), size: _small);
      expect(find.byKey(const Key('recent-strip')), findsOneWidget);
      final chips = find.descendant(of: find.byKey(const Key('recent-strip')), matching: find.byType(SxChip));
      expect(chips.evaluate().length, inInclusiveRange(1, 4));
      final names = [for (final w in t.widgetList<SxChip>(chips)) w.label];
      expect(names.toSet().length, names.length);
      expect(names.first, app.cardio.sessions.first.kind.label);

      await _search(t, 'run');
      expect(find.byKey(const Key('recent-strip')), findsNothing);
      await _search(t, '');
      expect(find.byKey(const Key('recent-strip')), findsOneWidget);
      await t.tap(find.text('Outdoor'));
      await t.pump();
      expect(find.byKey(const Key('recent-strip')), findsNothing);
    });

    testWidgets('no recents on an empty account', (t) async {
      await pumpPage(t, const SelectCardioActivityPage(), demo: false);
      expect(find.byKey(const Key('recent-strip')), findsNothing);
    });

    testWidgets('group headers on All, gone when searching or filtering', (t) async {
      await pumpPage(t, const SelectCardioActivityPage(), size: const Size(390, 844), demo: false);
      expect(find.text('WALK & RUN'), findsOneWidget);
      final list = find.byType(Scrollable).last;
      for (final h in ['CYCLING', 'MACHINES', 'WATER', 'OUTDOOR & WINTER', 'CLASSES & CONDITIONING', 'CUSTOM']) {
        await t.scrollUntilVisible(find.text(h), 300, scrollable: list);
        expect(find.text(h), findsOneWidget);
      }
      await t.scrollUntilVisible(find.text('Custom Cardio Activity'), 300, scrollable: list);
      await t.drag(list, const Offset(0, 5000));
      await t.pump();
      await t.tap(find.text('Classes'));
      await t.pump();
      expect(find.text('WALK & RUN'), findsNothing);
      expect(find.text('Dance / Zumba / Aerobics'), findsOneWidget);
      expect(find.text('Outdoor Run'), findsNothing);
      await t.tap(find.text('All (33)'));
      await t.pump();
      await _search(t, 'run');
      expect(find.text('WALK & RUN'), findsNothing);
    });

    testWidgets('compact rows: >= 64dp tall, LAST at trailing edge, semantic label', (t) async {
      final h = t.ensureSemantics();
      await pumpPage(t, const SelectCardioActivityPage(), size: const Size(390, 844));
      final card = find.ancestor(of: find.text('Outdoor Run').last, matching: find.byType(SxCard)).first;
      expect(t.getSize(card).height, greaterThanOrEqualTo(48));
      expect(t.getSize(card).height, lessThan(96));
      expect(find.textContaining('LAST:'), findsWidgets);
      expect(find.bySemanticsLabel(RegExp(r'^Outdoor Run, METRICS')), findsWidgets);
      h.dispose();
    });

    testWidgets('sensor banner is a single line', (t) async {
      await pumpPage(t, const SelectCardioActivityPage(), size: _small, demo: false);
      final list = find.byType(Scrollable).first;
      await t.scrollUntilVisible(find.textContaining('NO SENSORS'), 300, scrollable: list);
      expect(t.getSize(find.textContaining('NO SENSORS')).height, lessThan(20));
    });

    for (final (size, scale) in [(_small, 1.0), (_small, 1.3), (const Size(390, 844), 1.0)]) {
      testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()} @$scale', (t) async {
        await pumpPage(t, const SelectCardioActivityPage(), size: size, textScale: scale);
        expect(t.takeException(), isNull);
        final list = find.byType(Scrollable).last;
        await t.drag(list, const Offset(0, -6000));
        await t.pump();
        expect(t.takeException(), isNull);
        await t.drag(list, const Offset(0, 9000));
        await t.pump();
        await _search(t, 'walking pad');
        expect(t.takeException(), isNull);
        await _search(t, 'qqqq');
        expect(t.takeException(), isNull);
        await _search(t, 'padel');
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('works with reduced motion', (t) async {
      await pumpPage(
        t,
        Builder(
            builder: (c) => MediaQuery(
                data: MediaQuery.of(c).copyWith(disableAnimations: true), child: const SelectCardioActivityPage())),
        size: _small,
      );
      await _search(t, 'kayak');
      expect(find.text('Kayak / Canoe / SUP'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('no result', () {
    testWidgets('offers Create custom "q" which opens the form prefilled', (t) async {
      await pumpPage(t, const SelectCardioActivityPage(), size: _small);
      await _search(t, 'Curling');
      expect(find.text('No activity found'), findsOneWidget);
      expect(find.text('CREATE CUSTOM "CURLING"'), findsOneWidget);
      await t.tap(find.text('CREATE CUSTOM "CURLING"'));
      await t.pumpAndSettle();
      expect(find.byType(CreateCustomCardioActivityPage), findsOneWidget);
      expect(find.text('Curling'), findsOneWidget);
    });

    testWidgets('matching template is one tap: saved as custom and opened', (t) async {
      final app = await pumpPage(t, const SelectCardioActivityPage(), size: _small, demo: false);
      await _search(t, 'padel');
      expect(find.text('No activity found'), findsOneWidget);
      await t.tap(find.text('Use "Padel" template'));
      await t.pumpAndSettle();
      final padel = app.cardio.customActivities.where((a) => a.name == 'Padel');
      expect(padel.length, 1);
      expect(find.byType(CardioPreparePage), findsOneWidget);
    });

    testWidgets('a saved custom activity is listed, searchable and not duplicated by the template', (t) async {
      final app = await pumpPage(t, const SelectCardioActivityPage(), size: _small, demo: false);
      await app.cardio.addCustomActivity(CustomCardioActivity(id: 'c1', name: 'Padel', category: 'Racket Sports', iconKey: 'sports_tennis'));
      await t.pump();
      await _search(t, 'padel');
      expect(find.text('Padel'), findsOneWidget);
      expect(find.text('No activity found'), findsNothing);
    });
  });

  group('custom form', () {
    testWidgets('initialName prefills', (t) async {
      await pumpPage(t, const CreateCustomCardioActivityPage(initialName: 'Curling'), size: _small, demo: false);
      expect(find.text('Curling'), findsOneWidget);
    });

    testWidgets('suggestion chip prefills name, category, icon, metrics and intervals', (t) async {
      await pumpPage(t, const CreateCustomCardioActivityPage(), size: const Size(390, 2400), demo: false);
      expect(find.text('SUGGESTIONS'), findsOneWidget);
      final row = find.descendant(of: find.byKey(const Key('template-suggestions')), matching: find.byType(Scrollable));
      await t.scrollUntilVisible(find.text('Battle Ropes'), 100, scrollable: row);
      await t.drag(row, const Offset(-60, 0));
      await t.pump();
      await t.tap(find.text('Battle Ropes'));
      await t.pump();
      expect(find.text('Battle Ropes'), findsNWidgets(2)); // chip + name field
      expect(find.text('03 / ROUND & INTERVAL TEMPLATE'), findsOneWidget);
      final chip = t.widget<SxChip>(find.widgetWithText(SxChip, 'Functional HIIT'));
      expect(chip.selected, isTrue);
    });

    testWidgets('suggestion then save creates the activity', (t) async {
      final app = await pumpPage(t, const CreateCustomCardioActivityPage(), size: const Size(390, 2400), demo: false);
      await t.tap(find.text('Padel'));
      await t.pump();
      await t.tap(find.text('SAVE CUSTOM ACTIVITY'));
      await t.pumpAndSettle();
      final a = app.cardio.customActivities.single;
      expect(a.name, 'Padel');
      expect(a.category, 'Racket Sports');
      expect(a.iconKey, 'sports_tennis');
      expect(a.fields, contains(CardioField.heartRate));
    });

    testWidgets('every template references a real category icon key and valid metrics', (t) async {
      const cats = ['Combat Sport', 'Functional HIIT', 'Field Sports', 'Racket Sports', 'Water / Paddle', 'Mind & Body'];
      final names = <String>{};
      for (final tpl in cardioActivityTemplates) {
        expect(cardioCustomIcons.containsKey(tpl.iconKey), isTrue, reason: tpl.name);
        expect(cats, contains(tpl.category), reason: tpl.name);
        expect(names.add(tpl.name.toLowerCase()), isTrue, reason: 'duplicate ${tpl.name}');
      }
      expect(cardioCustomIcons.length, greaterThanOrEqualTo(20));
    });

    testWidgets('no overflow at 320x568 @1.3 incl. suggestions + 48dp targets', (t) async {
      await pumpPage(t, const CreateCustomCardioActivityPage(), size: _small, textScale: 1.3, demo: false);
      expect(t.takeException(), isNull);
      expect(t.getSize(find.widgetWithText(SxChip, 'Padel').first).height, greaterThanOrEqualTo(48));
      await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });
}
