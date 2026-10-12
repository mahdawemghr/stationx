import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Why a server operation did not complete.
enum RemoteFailure {
  /// No connection / timeout / DNS. Nothing was saved; retrying later is safe.
  offline,

  /// The session is gone, expired or revoked. The user must sign in again; retrying is pointless.
  authExpired,

  /// The server refused the data (constraint / policy / validation). Retrying the same input will fail again.
  rejected,

  /// The server had a problem (5xx). Retrying later may work.
  server,

  unknown,
}

/// Every failed Supabase call surfaces as this type, so UI and controllers never match on SDK
/// exceptions or raw text. [detail] is for logs only (never contains credentials or user content).
class RemoteException implements Exception {
  const RemoteException(this.kind, {this.code, this.detail});

  final RemoteFailure kind;
  final String? code;
  final String? detail;

  bool get isRetryable =>
      kind == RemoteFailure.offline ||
      kind == RemoteFailure.server ||
      kind == RemoteFailure.unknown;

  /// Ready-to-show wording; says plainly that nothing was saved.
  String get userMessage => switch (kind) {
    RemoteFailure.offline =>
      "Can't reach the server. Check your connection and try again.",
    RemoteFailure.authExpired => 'Your session expired. Please sign in again.',
    RemoteFailure.rejected =>
      'The server rejected this change. Check the values and try again.',
    RemoteFailure.server =>
      'The server had a problem. Please try again in a moment.',
    RemoteFailure.unknown => 'Something went wrong. Please try again.',
  };

  /// Maps any thrown object (SDK, socket, timeout…) to a [RemoteException]. Idempotent.
  static RemoteException from(Object e) {
    if (e is RemoteException) return e;
    if (e is PostgrestException) return _fromPostgrest(e);
    if (e is AuthRetryableFetchException) {
      return const RemoteException(RemoteFailure.offline, detail: 'auth fetch');
    }
    if (e is AuthException) return _fromAuth(e);
    if (e is TimeoutException ||
        e is SocketException ||
        e is HttpException ||
        e is IOException) {
      return RemoteException(
        RemoteFailure.offline,
        detail: e.runtimeType.toString(),
      );
    }
    // package:http's ClientException (and web XHR failures) are not exported by the SDK.
    final t = e.runtimeType.toString();
    if (t.contains('ClientException') || t.contains('XmlHttpRequest')) {
      return RemoteException(RemoteFailure.offline, detail: t);
    }
    return RemoteException(RemoteFailure.unknown, detail: t);
  }

  static RemoteException _fromAuth(AuthException e) {
    const lost = {
      'session_not_found',
      'session_expired',
      'refresh_token_not_found',
      'refresh_token_already_used',
      'bad_jwt',
      'user_not_found',
      'no_authorization',
    };
    if (lost.contains(e.code) ||
        e.statusCode == '401' ||
        e.statusCode == '403') {
      return RemoteException(
        RemoteFailure.authExpired,
        code: e.code ?? e.statusCode,
      );
    }
    if (e.statusCode != null && e.statusCode!.startsWith('5')) {
      return RemoteException(
        RemoteFailure.server,
        code: e.code ?? e.statusCode,
      );
    }
    return RemoteException(RemoteFailure.unknown, code: e.code ?? e.statusCode);
  }

  static RemoteException _fromPostgrest(PostgrestException e) {
    final c = e.code ?? '';
    final msg = e.message.toLowerCase();
    // Missing / expired / invalid JWT.
    if (c == '401' || c.startsWith('PGRST30') || msg.contains('jwt expired')) {
      return RemoteException(RemoteFailure.authExpired, code: c);
    }
    // 28000/28P01: invalid authorization (raised by our RPCs when auth.uid() is null).
    if (c == '28000' || c == '28P01') {
      return RemoteException(RemoteFailure.authExpired, code: c);
    }
    // 22xxx data exception, 23xxx integrity (check/unique/fk), 42501 policy/privilege violation, PGRST1xx bad request.
    if (c.startsWith('22') ||
        c.startsWith('23') ||
        c == '42501' ||
        c.startsWith('PGRST1') ||
        c == '400' ||
        c == '409' ||
        c == '413') {
      return RemoteException(RemoteFailure.rejected, code: c);
    }
    if (c.startsWith('5') ||
        c.startsWith('PGRST0') ||
        c.startsWith('XX') ||
        c.startsWith('53') ||
        c.startsWith('57')) {
      return RemoteException(RemoteFailure.server, code: c);
    }
    return RemoteException(RemoteFailure.unknown, code: c);
  }

  @override
  String toString() =>
      'RemoteException(${kind.name}${code == null ? '' : ', $code'}${detail == null ? '' : ', $detail'})';
}
