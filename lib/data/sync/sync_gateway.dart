import 'sync_rows.dart';
import 'sync_tables.dart';

/// The cloud session is gone or no longer accepted (expired / revoked token, 401, signed out).
/// Gateways translate their transport's auth failures into this so callers never match on text.
class SyncAuthLostException implements Exception {
  const SyncAuthLostException([this.detail]);
  final String? detail;
  @override
  String toString() => 'SyncAuthLostException(${detail ?? ''})';
}

/// Server side of sync (PostgREST). Rows are plain maps; `user_id` is handled
/// by the implementation. Implementations throw on network/server errors.
abstract class SyncGateway {
  /// Insert-or-update rows (`on conflict (user_id,id)` / `(user_id)`).
  /// The server ignores a row whose `updated_at` is older than the stored one.
  Future<void> upsert(SyncTable table, List<Row> rows);

  /// Mark a row deleted (tombstone) so other devices delete it too.
  Future<void> tombstone(SyncTable table, String id, DateTime at);

  /// Rows changed on the server since [sinceIso] (inclusive), oldest first,
  /// including tombstones. Each row carries `server_updated_at`.
  Future<List<Row>> pull(SyncTable table, {String? sinceIso, int limit = 500});
}
