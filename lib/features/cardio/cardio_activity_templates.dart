import '../../domain/domain.dart';

/// A one-tap starting point for "Create custom activity": team / racket sports and
/// conditioning styles that deliberately have no [CardioKind] (no schema change).
/// `iconKey` must be a key of `cardioCustomIcons`; `category` one of the page's category chips.
class CardioActivityTemplate {
  const CardioActivityTemplate({
    required this.name,
    required this.category,
    required this.iconKey,
    required this.fields,
    this.keywords = const [],
    this.roundSeconds,
    this.restSeconds,
    this.rounds,
  });

  final String name;
  final String category;
  final String iconKey;
  final List<CardioField> fields;

  /// Extra lower-case words the no-result search matches besides [name].
  final List<String> keywords;
  final int? roundSeconds;
  final int? restSeconds;
  final int? rounds;

  bool get hasIntervals => roundSeconds != null && restSeconds != null && rounds != null;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    return name.toLowerCase().contains(q) || keywords.any((k) => k.contains(q) || q.contains(k));
  }
}

const _dur = CardioField.duration;
const _hr = CardioField.heartRate;
const _kcal = CardioField.calories;
const _dist = CardioField.distance;
const _rpe = CardioField.rpe;
const _res = CardioField.resistance;

const cardioActivityTemplates = <CardioActivityTemplate>[
  CardioActivityTemplate(name: 'Padel', category: 'Racket Sports', iconKey: 'sports_tennis', fields: [_dur, _hr, _kcal], keywords: ['paddle tennis']),
  CardioActivityTemplate(name: 'Tennis', category: 'Racket Sports', iconKey: 'sports_tennis', fields: [_dur, _hr, _kcal]),
  CardioActivityTemplate(name: 'Pickleball', category: 'Racket Sports', iconKey: 'sports_tennis', fields: [_dur, _hr, _kcal]),
  CardioActivityTemplate(name: 'Badminton', category: 'Racket Sports', iconKey: 'sports_tennis', fields: [_dur, _hr, _kcal], keywords: ['shuttle']),
  CardioActivityTemplate(name: 'Squash', category: 'Racket Sports', iconKey: 'sports_tennis', fields: [_dur, _hr, _kcal], keywords: ['racquetball']),
  CardioActivityTemplate(name: 'Table Tennis', category: 'Racket Sports', iconKey: 'sports_tennis', fields: [_dur, _kcal], keywords: ['ping pong']),
  CardioActivityTemplate(name: 'Soccer', category: 'Field Sports', iconKey: 'sports_soccer', fields: [_dur, _dist, _hr, _kcal], keywords: ['football', 'futsal']),
  CardioActivityTemplate(name: 'Basketball', category: 'Field Sports', iconKey: 'sports_basketball', fields: [_dur, _hr, _kcal], keywords: ['hoops']),
  CardioActivityTemplate(name: 'Volleyball', category: 'Field Sports', iconKey: 'sports_volleyball', fields: [_dur, _hr, _kcal], keywords: ['beach volleyball']),
  CardioActivityTemplate(name: 'Handball', category: 'Field Sports', iconKey: 'sports_handball', fields: [_dur, _hr, _kcal]),
  CardioActivityTemplate(name: 'Rugby', category: 'Field Sports', iconKey: 'sports_rugby', fields: [_dur, _hr, _kcal]),
  CardioActivityTemplate(name: 'Cricket', category: 'Field Sports', iconKey: 'sports_cricket', fields: [_dur, _kcal]),
  CardioActivityTemplate(name: 'Hockey', category: 'Field Sports', iconKey: 'sports_hockey', fields: [_dur, _hr, _kcal]),
  CardioActivityTemplate(name: 'Pilates', category: 'Mind & Body', iconKey: 'self_improvement', fields: [_dur, _hr, _kcal], keywords: ['reformer']),
  CardioActivityTemplate(name: 'Yoga Flow', category: 'Mind & Body', iconKey: 'self_improvement', fields: [_dur, _kcal], keywords: ['yoga', 'vinyasa', 'stretching']),
  CardioActivityTemplate(
    name: 'Battle Ropes',
    category: 'Functional HIIT',
    iconKey: 'local_fire_department',
    fields: [_dur, _hr, _kcal, _rpe],
    keywords: ['ropes'],
    roundSeconds: 30,
    restSeconds: 30,
    rounds: 8,
  ),
  CardioActivityTemplate(
    name: 'Sled Push',
    category: 'Functional HIIT',
    iconKey: 'fitness_center',
    fields: [_dur, _dist, _hr, _rpe],
    keywords: ['sled', 'prowler'],
    roundSeconds: 30,
    restSeconds: 90,
    rounds: 6,
  ),
  CardioActivityTemplate(name: 'Stair Running', category: 'Functional HIIT', iconKey: 'stairs', fields: [_dur, _hr, _kcal, _rpe], keywords: ['stairs', 'stair sprints']),
  CardioActivityTemplate(name: 'Stadium Stairs', category: 'Functional HIIT', iconKey: 'stairs', fields: [_dur, _hr, _kcal, _rpe], keywords: ['stadium', 'bleachers']),
  CardioActivityTemplate(
    name: 'Bootcamp',
    category: 'Functional HIIT',
    iconKey: 'sports_kabaddi',
    fields: [_dur, _hr, _kcal, _rpe],
    keywords: ['boot camp', 'circuit class'],
  ),
  CardioActivityTemplate(name: 'Gymnastics', category: 'Functional HIIT', iconKey: 'sports_gymnastics', fields: [_dur, _hr, _kcal], keywords: ['calisthenics']),
  CardioActivityTemplate(name: 'Golf (Walking)', category: 'Field Sports', iconKey: 'sports_golf', fields: [_dur, _dist, _kcal], keywords: ['golf']),
  CardioActivityTemplate(name: 'Surfing', category: 'Water / Paddle', iconKey: 'surfing', fields: [_dur, _hr, _kcal], keywords: ['surf', 'bodyboard']),
  CardioActivityTemplate(name: 'Water Polo', category: 'Water / Paddle', iconKey: 'pool', fields: [_dur, _hr, _kcal]),
  CardioActivityTemplate(name: 'Aqua Aerobics', category: 'Water / Paddle', iconKey: 'pool', fields: [_dur, _hr, _kcal, _res], keywords: ['water aerobics']),
  CardioActivityTemplate(name: 'Wrestling', category: 'Combat Sport', iconKey: 'sports_mma', fields: [_dur, _hr, _kcal], keywords: ['grappling']),
];

/// Templates whose name or keywords match [query] (best first: name prefix, then the rest).
List<CardioActivityTemplate> cardioTemplatesMatching(String query) {
  final q = query.trim().toLowerCase();
  final hits = [for (final t in cardioActivityTemplates) if (t.matches(q)) t];
  hits.sort((a, b) {
    final ap = a.name.toLowerCase().startsWith(q) ? 0 : 1;
    final bp = b.name.toLowerCase().startsWith(q) ? 0 : 1;
    return ap.compareTo(bp);
  });
  return hits;
}
