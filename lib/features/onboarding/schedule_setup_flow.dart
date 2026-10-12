import 'package:flutter/material.dart';

import '../../data/remote/remote_exception.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_motion.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'setup_catalog.dart';
import 'setup_custom_step.dart';
import 'setup_day_step.dart';
import 'setup_equipment_step.dart';
import 'setup_experience_step.dart';
import 'setup_pick_step.dart';
import 'setup_review_step.dart';
import 'setup_week_step.dart';
import 'setup_widgets.dart';

/// Schedule setup: choose a split -> pick exercises per day -> review and save.
/// Pages: pick, [custom days], [one page per day, skipped by Quick start], days per week, review.
/// Skippable at every step; leaving midway asks before discarding.
class ScheduleSetupFlow extends StatefulWidget {
  const ScheduleSetupFlow({
    super.key,
    this.afterSignup = false,
    this.catalog,
    this.onDone,
  });

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
  SplitPreset? _source; // the preset the days came from (null for Custom)
  Set<Equipment>? _equipment; // null until the user touches the question
  Difficulty? _experience; // null until the user touches the question
  String? _fittedKey; // equipment + level the preset days were last fitted to
  String? _fitNote; // shown on Review when equipment removed exercises
  bool _saving = false;
  bool _saved = false;
  String _savedNote = '';

  /// Page list: pick, equipment, [custom days], [one page per day unless quick], week, review.
  List<(_Kind, int)> get _pages => [
    (_Kind.pick, 0),
    (_Kind.equipment, 0),
    (_Kind.experience, 0),
    if (_custom) (_Kind.custom, 0),
    if (!_quick)
      for (var i = 0; i < _days.length; i++) (_Kind.day, i),
    (_Kind.week, 0),
    (_Kind.review, 0),
  ];
  _Kind get _kind => _pages[_step.clamp(0, _pages.length - 1)].$1;
  int get _dayIndex => _pages[_step.clamp(0, _pages.length - 1)].$2;

  void _preset(SplitPreset p, {required bool quick}) => setState(() {
    _source = p;
    _fittedKey = null;
    _custom = false;
    _quick = quick;
    _days = [...p.days];
    _perWeek = defaultDaysPerWeek(
      p.suggestedDaysPerWeek,
      dayCount: p.days.length,
    );
    _step = 1;
  });

  void _startCustom() => setState(() {
    _source = null;
    _custom = true;
    _quick = false;
    _days = const [SplitDayPlan(name: 'Day 1', sectionMuscles: [])];
    _perWeek = 3;
    _step = 1;
  });

  /// What the equipment question shows: this run's choice, else the saved one, else a full gym.
  Set<Equipment> _equipmentNow(UserProfile p) =>
      _equipment ?? p.equipment ?? {...EquipmentAccess.choosable};

  /// What the experience question shows: this run's choice, else the saved one, else intermediate.
  Difficulty _experienceNow(UserProfile p) =>
      _experience ?? p.experienceLevel ?? Difficulty.intermediate;

  void _equipmentNext(UserProfile profile) => setState(() {
    _equipment = _equipmentNow(profile);
    _step++;
  });

  /// Leaves the experience step: a preset is fitted to the chosen equipment and level (only when one of
  /// them changed, so edits made later on the day pages are not thrown away by going back and forward).
  void _experienceNext(List<Exercise> all, UserProfile profile) {
    final chosen = _equipmentNow(profile);
    final level = _experienceNow(profile);
    final key =
        '${([for (final e in chosen) e.name]..sort()).join(',')}|${level.name}';
    final src = _source;
    String? note = _fitNote;
    if (src != null && _fittedKey != key) {
      final r = ProgramEquipmentFit.fitReport(
        src.days,
        all,
        chosen,
        level: level,
      );
      _days = r.days;
      _fittedKey = key;
      final parts = <String>[
        if (r.leftOut > 0)
          '${r.leftOut} ${r.leftOut == 1 ? 'exercise has' : 'exercises have'} no close match for your equipment and ${r.leftOut == 1 ? 'was' : 'were'} left out. Use Edit to add your own.',
      ];
      note = parts.isEmpty ? null : parts.join(' ');
    }
    setState(() {
      _equipment = chosen;
      _experience = level;
      _fitNote = note;
      _step++;
    });
  }

