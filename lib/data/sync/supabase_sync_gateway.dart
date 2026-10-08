import 'package:flutter/foundation.dart';
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
    if (id == null) throw const SyncAuthLostException('no session');
    return id;
  }

  /// Runs [call], turning auth failures (HTTP 401, PostgREST JWT errors PGRST30x, GoTrue
  /// [AuthException]s other than retryable network ones) into [SyncAuthLostException].
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      if (isAuthFailure(e)) throw SyncAuthLostException(e.code);
      rethrow;
    } on AuthRetryableFetchException {
      rethrow; // transient network problem, not a lost session
    } on AuthException catch (e) {
      throw SyncAuthLostException(e.code ?? e.statusCode);
    }
  }

  /// True for PostgREST errors that mean "your token is not valid" (not "your data is bad").
  @visibleForTesting
  static bool isAuthFailure(PostgrestException e) =>
      e.code == '401' || (e.code?.startsWith('PGRST30') ?? false);

  @override
  Future<void> upsert(SyncTable table, List<Row> rows) async {
    if (rows.isEmpty) return;
    final uid = _uid;
    await _guard(
      () => _client.from(table.name).upsert([
        for (final r in rows) {...r, 'user_id': uid},
      ], onConflict: table.conflictTarget),
    );
  }

  @override
  Future<void> tombstone(SyncTable table, String id, DateTime at) async {
    final iso = at.toUtc().toIso8601String();
    await _guard(
      () => _client
          .from(table.name)
          .update({'deleted_at': iso, 'updated_at': iso})
          .eq('id', id),
    );
  }

  @override
  Future<List<Row>> pull(
    SyncTable table, {
    String? sinceIso,
    int limit = 500,
  }) async {
    var q = _client.from(table.name).select();
    if (sinceIso != null) q = q.gte('server_updated_at', sinceIso);
    final res = await _guard(
      () => q.order('server_updated_at', ascending: true).limit(limit),
    );
    return [for (final r in res) Map<String, dynamic>.from(r)];
  }
}
