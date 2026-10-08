import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../domain/domain.dart';
import '../seed/seed_data.dart';
import '../sync/sync_local_store.dart';
import '../sync/sync_rows.dart';
import '../sync/sync_tables.dart';
import 'entities.dart';
import 'isar_store.dart';
import 'mappers.dart';

/// [SyncLocalStore] over the Isar database.
///
/// Rules (see supabase/README.md): last-write-wins on `updated_at`; a locally
/// dirty row is never overwritten by an older/equal cloud row; remote deletions
/// win only over older local versions; seed/default rows carry an epoch
/// `updatedAt` and are "clean" so they always lose to real cloud data.
class IsarSyncLocalStore implements SyncLocalStore {
  IsarSyncLocalStore(this._store);
  final IsarStore _store;
  Isar get _db => _store.db;

  static bool _dirty(SyncMeta m) => m.syncStatus != SyncStatus.synced;
  static SyncMeta _meta(MetaEmb m) => metaFromEmb(m);

  @override
  Future<List<DirtyRow>> dirtyRows(SyncTable table) async {
    switch (table) {
      case SyncTable.profiles:
        final e = await _db.profileEntitys.get(1);
        if (e == null || e.syncStatus == SyncStatus.synced) return [];
        return [
          DirtyRow(
            table.singletonId,
            e.updatedAt,
            profileToRow(profileFromEntity(e), updatedAt: e.updatedAt),
          ),
        ];
      case SyncTable.rotations:
        final e = await _db.rotationEntitys.get(1);
        if (e == null || e.syncStatus == SyncStatus.synced) return [];
        return [
          DirtyRow(
            table.singletonId,
            e.updatedAt,
            rotationToRow(
              rotationFromEntity(e),
              createdAt: e.updatedAt,
              updatedAt: e.updatedAt,
            ),
          ),
        ];
      case SyncTable.exercises:
        return [
          for (final e in await _db.exerciseEntitys.where().findAll())
            if (e.isCustom && _dirty(_meta(e.meta)))
              DirtyRow(
                e.uid,
                e.meta.updatedAt,
                exerciseToRow(exerciseFromEntity(e)),
              ),
        ];
      case SyncTable.workouts:
        return [
          for (final e in await _db.workoutEntitys.where().findAll())
            if (_dirty(_meta(e.meta)))
              DirtyRow(
                e.uid,
                e.meta.updatedAt,
                workoutToRow(workoutFromEntity(e), e.position),
              ),
        ];
      case SyncTable.workoutSessions:
        return [
          for (final e in await _db.sessionEntitys.where().findAll())
            if (_dirty(_meta(e.meta)))
              DirtyRow(
                e.uid,
                e.meta.updatedAt,
                sessionToRow(sessionFromEntity(e)),
              ),
        ];
      case SyncTable.cardioSessions:
        return [
          for (final e in await _db.cardioSessionEntitys.where().findAll())
            if (_dirty(_meta(e.data.meta)))
              DirtyRow(
                e.uid,
                e.data.meta.updatedAt,
                cardioToRow(cardioFromEntity(e)),
              ),
        ];
      case SyncTable.cardioGoals:
        return [
          for (final e in await _db.cardioGoalEntitys.where().findAll())
            if (_dirty(_meta(e.meta)))
              DirtyRow(e.uid, e.meta.updatedAt, goalToRow(goalFromEntity(e))),
        ];
      case SyncTable.customCardioActivities:
        return [
          for (final e in await _db.customActivityEntitys.where().findAll())
            if (_dirty(_meta(e.meta)))
              DirtyRow(
                e.uid,
                e.meta.updatedAt,
                customActivityToRow(customActivityFromEntity(e)),
              ),
        ];
    }
  }

  @override
  Future<List<SyncDeletion>> pendingDeletions() async => [
    for (final d in await _db.syncDeletionEntitys.where().findAll())
      if (SyncTable.byName(d.table) != null)
        SyncDeletion(SyncTable.byName(d.table)!, d.rowId, d.deletedAt),
  ];

  @override
  Future<void> clearDeletions(List<SyncDeletion> done) =>
      _db.writeTxn(() async {
        for (final d in done) {
          await _db.syncDeletionEntitys.deleteByTableRowId(d.table.name, d.id);
        }
      });