  /// Review note: what the equipment fit left out, plus a plain list of ADVANCED exercises when the user is
  /// not advanced (generation only uses them when nothing easier covers a muscle; manual picks are allowed).
  String? _reviewNote(List<Exercise> all, UserProfile profile) {
    final level = _experienceNow(profile);
    final names = <String>[];
    if (level != Difficulty.advanced) {
      final byId = {for (final e in all) e.id: e};
      for (final d in _days) {
        for (final r in d.exercises) {
          final e = byId[r.exerciseId];
          if (e?.difficulty == Difficulty.advanced &&
              !names.contains(e!.name)) {
            names.add(e.name);
          }
        }
      }
    }
    final parts = [
      ?_fitNote,
      if (names.isNotEmpty)
        'Advanced exercise${names.length == 1 ? '' : 's'} in this program: ${names.join(', ')}. ${level == Difficulty.beginner ? 'They are here only because nothing easier covers that movement, or you picked them.' : 'Swap any that feel too hard.'}',
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

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
        message:
            'Nothing has been saved yet. You can set it up later from Workouts or Profile.',
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
      if (d.sectionMuscles.isEmpty) {
        return 'Choose at least one muscle for "${d.name.trim()}".';
      }
    }
    final names = <String>{};
    for (final d in _days) {
      if (!names.add(d.name.trim().toLowerCase())) {
        return 'Two days are called "${d.name.trim()}".';
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return; // a second tap while the first save is running
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
      await app.profile.update(
        app.profile.profile.copyWith(
          weeklySessionTarget: _perWeek,
          equipment: _equipment,
          // Only a level the user actually saw/chose is stored; skipping the question keeps "no preference".
          experienceLevel: _experience,
        ),
      );
    } on ArgumentError {
      if (mounted) {
        setState(() => _saving = false);
        showSxSnack(
          context,
          'Couldn\'t save the schedule. Check that every day has at least one exercise, then try again.',
          icon: Icons.error_outline,
        );
      }
      return;
    } catch (e) {
      // Nothing is reported as saved: stay on the review page so the same plan can be saved again.
      if (mounted) {
        setState(() => _saving = false);
        showSxSnack(
          context,
          "Couldn't save the schedule. ${RemoteException.from(e).userMessage}",
          icon: Icons.error_outline,
        );
      }
      return;
    }
    if (!mounted) return;
    final archived = res.archivedOld.length;
    final note =
        'Schedule saved: ${_days.length} ${_days.length == 1 ? 'workout' : 'workouts'}, ${WeekPlan.summary(_perWeek)}'
        '${archived == 0 ? '' : '. $archived previous ${archived == 1 ? 'workout is' : 'workouts are'} archived, not deleted'}';
    showSxSnack(context, note);
    // Success state (animated check) first; the overlay enters the app when its animation ends.
    setState(() {
      _saving = false;
      _saved = true;
      _savedNote = note;
    });
  }

  void _finish() {
    if (!mounted) return;
    (widget.onDone ?? AppNav.enterApp)(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.sx;
    if (_saved) {
      return PopScope(
        canPop: false,
        child: SxScaffold(
          topBar: const SxTopBar(title: 'Schedule saved'),
          body: _SavedState(
            note: _savedNote,
            days: _days.length,
            onDone: _finish,
          ),
        ),
      );
    }
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
            _Kind.equipment => 'Your equipment',
            _Kind.experience => 'Your experience',
            _Kind.custom => 'Your days',
            _Kind.day => 'Day ${_dayIndex + 1} of ${_days.length}',
            _Kind.week => 'Your week',
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
            case _Kind.equipment:
              final chosen = _equipmentNow(app.profile.profile);
              body = SetupEquipmentStep(
                selected: chosen,
                onChanged: (s) => setState(() => _equipment = s),
              );
              bottom = _Cta(
                label: 'Continue',
                hint: null,
                onPressed: () => _equipmentNext(app.profile.profile),
              );
            case _Kind.experience:
              body = SetupExperienceStep(
                selected: _experienceNow(app.profile.profile),
                onChanged: (d) => setState(() => _experience = d),
              );
              bottom = _Cta(
                label: 'Continue',
                hint: null,
                onPressed: () => _experienceNext(all, app.profile.profile),
              );
            case _Kind.custom:
              final err = _customError();
              body = SetupCustomStep(
                days: _days,
                all: all,
                catalog: _catalog,
                equipment: _equipment,
                level: _experienceNow(app.profile.profile),
                onChanged: (d) => setState(() => _days = d),
              );
              bottom = _Cta(
                label: 'Continue',
                hint: err,
                onPressed: err == null ? () => setState(() => _step++) : null,
              );
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
                label: i == _days.length - 1
                    ? 'Next: your week'
                    : 'Next: ${_days[i + 1].name}',
                hint: _days[i].exercises.isEmpty
                    ? 'Tick at least one exercise for this day.'
                    : null,
                onPressed: () => setState(() => _step++),
              );
            case _Kind.week:
              body = SetupWeekStep(
                value: _perWeek,
                dayCount: _days.length,
                onChanged: (n) => setState(() => _perWeek = n),
              );
              bottom = _Cta(
                label: 'Review',
                hint: null,
                onPressed: () => setState(() => _step++),
              );
            case _Kind.review:
              final err = ScheduleBuilder.validate(_days, all);
              body = SetupReviewStep(
                note: _reviewNote(all, app.profile.profile),
                days: _days,
                all: all,
                error: err,
                perWeek: _perWeek,
                onEdit: _editDay,
              );
              bottom = _Cta(
                label: 'Save schedule',
                hint: null,
                loading: _saving,
                onPressed: err == null && !_saving ? _save : null,
              );
          }
          return SxScaffold(
            topBar: SxTopBar(
              title: title,
              onBack: _back,
              actions: [
                TextButton(
                  onPressed: _skip,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text(
                    'Skip',
                    semanticsLabel: 'Skip for now',
                    style: SxText.labelUi.copyWith(color: c.textBody),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                SetupStepDots(
                  count: _pages.length,
                  index: _step.clamp(0, _pages.length - 1),
                ),
                Expanded(
                  child: SxStepTransition(step: _step, child: body),
                ),
              ],
            ),
            bottom: bottom == null
                ? null
                : SxSwap(
                    alignment: Alignment.bottomCenter,
                    child: KeyedSubtree(
                      key: ValueKey<int>(_step),
                      child: bottom,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

enum _Kind { pick, equipment, experience, custom, day, week, review }

class _Cta extends StatelessWidget {
  const _Cta({
    required this.label,
    required this.onPressed,
    this.hint,
    this.loading = false,
  });
  final String label;
  final String? hint;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              hint!,
              textAlign: TextAlign.center,
              style: SxText.bodySm.copyWith(color: c.textBody),
            ),
          ),
        SxButton(
          label: label,
          loading: loading,
          onPressed: onPressed,
          trailingIcon: Icons.arrow_forward,
        ),
      ],
    );
  }
}

/// Success state after saving: a popping check, then [onDone] once the short animation has run.
class _SavedState extends StatefulWidget {
  const _SavedState({
    required this.note,
    required this.days,
    required this.onDone,
  });
  final String note;
  final int days;
  final VoidCallback onDone;

  @override
  State<_SavedState> createState() => _SavedStateState();
}

class _SavedStateState extends State<_SavedState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (SxMotion.reduced(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return;
    }
    _c.duration = const Duration(milliseconds: 900);
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Semantics(
      liveRegion: true,
      label: 'Schedule saved',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SxPop(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 52, color: c.onPrimary),
              ),
            ),
            const SizedBox(height: 16),
            SxFadeSlideIn(
              dy: 8,
              child: Text(
                'Schedule saved',
                style: SxText.headlineLg.copyWith(color: c.textHigh),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.days} ${widget.days == 1 ? 'workout' : 'workouts'} ready',
              style: SxText.bodyMd.copyWith(color: c.textBody),
            ),
          ],
        ),
      ),
    );
  }
}
