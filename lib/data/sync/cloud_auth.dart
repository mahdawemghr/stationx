import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum CloudAuthStatus {
  ok,
  needsEmailConfirmation,
  invalidCredentials,
  emailNotConfirmed,
  userExists,
  weakPassword,
  rateLimited,
  network,
  unavailable,
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
  const CloudUser({required this.id, required this.email});
  final String id;
  final String email;
}

/// Cloud account operations. UI and sync code depend on this interface only, so
/// no Supabase types leak out and tests can use a fake. Passwords are passed
/// through to the server and are never stored or logged by the app.
abstract class CloudAuth implements Listenable {
  /// False when the build has no Supabase URL / key: the whole feature is hidden.
  bool get isConfigured;
  CloudUser? get user;

  Future<CloudAuthResult> signIn(String email, String password);
  Future<CloudAuthResult> signUp(String email, String password, {String? name});
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
  Future<CloudAuthResult> signIn(String email, String password) async =>
      const CloudAuthResult(CloudAuthStatus.unavailable);
  @override
  Future<CloudAuthResult> signUp(
    String email,
    String password, {
    String? name,
  }) async => const CloudAuthResult(CloudAuthStatus.unavailable);
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
    return CloudUser(id: u.id, email: u.email ?? '');
  }

  CloudAuthResult _fail(Object e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'invalid_credentials':
          return CloudAuthResult(CloudAuthStatus.invalidCredentials, e.code);
        case 'email_not_confirmed':
          return CloudAuthResult(CloudAuthStatus.emailNotConfirmed, e.code);
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
  Future<CloudAuthResult> signIn(String email, String password) async {
    try {
      final r = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return r.session != null
          ? const CloudAuthResult(CloudAuthStatus.ok)
          : const CloudAuthResult(CloudAuthStatus.unknown, 'no session');
    } catch (e) {
      return _fail(e);
    }
  }

  @override
  Future<CloudAuthResult> signUp(
    String email,
    String password, {
    String? name,
  }) async {
    try {
      final r = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {if (name != null && name.trim().isNotEmpty) 'name': name.trim()},
      );
      if (r.session != null) return const CloudAuthResult(CloudAuthStatus.ok);
      // With e-mail confirmation on, an existing address comes back as a user with no identities
      // (so the API does not reveal which e-mails are registered).
      if (r.user != null && (r.user!.identities?.isEmpty ?? false)) {
        return const CloudAuthResult(
          CloudAuthStatus.userExists,
          'obfuscated existing user',
        );
      }
      return const CloudAuthResult(CloudAuthStatus.needsEmailConfirmation);
    } catch (e) {
      return _fail(e);
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
      return _fail(e);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
