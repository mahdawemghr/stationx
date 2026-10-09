import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'setup_catalog.dart';
import 'setup_custom_step.dart';
import 'setup_day_step.dart';
import 'setup_pick_step.dart';
import 'setup_review_step.dart';
import 'setup_week_step.dart';

/// Schedule setup: choose a split -> pick exercises per day -> review and save.
/// Pages: pick, [custom days], [one page per day, skipped by Quick start], days per week, review.
/// Skippable at every step; leaving midway asks before discarding.
class ScheduleSetupFlow extends StatefulWidget {
  const ScheduleSetupFlow({super.key, this.afterSignup = false, this.catalog, this.onDone});

  /// Opened right after Create account: leaving (skip/back) enters the app instead of popping.
  final bool afterSignup;
  final SetupCatalog? catalog;

  /// Called after a successful save (default: enter the app).
  final void Function(BuildContext)? onDone;

  @override
  State<ScheduleSetupFlow> createState() => _ScheduleSetupFlowState();
}

class _ScheduleSetupFlowState extends State<ScheduleSetupFlow> {
  late final SetupCatalog _catalog = widget.catalog ?? SetupCatalog();
  int _step = 0;
  bool _custom = false;
  bool _quick = false;
  List<SplitDayPlan> _days = const [];
  int _perWeek = 4;
  bool _saving = false;

  /// Page list: pick, [custom days], [one page per day unless quick], week, review.
  List<(_Kind, int)> get _pages => [
        (_Kind.pick, 0),
        if (_custom) (_Kind.custom, 0),
        if (!_quick) for (var i = 0; i < _days.length; i++) (_Kind.day, i),
        (_Kind.week, 0),
        (_Kind.review, 0),
      ];
  _Kind get _kind => _pages[_step.clamp(0, _pages.length - 1)].$1;
  int get _dayIndex => _pages[_step.clamp(0, _pages.length - 1)].$2;

  void _preset(SplitPreset p, {required bool quick}) => setState(() {
        _custom = false;
        _quick = quick;
        _days = [...p.days];
        _perWeek = defaultDaysPerWeek(p.suggestedDaysPerWeek, dayCount: p.days.length);
        _step = 1;
      });

  void _startCustom() => setState(() {
        _custom = true;
        _quick = false;
        _days = const [SplitDayPlan(name: 'Day 1', sectionMuscles: [])];
        _perWeek = 3;
        _step = 1;
      });

  void _editDay(int i) => setState(() {
        _quick = false;
        _step = _pages.indexWhere((p) => p.$1 == _Kind.day && p.$2 == i);
      });

