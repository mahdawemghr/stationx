import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/domain.dart';

/// Shared health-store flows (Health Connect on Android, Apple Health on iOS)
/// used by Today and Profile.

/// Where an iOS user manages access (HealthKit can't be revoked from the app).
const iosHealthAccessPath = 'Settings › Health › Data Access & Devices › StationX';

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
    message: 'StationX will READ your sleep and resting heart rate from ${health.provider.label} to show a recovery summary on Today. '
        'It never writes to ${health.provider.label}, and the data stays on this device — it is not uploaded or shared. '
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
    showSxSnack(context, '${health.provider.label} is not installed on this device', icon: Icons.info_outline);
  } else {
    showSxSnack(context, 'Access was not granted', icon: Icons.info_outline);
  }
}

Future<void> disconnectHealthConnect(BuildContext context) async {
  final health = context.app.health;
  final ios = health.provider == HealthProvider.appleHealth;
  final ok = await showSxConfirm(
    context,
    title: 'Disconnect ${health.provider.label}?',
    message: 'StationX will stop reading sleep and heart-rate data and clear what it has cached. '
        '${ios ? 'To fully remove access, open $iosHealthAccessPath.' : 'Android may need the app to be restarted before the permission is fully removed.'}',
    confirmLabel: 'Disconnect',
    destructive: true,
    icon: Icons.link_off,
  );
  if (!ok || !context.mounted) return;
  await health.disconnect();
  if (context.mounted) showSxSnack(context, '${health.provider.label} disconnected');
}

/// "7h 40m" for a minute count.
String sleepLabel(int minutes) => Fmt.durationShort(minutes * 60);
