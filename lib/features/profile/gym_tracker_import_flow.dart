import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/import/gym_tracker_import.dart';

/// "Import from Gym Tracker": choose the exported file (or paste it) → preview what will happen →
/// confirm → add. Nothing is changed before the confirmation, and existing data is never modified.
Future<void> importFromGymTracker(BuildContext context) async {
  final app = context.app;
  final source = await showSxSheet<_Source>(context, builder: (_) => const _SourceSheet());
  if (source == null || !context.mounted) return;

  final String? text;
  try {
    text = switch (source) {
      _Source.file => await app.importSource.pickJsonText(),
      _Source.paste => (await Clipboard.getData(Clipboard.kTextPlain))?.text,
    };
  } on ImportException catch (e) {
    if (context.mounted) await _showProblem(context, e);
    return;
  } catch (_) {
    if (context.mounted) await _showMessage(context, 'Couldn\'t read the file', 'The file could not be opened. Try exporting again, or use "Paste copied data".');
    return;
  }
  if (text == null || !context.mounted) return; // cancelled
  if (GymTrackerImport.exceedsLimit(text)) {
    await _showProblem(context, const ImportException(ImportProblem.tooLarge));
    return;
  }
  if (text.trim().isEmpty) {
    await _showMessage(context, 'Nothing to import', 'The clipboard is empty. In Gym Tracker choose Settings › Export Data, then try again.');
    return;
  }

  final GymTrackerImportPlan plan;
  try {
    plan = await GymTrackerImport.planAsync(
      text,
      existingSessionIds: {for (final s in app.sessions.sessions) s.id},
      catalog: app.exercises.all,
      workouts: app.workouts.workouts,
    );
  } on ImportException catch (e) {
    if (context.mounted) await _showProblem(context, e);
    return;
  }
  if (!context.mounted) return;

  if (plan.isEmpty) {
    final why = <String>[
      if (plan.skippedAlreadyImported > 0) '${plan.skippedAlreadyImported} workout${plan.skippedAlreadyImported == 1 ? ' is' : 's are'} already in StationX.',
      if (plan.skippedNotCompleted > 0) '${plan.skippedNotCompleted} unfinished workout${plan.skippedNotCompleted == 1 ? ' was' : 's were'} skipped.',
      if (plan.skippedInvalid > 0) '${plan.skippedInvalid} entr${plan.skippedInvalid == 1 ? 'y' : 'ies'} could not be read.',
    ];
    await _showMessage(context, 'Nothing new to import', why.isEmpty ? 'This file has no completed workouts.' : why.join(' '));
    return;
  }

  final choice = await showDialog<_Confirmed>(context: context, builder: (_) => _PreviewDialog(plan: plan));
  if (choice == null || !context.mounted) return;

  // Busy indicator while the workouts are written (can take a moment for big files).
  final nav = Navigator.of(context, rootNavigator: true);
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: _BusyDialog()),
  ));
  final ImportResult result;
  try {
    result = await GymTrackerImport.apply(
      plan,
      exercises: app.exercises,
      sessions: app.sessions,
      workouts: app.workouts,
      applyRotation: choice.applyRotation,
    );
  } catch (_) {
    nav.pop();
    if (context.mounted) {
      await _showMessage(context, 'Import didn\'t finish', 'Something went wrong while adding your workouts. Anything already added is safe; you can run the import again and duplicates are skipped.');
    }
    return;
  }
  nav.pop();
  if (!context.mounted) return;
  showSxSnack(context, 'Imported ${result.sessionsAdded} workout${result.sessionsAdded == 1 ? '' : 's'} from Gym Tracker');
}

enum _Source { file, paste }

class _Confirmed {
  const _Confirmed(this.applyRotation);
  final bool applyRotation;
}

String _problemText(ImportProblem p) => switch (p) {
      ImportProblem.tooLarge => 'This file is too large to be a Gym Tracker export (the limit is 10 MB).',
      ImportProblem.notJson => 'This isn\'t a Gym Tracker export. Choose the .json file made by Gym Tracker › Settings › Export Data.',
      ImportProblem.wrongFormat => 'This file was not made by Gym Tracker. Choose the .json file made by Gym Tracker › Settings › Export Data.',
      ImportProblem.unsupportedVersion => 'This export comes from a newer version of Gym Tracker. Update StationX, then try again.',
      ImportProblem.nothingToImport => 'This file has no completed workouts.',
    };

