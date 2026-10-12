import 'dart:convert';
import 'dart:io';

import 'package:isar_community/isar.dart';

import '../../domain/domain.dart';
import '../data_store.dart';
import '../health/health_consent_store.dart';
import '../memory/memory_repositories.dart';
import 'entities.dart';

/// Persistent [DeviceStore] backed by Isar: ONLY device-local state (see `entities.dart`). It holds no
/// user data and is never the source of truth for any record that exists on the server.
class IsarDeviceStore implements DeviceStore {
  IsarDeviceStore._(this._db, AppMetaEntity meta)
    : _owner = meta.ownerUserId,
      healthConsent = _IsarHealthConsent(_db, meta.healthConnected),
      workoutDraft = IsarWorkoutDraftStore(_db, meta.workoutDraftJson);

  static const schemas = [AppMetaEntitySchema];

  /// Opens (creating if needed) the database in [directory]. Pass [name] to isolate databases (tests).
  static Future<IsarDeviceStore> open({
    required String directory,
    String name = 'stationx',
  }) async {
    final db = await Isar.open(schemas, directory: directory, name: name);
    var meta = await db.appMetaEntitys.get(1);
    if (meta == null) {
      meta = AppMetaEntity();
      await db.writeTxn(() => db.appMetaEntitys.put(meta!));
    }
    return IsarDeviceStore._(db, meta);
  }

  final Isar _db;

  @override
  final HealthConsentStore healthConsent;
  @override
  final IsarWorkoutDraftStore workoutDraft;

  String? _owner;

  Future<void> _update(void Function(AppMetaEntity m) change) =>
      _db.writeTxn(() async {
        final m = (await _db.appMetaEntitys.get(1)) ?? AppMetaEntity();
        change(m);
        await _db.appMetaEntitys.put(m);
      });

  @override
  String? get ownerUserId => _owner;
  @override
  Future<void> setOwnerUserId(String? id) async {
    if (id == _owner) return;
    await _update((m) => m.ownerUserId = id);
    _owner = id;
  }

  @override
  Future<void> clearUserScopedState() async {
    await _update((m) {
      m.workoutDraftJson = null;
      m.ownerUserId = null;
    });
    _owner = null;
    workoutDraft.resetCache();
  }

  @override
  Future<void> close() => _db.close();
}

/// Deletes the Isar database files for [dbName] in [directory]. Destructive — only called after an
/// explicit user confirmation. Safe: it holds device state only, never the user's data.
Future<void> resetDatabaseFiles(
  String directory, {
  String dbName = 'stationx',
}) async {
  for (final suffix in ['.isar', '.isar-lck']) {
    final f = File('$directory/$dbName$suffix');
    if (await f.exists()) await f.delete();
  }
}

class _IsarHealthConsent implements HealthConsentStore {
  _IsarHealthConsent(this._db, this._connected);
  final Isar _db;
  bool _connected;

  @override
  bool get connected => _connected;

  @override
  Future<void> setConnected(bool value) async {
    await _db.writeTxn(() async {
      final m = (await _db.appMetaEntitys.get(1)) ?? AppMetaEntity();
      m.healthConnected = value;
      await _db.appMetaEntitys.put(m);
    });
    _connected = value;
  }
}

/// Draft persisted as one JSON string on the AppMeta singleton. Write-through: the cache updates
/// after the disk write.
class IsarWorkoutDraftStore extends MemoryWorkoutDraftStore {
  IsarWorkoutDraftStore(this._db, String? initial) : super(initial);
  final Isar _db;

  Future<void> _persist(String? json) => _db.writeTxn(() async {
    final m = (await _db.appMetaEntitys.get(1)) ?? AppMetaEntity();
    m.workoutDraftJson = json;
    await _db.appMetaEntitys.put(m);
  });

  @override
  Future<void> save(WorkoutDraft draft) async {
    await _persist(jsonEncode(draft.toJson()));
    await super.save(draft);
  }

  @override
  Future<void> clear() async {
    if (rawJson == null) return;
    await _persist(null);
    await super.clear();
  }

  /// Called after the column was nulled by [IsarDeviceStore.clearUserScopedState].
  void resetCache() => super.clear();
}
