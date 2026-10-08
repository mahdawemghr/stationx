import 'enums.dart';

/// Fields kept on every persisted entity so a future Isar/sync layer can adopt
/// the models unchanged. Do not remove even if the UI never shows them.
class SyncMeta {
  SyncMeta({
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.pending,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  SyncMeta touched() => SyncMeta(
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    syncStatus: SyncStatus.pending,
  );
}
