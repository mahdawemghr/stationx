import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stationx/data/remote/auth_service.dart';

void main() {
  CloudAuthStatus map(Object e) => SupabaseCloudAuth.mapError(e).status;

  test('server codes map to username-flavoured statuses', () {
    expect(
      map(
        const AuthApiException(
          'x',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      ),
      CloudAuthStatus.invalidCredentials,
    );
    expect(
      map(
        const AuthApiException(
          'x',
          statusCode: '422',
          code: 'user_already_exists',
        ),
      ),
      CloudAuthStatus.userExists,
    );
    expect(
      map(const AuthApiException('x', statusCode: '422', code: 'email_exists')),
      CloudAuthStatus.userExists,
    );
    expect(
      map(
        const AuthApiException('x', statusCode: '422', code: 'weak_password'),
      ),
      CloudAuthStatus.weakPassword,
    );
    expect(
      map(
        const AuthApiException(
          'x',
          statusCode: '429',
          code: 'over_request_rate_limit',
        ),
      ),
      CloudAuthStatus.rateLimited,
    );
    expect(
      map(const AuthApiException('x', statusCode: '429')),
      CloudAuthStatus.rateLimited,
    );
  });

  test('older servers: "Invalid login credentials" without a code', () {
    expect(
      map(
        const AuthApiException('Invalid login credentials', statusCode: '400'),
      ),
      CloudAuthStatus.invalidCredentials,
    );
  });

  test(
    'transport problems are "network"; anything else is "unknown" with no raw text',
    () {
      expect(map(const SocketException('offline')), CloudAuthStatus.network);
      expect(
        map(AuthRetryableFetchException(message: 'x')),
        CloudAuthStatus.network,
      );
      final r = SupabaseCloudAuth.mapError(StateError('secret detail'));
      expect(r.status, CloudAuthStatus.unknown);
      expect(r.message, isNot(contains('secret')));
    },
  );
}
