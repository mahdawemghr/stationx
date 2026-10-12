import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/services/username.dart';

enum CloudAuthStatus {
  ok,
  invalidCredentials,
  userExists,
  weakPassword,
  rateLimited,
  network,
  unavailable,

  /// Sign-up went through but the server returned no session (should not happen with auto-confirm).
  signUpIncomplete,
  unknown,
}

class CloudAuthResult {
  const CloudAuthResult(this.status, [this.message]);
  final CloudAuthStatus status;

  /// Technical detail for logs only (never contains credentials).
  final String? message;
  bool get ok => status == CloudAuthStatus.ok;
}

class CloudUser {
  const CloudUser({required this.id, required this.username});
  final String id;

  /// What the user typed at sign-up (normalised). The private backend identifier is never exposed.
  final String username;
}

/// Cloud account operations. UI and sync code depend on this interface only, so
/// no Supabase types leak out and tests can use a fake. Passwords are passed
/// through to the server and are never stored or logged by the app.
abstract class CloudAuth implements Listenable {
  /// False when the build has no Supabase URL / key: the whole feature is hidden.
  bool get isConfigured;
  CloudUser? get user;

  /// [username] is mapped to a private backend identifier; callers validate it with [Username.validate].
  Future<CloudAuthResult> signIn(String username, String password);

  /// With e-mail auto-confirm on the server this returns a session immediately.
  Future<CloudAuthResult> signUp(String username, String password);
  Future<void> signOut();

  /// Deletes the cloud account and all of its cloud data (store requirement).
  Future<CloudAuthResult> deleteAccount();
}

/// Used when the build has no cloud configuration.
class NoCloudAuth extends ChangeNotifier implements CloudAuth {
  @override
  bool get isConfigured => false;
  @override
  CloudUser? get user => null;
  @override
  Future<CloudAuthResult> signIn(String username, String password) async =>
      const CloudAuthResult(CloudAuthStatus.unavailable);
  @override
  Future<CloudAuthResult> signUp(String username, String password) async =>
      const CloudAuthResult(CloudAuthStatus.unavailable);
  @override
  Future<void> signOut() async {}
  @override
  Future<CloudAuthResult> deleteAccount() async =>
      const CloudAuthResult(CloudAuthStatus.unavailable);
}

class SupabaseCloudAuth extends ChangeNotifier implements CloudAuth {
  SupabaseCloudAuth(this._client) {
    _sub = _client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  final SupabaseClient _client;
  StreamSubscription<AuthState>? _sub;

  @override
  bool get isConfigured => true;

  @override
  CloudUser? get user {
    final u = _client.auth.currentUser;
    if (u == null) return null;
    final meta = u.userMetadata?['username'];
    final name =
        Username.fromIdentifier(u.email ?? '') ??
        (meta is String ? Username.normalize(meta) : '');
    return CloudUser(id: u.id, username: name);
  }

  /// Maps a client exception to a status (never keeps credentials or raw text).
  @visibleForTesting
  static CloudAuthResult mapError(Object e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'invalid_credentials':
          return CloudAuthResult(CloudAuthStatus.invalidCredentials, e.code);
        case 'user_already_exists':
        case 'email_exists':
          return CloudAuthResult(CloudAuthStatus.userExists, e.code);
        case 'weak_password':
          return CloudAuthResult(CloudAuthStatus.weakPassword, e.code);
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          return CloudAuthResult(CloudAuthStatus.rateLimited, e.code);
      }
      if (e is AuthRetryableFetchException) {
        return CloudAuthResult(CloudAuthStatus.network, 'network');
      }
      if (e.statusCode == '429') {
        return CloudAuthResult(CloudAuthStatus.rateLimited, e.code);
      }
      // Older server responses without a code.
      if (e.statusCode == '400' &&
          e.message.toLowerCase().contains('invalid login')) {
        return const CloudAuthResult(
          CloudAuthStatus.invalidCredentials,
          'invalid login',
        );
      }
      return CloudAuthResult(CloudAuthStatus.unknown, e.code ?? e.statusCode);
    }
    if (e is SocketException || e is TimeoutException || e is HttpException) {
      return const CloudAuthResult(CloudAuthStatus.network, 'network');
    }
    return CloudAuthResult(CloudAuthStatus.unknown, e.runtimeType.toString());
  }

  @override
  Future<CloudAuthResult> signIn(String username, String password) async {
    try {
      final r = await _client.auth.signInWithPassword(
        email: Username.toIdentifier(username),
        password: password,
      );
      return r.session != null
          ? const CloudAuthResult(CloudAuthStatus.ok)
          : const CloudAuthResult(CloudAuthStatus.unknown, 'no session');
    } catch (e) {
      return mapError(e);
    }
  }

  @override
  Future<CloudAuthResult> signUp(String username, String password) async {
    try {
      final name = Username.normalize(username);
      final r = await _client.auth.signUp(
        email: Username.toIdentifier(name),
        password: password,
        data: {'username': name},
      );
      if (r.session != null) return const CloudAuthResult(CloudAuthStatus.ok);
      // An existing identifier can come back as a user with no identities (obfuscated duplicate).
      if (r.user != null && (r.user!.identities?.isEmpty ?? false)) {
        return const CloudAuthResult(
          CloudAuthStatus.userExists,
          'obfuscated existing user',
        );
      }
      return const CloudAuthResult(
        CloudAuthStatus.signUpIncomplete,
        'no session',
      );
    } catch (e) {
      return mapError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      await _client.auth.signOut(
        scope: SignOutScope.local,
      ); // offline: still drop the local session
    }
  }

  @override
  Future<CloudAuthResult> deleteAccount() async {
    try {
      await _client.rpc('delete_account');
      try {
        await _client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
      return const CloudAuthResult(CloudAuthStatus.ok);
    } catch (e) {
      if (e is PostgrestException) {
        return CloudAuthResult(CloudAuthStatus.unknown, e.code);
      }
      return mapError(e);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