  @override
  Future<void> markPushed(SyncTable table, List<DirtyRow> pushed) =>
      _db.writeTxn(() async {
        for (final p in pushed) {
          switch (table) {
            case SyncTable.profiles:
              final e = await _db.profileEntitys.get(1);
              if (e != null && e.updatedAt.isAtSameMomentAs(p.updatedAt)) {
                e.syncStatus = SyncStatus.synced;
                await _db.profileEntitys.put(e);
              }
            case SyncTable.rotations:
              final e = await _db.rotationEntitys.get(1);
              if (e != null && e.updatedAt.isAtSameMomentAs(p.updatedAt)) {
                e.syncStatus = SyncStatus.synced;
                await _db.rotationEntitys.put(e);
              }
            case SyncTable.exercises:
              final e = await _db.exerciseEntitys.getByUid(p.id);
              if (e != null && e.meta.updatedAt.isAtSameMomentAs(p.updatedAt)) {
                e.meta.syncStatus = SyncStatus.synced;
                await _db.exerciseEntitys.putByUid(e);
              }
            case SyncTable.workouts:
              final e = await _db.workoutEntitys.getByUid(p.id);
              if (e != null && e.meta.updatedAt.isAtSameMomentAs(p.updatedAt)) {
                e.meta.syncStatus = SyncStatus.synced;
                await _db.workoutEntitys.putByUid(e);
              }
            case SyncTable.workoutSessions:
              final e = await _db.sessionEntitys.getByUid(p.id);
              if (e != null && e.meta.updatedAt.isAtSameMomentAs(p.updatedAt)) {
                e.meta.syncStatus = SyncStatus.synced;
                await _db.sessionEntitys.putByUid(e);
              }
            case SyncTable.cardioSessions:
              final e = await _db.cardioSessionEntitys.getByUid(p.id);
              if (e != null &&
                  e.data.meta.updatedAt.isAtSameMomentAs(p.updatedAt)) {
                e.data.meta.syncStatus = SyncStatus.synced;
                await _db.cardioSessionEntitys.putByUid(e);
              }
            case SyncTable.cardioGoals:
              final e = await _db.cardioGoalEntitys.getByUid(p.id);
              if (e != null && e.meta.updatedAt.isAtSameMomentAs(p.updatedAt)) {
                e.meta.syncStatus = SyncStatus.synced;
                await _db.cardioGoalEntitys.putByUid(e);
              }
            case SyncTable.customCardioActivities:
              final e = await _db.customActivityEntitys.getByUid(p.id);
              if (e != null && e.meta.updatedAt.isAtSameMomentAs(p.updatedAt)) {
                e.meta.syncStatus = SyncStatus.synced;
                await _db.customActivityEntitys.putByUid(e);
              }
          }
        }
      });

  @override
  Future<int> pendingCount() async {
    var n = (await _db.syncDeletionEntitys.count());
    for (final t in SyncTable.values) {
      n += (await dirtyRows(t)).length;
    }
    return n;
  }

  // ───────────────────────── applying cloud rows ─────────────────────────

  @override
  Future<int> applyRemote(SyncTable table, List<Row> rows) async {
    var changed = 0;
    await _db.writeTxn(() async {
      for (final r in rows) {
        if (await _applyOne(table, r)) changed++;
      }
    });
    return changed;
  }

