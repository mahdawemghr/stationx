import 'sync_rows.dart';
import 'sync_tables.dart';

/// A local row that has to be pushed.
class DirtyRow {
  const DirtyRow(this.id, this.updatedAt, this.row);
  final String id;

  /// Version of the local row when it was read — used to avoid marking a row
  /// "synced" if the user edited it again while the push was in flight.
  final DateTime updatedAt;
  final Row row;
}

/// A local deletion still to be sent (tombstone).
class SyncDeletion {
  const SyncDeletion(this.table, this.id, this.at);
  final SyncTable table;
  final String id;
  final DateTime at;
}

/// Persisted sync bookkeeping (no credentials, ever).
class SyncState {
  const SyncState({this.userId, this.cursors = const {}, this.lastSyncAt});

  /// Cloud account this device's data is linked to.
  final String? userId;

  /// Per table: last `server_updated_at` pulled (ISO-8601).
  final Map<String, String> cursors;
  final DateTime? lastSyncAt;

  SyncState copyWith({String? userId, Map<String, String>? cursors, DateTime? lastSyncAt, bool clearUser = false}) => SyncState(
        userId: clearUser ? null : (userId ?? this.userId),
        cursors: cursors ?? this.cursors,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      );
}

/// The device side of sync. The engine only talks to this and to a gateway,
/// so the engine is testable without Isar or a network.
abstract class SyncLocalStore {
  Future<List<DirtyRow>> dirtyRows(SyncTable table);
  Future<List<SyncDeletion>> pendingDeletions();

  /// Marks pushed rows as synced — only those whose local version is unchanged.
  Future<void> markPushed(SyncTable table, List<DirtyRow> pushed);
  Future<void> clearDeletions(List<SyncDeletion> done);

  /// Rows + deletions waiting to be pushed.
  Future<int> pendingCount();

  /// Applies cloud rows with last-write-wins; returns how many local rows changed.
  Future<int> applyRemote(SyncTable table, List<Row> rows);

  Future<SyncState> loadState();
  Future<void> saveState(SyncState state);

  /// Refresh in-memory repositories after rows changed behind their backs.
  Future<void> reloadCaches();

  /// First link to an account: locally edited profile/rotation must win over the
  /// cloud's defaults, so stamp them "now".
  Future<void> bumpDirtySingletons();

  /// Local profile/rotation were only defaults (e.g. a guest): let the cloud copy win.
  Future<void> markSingletonsClean();

  /// Merging this device's data into a *different* account: everything the user created
  /// (not built-in defaults) must be uploaded again, even if it was synced to the old account.
  Future<void> markAllUserDataDirty();

  /// True when there is user-generated data on the device.
  Future<bool> hasUserData();

  /// Wipe user data (keeping the catalogue + defaults) and forget sync state.
  Future<void> resetForAccountSwitch();
}
