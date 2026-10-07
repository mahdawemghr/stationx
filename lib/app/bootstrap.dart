import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../core/theme/sx_colors.dart';
import '../core/theme/sx_typography.dart';
import '../data/health/health_connect_repository.dart';
import '../data/health/plugin_health_gateway.dart';
import '../data/isar/isar_store.dart';
import '../domain/domain.dart';
import 'app_controller.dart';
import 'startup_error_app.dart';
import 'stationx_app.dart';

const _dbName = 'stationx';

/// App entry used by main(): global error handling, then open the database and
/// start the UI. A database failure shows a recovery screen instead of crashing.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1A1C1E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  _installErrorHandling();
  await _start();
}

void _installErrorHandling() {
  // Release: never show the red error screen or leak exception details to the user.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _FriendlyError();
  }
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (kReleaseMode) {
      debugPrint('FlutterError: ${details.exception.runtimeType}'); // type only, no data
    } else {
      previous?.call(details);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled: ${error.runtimeType}');
    return kReleaseMode; // release: handled (no crash); debug: keep default reporting
  };
}

Future<void> _start() async {
  final String dir;
  final IsarStore store;
  try {
    dir = (await getApplicationDocumentsDirectory()).path;
    store = await IsarStore.open(directory: dir, name: _dbName);
  } catch (e) {
    debugPrint('Database open failed: ${e.runtimeType}');
    runApp(StartupErrorApp(
      onRetry: _start,
      onReset: () async {
        await resetDatabaseFiles((await getApplicationDocumentsDirectory()).path);
        await _start();
      },
    ));
    return;
  }

  // Health Connect (Android) / Apple Health (iOS); inert on other platforms.
  final HealthRepository health = (Platform.isAndroid || Platform.isIOS)
      ? HealthConnectRepository(PluginHealthGateway(), consent: store.healthConsent)
      : NoopHealthRepository();
  unawaited(health.init()); // never blocks startup; UI reacts when it completes

  runApp(StationXApp(controller: AppController(store: store, health: health)));
}

/// Deletes the Isar database files for [dbName] in [directory]. Destructive —
/// only called after an explicit user confirmation.
Future<void> resetDatabaseFiles(String directory, {String dbName = _dbName}) async {
  for (final suffix in ['.isar', '.isar-lck']) {
    final f = File('$directory/$dbName$suffix');
    if (await f.exists()) await f.delete();
  }
}

class _FriendlyError extends StatelessWidget {
  const _FriendlyError();

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        color: SxColors.obsidian.surface1,
        child: Text('Something went wrong here.\nPlease go back and try again.',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: SxText.bodyMd.copyWith(color: SxColors.obsidian.textBody)),
      );
}