  Future<bool> _applyOne(SyncTable table, Row r) async {
    final remoteUpdated = DateTime.parse(r['updated_at'] as String);
    final deleted = r['deleted_at'] != null;
    switch (table) {
      case SyncTable.profiles:
        if (deleted) {
          return false; // a profile is never deleted remotely except with the account
        }
        final local = await _db.profileEntitys.get(1) ?? ProfileEntity();
        final localDirty = local.syncStatus != SyncStatus.synced;
        if (localDirty && !remoteUpdated.isAfter(local.updatedAt)) {
          return false; // local edit wins; it will be pushed
        }
        if (!localDirty && local.updatedAt.isAtSameMomentAs(remoteUpdated)) {
          return false; // `==` would also compare the UTC flag // already applied
        }
        await _db.profileEntitys.put(
          profileToEntity(profileFromRow(r, profileFromEntity(local)))
            ..updatedAt = remoteUpdated
            ..syncStatus = SyncStatus.synced,
        );
        return true;
      case SyncTable.rotations:
        if (deleted) return false;
        final local = await _db.rotationEntitys.get(1) ?? RotationEntity();
        final localDirty = local.syncStatus != SyncStatus.synced;
        if (localDirty && !remoteUpdated.isAfter(local.updatedAt)) return false;
        if (!localDirty && local.updatedAt.isAtSameMomentAs(remoteUpdated)) {
          return false; // `==` would also compare the UTC flag
        }
        await _db.rotationEntitys.put(
          rotationToEntity(rotationFromRow(r))
            ..updatedAt = remoteUpdated
            ..syncStatus = SyncStatus.synced,
        );
        return true;
      case SyncTable.exercises:
        return _collection<ExerciseEntity>(
          r,
          remoteUpdated,
          deleted,
          get: _db.exerciseEntitys.getByUid,
          localUpdated: (e) => e.meta.updatedAt,
          delete: _db.exerciseEntitys.deleteByUid,
          put: () => _db.exerciseEntitys.putByUid(
            exerciseToEntity(exerciseFromRow(r)),
          ),
        );
      case SyncTable.workouts:
        return _collection<WorkoutEntity>(
          r,
          remoteUpdated,
          deleted,
          get: _db.workoutEntitys.getByUid,
          localUpdated: (e) => e.meta.updatedAt,
          delete: _db.workoutEntitys.deleteByUid,
          put: () {
            final (w, pos) = workoutFromRow(r);
            return _db.workoutEntitys.putByUid(workoutToEntity(w, pos));
          },
        );
      case SyncTable.workoutSessions:
        return _collection<SessionEntity>(
          r,
          remoteUpdated,
          deleted,
          get: _db.sessionEntitys.getByUid,
          localUpdated: (e) => e.meta.updatedAt,
          delete: _db.sessionEntitys.deleteByUid,
          put: () =>
              _db.sessionEntitys.putByUid(sessionToEntity(sessionFromRow(r))),
        );
      case SyncTable.cardioSessions:
        return _collection<CardioSessionEntity>(
          r,
          remoteUpdated,
          deleted,
          get: _db.cardioSessionEntitys.getByUid,
          localUpdated: (e) => e.data.meta.updatedAt,
          delete: _db.cardioSessionEntitys.deleteByUid,
          put: () => _db.cardioSessionEntitys.putByUid(
            cardioToEntity(cardioFromRow(r)),
          ),
        );
      case SyncTable.cardioGoals:
        return _collection<CardioGoalEntity>(
          r,
          remoteUpdated,
          deleted,
          get: _db.cardioGoalEntitys.getByUid,
          localUpdated: (e) => e.meta.updatedAt,
          delete: _db.cardioGoalEntitys.deleteByUid,
          put: () =>
              _db.cardioGoalEntitys.putByUid(goalToEntity(goalFromRow(r))),
        );
      case SyncTable.customCardioActivities:
        return _collection<CustomActivityEntity>(
          r,
          remoteUpdated,
          deleted,
          get: _db.customActivityEntitys.getByUid,
          localUpdated: (e) => e.meta.updatedAt,
          delete: _db.customActivityEntitys.deleteByUid,
          put: () => _db.customActivityEntitys.putByUid(
            customActivityToEntity(customActivityFromRow(r)),
          ),
        );
    }
  }

  /// Last-write-wins for one collection row.
  Future<bool> _collection<E>(
    Row r,
    DateTime remoteUpdated,
    bool deleted, {
    required Future<E?> Function(String uid) get,
    required DateTime Function(E e) localUpdated,
    required Future<bool> Function(String uid) delete,
    required Future<Object?> Function() put,
  }) async {
    final id = r['id'] as String;
    final local = await get(id);
    if (deleted) {
      // A cloud deletion removes the local row unless the user edited it afterwards.
      if (local != null && !remoteUpdated.isBefore(localUpdated(local))) {
        return delete(id);
      }
      return false;
    }
    if (local != null && !remoteUpdated.isAfter(localUpdated(local))) {
      return false; // local is newer/equal
    }
    await put();
    return true;
  }

  // ───────────────────────── state & account handling ─────────────────────────

  @override
  Future<SyncState> loadState() async {
    final e = await _db.syncStateEntitys.get(1);
    if (e == null) return const SyncState();
    final map = (jsonDecode(e.cursorsJson) as Map).cast<String, String>();
    return SyncState(userId: e.userId, cursors: map, lastSyncAt: e.lastSyncAt);
  }

  @override
  Future<void> saveState(SyncState s) => _db.writeTxn(
    () => _db.syncStateEntitys.put(
      SyncStateEntity()
        ..userId = s.userId
        ..cursorsJson = jsonEncode(s.cursors)
        ..lastSyncAt = s.lastSyncAt,
    ),
  );

  @override
  Future<void> reloadCaches() => _store.reloadCaches();

