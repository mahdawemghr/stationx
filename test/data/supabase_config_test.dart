import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/data/sync/supabase_config.dart';

void main() {
  const url = 'https://abc.supabase.co';
  // header.payload with role claim (signature irrelevant for this check)
  String jwt(String role) {
    String b64(String s) => base64Url.encode(utf8.encode(s)).replaceAll('=', '');
    return '${b64('{"alg":"HS256"}')}.${b64('{"role":"$role"}')}.sig';
  }

  test('accepts https URL + publishable/anon keys', () {
    expect(SupabaseConfig.validate(url, 'sb_publishable_abc123'), isNull);
    expect(SupabaseConfig.validate(url, jwt('anon')), isNull);
  });

  test('refuses anything that would expose everyone\'s data', () {
    expect(SupabaseConfig.validate(url, 'sbp_0123456789abcdef'), contains('personal access token'));
    expect(SupabaseConfig.validate(url, 'sb_secret_abc'), contains('secret key'));
    expect(SupabaseConfig.validate(url, jwt('service_role')), contains('service_role'));
  });

  test('refuses missing config or non-https URLs', () {
    expect(SupabaseConfig.validate('', ''), 'not configured');
    expect(SupabaseConfig.validate(url, ''), 'not configured');
    expect(SupabaseConfig.validate('http://abc.supabase.co', 'sb_publishable_x'), contains('https'));
    expect(SupabaseConfig.validate('not a url', 'sb_publishable_x'), isNotNull);
  });

  test('unconfigured by default (no --dart-define): feature absent', () {
    expect(SupabaseConfig.isConfigured, isFalse);
  });
}
