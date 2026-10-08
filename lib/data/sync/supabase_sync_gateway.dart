import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_gateway.dart';
import 'sync_rows.dart';
import 'sync_tables.dart';

/// [SyncGateway] over the Supabase client (PostgREST). Row Level Security on the
/// server guarantees a user can only touch their own rows; `user_id` is sent
/// explicitly for clarity and must equal the signed-in user (or the write is rejected).
class SupabaseSyncGateway implements SyncGateway {
  SupabaseSyncGateway(this._client);
  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('not signed in');
    return id;
  }

  @override
  Future<void> upsert(SyncTable table, List<Row> rows) async {
    if (rows.isEmpty) return;
    final uid = _uid;
    await _client.from(table.name).upsert(
      [for (final r in rows) {...r, 'user_id': uid}],
      onConflict: table.conflictTarget,
    );
  }

  @override
  Future<void> tombstone(SyncTable table, String id, DateTime at) async {
    final iso = at.toUtc().toIso8601String();
    await _client.from(table.name).update({'deleted_at': iso, 'updated_at': iso}).eq('id', id);
  }

  @override
  Future<List<Row>> pull(SyncTable table, {String? sinceIso, int limit = 500}) async {
    var q = _client.from(table.name).select();
    if (sinceIso != null) q = q.gte('server_updated_at', sinceIso);
    final res = await q.order('server_updated_at', ascending: true).limit(limit);
    return [for (final r in res) Map<String, dynamic>.from(r)];
  }
}
