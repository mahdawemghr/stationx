import '../models/models.dart';
import 'exercise_name.dart';
import 'muscle_profiles.dart';

/// Pure exercise search: normalised (case/space/hyphen-insensitive), tokenised, synonym-aware and ranked.
///
/// Every query token must match the exercise's name, a muscle label (broad, region or sub-muscle), its
/// equipment label, or - on the query side - a synonym of the token ("rdl" -> "romanian deadlift").
/// Ranking: exact name > name prefix > all tokens at name-word starts > all tokens inside the name >
/// muscle/equipment/synonym match; ties fall back to alphabetical order (stable and deterministic).
/// Search keys are memoised per exercise (re-built only when the [Exercise] instance changes).
class ExerciseSearch {
  ExerciseSearch();

  final Map<String, _Key> _keys = {};

  /// Number of search keys built so far (exposed for tests: proves memoisation).
  int get keyBuilds => _keyBuilds;
  int _keyBuilds = 0;

  /// Query-side synonyms, keyed by a normalised token. Values are normalised alternatives that may match
  /// the exercise name/labels instead of (or in addition to) the token itself.
  static const Map<String, List<String>> synonyms = {
    'rdl': ['romaniandeadlift'],
    'sldl': ['stifflegdeadlift', 'stifflegged'],
    'ohp': ['overheadpress', 'shoulderpress', 'militarypress'],
    'military': ['overheadpress', 'militarypress'],
    'db': ['dumbbell'],
    'dumbell': ['dumbbell'],
    'bb': ['barbell'],
    'kb': ['kettlebell'],
    'ez': ['ezbar', 'ezcurl'],
    'ezbar': ['ezbar', 'ezcurl'],
    'tbar': ['tbar'],
    'hack': ['hacksquat', 'hack'],
    'ghr': ['gluteham', 'gluteh', 'hamraise'],
    'skullcrusher': ['skullcrusher', 'lyingtricepsextension', 'lyingtriceps'],
    'skullcrushers': ['skullcrusher', 'lyingtricepsextension'],
    'pulldown': ['pulldown', 'latpull'],
    'latpull': ['pulldown', 'latpull'],
    'pullup': ['pullup', 'chinup'],
    'chinup': ['chinup', 'pullup'],
    'pullups': ['pullup', 'chinup'],
    'chinups': ['chinup', 'pullup'],
    'goodmorning': ['goodmorning'],
    'wrist': ['wrist', 'forearm'],
    'grip': ['grip', 'forearm', 'farmer', 'deadhang', 'wrist'],
    'forearm': ['forearm'],
    'forearms': ['forearm'],
    'sawaed': ['forearm'],
    'sawa3d': ['forearm'],
    'سواعد': ['forearm'],
    'ساعد': ['forearm'],
    'صدر': ['chest'],
    'ظهر': ['back'],
    'اكتاف': ['shoulder'],
    'أكتاف': ['shoulder'],
    'كتف': ['shoulder'],
    'باي': ['biceps'],
    'بايسبس': ['biceps'],
    'ترايسبس': ['triceps'],
    'رجل': ['legs', 'quadriceps'],
    'ارجل': ['legs', 'quadriceps'],
    'أرجل': ['legs', 'quadriceps'],
    'بطن': ['core', 'abs'],
    'abs': ['abs', 'core'],
    'quads': ['quadriceps'],
    'quad': ['quadriceps'],
    'hams': ['hamstrings'],
    'glute': ['glutes', 'glute'],
    'delts': ['delts', 'shoulder'],
    'lats': ['lats'],
    'pecs': ['chest', 'pec'],
    'smith': ['smithmachine', 'smith'],
    'band': ['band', 'resistance'],
    'machine': ['machine', 'smithmachine'],
  };

  static final RegExp _arabic = RegExp(r'[؀-ۿ]');
  static final RegExp _splitter = RegExp(r'[\s\-_/,.+]+');

  /// Normalises one raw token: Latin goes through [normalizeExerciseName]; Arabic is kept as typed.
  static String normalizeToken(String t) {
    final lower = t.trim().toLowerCase();
    if (_arabic.hasMatch(lower)) {
      return lower.replaceAll(RegExp(r'[^؀-ۿa-z0-9]'), '');
    }
    return normalizeExerciseName(lower);
  }

  static List<String> tokenize(String query) => [
    for (final t in query.split(_splitter))
      if (normalizeToken(t).isNotEmpty) normalizeToken(t),
  ];

  _Key _keyFor(Exercise e) {
    final hit = _keys[e.id];
    if (hit != null && identical(hit.source, e)) return hit;
    _keyBuilds++;
    return _keys[e.id] = _build(e);
  }

  static _Key _build(Exercise e) {
    final name = normalizeExerciseName(e.name);
    final words = [
      for (final w in e.name.toLowerCase().split(_splitter))
        if (normalizeExerciseName(w).isNotEmpty) normalizeExerciseName(w),
    ];
    final profile = MuscleProfiles.of(e);
    final labels = <String>{
      SectionMuscle.of(profile.primaryRegion).label,
      e.primaryMuscle.label,
      for (final m in e.secondaryMuscles) m.label,
      for (final t in profile.targets) ...[
        t.region.label,
        if (t.muscle != null) t.muscle!.label,
      ],
      e.equipment.label,
    };
    final other = labels.map(normalizeExerciseName).join(' ');
    return _Key(e, name, words, other);
  }

  /// Relevance score of [e] for [tokens]/[phrase]; 0 = no match.
  int _score(_Key k, List<String> tokens, String phrase) {
    if (tokens.isEmpty) return 1;
    final alts = [for (final t in tokens) _expand(t)];
    // Whole-phrase checks (spaces ignored, so "skull crusher" == "skullcrusher").
    final phraseAlts = <String>{..._expand(phrase)};
    if (phraseAlts.contains(k.name)) return 100;
    if (phraseAlts.any(k.name.startsWith)) return 80;
    var inName = true;
    var wordStarts = true;
    var inAll = true;
    for (final a in alts) {
      if (!a.any(k.name.contains)) inName = false;
      if (!a.any((x) => k.words.any((w) => w.startsWith(x)))) {
        wordStarts = false;
      }
      if (!a.any((x) => k.name.contains(x) || k.other.contains(x))) {
        inAll = false;
        break;
      }
    }
    if (inName && wordStarts) return 60;
    if (inName) return 50;
    if (phraseAlts.any(k.name.contains)) return 45;
    if (inAll) return 10;
    return 0;
  }

  static List<String> _expand(String t) =>
      synonyms[t] ??
      [
        t,
      ]; // synonym entries replace short raw tokens ("bb" must not hit "dumbbell")

  /// Exercises matching [query], most relevant first (alphabetical tie-break). Empty query returns all
  /// exercises alphabetically.
  List<Exercise> search(Iterable<Exercise> items, String query) {
    final tokens = tokenize(query);
    final phrase = tokens.join();
    final scored = <(Exercise, int)>[];
    for (final e in items) {
      final s = _score(_keyFor(e), tokens, phrase);
      if (s > 0) scored.add((e, s));
    }
    scored.sort((a, b) {
      final c = b.$2.compareTo(a.$2);
      return c != 0
          ? c
          : a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase());
    });
    return [for (final s in scored) s.$1];
  }

  /// Whether [e] matches [query] at all.
  bool matches(Exercise e, String query) {
    final tokens = tokenize(query);
    return _score(_keyFor(e), tokens, tokens.join()) > 0;
  }
}

class _Key {
  _Key(this.source, this.name, this.words, this.other);
  final Exercise source;
  final String name;
  final List<String> words;
  final String other;
}
