/// One curated sub-section of a muscle (data only). [key] is stable (section id = 'MUSCLE_KEY').
///
/// Big sub-areas are split into several sections so no list is longer than ~13 exercises. All sections of
/// one sub-area form a FAMILY: the lead section has `family == null` (its key IS the family key), the others
/// name the lead's key in [family]. Profile derivation (see SplitCatalog) works at family level; the exact
/// section inside a family is curated.
class SectionDef {
  const SectionDef(this.key, this.label, this.hint, this.ids, {this.family});
  final String key;
  final String label;
  final String hint;

  /// Exercise ids in display order (compounds first).
  final List<String> ids;

  /// Key of the lead section of this sub-area (null when this section is the lead itself).
  final String? family;

  String get familyKey => family ?? key;
}
