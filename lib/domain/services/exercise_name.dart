/// Canonical key for matching exercise names: "EZ-Bar Preacher Curl" → "ezbarpreachercurl".
/// Case, spaces and punctuation are ignored. Pure Dart, shared by import aliases and search.
String normalizeExerciseName(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
