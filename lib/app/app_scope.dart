import 'package:flutter/widgets.dart';

import 'app_controller.dart';

/// Provides [AppController] to the tree.
/// `AppScope.of(context)` listens (rebuilds when the store is swapped);
/// `AppScope.read(context)` does not.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({super.key, required AppController controller, required super.child})
      : super(notifier: controller);

  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppController read(BuildContext context) =>
      (context.getInheritedWidgetOfExactType<AppScope>()!).notifier!;
}

extension AppContext on BuildContext {
  /// Non-listening access to repositories/services. To react to data changes,
  /// wrap in `ListenableBuilder(listenable: app.sessions, ...)`.
  AppController get app => AppScope.read(this);
}
