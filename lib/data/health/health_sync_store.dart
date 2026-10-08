import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';

/// A queued health-store operation (local-first: saving a session never waits for these).
class PendingHealthOp {
  PendingHealthOp.upsert(HealthWriteRequest this.request) : isDelete = false;
  PendingHealthOp.delete() : isDelete = true, request = null;
  PendingHealthOp._(this.isDelete, this.request, this.attempts);

  final bool isDelete;
  final HealthWriteRequest? request;
  int attempts = 0;

  Map<String, Object?> toJson() => {
    'delete': isDelete,
    'request': request?.toJson(),
    'attempts': attempts,
  };

  static PendingHealthOp? tryParse(Object? raw) {
    try {
      final m = (raw as Map).cast<String, Object?>();
      if (m['delete'] == true) {
        return PendingHealthOp._(true, null, (m['attempts'] as int?) ?? 0);
      }
      final r = HealthWriteRequest.tryParse(m['request']);
      return r == null ? null : PendingHealthOp._(false, r, (m['attempts'] as int?) ?? 0);
    } catch (_) {
      return null;
    }
  }
}

/// Everything the health integration remembers on THIS device. Local-only, never synced.
class HealthSyncState {
  /// Opt-ins; a feature absent from the set is OFF (the default).
  final Set<HealthFeature> enabled = {};

  /// StationX key (`c:<id>` / `s:<id>`) -> what StationX wrote for it.
  final Map<String, HealthWriteReceipt> receipts = {};

  /// Operations still to be sent to the health store, by key.
  final Map<String, PendingHealthOp> pending = {};

  /// External record ids already imported (kept even if the imported session is deleted).
  final Set<String> importedIds = {};

  String toJsonString() => jsonEncode({
    'v': 1,
    'enabled': [for (final f in enabled) f.name],
    'receipts': {for (final e in receipts.entries) e.key: e.value.toJson()},
    'pending': {for (final e in pending.entries) e.key: e.value.toJson()},
    'imported': importedIds.toList(),
  });

  static HealthSyncState parse(String? text) {
    final s = HealthSyncState();
    if (text == null || text.isEmpty) return s;
    try {
      final m = (jsonDecode(text) as Map).cast<String, Object?>();
      for (final n in (m['enabled'] as List? ?? const [])) {
        for (final f in HealthFeature.values) {
          if (f.name == n) s.enabled.add(f);
        }
      }
      (m['receipts'] as Map? ?? const {}).forEach((k, v) {
        final r = HealthWriteReceipt.tryParse(v);
        if (k is String && r != null) s.receipts[k] = r;
      });
      (m['pending'] as Map? ?? const {}).forEach((k, v) {
        final o = PendingHealthOp.tryParse(v);
        if (k is String && o != null) s.pending[k] = o;
      });
      for (final i in (m['imported'] as List? ?? const [])) {
        if (i is String) s.importedIds.add(i);
      }
    } catch (_) {
      return HealthSyncState(); // corrupt file reads as "everything off"
    }
    return s;
  }
}

/// Persistence for [HealthSyncState]. [load] is synchronous (cached at startup).
abstract class HealthSyncStore {
  HealthSyncState load();
  Future<void> save(HealthSyncState state);
}

class MemoryHealthSyncStore implements HealthSyncStore {
  MemoryHealthSyncStore([HealthSyncState? initial]) : _state = initial ?? HealthSyncState();
  HealthSyncState _state;
  @override
  HealthSyncState load() => _state;
  @override
  Future<void> save(HealthSyncState state) async => _state = state;
}

/// JSON file next to the database (`health_sync.json`). Written atomically (temp + rename).
class FileHealthSyncStore implements HealthSyncStore {
  FileHealthSyncStore._(this._file, this._state);
  final File _file;
  HealthSyncState _state;

  static Future<FileHealthSyncStore> open(String directory) async {
    final f = File('$directory/health_sync.json');
    String? text;
    try {
      if (await f.exists()) text = await f.readAsString();
    } catch (_) {}
    return FileHealthSyncStore._(f, HealthSyncState.parse(text));
  }

  @override
  HealthSyncState load() => _state;

  @override
  Future<void> save(HealthSyncState state) async {
    _state = state;
    try {
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsString(state.toJsonString(), flush: true);
      await tmp.rename(_file.path);
    } catch (e) {
      debugPrint('Health sync state save failed: ${e.runtimeType}');
    }
  }

  /// Forget everything (used by "delete all local data").
  Future<void> wipe() async {
    _state = HealthSyncState();
    try {
      if (await _file.exists()) await _file.delete();
    } catch (_) {}
  }
}
