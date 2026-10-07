import 'package:package_info_plus/package_info_plus.dart';

/// "v1.0.0 (1)" from the installed package info (pubspec version), or '' when
/// unavailable (tests / unsupported platform).
Future<String> appVersionLabel() async {
  try {
    final i = await PackageInfo.fromPlatform();
    return 'v${i.version} (${i.buildNumber})';
  } catch (_) {
    return '';
  }
}
