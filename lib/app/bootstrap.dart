import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/sx_colors.dart';
import '../core/theme/sx_typography.dart';
import '../data/health/health_connect_repository.dart';
import '../data/health/health_gateway.dart';
import '../data/health/health_sync_service.dart';
import '../data/health/health_sync_store.dart';
import '../data/health/plugin_health_gateway.dart';
import '../data/isar/isar_device_store.dart';
import '../data/remote/auth_service.dart';
import '../data/remote/online_store.dart';
import '../data/remote/supabase_config.dart';
import '../data/remote/supabase_remote.dart';
import '../domain/domain.dart';
import 'app_controller.dart';
import 'startup_error_app.dart';
import 'stationx_app.dart';

const _dbName = 'stationx';

/// App entry used by main(): global error handling, then open the device store, initialise Supabase
/// and start the UI. A failure shows a recovery screen instead of crashing.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SxColors.obsidian.systemOverlay);
  _installErrorHandling();
  await _start();
}

/// System bar colours for [mode]; mirrors the palette chosen in `StationXApp`
/// ("system" resolves to the dark Obsidian palette).
void applySystemOverlayFor(SxThemeMode mode) {
  final colors = mode == SxThemeMode.oled ? SxColors.oled : SxColors.obsidian;
  SystemChrome.setSystemUIOverlayStyle(colors.systemOverlay);
}

void _installErrorHandling() {
  // Release: never show the red error screen or leak exception details to the user.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _FriendlyError();
  }
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (kReleaseMode) {
      debugPrint(
        'FlutterError: ${details.exception.runtimeType}',
      ); // type only, no data
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
  final problem = SupabaseConfig.validate(
    SupabaseConfig.url,
    SupabaseConfig.anonKey,
  );
  if (problem != null) {
    // Online-first: without a server there is no app. Say so instead of showing a broken UI.
    debugPrint('Supabase config invalid: $problem');
    runApp(const StartupErrorApp.notConfigured());
    return;
  }
  final String dir;
  final IsarDeviceStore device;
  try {
    dir = (await getApplicationDocumentsDirectory()).path;
    device = await IsarDeviceStore.open(directory: dir, name: _dbName);
  } catch (e) {
    debugPrint('Database open failed: ${e.runtimeType}');
    runApp(
      StartupErrorApp(
        onRetry: _start,
        onReset: () async {
          await resetDatabaseFiles(
            (await getApplicationDocumentsDirectory()).path,
          );
          await _start();
        },
      ),
    );
    return;
  }
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase init failed: ${e.runtimeType}');
    runApp(StartupErrorApp(onRetry: _start));
    return;
  }
  final client = Supabase.instance.client;

  // Health Connect (Android) / Apple Health (iOS); inert on other platforms.
  final HealthRepository health = (Platform.isAndroid || Platform.isIOS)
      ? HealthConnectRepository(
          PluginHealthGateway(),
          consent: device.healthConsent,
        )
      : NoopHealthRepository();
  unawaited(health.init()); // never blocks startup; UI reacts when it completes

  final healthSync = HealthSyncService(
    (Platform.isAndroid || Platform.isIOS)
        ? PluginHealthGateway()
        : HealthGateway.inert,
    await FileHealthSyncStore.open(dir),
  );
  final store = OnlineStore(SupabaseRemote(client), device);
  final controller = AppController(
    store: store,
    health: health,
    healthSync: healthSync,
    auth: SupabaseCloudAuth(client),
  );
  applySystemOverlayFor(controller.profile.profile.themeMode);
  // Keep the system navigation bar in step with the active theme (Obsidian / OLED).
  var lastMode = controller.profile.profile.themeMode;
  controller.profile.addListener(() {
    final mode = controller.profile.profile.themeMode;
    if (mode == lastMode) return;
    lastMode = mode;
    applySystemOverlayFor(mode);
  });
  runApp(StationXApp(controller: controller));
  unawaited(
    controller.init(),
  ); // restores the saved session and loads the user's data
}

class _FriendlyError extends StatelessWidget {
  const _FriendlyError();

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.all(16),
    color: SxColors.obsidian.surface1,
    child: Text(
      'Something went wrong here.\nPlease go back and try again.',
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      style: SxText.bodyMd.copyWith(color: SxColors.obsidian.textBody),
    ),
  );
}
