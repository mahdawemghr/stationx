/// A PostgREST row: snake_case columns, JSON values.
typedef Row = Map<String, dynamic>;

/// The tables the app reads and writes. [orderColumn] / [descending] define the stable paging order
/// (always tie-broken by `id`); [singleton] tables hold one row per user keyed by `user_id`.
enum RemoteTable {
  profiles('profiles', singleton: true),
  exercises('exercises', orderColumn: 'created_at'),
  workouts('workouts', orderColumn: 'position'),
  rotations('rotations', singleton: true),
  workoutSessions(
    'workout_sessions',
    orderColumn: 'workout_date',
    descending: true,
  ),
  cardioSessions(
    'cardio_sessions',
    orderColumn: 'workout_date',
    descending: true,
  ),
  cardioGoals('cardio_goals', orderColumn: 'created_at'),
  customCardioActivities('custom_cardio_activities', orderColumn: 'created_at');

  const RemoteTable(
    this.name, {
    this.singleton = false,
    this.orderColumn = 'created_at',
    this.descending = false,
  });

  final String name;
  final bool singleton;
  final String orderColumn;
  final bool descending;

  String get conflictTarget => singleton ? 'user_id' : 'user_id,id';
}

/// Everything the app asks of the server. Implementations throw [RemoteException] (never SDK types)
/// and never return before the server has answered, so callers can treat a normal return as
/// "confirmed by the server". `user_id` is never chosen by callers: it is the authenticated user.
abstract class RemoteGateway {
  /// The authenticated user, or null when signed out.
  String? get userId;

  /// The caller's profile row, or null if it does not exist yet.
  Future<Row?> fetchProfile();

  /// The caller's rotation row, or null.
  Future<Row?> fetchRotation();

  /// Every row of [table] for the caller, read in pages of [pageSize] (keyset on the table's order
  /// column + id) so memory and request size stay bounded.
  Future<List<Row>> fetchAll(RemoteTable table);

  /// Insert-or-update [rows] (client-generated `id`s make retries idempotent). Large lists are sent
  /// in several requests; ONE request is atomic, several are not (see [maxBatch]).
  Future<void> upsert(RemoteTable table, List<Row> rows);

  /// Deletes the row with [id]. Succeeds when the row is gone afterwards (including "was already gone").
  Future<void> delete(RemoteTable table, String id);

  /// Calls a Postgres function (`sx_*`). Atomic on the server.
  Future<Object?> rpc(String function, Map<String, dynamic> params);

  /// Largest number of rows sent in one upsert request.
  static const maxBatch = 100;
}