  @override
  Future<void> bumpDirtySingletons() => _db.writeTxn(() async {
    final now = DateTime.now();
    final p = await _db.profileEntitys.get(1);
    if (p != null && p.syncStatus != SyncStatus.synced) {
      await _db.profileEntitys.put(p..updatedAt = now);
    }
    final r = await _db.rotationEntitys.get(1);
    if (r != null && r.syncStatus != SyncStatus.synced) {
      await _db.rotationEntitys.put(r..updatedAt = now);
    }
  });

  @override
  Future<void> markSingletonsClean() => _db.writeTxn(() async {
    final p = await _db.profileEntitys.get(1);
    if (p != null) {
      p
        ..updatedAt = DateTime.fromMillisecondsSinceEpoch(0)
        ..syncStatus = SyncStatus.synced;
      await _db.profileEntitys.put(p);
    }
    final r = await _db.rotationEntitys.get(1);
    if (r != null) {
      r
        ..updatedAt = DateTime.fromMillisecondsSinceEpoch(0)
        ..syncStatus = SyncStatus.synced;
      await _db.rotationEntitys.put(r);
    }
  });

  @override
  Future<void> markAllUserDataDirty() => _db.writeTxn(() async {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    bool real(DateTime updatedAt) => updatedAt.isAfter(
      epoch,
    ); // built-in defaults/demo rows keep an epoch stamp
    for (final e in await _db.exerciseEntitys.where().findAll()) {
      if (e.isCustom && real(e.meta.updatedAt)) {
        await _db.exerciseEntitys.putByUid(
          e..meta.syncStatus = SyncStatus.pending,
        );
      }
    }
    for (final e in await _db.workoutEntitys.where().findAll()) {
      if (real(e.meta.updatedAt)) {
        await _db.workoutEntitys.putByUid(
          e..meta.syncStatus = SyncStatus.pending,
        );
      }
    }
    for (final e in await _db.sessionEntitys.where().findAll()) {
      if (real(e.meta.updatedAt)) {
        await _db.sessionEntitys.putByUid(
          e..meta.syncStatus = SyncStatus.pending,
        );
      }
    }
    for (final e in await _db.cardioSessionEntitys.where().findAll()) {
      if (real(e.data.meta.updatedAt)) {
        await _db.cardioSessionEntitys.putByUid(
          e..data.meta.syncStatus = SyncStatus.pending,
        );
      }
    }
    for (final e in await _db.cardioGoalEntitys.where().findAll()) {
      if (real(e.meta.updatedAt)) {
        await _db.cardioGoalEntitys.putByUid(
          e..meta.syncStatus = SyncStatus.pending,
        );
      }
    }
    for (final e in await _db.customActivityEntitys.where().findAll()) {
      if (real(e.meta.updatedAt)) {
        await _db.customActivityEntitys.putByUid(
          e..meta.syncStatus = SyncStatus.pending,
        );
      }
    }
    // The profile belongs to the PREVIOUS account (name, email, measurements): it is never uploaded
    // to the new one. Reset to a blank, clean profile so the new account's own profile wins.
    await _db.profileEntitys.put(
      profileToEntity(const UserProfile())
        ..updatedAt = epoch
        ..syncStatus = SyncStatus.synced,
    );
    final r = await _db.rotationEntitys.get(1);
    if (r != null && real(r.updatedAt)) {
      await _db.rotationEntitys.put(r..syncStatus = SyncStatus.pending);
    }
  }).then((_) => _store.profile.reset(const UserProfile()));

  @override
  Future<bool> hasUserData() async {
    // Demo rows (`seed_*`) are not the user's data: they must not trigger the account-switch prompt.
    if (await _db.sessionEntitys.filter().not().uidStartsWith(kDemoIdPrefix).count() > 0) return true;
    if (await _db.cardioSessionEntitys.filter().not().uidStartsWith(kDemoIdPrefix).count() > 0) return true;
    for (final g in await _db.cardioGoalEntitys.where().findAll()) {
      if (!SeedData.demoGoalIds.contains(g.uid)) return true;
    }
    if (await _db.customActivityEntitys.count() > 0) return true;
    for (final e in await _db.exerciseEntitys.where().findAll()) {
      if (e.isCustom) return true;
    }
    return (await pendingCount()) > 0;
  }

  @override
  Future<void> resetForAccountSwitch() async {
    // The previous account's profile (name/email/measurements) must not follow the data into the
    // new account: start blank; the new account's profile/rotation come from the cloud.
    await _store.replaceAll(SeedData.fresh(), const UserProfile());
    await markSingletonsClean();
    await saveState(const SyncState());
  }
}
