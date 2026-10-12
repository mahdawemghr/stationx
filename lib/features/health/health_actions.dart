import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// Shared health-store flows (Health Connect on Android, Apple Health on iOS)
/// used by Today and Profile.

/// Where an iOS user manages access (HealthKit can't be revoked from the app).
const iosHealthAccessPath =
    'Settings › Health › Data Access & Devices › StationX';

/// Explains exactly what is read, THEN asks the system for permission.
Future<void> connectHealthConnect(BuildContext context) async {
  final health = context.app.health;
  if (health.status == HealthStatus.notInstalled) {
    await health.installProvider();
    return;
  }
  final ok = await showSxConfirm(
    context,
    title: 'Connect ${health.provider.label}?',
    message:
        'StationX will READ the workouts recorded in ${health.provider.label} so you can import them. '
        'Heart rate and write-back are separate switches you turn on later. Nothing is written to ${health.provider.label} until you allow it, and the data is not shared. '
        '${health.provider == HealthProvider.appleHealth ? 'iOS will ask which data to share. ' : ''}'
        'You can disconnect at any time.',
    confirmLabel: 'Continue',
    icon: Icons.monitor_heart_outlined,
  );
  if (!ok || !context.mounted) return;
  final granted = await health.connect();
  if (!context.mounted) return;
  if (granted) {
    showSxSnack(context, '${health.provider.label} connected');
  } else if (health.status == HealthStatus.notInstalled) {
    showSxSnack(
      context,
      '${health.provider.label} is not installed on this device',
      icon: Icons.info_outline,
    );
  } else {
    showSxSnack(
      context,
      healthDeniedMessage(health.provider),
      icon: Icons.info_outline,
    );
  }
}

/// Denied-permission copy with the concrete next step.
String healthDeniedMessage(HealthProvider p) => p == HealthProvider.appleHealth
    ? 'Access was not granted. To allow it, open $iosHealthAccessPath.'
    : 'Access was not granted. To allow it, open Health Connect › App permissions › StationX.';

Future<void> disconnectHealthConnect(BuildContext context) async {
  final health = context.app.health;
  final ios = health.provider == HealthProvider.appleHealth;
  final ok = await showSxConfirm(
    context,
    title: 'Disconnect ${health.provider.label}?',
    message:
        'StationX will stop reading health data. '
        '${ios ? 'To fully remove access, open $iosHealthAccessPath.' : 'Android may need the app to be restarted before the permission is fully removed.'}',
    confirmLabel: 'Disconnect',
    destructive: true,
    icon: Icons.link_off,
  );
  if (!ok || !context.mounted) return;
  await health.disconnect();
  if (context.mounted) {
    showSxSnack(context, '${health.provider.label} disconnected');
  }
}

// ───────────────────────── two-way workout sync (opt-in) ─────────────────────────

/// Plain-language title for each opt-in feature.
String healthFeatureTitle(HealthFeature f, HealthProvider p) => switch (f) {
  HealthFeature.writeWorkouts => 'Save my workouts to ${p.label}',
  HealthFeature.enrichCardio => 'Fill heart rate & calories from my watch',
  HealthFeature.importWorkouts => 'Import workouts from other apps',
};

/// What the explanation shown BEFORE the system permission sheet says.
String healthFeatureExplanation(HealthFeature f, HealthProvider p) {
  final ios = p == HealthProvider.appleHealth;
  final tail =
      'The data stays on this device. You can turn this off at any time.';
  return switch (f) {
    HealthFeature.writeWorkouts =>
      'When you finish a workout, StationX saves it to ${p.label}: the type, start and end time, and the distance and calories only if you logged them. '
          'It never writes heart rate. Workouts you already have are NOT sent; only new or edited ones from now on. $tail',
    HealthFeature.enrichCardio =>
      'StationX can READ heart rate and calories your watch recorded in ${p.label}: it suggests them for a cardio session (you confirm first, only empty fields are filled), '
          'shows your average and max heart rate on finished workouts, a recent heart rate while you train, and heart-rate trends. ${ios ? 'iOS will ask which data to share. ' : ''}$tail',
    HealthFeature.importWorkouts =>
      'StationX can READ cardio and strength workouts that other apps (a watch, Samsung Health, ...) saved in ${p.label}, including older ones if you allow it. '
          'You see a preview first and nothing is added until you confirm, unless you also turn on automatic import. Importing again never creates duplicates. $tail',
  };
}

/// Calm copy when permission was not granted, with the concrete next step.
String healthFeatureDeniedMessage(HealthProvider p) =>
    p == HealthProvider.appleHealth
    ? 'Nothing was turned on. To allow it, open $iosHealthAccessPath.'
    : 'Nothing was turned on. To allow it, open Health Connect › App permissions › StationX.';

/// Explanation first, THEN the system permission, THEN `enable`. Returns true when turned on.
Future<bool> enableHealthFeature(BuildContext context, HealthFeature f) async {
  final sync = context.app.healthSync;
  final p = sync.provider;
  final ok = await showSxConfirm(
    context,
    title: healthFeatureTitle(f, p),
    message: healthFeatureExplanation(f, p),
    confirmLabel: 'Continue',
    icon: Icons.health_and_safety_outlined,
  );
  if (!ok || !context.mounted) return false;
  final on = await sync.enable(f);
  if (!context.mounted) return on;
  if (on) {
    showSxSnack(context, 'Turned on');
  } else {
    showSxSnack(
      context,
      healthFeatureDeniedMessage(p),
      icon: Icons.info_outline,
    );
  }
  return on;
}