  void _exit() {
    if (widget.afterSignup) {
      AppNav.enterApp(context);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _skip() async {
    if (_step > 0) {
      final ok = await showSxConfirm(
        context,
        title: 'Discard this schedule?',
        message: 'Nothing has been saved yet. You can set it up later from Workouts or Profile.',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep editing',
        destructive: true,
        icon: Icons.delete_outline,
      );
      if (!ok || !mounted) return;
    }
    _exit();
  }

  Future<void> _back() async {
    if (_step == 0) return _exit();
    setState(() => _step--);
  }

  String? _customError() {
    for (final d in _days) {
      if (d.name.trim().isEmpty) return 'Every day needs a name.';
      if (d.sectionMuscles.isEmpty) return 'Choose at least one muscle for "${d.name.trim()}".';
    }
    final names = <String>{};
    for (final d in _days) {
      if (!names.add(d.name.trim().toLowerCase())) return 'Two days are called "${d.name.trim()}".';
    }
    return null;
  }

  Future<void> _save() async {
    final app = context.app;
    setState(() => _saving = true);
    ScheduleSaveResult res;
    try {
      res = await ScheduleBuilder.save(
        _days,
        workouts: app.workouts,
        sessions: app.sessions,
        catalog: app.exercises.all,
        stamp: DateTime.now().microsecondsSinceEpoch.toString(),
      );
      await app.profile.update(app.profile.profile.copyWith(weeklySessionTarget: _perWeek));
    } on ArgumentError {
      if (mounted) {
        setState(() => _saving = false);
        showSxSnack(context, 'Couldn\'t save the schedule. Check that every day has at least one exercise, then try again.', icon: Icons.error_outline);
      }
      return;
    }
    if (!mounted) return;
    final archived = res.archivedOld.length;
    showSxSnack(
      context,
      'Schedule saved: ${_days.length} ${_days.length == 1 ? 'workout' : 'workouts'}, goal $_perWeek days a week'
      '${archived == 0 ? '' : '. $archived previous ${archived == 1 ? 'workout is' : 'workouts are'} archived, not deleted'}',
    );
    (widget.onDone ?? AppNav.enterApp)(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.sx;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([app.exercises, app.profile]),
        builder: (context, _) {
          final all = app.exercises.all;
          final kind = _kind;
          final title = switch (kind) {
            _Kind.pick => 'Set up your schedule',
            _Kind.custom => 'Your days',
            _Kind.day => 'Day ${_dayIndex + 1} of ${_days.length}',
            _Kind.week => 'Days per week',
            _Kind.review => 'Review',
          };
          Widget body;
          Widget? bottom;
          switch (kind) {
            case _Kind.pick:
              body = SetupPickStep(
                presets: _catalog.presets,
                onQuick: (p) => _preset(p, quick: true),
                onCustomize: (p) => _preset(p, quick: false),
                onCustom: _startCustom,
              );
            case _Kind.custom:
              final err = _customError();
              body = SetupCustomStep(
                days: _days,
                all: all,
                catalog: _catalog,
                onChanged: (d) => setState(() => _days = d),
              );
              bottom = _Cta(label: 'Continue', hint: err, onPressed: err == null ? () => setState(() => _step++) : null);
            case _Kind.day:
              final i = _dayIndex;
              body = SetupDayStep(
                key: ValueKey('day$i'),
                day: _days[i],
                all: all,
                catalog: _catalog,
                profile: app.profile.profile,
                onChanged: (d) => setState(() => _days = [..._days]..[i] = d),
              );
              bottom = _Cta(
                label: i == _days.length - 1 ? 'Next: days per week' : 'Next: ${_days[i + 1].name}',
                hint: _days[i].exercises.isEmpty ? 'Tick at least one exercise for this day.' : null,
                onPressed: () => setState(() => _step++),
              );
            case _Kind.week:
              body = SetupWeekStep(value: _perWeek, dayCount: _days.length, onChanged: (n) => setState(() => _perWeek = n));
              bottom = _Cta(label: 'Review', hint: null, onPressed: () => setState(() => _step++));
            case _Kind.review:
              final err = ScheduleBuilder.validate(_days, all);
              body = SetupReviewStep(days: _days, all: all, error: err, perWeek: _perWeek, onEdit: _editDay);
              bottom = _Cta(label: 'Save schedule', hint: null, loading: _saving, onPressed: err == null && !_saving ? _save : null);
          }
          return SxScaffold(
            topBar: SxTopBar(
              title: title,
              onBack: _back,
              actions: [
                TextButton(
                  onPressed: _skip,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text('Skip', semanticsLabel: 'Skip for now', style: SxText.labelUi.copyWith(color: c.textBody)),
                ),
              ],
            ),
            body: SxStepTransition(step: _step, child: body),
            bottom: bottom == null ? null : SxSwap(alignment: Alignment.bottomCenter, child: KeyedSubtree(key: ValueKey<int>(_step), child: bottom)),
          );
        },
      ),
    );
  }
}

enum _Kind { pick, custom, day, week, review }

class _Cta extends StatelessWidget {
  const _Cta({required this.label, required this.onPressed, this.hint, this.loading = false});
  final String label;
  final String? hint;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (hint != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(hint!, textAlign: TextAlign.center, style: SxText.bodySm.copyWith(color: c.textBody)),
        ),
      SxButton(label: label, loading: loading, onPressed: onPressed, trailingIcon: Icons.arrow_forward),
    ]);
  }
}
