import 'package:flutter/material.dart';

import '../../data/remote/remote_exception.dart';
import '../theme/sx_theme.dart';
import '../widgets/widgets.dart';

final Set<Object> _inFlight = <Object>{};

/// Runs a server write the way every screen should: at most one at a time per [key] (a second tap
/// while the first is running is ignored), success feedback ONLY after the server confirmed, and a
/// plain error with a Retry action when it did not (nothing was saved; the caller keeps its input).
///
/// Returns true when the write succeeded. [what] completes "Couldn't …" ("save the workout").
Future<bool> runRemote(
  BuildContext context,
  Future<void> Function() action, {
  required String what,
  String? success,
  Object? key,
  bool showRetry = true,
}) async {
  if (key != null && !_inFlight.add(key)) return false;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final colors = context.sx;
  try {
    await action();
    if (success != null && context.mounted) showSxSnack(context, success);
    return true;
  } catch (e) {
    final err = RemoteException.from(
      e,
    ); // An expired session is handled globally (the user is taken to the login screen).
    if (err.kind != RemoteFailure.authExpired && messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: colors.danger),
                const SizedBox(width: 10),
                Expanded(child: Text("Couldn't $what. ${err.userMessage}")),
              ],
            ),
            action: showRetry && err.isRetryable
                ? SnackBarAction(
                    label: 'Retry',
                    onPressed: () {
                      if (context.mounted) {
                        runRemote(
                          context,
                          action,
                          what: what,
                          success: success,
                          key: key,
                          showRetry: showRetry,
                        );
                      }
                    },
                  )
                : null,
          ),
        );
    }
    return false;
  } finally {
    if (key != null) _inFlight.remove(key);
  }
}