Future<void> _showProblem(BuildContext context, ImportException e) => _showMessage(context, 'Can\'t import this file', _problemText(e.problem));

Future<void> _showMessage(BuildContext context, String title, String message) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('IMPORT FROM GYM TRACKER', style: SxText.headlineMd.copyWith(color: c.textHigh)),
        const SizedBox(height: 8),
        Text(
          'In Gym Tracker open Settings › Export Data and save the file, then choose it here. '
          'Your completed workouts are added to your history; nothing you already have is changed or removed.',
          style: SxText.bodyMd.copyWith(color: c.textBody),
        ),
        const SizedBox(height: SxSpace.md),
        SxButton(label: 'Choose file', icon: Icons.folder_open_outlined, onPressed: () => Navigator.pop(context, _Source.file)),
        const SizedBox(height: 8),
        SxButton(label: 'Paste copied data', icon: Icons.content_paste, variant: SxButtonVariant.secondary, height: 48, onPressed: () => Navigator.pop(context, _Source.paste)),
      ]),
    );
  }
}

class _BusyDialog extends StatelessWidget {
  const _BusyDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(SxSpace.lg),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SxSpinner(),
          const SizedBox(width: 16),
          Flexible(child: Text('Adding your workouts…', style: SxText.bodyMd.copyWith(color: c.textHigh))),
        ]),
      ),
    );
  }
}

class _PreviewDialog extends StatefulWidget {
  const _PreviewDialog({required this.plan});
  final GymTrackerImportPlan plan;

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  bool _rotation = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final p = widget.plan;
    final app = context.app;
    final target = p.rotationWorkoutId == null ? null : app.workouts.byId(p.rotationWorkoutId!);
    final canRotate = target != null && app.workouts.currentWorkout?.id != target.id;
    String range() => p.firstDate == null ? '' : '${Fmt.dateMedium(p.firstDate!.toLocal())} – ${Fmt.dateMedium(p.lastDate!.toLocal())}';
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(label, style: SxText.bodyMd.copyWith(color: c.textBody))),
            const SizedBox(width: 12),
            Flexible(child: Text(value, textAlign: TextAlign.end, style: SxText.bodyMd.copyWith(color: c.textHigh, fontWeight: FontWeight.w600))),
          ]),
        );
    final skipped = p.skippedAlreadyImported + p.skippedNotCompleted + p.skippedInvalid;
    return Dialog(
      insetPadding: const EdgeInsets.all(SxSpace.lg),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SxSpace.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('IMPORT ${p.sessions.length} WORKOUT${p.sessions.length == 1 ? '' : 'S'}?', style: SxText.headlineMd.copyWith(color: c.textHigh)),
          const SizedBox(height: 8),
          line('Workouts', '${p.sessions.length}'),
          line('Sets', '${p.sets}'),
          if (p.firstDate != null) line('Dates', range()),
          line('Matched exercises', '${p.matchedExercises}'),
          if (p.newExercises.isNotEmpty) line('New custom exercises', '${p.newExercises.length}'),
          if (skipped > 0) line('Skipped', '$skipped'),
          if (p.newExercises.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(p.newExercises.map((e) => e.name).join(', '), style: SxText.bodySm.copyWith(color: c.textMuted)),
          ],
          if (p.needsReview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Check muscles for: ${_reviewList(p.needsReview)}. You can edit them later.',
              style: SxText.bodySm.copyWith(color: c.textMuted),
            ),
          ],
          const SizedBox(height: SxSpace.sm),
          Text('Workouts keep the date you trained. Personal records and estimated 1RM are recalculated from this history.',
              style: SxText.bodySm.copyWith(color: c.textBody)),
          if (canRotate)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _rotation,
              onChanged: (v) => setState(() => _rotation = v ?? false),
              title: Text('Make "${target.name}" my next workout', style: SxText.bodyMd.copyWith(color: c.textHigh)),
              subtitle: Text('Continue where Gym Tracker left off', style: SxText.bodySm.copyWith(color: c.textBody)),
            ),
          const SizedBox(height: SxSpace.md),
          Row(children: [
            Expanded(child: SxButton(label: 'Cancel', variant: SxButtonVariant.secondary, onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(child: SxButton(label: 'Import', onPressed: () => Navigator.pop(context, _Confirmed(_rotation && canRotate)))),
          ]),
        ]),
      ),
    );
  }
}

String _reviewList(List<String> names) =>
    names.length <= 5 ? names.join(', ') : '${names.take(5).join(', ')} and ${names.length - 5} more';
