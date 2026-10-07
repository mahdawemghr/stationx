import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';
import 'cardio_delete_dialog.dart';
import 'cardio_manage_form.dart';
import 'cardio_manage_helpers.dart';

/// Edit a logged cardio session. Keeps the original `createdAt`; only
/// `updatedAt` moves. Date/time edits change `workoutDate` only.
class EditCardioSessionPage extends StatelessWidget {
  const EditCardioSessionPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final repo = context.app.cardio;
    final s = repo.byId(sessionId);
    if (s == null) {
      return const SxScaffold(
        topBar: SxTopBar(title: 'Edit session'),
        body: Center(child: ErrorState(message: 'This session no longer exists.')),
      );
    }
    return _EditForm(session: s);
  }
}

class _EditForm extends StatefulWidget {
  const _EditForm({required this.session});
  final CardioSession session;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final CardioFormState _form;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _form = CardioFormState(
      kind: widget.session.kind,
      date: widget.session.workoutDate,
      kmUnit: context.app.profile.profile.cardioDistanceUnitKm,
      from: widget.session,
    );
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.validate() || _busy) return;
    setState(() => _busy = true);
    final old = widget.session;
    // Build a fresh object (not copyWith) so cleared optional fields really clear.
    final next = _form.build(id: old.id, meta: old.meta.touched(), customActivityId: old.customActivityId);
    await context.app.cardio.update(next);
    if (!mounted) return;
    showSxSnack(context, 'Session updated');
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (!await confirmDeleteCardio(context, widget.session) || !mounted) return;
    final nav = Navigator.of(context);
    await context.app.cardio.delete(widget.session.id);
    if (!mounted) return;
    showSxSnack(context, 'Session deleted');
    // The details page underneath pops itself when its session disappears.
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    final s = widget.session;
    final n = cardioSessionNumber(context.app.cardio.sessions, s);
    return ListenableBuilder(
      listenable: _form,
      builder: (context, _) => SxScaffold(
        topBar: SxTopBar(
          title: 'Edit session',
          subtitle: 'SESSION #$n',
          actions: [TextButton(onPressed: _save, child: Text('Save', style: SxText.headlineSm.copyWith(color: c.primary)))],
        ),
        bottom: Row(children: [
          Expanded(child: SxButton(label: 'Save changes', icon: Icons.save_outlined, onPressed: _busy ? null : _save)),
          const SizedBox(width: 8),
          SxIconButton(icon: Icons.delete_outline, tooltip: 'Delete cardio session', iconColor: c.danger, size: 52, onPressed: _delete),
        ]),
        children: [
          SxCard(
            color: c.surface2,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.edit_note, color: c.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Changing distance or duration recalculates pace here, and your cardio records and goal progress update from history automatically.',
                  style: SxText.bodySm.copyWith(color: c.textBody),
                ),
              ),
            ]),
          ),
          SxCard(
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(SxRadius.md)),
                child: Icon(cardioKindIcon(s.kind), color: c.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.kind.label, style: SxText.headlineMd.copyWith(color: c.textHigh), overflow: TextOverflow.ellipsis),
                  Text('Logged ${Fmt.dateMedium(s.meta.createdAt)} • activity type fixed',
                      style: SxText.bodySm.copyWith(color: c.textBody), overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
          CardioDateTimeRow(form: _form, dateLabel: 'Date'),
          CardioMetricsSection(form: _form),
          CardioBiometricsSection(form: _form),
          CardioContextSection(form: _form),
        ],
      ),
    );
  }
}
