import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'remote_exception.dart';
import 'remote_gateway.dart';

/// [RemoteGateway] over the Supabase client (PostgREST + RPC). Row Level Security on the server is
/// what keeps users apart; `user_id` is still sent on writes (needed for the composite-key upsert) and
/// the server rejects any value other than the caller's.
class SupabaseRemote implements RemoteGateway {
  SupabaseRemote(
    this._client, {
    this.timeout = const Duration(seconds: 20),
    this.pageSize = 500,
  });

  final SupabaseClient _client;

  /// A request that takes longer is reported as [RemoteFailure.offline] (nothing is assumed saved).
  final Duration timeout;
  final int pageSize;

  @override
  String? get userId => _client.auth.currentUser?.id;

  String get _uid {
    final id = userId;
    if (id == null) {
      throw const RemoteException(
        RemoteFailure.authExpired,
        detail: 'no session',
      );
    }
    return id;
  }

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(timeout);
    } catch (e) {
      throw RemoteException.from(e);
    }
  }

  @override
  Future<Row?> fetchProfile() => _singleton(RemoteTable.profiles);

  @override
  Future<Row?> fetchRotation() => _singleton(RemoteTable.rotations);

  Future<Row?> _singleton(RemoteTable t) async {
    final uid = _uid;
    final r = await _run(
      () => _client.from(t.name).select().eq('user_id', uid).maybeSingle(),
    );
    return r == null ? null : Map<String, dynamic>.from(r);
  }

  @override
  Future<List<Row>> fetchAll(RemoteTable table) async {
    final uid = _uid;
    final out = <Row>[];
    Row? last;
    while (true) {
      var q = _client.from(table.name).select().eq('user_id', uid);
      if (last != null) q = q.or(keysetFilter(table, last));
      final page = await _run(
        () => q
            .order(table.orderColumn, ascending: !table.descending)
            .order('id', ascending: true)
            .limit(pageSize),
      );
      out.addAll([for (final r in page) Map<String, dynamic>.from(r)]);
      if (page.length < pageSize) return out;
      last = out.last;
    }
  }

  /// PostgREST `or` filter for "strictly after [last] in the table's order". Values are double-quoted so
  /// ids containing `,` `(` `)` cannot break out of the expression.
  @visibleForTesting
  static String keysetFilter(RemoteTable t, Row last) {
    String q(Object? v) =>
        '"${'$v'.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
    final op = t.descending ? 'lt' : 'gt';
    final col = t.orderColumn;
    return '$col.$op.${q(last[col])},and($col.eq.${q(last[col])},id.gt.${q(last['id'])})';
  }

  @override
  Future<void> upsert(RemoteTable table, List<Row> rows) async {
    if (rows.isEmpty) return;
    final uid = _uid;
    for (var i = 0; i < rows.length; i += RemoteGateway.maxBatch) {
      final chunk = rows.skip(i).take(RemoteGateway.maxBatch);
      await _run(
        () => _client.from(table.name).upsert([
          for (final r in chunk) {...r, 'user_id': uid},
        ], onConflict: table.conflictTarget),
      );
    }
  }

  @override
  Future<void> delete(RemoteTable table, String id) async {
    final uid = _uid;
    await _run(
      () => _client
          .from(table.name)
          .delete()
          .eq('user_id', uid)
          .eq('id', id)
          .select('id'),
    );
  }

  @override
  Future<Object?> rpc(String function, Map<String, dynamic> params) =>
      _run(() => _client.rpc(function, params: params));
}
