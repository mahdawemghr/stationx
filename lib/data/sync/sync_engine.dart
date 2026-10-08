import 'package:flutter/foundation.dart';

import 'sync_gateway.dart';
import 'sync_local_store.dart';
import 'sync_tables.dart';

/// What to do when a *different* cloud account signs in on a device that already
/// holds another account's (or guest) data.
enum AccountSwitch {
  /// Not decided yet — the engine stops and asks.
  undecided,

  /// Keep this device's data and upload it to the new account (union).
  merge,

  /// Discard this device's data and load the new account's cloud data.
  replaceWithCloud,
}

class SyncResult {
  const SyncResult({this.pushed = 0, this.deleted = 0, this.pulled = 0, this.needsAccountDecision = false, this.error});
  final int pushed;
  final int deleted;
  final int pulled;

  /// A different account signed in on a device with data; the caller must pick an [AccountSwitch].
  final bool needsAccountDecision;
  final Object? error;
  bool get ok => error == null && !needsAccountDecision;
  int get changes => pushed + deleted + pulled;
}

/// Two-phase sync: PUSH local changes, then PULL what changed in the cloud.
/// Conflicts are resolved last-write-wins on `updated_at` (server and store both
/// apply that rule), so running it twice, or from two devices, always converges.
/// Never throws: failures are returned in [SyncResult.error]; progress made so far is kept.
class SyncEngine {
  SyncEngine(this.local, this.gateway, {this.pushBatch = 100, this.pullPage = 500, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final SyncLocalStore local;
  final SyncGateway gateway;
  final int pushBatch;
  final int pullPage;
  final DateTime Function() _clock;

  Future<SyncResult> run({
    required String userId,
    AccountSwitch decision = AccountSwitch.undecided,
    bool preferCloudSingletons = false,
  }) async {
    var pushed = 0, deleted = 0, pulled = 0;
    try {
      var state = await local.loadState();

      // ── account linking ──
      final switching = state.userId != null && state.userId != userId;
      if (switching) {
        if (await local.hasUserData() && decision == AccountSwitch.undecided) {
          return const SyncResult(needsAccountDecision: true);
        }
        if (decision == AccountSwitch.replaceWithCloud) {
          await local.resetForAccountSwitch();
        } else {
          await local.markAllUserDataDirty(); // merge: re-upload everything to the new account
        }
        state = const SyncState(); // cursors belong to the previous account
      }
      if (state.userId != userId) {
        // First time this device talks to this account.
        if (preferCloudSingletons) {
          await local.markSingletonsClean();
        } else {
          await local.bumpDirtySingletons();
        }
        state = state.copyWith(userId: userId, cursors: const {});
        await local.saveState(state);
      }

      // ── PUSH ──
      for (final table in SyncTable.values) {
        final dirty = await local.dirtyRows(table);
        for (var i = 0; i < dirty.length; i += pushBatch) {
          final batch = dirty.sublist(i, i + pushBatch > dirty.length ? dirty.length : i + pushBatch);
          await gateway.upsert(table, [for (final d in batch) d.row]);
          await local.markPushed(table, batch);
          pushed += batch.length;
        }
      }
      final deletions = await local.pendingDeletions();
      final done = <SyncDeletion>[];
      try {
        for (final d in deletions) {
          if (d.table.singleton) {
            done.add(d);
            continue;
          }
          await gateway.tombstone(d.table, d.id, d.at);
          done.add(d);
          deleted++;
        }
      } finally {
        if (done.isNotEmpty) await local.clearDeletions(done);
      }

      // ── PULL ──
      final cursors = Map<String, String>.of(state.cursors);
      for (final table in SyncTable.values) {
        while (true) {
          final rows = await gateway.pull(table, sinceIso: cursors[table.name], limit: pullPage);
          if (rows.isEmpty) break;
          pulled += await local.applyRemote(table, rows);
          final last = rows.last['server_updated_at'] as String;
          final advanced = last != cursors[table.name];
          cursors[table.name] = last;
          await local.saveState(state.copyWith(cursors: Map.of(cursors)));
          if (rows.length < pullPage || !advanced) break;
        }
      }

      await local.saveState(state.copyWith(cursors: cursors, lastSyncAt: _clock()));
      if (pushed + deleted + pulled > 0) await local.reloadCaches();
      return SyncResult(pushed: pushed, deleted: deleted, pulled: pulled);
    } catch (e) {
      debugPrint('Sync failed: ${e.runtimeType}'); // type only — never data
      try {
        if (pushed + deleted + pulled > 0) await local.reloadCaches();
      } catch (_) {}
      return SyncResult(pushed: pushed, deleted: deleted, pulled: pulled, error: e);
    }
  }
}
