// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entities.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetExerciseEntityCollection on Isar {
  IsarCollection<ExerciseEntity> get exerciseEntitys => this.collection();
}

const ExerciseEntitySchema = CollectionSchema(
  name: r'ExerciseEntity',
  id: -1061429956440164644,
  properties: {
    r'equipment': PropertySchema(
      id: 0,
      name: r'equipment',
      type: IsarType.string,
      enumMap: _ExerciseEntityequipmentEnumValueMap,
    ),
    r'instructions': PropertySchema(
      id: 1,
      name: r'instructions',
      type: IsarType.objectList,

      target: r'StepEmb',
    ),
    r'isCustom': PropertySchema(id: 2, name: r'isCustom', type: IsarType.bool),
    r'meta': PropertySchema(
      id: 3,
      name: r'meta',
      type: IsarType.object,

      target: r'MetaEmb',
    ),
    r'movementPattern': PropertySchema(
      id: 4,
      name: r'movementPattern',
      type: IsarType.string,
    ),
    r'name': PropertySchema(id: 5, name: r'name', type: IsarType.string),
    r'primaryMuscle': PropertySchema(
      id: 6,
      name: r'primaryMuscle',
      type: IsarType.string,
      enumMap: _ExerciseEntityprimaryMuscleEnumValueMap,
    ),
    r'secondaryMuscles': PropertySchema(
      id: 7,
      name: r'secondaryMuscles',
      type: IsarType.stringList,
      enumMap: _ExerciseEntitysecondaryMusclesEnumValueMap,
    ),
    r'tempo': PropertySchema(id: 8, name: r'tempo', type: IsarType.string),
    r'uid': PropertySchema(id: 9, name: r'uid', type: IsarType.string),
  },

  estimateSize: _exerciseEntityEstimateSize,
  serialize: _exerciseEntitySerialize,
  deserialize: _exerciseEntityDeserialize,
  deserializeProp: _exerciseEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {r'StepEmb': StepEmbSchema, r'MetaEmb': MetaEmbSchema},

  getId: _exerciseEntityGetId,
  getLinks: _exerciseEntityGetLinks,
  attach: _exerciseEntityAttach,
  version: '3.3.2',
);

int _exerciseEntityEstimateSize(
  ExerciseEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.equipment.name.length * 3;
  bytesCount += 3 + object.instructions.length * 3;
  {
    final offsets = allOffsets[StepEmb]!;
    for (var i = 0; i < object.instructions.length; i++) {
      final value = object.instructions[i];
      bytesCount += StepEmbSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount +=
      3 +
      MetaEmbSchema.estimateSize(object.meta, allOffsets[MetaEmb]!, allOffsets);
  bytesCount += 3 + object.movementPattern.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.primaryMuscle.name.length * 3;
  bytesCount += 3 + object.secondaryMuscles.length * 3;
  {
    for (var i = 0; i < object.secondaryMuscles.length; i++) {
      final value = object.secondaryMuscles[i];
      bytesCount += value.name.length * 3;
    }
  }
  {
    final value = object.tempo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _exerciseEntitySerialize(
  ExerciseEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.equipment.name);
  writer.writeObjectList<StepEmb>(
    offsets[1],
    allOffsets,
    StepEmbSchema.serialize,
    object.instructions,
  );
  writer.writeBool(offsets[2], object.isCustom);
  writer.writeObject<MetaEmb>(
    offsets[3],
    allOffsets,
    MetaEmbSchema.serialize,
    object.meta,
  );
  writer.writeString(offsets[4], object.movementPattern);
  writer.writeString(offsets[5], object.name);
  writer.writeString(offsets[6], object.primaryMuscle.name);
  writer.writeStringList(
    offsets[7],
    object.secondaryMuscles.map((e) => e.name).toList(),
  );
  writer.writeString(offsets[8], object.tempo);
  writer.writeString(offsets[9], object.uid);
}

ExerciseEntity _exerciseEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExerciseEntity();
  object.equipment =
      _ExerciseEntityequipmentValueEnumMap[reader.readStringOrNull(
        offsets[0],
      )] ??
      Equipment.cable;
  object.id = id;
  object.instructions =
      reader.readObjectList<StepEmb>(
        offsets[1],
        StepEmbSchema.deserialize,
        allOffsets,
        StepEmb(),
      ) ??
      [];
  object.isCustom = reader.readBool(offsets[2]);
  object.meta =
      reader.readObjectOrNull<MetaEmb>(
        offsets[3],
        MetaEmbSchema.deserialize,
        allOffsets,
      ) ??
      MetaEmb();
  object.movementPattern = reader.readString(offsets[4]);
  object.name = reader.readString(offsets[5]);
  object.primaryMuscle =
      _ExerciseEntityprimaryMuscleValueEnumMap[reader.readStringOrNull(
        offsets[6],
      )] ??
      MuscleGroup.chest;
  object.secondaryMuscles =
      reader
          .readStringList(offsets[7])
          ?.map(
            (e) =>
                _ExerciseEntitysecondaryMusclesValueEnumMap[e] ??
                MuscleGroup.chest,
          )
          .toList() ??
      [];
  object.tempo = reader.readStringOrNull(offsets[8]);
  object.uid = reader.readString(offsets[9]);
  return object;
}

P _exerciseEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_ExerciseEntityequipmentValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              Equipment.cable)
          as P;
    case 1:
      return (reader.readObjectList<StepEmb>(
                offset,
                StepEmbSchema.deserialize,
                allOffsets,
                StepEmb(),
              ) ??
              [])
          as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readObjectOrNull<MetaEmb>(
                offset,
                MetaEmbSchema.deserialize,
                allOffsets,
              ) ??
              MetaEmb())
          as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (_ExerciseEntityprimaryMuscleValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              MuscleGroup.chest)
          as P;
    case 7:
      return (reader
                  .readStringList(offset)
                  ?.map(
                    (e) =>
                        _ExerciseEntitysecondaryMusclesValueEnumMap[e] ??
                        MuscleGroup.chest,
                  )
                  .toList() ??
              [])
          as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ExerciseEntityequipmentEnumValueMap = {
  r'cable': r'cable',
  r'dumbbell': r'dumbbell',
  r'barbell': r'barbell',
  r'machine': r'machine',
  r'bodyweight': r'bodyweight',
};
const _ExerciseEntityequipmentValueEnumMap = {
  r'cable': Equipment.cable,
  r'dumbbell': Equipment.dumbbell,
  r'barbell': Equipment.barbell,
  r'machine': Equipment.machine,
  r'bodyweight': Equipment.bodyweight,
};
const _ExerciseEntityprimaryMuscleEnumValueMap = {
  r'chest': r'chest',
  r'back': r'back',
  r'shoulders': r'shoulders',
  r'biceps': r'biceps',
  r'triceps': r'triceps',
  r'legs': r'legs',
  r'core': r'core',
};
const _ExerciseEntityprimaryMuscleValueEnumMap = {
  r'chest': MuscleGroup.chest,
  r'back': MuscleGroup.back,
  r'shoulders': MuscleGroup.shoulders,
  r'biceps': MuscleGroup.biceps,
  r'triceps': MuscleGroup.triceps,
  r'legs': MuscleGroup.legs,
  r'core': MuscleGroup.core,
};
const _ExerciseEntitysecondaryMusclesEnumValueMap = {
  r'chest': r'chest',
  r'back': r'back',
  r'shoulders': r'shoulders',
  r'biceps': r'biceps',
  r'triceps': r'triceps',
  r'legs': r'legs',
  r'core': r'core',
};
const _ExerciseEntitysecondaryMusclesValueEnumMap = {
  r'chest': MuscleGroup.chest,
  r'back': MuscleGroup.back,
  r'shoulders': MuscleGroup.shoulders,
  r'biceps': MuscleGroup.biceps,
  r'triceps': MuscleGroup.triceps,
  r'legs': MuscleGroup.legs,
  r'core': MuscleGroup.core,
};

Id _exerciseEntityGetId(ExerciseEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _exerciseEntityGetLinks(ExerciseEntity object) {
  return [];
}

void _exerciseEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  ExerciseEntity object,
) {
  object.id = id;
}

extension ExerciseEntityByIndex on IsarCollection<ExerciseEntity> {
  Future<ExerciseEntity?> getByUid(String uid) {
    return getByIndex(r'uid', [uid]);
  }

  ExerciseEntity? getByUidSync(String uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<ExerciseEntity?>> getAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<ExerciseEntity?> getAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(ExerciseEntity object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(ExerciseEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<ExerciseEntity> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(
    List<ExerciseEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension ExerciseEntityQueryWhereSort
    on QueryBuilder<ExerciseEntity, ExerciseEntity, QWhere> {
  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ExerciseEntityQueryWhere
    on QueryBuilder<ExerciseEntity, ExerciseEntity, QWhereClause> {
  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterWhereClause> uidEqualTo(
    String uid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uid', value: [uid]),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterWhereClause> uidNotEqualTo(
    String uid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension ExerciseEntityQueryFilter
    on QueryBuilder<ExerciseEntity, ExerciseEntity, QFilterCondition> {
  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  equipmentEqualTo(Equipment value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'equipment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  equipmentGreaterThan(
    Equipment value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'equipment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  equipmentLessThan(
    Equipment value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'equipment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  equipmentBetween(
    Equipment lower,
    Equipment upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'equipment',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  equipmentStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'equipment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  equipmentEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'equipment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  equipmentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'equipment',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  equipmentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'equipment',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  equipmentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'equipment', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  equipmentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'equipment', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  instructionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'instructions', length, true, length, true);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  instructionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'instructions', 0, true, 0, true);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  instructionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'instructions', 0, false, 999999, true);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  instructionsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'instructions', 0, true, length, include);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  instructionsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'instructions', length, include, 999999, true);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  instructionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'instructions',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  isCustomEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isCustom', value: value),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  movementPatternEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'movementPattern',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  movementPatternGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'movementPattern',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  movementPatternLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'movementPattern',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  movementPatternBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'movementPattern',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  movementPatternStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'movementPattern',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  movementPatternEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'movementPattern',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  movementPatternContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'movementPattern',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  movementPatternMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'movementPattern',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  movementPatternIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'movementPattern', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  movementPatternIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'movementPattern', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  nameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  primaryMuscleEqualTo(MuscleGroup value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'primaryMuscle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  primaryMuscleGreaterThan(
    MuscleGroup value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'primaryMuscle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  primaryMuscleLessThan(
    MuscleGroup value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'primaryMuscle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  primaryMuscleBetween(
    MuscleGroup lower,
    MuscleGroup upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'primaryMuscle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  primaryMuscleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'primaryMuscle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  primaryMuscleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'primaryMuscle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  primaryMuscleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'primaryMuscle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  primaryMuscleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'primaryMuscle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  primaryMuscleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'primaryMuscle', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  primaryMuscleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'primaryMuscle', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesElementEqualTo(
    MuscleGroup value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'secondaryMuscles',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesElementGreaterThan(
    MuscleGroup value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'secondaryMuscles',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesElementLessThan(
    MuscleGroup value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'secondaryMuscles',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesElementBetween(
    MuscleGroup lower,
    MuscleGroup upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'secondaryMuscles',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'secondaryMuscles',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'secondaryMuscles',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'secondaryMuscles',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'secondaryMuscles',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'secondaryMuscles', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'secondaryMuscles', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'secondaryMuscles', length, true, length, true);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'secondaryMuscles', 0, true, 0, true);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'secondaryMuscles', 0, false, 999999, true);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'secondaryMuscles', 0, true, length, include);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'secondaryMuscles',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  secondaryMusclesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'secondaryMuscles',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'tempo'),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'tempo'),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tempo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tempo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tempo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tempo',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tempo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tempo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tempo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tempo',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tempo', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  tempoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tempo', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  uidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  uidLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  uidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }
}

extension ExerciseEntityQueryObject
    on QueryBuilder<ExerciseEntity, ExerciseEntity, QFilterCondition> {
  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition>
  instructionsElement(FilterQuery<StepEmb> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'instructions');
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterFilterCondition> meta(
    FilterQuery<MetaEmb> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'meta');
    });
  }
}

extension ExerciseEntityQueryLinks
    on QueryBuilder<ExerciseEntity, ExerciseEntity, QFilterCondition> {}

extension ExerciseEntityQuerySortBy
    on QueryBuilder<ExerciseEntity, ExerciseEntity, QSortBy> {
  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> sortByEquipment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'equipment', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  sortByEquipmentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'equipment', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> sortByIsCustom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  sortByIsCustomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  sortByMovementPattern() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementPattern', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  sortByMovementPatternDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementPattern', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  sortByPrimaryMuscle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryMuscle', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  sortByPrimaryMuscleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryMuscle', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> sortByTempo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempo', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> sortByTempoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempo', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension ExerciseEntityQuerySortThenBy
    on QueryBuilder<ExerciseEntity, ExerciseEntity, QSortThenBy> {
  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> thenByEquipment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'equipment', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  thenByEquipmentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'equipment', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> thenByIsCustom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  thenByIsCustomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  thenByMovementPattern() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementPattern', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  thenByMovementPatternDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementPattern', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  thenByPrimaryMuscle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryMuscle', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy>
  thenByPrimaryMuscleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryMuscle', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> thenByTempo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempo', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> thenByTempoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempo', Sort.desc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension ExerciseEntityQueryWhereDistinct
    on QueryBuilder<ExerciseEntity, ExerciseEntity, QDistinct> {
  QueryBuilder<ExerciseEntity, ExerciseEntity, QDistinct> distinctByEquipment({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'equipment', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QDistinct> distinctByIsCustom() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCustom');
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QDistinct>
  distinctByMovementPattern({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'movementPattern',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QDistinct>
  distinctByPrimaryMuscle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'primaryMuscle',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QDistinct>
  distinctBySecondaryMuscles() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'secondaryMuscles');
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QDistinct> distinctByTempo({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tempo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExerciseEntity, ExerciseEntity, QDistinct> distinctByUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension ExerciseEntityQueryProperty
    on QueryBuilder<ExerciseEntity, ExerciseEntity, QQueryProperty> {
  QueryBuilder<ExerciseEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ExerciseEntity, Equipment, QQueryOperations>
  equipmentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'equipment');
    });
  }

  QueryBuilder<ExerciseEntity, List<StepEmb>, QQueryOperations>
  instructionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'instructions');
    });
  }

  QueryBuilder<ExerciseEntity, bool, QQueryOperations> isCustomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCustom');
    });
  }

  QueryBuilder<ExerciseEntity, MetaEmb, QQueryOperations> metaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meta');
    });
  }

  QueryBuilder<ExerciseEntity, String, QQueryOperations>
  movementPatternProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'movementPattern');
    });
  }

  QueryBuilder<ExerciseEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<ExerciseEntity, MuscleGroup, QQueryOperations>
  primaryMuscleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primaryMuscle');
    });
  }

  QueryBuilder<ExerciseEntity, List<MuscleGroup>, QQueryOperations>
  secondaryMusclesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secondaryMuscles');
    });
  }

  QueryBuilder<ExerciseEntity, String?, QQueryOperations> tempoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tempo');
    });
  }

  QueryBuilder<ExerciseEntity, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWorkoutEntityCollection on Isar {
  IsarCollection<WorkoutEntity> get workoutEntitys => this.collection();
}

const WorkoutEntitySchema = CollectionSchema(
  name: r'WorkoutEntity',
  id: 2868188222266803158,
  properties: {
    r'cardioFinisher': PropertySchema(
      id: 0,
      name: r'cardioFinisher',
      type: IsarType.object,

      target: r'CardioTargetEmb',
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'exercises': PropertySchema(
      id: 2,
      name: r'exercises',
      type: IsarType.objectList,

      target: r'RoutineExerciseEmb',
    ),
    r'meta': PropertySchema(
      id: 3,
      name: r'meta',
      type: IsarType.object,

      target: r'MetaEmb',
    ),
    r'name': PropertySchema(id: 4, name: r'name', type: IsarType.string),
    r'position': PropertySchema(id: 5, name: r'position', type: IsarType.long),
    r'restSeconds': PropertySchema(
      id: 6,
      name: r'restSeconds',
      type: IsarType.long,
    ),
    r'uid': PropertySchema(id: 7, name: r'uid', type: IsarType.string),
  },

  estimateSize: _workoutEntityEstimateSize,
  serialize: _workoutEntitySerialize,
  deserialize: _workoutEntityDeserialize,
  deserializeProp: _workoutEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {
    r'RoutineExerciseEmb': RoutineExerciseEmbSchema,
    r'CardioTargetEmb': CardioTargetEmbSchema,
    r'MetaEmb': MetaEmbSchema,
  },

  getId: _workoutEntityGetId,
  getLinks: _workoutEntityGetLinks,
  attach: _workoutEntityAttach,
  version: '3.3.2',
);

int _workoutEntityEstimateSize(
  WorkoutEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.cardioFinisher;
    if (value != null) {
      bytesCount +=
          3 +
          CardioTargetEmbSchema.estimateSize(
            value,
            allOffsets[CardioTargetEmb]!,
            allOffsets,
          );
    }
  }
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.exercises.length * 3;
  {
    final offsets = allOffsets[RoutineExerciseEmb]!;
    for (var i = 0; i < object.exercises.length; i++) {
      final value = object.exercises[i];
      bytesCount += RoutineExerciseEmbSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount +=
      3 +
      MetaEmbSchema.estimateSize(object.meta, allOffsets[MetaEmb]!, allOffsets);
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _workoutEntitySerialize(
  WorkoutEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObject<CardioTargetEmb>(
    offsets[0],
    allOffsets,
    CardioTargetEmbSchema.serialize,
    object.cardioFinisher,
  );
  writer.writeString(offsets[1], object.description);
  writer.writeObjectList<RoutineExerciseEmb>(
    offsets[2],
    allOffsets,
    RoutineExerciseEmbSchema.serialize,
    object.exercises,
  );
  writer.writeObject<MetaEmb>(
    offsets[3],
    allOffsets,
    MetaEmbSchema.serialize,
    object.meta,
  );
  writer.writeString(offsets[4], object.name);
  writer.writeLong(offsets[5], object.position);
  writer.writeLong(offsets[6], object.restSeconds);
  writer.writeString(offsets[7], object.uid);
}

WorkoutEntity _workoutEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkoutEntity();
  object.cardioFinisher = reader.readObjectOrNull<CardioTargetEmb>(
    offsets[0],
    CardioTargetEmbSchema.deserialize,
    allOffsets,
  );
  object.description = reader.readString(offsets[1]);
  object.exercises =
      reader.readObjectList<RoutineExerciseEmb>(
        offsets[2],
        RoutineExerciseEmbSchema.deserialize,
        allOffsets,
        RoutineExerciseEmb(),
      ) ??
      [];
  object.id = id;
  object.meta =
      reader.readObjectOrNull<MetaEmb>(
        offsets[3],
        MetaEmbSchema.deserialize,
        allOffsets,
      ) ??
      MetaEmb();
  object.name = reader.readString(offsets[4]);
  object.position = reader.readLong(offsets[5]);
  object.restSeconds = reader.readLong(offsets[6]);
  object.uid = reader.readString(offsets[7]);
  return object;
}

P _workoutEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectOrNull<CardioTargetEmb>(
            offset,
            CardioTargetEmbSchema.deserialize,
            allOffsets,
          ))
          as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readObjectList<RoutineExerciseEmb>(
                offset,
                RoutineExerciseEmbSchema.deserialize,
                allOffsets,
                RoutineExerciseEmb(),
              ) ??
              [])
          as P;
    case 3:
      return (reader.readObjectOrNull<MetaEmb>(
                offset,
                MetaEmbSchema.deserialize,
                allOffsets,
              ) ??
              MetaEmb())
          as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _workoutEntityGetId(WorkoutEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _workoutEntityGetLinks(WorkoutEntity object) {
  return [];
}

void _workoutEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  WorkoutEntity object,
) {
  object.id = id;
}

extension WorkoutEntityByIndex on IsarCollection<WorkoutEntity> {
  Future<WorkoutEntity?> getByUid(String uid) {
    return getByIndex(r'uid', [uid]);
  }

  WorkoutEntity? getByUidSync(String uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<WorkoutEntity?>> getAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<WorkoutEntity?> getAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(WorkoutEntity object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(WorkoutEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<WorkoutEntity> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(
    List<WorkoutEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension WorkoutEntityQueryWhereSort
    on QueryBuilder<WorkoutEntity, WorkoutEntity, QWhere> {
  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WorkoutEntityQueryWhere
    on QueryBuilder<WorkoutEntity, WorkoutEntity, QWhereClause> {
  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterWhereClause> uidEqualTo(
    String uid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uid', value: [uid]),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterWhereClause> uidNotEqualTo(
    String uid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension WorkoutEntityQueryFilter
    on QueryBuilder<WorkoutEntity, WorkoutEntity, QFilterCondition> {
  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  cardioFinisherIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cardioFinisher'),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  cardioFinisherIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cardioFinisher'),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  descriptionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'description',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  descriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  descriptionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'description',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  exercisesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'exercises', length, true, length, true);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  exercisesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'exercises', 0, true, 0, true);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  exercisesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'exercises', 0, false, 999999, true);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  exercisesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'exercises', 0, true, length, include);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  exercisesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'exercises', length, include, 999999, true);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  exercisesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  positionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'position', value: value),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  positionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'position',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  positionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'position',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  positionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'position',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  restSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'restSeconds', value: value),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  restSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'restSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  restSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'restSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  restSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'restSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> uidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> uidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> uidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> uidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }
}

extension WorkoutEntityQueryObject
    on QueryBuilder<WorkoutEntity, WorkoutEntity, QFilterCondition> {
  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  cardioFinisher(FilterQuery<CardioTargetEmb> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'cardioFinisher');
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition>
  exercisesElement(FilterQuery<RoutineExerciseEmb> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'exercises');
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterFilterCondition> meta(
    FilterQuery<MetaEmb> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'meta');
    });
  }
}

extension WorkoutEntityQueryLinks
    on QueryBuilder<WorkoutEntity, WorkoutEntity, QFilterCondition> {}

extension WorkoutEntityQuerySortBy
    on QueryBuilder<WorkoutEntity, WorkoutEntity, QSortBy> {
  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy>
  sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> sortByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy>
  sortByPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.desc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> sortByRestSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restSeconds', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy>
  sortByRestSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restSeconds', Sort.desc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension WorkoutEntityQuerySortThenBy
    on QueryBuilder<WorkoutEntity, WorkoutEntity, QSortThenBy> {
  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy>
  thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> thenByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy>
  thenByPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.desc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> thenByRestSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restSeconds', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy>
  thenByRestSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restSeconds', Sort.desc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension WorkoutEntityQueryWhereDistinct
    on QueryBuilder<WorkoutEntity, WorkoutEntity, QDistinct> {
  QueryBuilder<WorkoutEntity, WorkoutEntity, QDistinct> distinctByDescription({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QDistinct> distinctByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'position');
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QDistinct>
  distinctByRestSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restSeconds');
    });
  }

  QueryBuilder<WorkoutEntity, WorkoutEntity, QDistinct> distinctByUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension WorkoutEntityQueryProperty
    on QueryBuilder<WorkoutEntity, WorkoutEntity, QQueryProperty> {
  QueryBuilder<WorkoutEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WorkoutEntity, CardioTargetEmb?, QQueryOperations>
  cardioFinisherProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cardioFinisher');
    });
  }

  QueryBuilder<WorkoutEntity, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<WorkoutEntity, List<RoutineExerciseEmb>, QQueryOperations>
  exercisesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exercises');
    });
  }

  QueryBuilder<WorkoutEntity, MetaEmb, QQueryOperations> metaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meta');
    });
  }

  QueryBuilder<WorkoutEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<WorkoutEntity, int, QQueryOperations> positionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'position');
    });
  }

  QueryBuilder<WorkoutEntity, int, QQueryOperations> restSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restSeconds');
    });
  }

  QueryBuilder<WorkoutEntity, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRotationEntityCollection on Isar {
  IsarCollection<RotationEntity> get rotationEntitys => this.collection();
}

const RotationEntitySchema = CollectionSchema(
  name: r'RotationEntity',
  id: -8110638176524179973,
  properties: {
    r'currentIndex': PropertySchema(
      id: 0,
      name: r'currentIndex',
      type: IsarType.long,
    ),
    r'workoutIds': PropertySchema(
      id: 1,
      name: r'workoutIds',
      type: IsarType.stringList,
    ),
  },

  estimateSize: _rotationEntityEstimateSize,
  serialize: _rotationEntitySerialize,
  deserialize: _rotationEntityDeserialize,
  deserializeProp: _rotationEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _rotationEntityGetId,
  getLinks: _rotationEntityGetLinks,
  attach: _rotationEntityAttach,
  version: '3.3.2',
);

int _rotationEntityEstimateSize(
  RotationEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.workoutIds.length * 3;
  {
    for (var i = 0; i < object.workoutIds.length; i++) {
      final value = object.workoutIds[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _rotationEntitySerialize(
  RotationEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.currentIndex);
  writer.writeStringList(offsets[1], object.workoutIds);
}

RotationEntity _rotationEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RotationEntity();
  object.currentIndex = reader.readLong(offsets[0]);
  object.id = id;
  object.workoutIds = reader.readStringList(offsets[1]) ?? [];
  return object;
}

P _rotationEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _rotationEntityGetId(RotationEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _rotationEntityGetLinks(RotationEntity object) {
  return [];
}

void _rotationEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  RotationEntity object,
) {
  object.id = id;
}

extension RotationEntityQueryWhereSort
    on QueryBuilder<RotationEntity, RotationEntity, QWhere> {
  QueryBuilder<RotationEntity, RotationEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RotationEntityQueryWhere
    on QueryBuilder<RotationEntity, RotationEntity, QWhereClause> {
  QueryBuilder<RotationEntity, RotationEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension RotationEntityQueryFilter
    on QueryBuilder<RotationEntity, RotationEntity, QFilterCondition> {
  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  currentIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'currentIndex', value: value),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  currentIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currentIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  currentIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currentIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  currentIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currentIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'workoutIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'workoutIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'workoutIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'workoutIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'workoutIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'workoutIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'workoutIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'workoutIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'workoutIds', value: ''),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'workoutIds', value: ''),
      );
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'workoutIds', length, true, length, true);
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'workoutIds', 0, true, 0, true);
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'workoutIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'workoutIds', 0, true, length, include);
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'workoutIds', length, include, 999999, true);
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterFilterCondition>
  workoutIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'workoutIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension RotationEntityQueryObject
    on QueryBuilder<RotationEntity, RotationEntity, QFilterCondition> {}

extension RotationEntityQueryLinks
    on QueryBuilder<RotationEntity, RotationEntity, QFilterCondition> {}

extension RotationEntityQuerySortBy
    on QueryBuilder<RotationEntity, RotationEntity, QSortBy> {
  QueryBuilder<RotationEntity, RotationEntity, QAfterSortBy>
  sortByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.asc);
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterSortBy>
  sortByCurrentIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.desc);
    });
  }
}

extension RotationEntityQuerySortThenBy
    on QueryBuilder<RotationEntity, RotationEntity, QSortThenBy> {
  QueryBuilder<RotationEntity, RotationEntity, QAfterSortBy>
  thenByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.asc);
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterSortBy>
  thenByCurrentIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.desc);
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension RotationEntityQueryWhereDistinct
    on QueryBuilder<RotationEntity, RotationEntity, QDistinct> {
  QueryBuilder<RotationEntity, RotationEntity, QDistinct>
  distinctByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentIndex');
    });
  }

  QueryBuilder<RotationEntity, RotationEntity, QDistinct>
  distinctByWorkoutIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutIds');
    });
  }
}

extension RotationEntityQueryProperty
    on QueryBuilder<RotationEntity, RotationEntity, QQueryProperty> {
  QueryBuilder<RotationEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RotationEntity, int, QQueryOperations> currentIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentIndex');
    });
  }

  QueryBuilder<RotationEntity, List<String>, QQueryOperations>
  workoutIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutIds');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSessionEntityCollection on Isar {
  IsarCollection<SessionEntity> get sessionEntitys => this.collection();
}

const SessionEntitySchema = CollectionSchema(
  name: r'SessionEntity',
  id: 7472964409236372477,
  properties: {
    r'cardio': PropertySchema(
      id: 0,
      name: r'cardio',
      type: IsarType.object,

      target: r'CardioSessionEmb',
    ),
    r'durationSeconds': PropertySchema(
      id: 1,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'exercises': PropertySchema(
      id: 2,
      name: r'exercises',
      type: IsarType.objectList,

      target: r'ExerciseLogEmb',
    ),
    r'meta': PropertySchema(
      id: 3,
      name: r'meta',
      type: IsarType.object,

      target: r'MetaEmb',
    ),
    r'name': PropertySchema(id: 4, name: r'name', type: IsarType.string),
    r'notes': PropertySchema(id: 5, name: r'notes', type: IsarType.string),
    r'uid': PropertySchema(id: 6, name: r'uid', type: IsarType.string),
    r'workoutDate': PropertySchema(
      id: 7,
      name: r'workoutDate',
      type: IsarType.dateTime,
    ),
    r'workoutId': PropertySchema(
      id: 8,
      name: r'workoutId',
      type: IsarType.string,
    ),
  },

  estimateSize: _sessionEntityEstimateSize,
  serialize: _sessionEntitySerialize,
  deserialize: _sessionEntityDeserialize,
  deserializeProp: _sessionEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'workoutDate': IndexSchema(
      id: -5586023166526116543,
      name: r'workoutDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'workoutDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {
    r'ExerciseLogEmb': ExerciseLogEmbSchema,
    r'SetLogEmb': SetLogEmbSchema,
    r'CardioSessionEmb': CardioSessionEmbSchema,
    r'MetaEmb': MetaEmbSchema,
  },

  getId: _sessionEntityGetId,
  getLinks: _sessionEntityGetLinks,
  attach: _sessionEntityAttach,
  version: '3.3.2',
);

int _sessionEntityEstimateSize(
  SessionEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.cardio;
    if (value != null) {
      bytesCount +=
          3 +
          CardioSessionEmbSchema.estimateSize(
            value,
            allOffsets[CardioSessionEmb]!,
            allOffsets,
          );
    }
  }
  bytesCount += 3 + object.exercises.length * 3;
  {
    final offsets = allOffsets[ExerciseLogEmb]!;
    for (var i = 0; i < object.exercises.length; i++) {
      final value = object.exercises[i];
      bytesCount += ExerciseLogEmbSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount +=
      3 +
      MetaEmbSchema.estimateSize(object.meta, allOffsets[MetaEmb]!, allOffsets);
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.notes.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  bytesCount += 3 + object.workoutId.length * 3;
  return bytesCount;
}

void _sessionEntitySerialize(
  SessionEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObject<CardioSessionEmb>(
    offsets[0],
    allOffsets,
    CardioSessionEmbSchema.serialize,
    object.cardio,
  );
  writer.writeLong(offsets[1], object.durationSeconds);
  writer.writeObjectList<ExerciseLogEmb>(
    offsets[2],
    allOffsets,
    ExerciseLogEmbSchema.serialize,
    object.exercises,
  );
  writer.writeObject<MetaEmb>(
    offsets[3],
    allOffsets,
    MetaEmbSchema.serialize,
    object.meta,
  );
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.notes);
  writer.writeString(offsets[6], object.uid);
  writer.writeDateTime(offsets[7], object.workoutDate);
  writer.writeString(offsets[8], object.workoutId);
}

SessionEntity _sessionEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SessionEntity();
  object.cardio = reader.readObjectOrNull<CardioSessionEmb>(
    offsets[0],
    CardioSessionEmbSchema.deserialize,
    allOffsets,
  );
  object.durationSeconds = reader.readLong(offsets[1]);
  object.exercises =
      reader.readObjectList<ExerciseLogEmb>(
        offsets[2],
        ExerciseLogEmbSchema.deserialize,
        allOffsets,
        ExerciseLogEmb(),
      ) ??
      [];
  object.id = id;
  object.meta =
      reader.readObjectOrNull<MetaEmb>(
        offsets[3],
        MetaEmbSchema.deserialize,
        allOffsets,
      ) ??
      MetaEmb();
  object.name = reader.readString(offsets[4]);
  object.notes = reader.readString(offsets[5]);
  object.uid = reader.readString(offsets[6]);
  object.workoutDate = reader.readDateTime(offsets[7]);
  object.workoutId = reader.readString(offsets[8]);
  return object;
}

P _sessionEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectOrNull<CardioSessionEmb>(
            offset,
            CardioSessionEmbSchema.deserialize,
            allOffsets,
          ))
          as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readObjectList<ExerciseLogEmb>(
                offset,
                ExerciseLogEmbSchema.deserialize,
                allOffsets,
                ExerciseLogEmb(),
              ) ??
              [])
          as P;
    case 3:
      return (reader.readObjectOrNull<MetaEmb>(
                offset,
                MetaEmbSchema.deserialize,
                allOffsets,
              ) ??
              MetaEmb())
          as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _sessionEntityGetId(SessionEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _sessionEntityGetLinks(SessionEntity object) {
  return [];
}

void _sessionEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  SessionEntity object,
) {
  object.id = id;
}

extension SessionEntityByIndex on IsarCollection<SessionEntity> {
  Future<SessionEntity?> getByUid(String uid) {
    return getByIndex(r'uid', [uid]);
  }

  SessionEntity? getByUidSync(String uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<SessionEntity?>> getAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<SessionEntity?> getAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(SessionEntity object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(SessionEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<SessionEntity> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(
    List<SessionEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension SessionEntityQueryWhereSort
    on QueryBuilder<SessionEntity, SessionEntity, QWhere> {
  QueryBuilder<SessionEntity, SessionEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhere> anyWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'workoutDate'),
      );
    });
  }
}

extension SessionEntityQueryWhere
    on QueryBuilder<SessionEntity, SessionEntity, QWhereClause> {
  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause> uidEqualTo(
    String uid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uid', value: [uid]),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause> uidNotEqualTo(
    String uid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause>
  workoutDateEqualTo(DateTime workoutDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'workoutDate',
          value: [workoutDate],
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause>
  workoutDateNotEqualTo(DateTime workoutDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'workoutDate',
                lower: [],
                upper: [workoutDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'workoutDate',
                lower: [workoutDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'workoutDate',
                lower: [workoutDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'workoutDate',
                lower: [],
                upper: [workoutDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause>
  workoutDateGreaterThan(DateTime workoutDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'workoutDate',
          lower: [workoutDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause>
  workoutDateLessThan(DateTime workoutDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'workoutDate',
          lower: [],
          upper: [workoutDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterWhereClause>
  workoutDateBetween(
    DateTime lowerWorkoutDate,
    DateTime upperWorkoutDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'workoutDate',
          lower: [lowerWorkoutDate],
          includeLower: includeLower,
          upper: [upperWorkoutDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SessionEntityQueryFilter
    on QueryBuilder<SessionEntity, SessionEntity, QFilterCondition> {
  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  cardioIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cardio'),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  cardioIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cardio'),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  durationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'durationSeconds', value: value),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  durationSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'durationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  durationSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'durationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  durationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'durationSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  exercisesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'exercises', length, true, length, true);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  exercisesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'exercises', 0, true, 0, true);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  exercisesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'exercises', 0, false, 999999, true);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  exercisesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'exercises', 0, true, length, include);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  exercisesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'exercises', length, include, 999999, true);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  exercisesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  notesEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  notesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  notesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  notesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  notesStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  notesEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'notes',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> uidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> uidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> uidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> uidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'workoutDate', value: value),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'workoutDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'workoutDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'workoutDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'workoutId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'workoutId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'workoutId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'workoutId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'workoutId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'workoutId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'workoutId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'workoutId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'workoutId', value: ''),
      );
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  workoutIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'workoutId', value: ''),
      );
    });
  }
}

extension SessionEntityQueryObject
    on QueryBuilder<SessionEntity, SessionEntity, QFilterCondition> {
  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> cardio(
    FilterQuery<CardioSessionEmb> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'cardio');
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition>
  exercisesElement(FilterQuery<ExerciseLogEmb> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'exercises');
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterFilterCondition> meta(
    FilterQuery<MetaEmb> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'meta');
    });
  }
}

extension SessionEntityQueryLinks
    on QueryBuilder<SessionEntity, SessionEntity, QFilterCondition> {}

extension SessionEntityQuerySortBy
    on QueryBuilder<SessionEntity, SessionEntity, QSortBy> {
  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy>
  sortByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy>
  sortByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> sortByWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy>
  sortByWorkoutDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> sortByWorkoutId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutId', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy>
  sortByWorkoutIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutId', Sort.desc);
    });
  }
}

extension SessionEntityQuerySortThenBy
    on QueryBuilder<SessionEntity, SessionEntity, QSortThenBy> {
  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy>
  thenByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy>
  thenByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> thenByWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy>
  thenByWorkoutDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.desc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy> thenByWorkoutId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutId', Sort.asc);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QAfterSortBy>
  thenByWorkoutIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutId', Sort.desc);
    });
  }
}

extension SessionEntityQueryWhereDistinct
    on QueryBuilder<SessionEntity, SessionEntity, QDistinct> {
  QueryBuilder<SessionEntity, SessionEntity, QDistinct>
  distinctByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationSeconds');
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QDistinct> distinctByNotes({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QDistinct> distinctByUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QDistinct>
  distinctByWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutDate');
    });
  }

  QueryBuilder<SessionEntity, SessionEntity, QDistinct> distinctByWorkoutId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutId', caseSensitive: caseSensitive);
    });
  }
}

extension SessionEntityQueryProperty
    on QueryBuilder<SessionEntity, SessionEntity, QQueryProperty> {
  QueryBuilder<SessionEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SessionEntity, CardioSessionEmb?, QQueryOperations>
  cardioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cardio');
    });
  }

  QueryBuilder<SessionEntity, int, QQueryOperations> durationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationSeconds');
    });
  }

  QueryBuilder<SessionEntity, List<ExerciseLogEmb>, QQueryOperations>
  exercisesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exercises');
    });
  }

  QueryBuilder<SessionEntity, MetaEmb, QQueryOperations> metaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meta');
    });
  }

  QueryBuilder<SessionEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<SessionEntity, String, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<SessionEntity, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<SessionEntity, DateTime, QQueryOperations>
  workoutDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutDate');
    });
  }

  QueryBuilder<SessionEntity, String, QQueryOperations> workoutIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCardioSessionEntityCollection on Isar {
  IsarCollection<CardioSessionEntity> get cardioSessionEntitys =>
      this.collection();
}

const CardioSessionEntitySchema = CollectionSchema(
  name: r'CardioSessionEntity',
  id: 2470310766889421116,
  properties: {
    r'data': PropertySchema(
      id: 0,
      name: r'data',
      type: IsarType.object,

      target: r'CardioSessionEmb',
    ),
    r'uid': PropertySchema(id: 1, name: r'uid', type: IsarType.string),
    r'workoutDate': PropertySchema(
      id: 2,
      name: r'workoutDate',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _cardioSessionEntityEstimateSize,
  serialize: _cardioSessionEntitySerialize,
  deserialize: _cardioSessionEntityDeserialize,
  deserializeProp: _cardioSessionEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'workoutDate': IndexSchema(
      id: -5586023166526116543,
      name: r'workoutDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'workoutDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {
    r'CardioSessionEmb': CardioSessionEmbSchema,
    r'MetaEmb': MetaEmbSchema,
  },

  getId: _cardioSessionEntityGetId,
  getLinks: _cardioSessionEntityGetLinks,
  attach: _cardioSessionEntityAttach,
  version: '3.3.2',
);

int _cardioSessionEntityEstimateSize(
  CardioSessionEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount +=
      3 +
      CardioSessionEmbSchema.estimateSize(
        object.data,
        allOffsets[CardioSessionEmb]!,
        allOffsets,
      );
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _cardioSessionEntitySerialize(
  CardioSessionEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObject<CardioSessionEmb>(
    offsets[0],
    allOffsets,
    CardioSessionEmbSchema.serialize,
    object.data,
  );
  writer.writeString(offsets[1], object.uid);
  writer.writeDateTime(offsets[2], object.workoutDate);
}

CardioSessionEntity _cardioSessionEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CardioSessionEntity();
  object.data =
      reader.readObjectOrNull<CardioSessionEmb>(
        offsets[0],
        CardioSessionEmbSchema.deserialize,
        allOffsets,
      ) ??
      CardioSessionEmb();
  object.id = id;
  object.uid = reader.readString(offsets[1]);
  object.workoutDate = reader.readDateTime(offsets[2]);
  return object;
}

P _cardioSessionEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectOrNull<CardioSessionEmb>(
                offset,
                CardioSessionEmbSchema.deserialize,
                allOffsets,
              ) ??
              CardioSessionEmb())
          as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cardioSessionEntityGetId(CardioSessionEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cardioSessionEntityGetLinks(
  CardioSessionEntity object,
) {
  return [];
}

void _cardioSessionEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  CardioSessionEntity object,
) {
  object.id = id;
}

extension CardioSessionEntityByIndex on IsarCollection<CardioSessionEntity> {
  Future<CardioSessionEntity?> getByUid(String uid) {
    return getByIndex(r'uid', [uid]);
  }

  CardioSessionEntity? getByUidSync(String uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<CardioSessionEntity?>> getAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<CardioSessionEntity?> getAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(CardioSessionEntity object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(CardioSessionEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<CardioSessionEntity> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(
    List<CardioSessionEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension CardioSessionEntityQueryWhereSort
    on QueryBuilder<CardioSessionEntity, CardioSessionEntity, QWhere> {
  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhere>
  anyWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'workoutDate'),
      );
    });
  }
}

extension CardioSessionEntityQueryWhere
    on QueryBuilder<CardioSessionEntity, CardioSessionEntity, QWhereClause> {
  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  uidEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uid', value: [uid]),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  uidNotEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  workoutDateEqualTo(DateTime workoutDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'workoutDate',
          value: [workoutDate],
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  workoutDateNotEqualTo(DateTime workoutDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'workoutDate',
                lower: [],
                upper: [workoutDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'workoutDate',
                lower: [workoutDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'workoutDate',
                lower: [workoutDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'workoutDate',
                lower: [],
                upper: [workoutDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  workoutDateGreaterThan(DateTime workoutDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'workoutDate',
          lower: [workoutDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  workoutDateLessThan(DateTime workoutDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'workoutDate',
          lower: [],
          upper: [workoutDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterWhereClause>
  workoutDateBetween(
    DateTime lowerWorkoutDate,
    DateTime upperWorkoutDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'workoutDate',
          lower: [lowerWorkoutDate],
          includeLower: includeLower,
          upper: [upperWorkoutDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CardioSessionEntityQueryFilter
    on
        QueryBuilder<
          CardioSessionEntity,
          CardioSessionEntity,
          QFilterCondition
        > {
  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  uidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  uidLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  uidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  workoutDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'workoutDate', value: value),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  workoutDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'workoutDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  workoutDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'workoutDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  workoutDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'workoutDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CardioSessionEntityQueryObject
    on
        QueryBuilder<
          CardioSessionEntity,
          CardioSessionEntity,
          QFilterCondition
        > {
  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterFilterCondition>
  data(FilterQuery<CardioSessionEmb> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'data');
    });
  }
}

extension CardioSessionEntityQueryLinks
    on
        QueryBuilder<
          CardioSessionEntity,
          CardioSessionEntity,
          QFilterCondition
        > {}

extension CardioSessionEntityQuerySortBy
    on QueryBuilder<CardioSessionEntity, CardioSessionEntity, QSortBy> {
  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterSortBy>
  sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterSortBy>
  sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterSortBy>
  sortByWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.asc);
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterSortBy>
  sortByWorkoutDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.desc);
    });
  }
}

extension CardioSessionEntityQuerySortThenBy
    on QueryBuilder<CardioSessionEntity, CardioSessionEntity, QSortThenBy> {
  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterSortBy>
  thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterSortBy>
  thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterSortBy>
  thenByWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.asc);
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QAfterSortBy>
  thenByWorkoutDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDate', Sort.desc);
    });
  }
}

extension CardioSessionEntityQueryWhereDistinct
    on QueryBuilder<CardioSessionEntity, CardioSessionEntity, QDistinct> {
  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QDistinct>
  distinctByUid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEntity, QDistinct>
  distinctByWorkoutDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutDate');
    });
  }
}

extension CardioSessionEntityQueryProperty
    on QueryBuilder<CardioSessionEntity, CardioSessionEntity, QQueryProperty> {
  QueryBuilder<CardioSessionEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CardioSessionEntity, CardioSessionEmb, QQueryOperations>
  dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'data');
    });
  }

  QueryBuilder<CardioSessionEntity, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<CardioSessionEntity, DateTime, QQueryOperations>
  workoutDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutDate');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCardioGoalEntityCollection on Isar {
  IsarCollection<CardioGoalEntity> get cardioGoalEntitys => this.collection();
}

const CardioGoalEntitySchema = CollectionSchema(
  name: r'CardioGoalEntity',
  id: -2490669604554985934,
  properties: {
    r'isPrimary': PropertySchema(
      id: 0,
      name: r'isPrimary',
      type: IsarType.bool,
    ),
    r'meta': PropertySchema(
      id: 1,
      name: r'meta',
      type: IsarType.object,

      target: r'MetaEmb',
    ),
    r'metric': PropertySchema(
      id: 2,
      name: r'metric',
      type: IsarType.string,
      enumMap: _CardioGoalEntitymetricEnumValueMap,
    ),
    r'period': PropertySchema(
      id: 3,
      name: r'period',
      type: IsarType.string,
      enumMap: _CardioGoalEntityperiodEnumValueMap,
    ),
    r'target': PropertySchema(id: 4, name: r'target', type: IsarType.double),
    r'title': PropertySchema(id: 5, name: r'title', type: IsarType.string),
    r'uid': PropertySchema(id: 6, name: r'uid', type: IsarType.string),
  },

  estimateSize: _cardioGoalEntityEstimateSize,
  serialize: _cardioGoalEntitySerialize,
  deserialize: _cardioGoalEntityDeserialize,
  deserializeProp: _cardioGoalEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {r'MetaEmb': MetaEmbSchema},

  getId: _cardioGoalEntityGetId,
  getLinks: _cardioGoalEntityGetLinks,
  attach: _cardioGoalEntityAttach,
  version: '3.3.2',
);

int _cardioGoalEntityEstimateSize(
  CardioGoalEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount +=
      3 +
      MetaEmbSchema.estimateSize(object.meta, allOffsets[MetaEmb]!, allOffsets);
  bytesCount += 3 + object.metric.name.length * 3;
  bytesCount += 3 + object.period.name.length * 3;
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _cardioGoalEntitySerialize(
  CardioGoalEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isPrimary);
  writer.writeObject<MetaEmb>(
    offsets[1],
    allOffsets,
    MetaEmbSchema.serialize,
    object.meta,
  );
  writer.writeString(offsets[2], object.metric.name);
  writer.writeString(offsets[3], object.period.name);
  writer.writeDouble(offsets[4], object.target);
  writer.writeString(offsets[5], object.title);
  writer.writeString(offsets[6], object.uid);
}

CardioGoalEntity _cardioGoalEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CardioGoalEntity();
  object.id = id;
  object.isPrimary = reader.readBool(offsets[0]);
  object.meta =
      reader.readObjectOrNull<MetaEmb>(
        offsets[1],
        MetaEmbSchema.deserialize,
        allOffsets,
      ) ??
      MetaEmb();
  object.metric =
      _CardioGoalEntitymetricValueEnumMap[reader.readStringOrNull(
        offsets[2],
      )] ??
      GoalMetric.durationMinutes;
  object.period =
      _CardioGoalEntityperiodValueEnumMap[reader.readStringOrNull(
        offsets[3],
      )] ??
      GoalPeriod.week;
  object.target = reader.readDouble(offsets[4]);
  object.title = reader.readString(offsets[5]);
  object.uid = reader.readString(offsets[6]);
  return object;
}

P _cardioGoalEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readObjectOrNull<MetaEmb>(
                offset,
                MetaEmbSchema.deserialize,
                allOffsets,
              ) ??
              MetaEmb())
          as P;
    case 2:
      return (_CardioGoalEntitymetricValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              GoalMetric.durationMinutes)
          as P;
    case 3:
      return (_CardioGoalEntityperiodValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              GoalPeriod.week)
          as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CardioGoalEntitymetricEnumValueMap = {
  r'durationMinutes': r'durationMinutes',
  r'distanceKm': r'distanceKm',
  r'sessions': r'sessions',
  r'calories': r'calories',
};
const _CardioGoalEntitymetricValueEnumMap = {
  r'durationMinutes': GoalMetric.durationMinutes,
  r'distanceKm': GoalMetric.distanceKm,
  r'sessions': GoalMetric.sessions,
  r'calories': GoalMetric.calories,
};
const _CardioGoalEntityperiodEnumValueMap = {
  r'week': r'week',
  r'month': r'month',
};
const _CardioGoalEntityperiodValueEnumMap = {
  r'week': GoalPeriod.week,
  r'month': GoalPeriod.month,
};

Id _cardioGoalEntityGetId(CardioGoalEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cardioGoalEntityGetLinks(CardioGoalEntity object) {
  return [];
}

void _cardioGoalEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  CardioGoalEntity object,
) {
  object.id = id;
}

extension CardioGoalEntityByIndex on IsarCollection<CardioGoalEntity> {
  Future<CardioGoalEntity?> getByUid(String uid) {
    return getByIndex(r'uid', [uid]);
  }

  CardioGoalEntity? getByUidSync(String uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<CardioGoalEntity?>> getAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<CardioGoalEntity?> getAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(CardioGoalEntity object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(CardioGoalEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<CardioGoalEntity> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(
    List<CardioGoalEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension CardioGoalEntityQueryWhereSort
    on QueryBuilder<CardioGoalEntity, CardioGoalEntity, QWhere> {
  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CardioGoalEntityQueryWhere
    on QueryBuilder<CardioGoalEntity, CardioGoalEntity, QWhereClause> {
  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterWhereClause>
  uidEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uid', value: [uid]),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterWhereClause>
  uidNotEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension CardioGoalEntityQueryFilter
    on QueryBuilder<CardioGoalEntity, CardioGoalEntity, QFilterCondition> {
  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  isPrimaryEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isPrimary', value: value),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  metricEqualTo(GoalMetric value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'metric',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  metricGreaterThan(
    GoalMetric value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'metric',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  metricLessThan(
    GoalMetric value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'metric',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  metricBetween(
    GoalMetric lower,
    GoalMetric upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'metric',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  metricStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'metric',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  metricEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'metric',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  metricContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'metric',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  metricMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'metric',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  metricIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'metric', value: ''),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  metricIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'metric', value: ''),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  periodEqualTo(GoalPeriod value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'period',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  periodGreaterThan(
    GoalPeriod value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'period',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  periodLessThan(
    GoalPeriod value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'period',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  periodBetween(
    GoalPeriod lower,
    GoalPeriod upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'period',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  periodStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'period',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  periodEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'period',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  periodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'period',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  periodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'period',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  periodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'period', value: ''),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  periodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'period', value: ''),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  targetEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'target',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  targetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'target',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  targetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'target',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  targetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'target',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  uidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  uidLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  uidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }
}

extension CardioGoalEntityQueryObject
    on QueryBuilder<CardioGoalEntity, CardioGoalEntity, QFilterCondition> {
  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterFilterCondition> meta(
    FilterQuery<MetaEmb> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'meta');
    });
  }
}

extension CardioGoalEntityQueryLinks
    on QueryBuilder<CardioGoalEntity, CardioGoalEntity, QFilterCondition> {}

extension CardioGoalEntityQuerySortBy
    on QueryBuilder<CardioGoalEntity, CardioGoalEntity, QSortBy> {
  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  sortByIsPrimary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPrimary', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  sortByIsPrimaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPrimary', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  sortByMetric() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metric', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  sortByMetricDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metric', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  sortByPeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  sortByPeriodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  sortByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  sortByTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension CardioGoalEntityQuerySortThenBy
    on QueryBuilder<CardioGoalEntity, CardioGoalEntity, QSortThenBy> {
  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByIsPrimary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPrimary', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByIsPrimaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPrimary', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByMetric() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metric', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByMetricDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metric', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByPeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByPeriodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QAfterSortBy>
  thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension CardioGoalEntityQueryWhereDistinct
    on QueryBuilder<CardioGoalEntity, CardioGoalEntity, QDistinct> {
  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QDistinct>
  distinctByIsPrimary() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPrimary');
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QDistinct> distinctByMetric({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metric', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QDistinct> distinctByPeriod({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'period', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QDistinct>
  distinctByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'target');
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardioGoalEntity, CardioGoalEntity, QDistinct> distinctByUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension CardioGoalEntityQueryProperty
    on QueryBuilder<CardioGoalEntity, CardioGoalEntity, QQueryProperty> {
  QueryBuilder<CardioGoalEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CardioGoalEntity, bool, QQueryOperations> isPrimaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPrimary');
    });
  }

  QueryBuilder<CardioGoalEntity, MetaEmb, QQueryOperations> metaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meta');
    });
  }

  QueryBuilder<CardioGoalEntity, GoalMetric, QQueryOperations>
  metricProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metric');
    });
  }

  QueryBuilder<CardioGoalEntity, GoalPeriod, QQueryOperations>
  periodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'period');
    });
  }

  QueryBuilder<CardioGoalEntity, double, QQueryOperations> targetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'target');
    });
  }

  QueryBuilder<CardioGoalEntity, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<CardioGoalEntity, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomActivityEntityCollection on Isar {
  IsarCollection<CustomActivityEntity> get customActivityEntitys =>
      this.collection();
}

const CustomActivityEntitySchema = CollectionSchema(
  name: r'CustomActivityEntity',
  id: -2606902004025751304,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'fields': PropertySchema(
      id: 1,
      name: r'fields',
      type: IsarType.stringList,
      enumMap: _CustomActivityEntityfieldsEnumValueMap,
    ),
    r'iconKey': PropertySchema(id: 2, name: r'iconKey', type: IsarType.string),
    r'meta': PropertySchema(
      id: 3,
      name: r'meta',
      type: IsarType.object,

      target: r'MetaEmb',
    ),
    r'name': PropertySchema(id: 4, name: r'name', type: IsarType.string),
    r'restSeconds': PropertySchema(
      id: 5,
      name: r'restSeconds',
      type: IsarType.long,
    ),
    r'roundSeconds': PropertySchema(
      id: 6,
      name: r'roundSeconds',
      type: IsarType.long,
    ),
    r'rounds': PropertySchema(id: 7, name: r'rounds', type: IsarType.long),
    r'uid': PropertySchema(id: 8, name: r'uid', type: IsarType.string),
  },

  estimateSize: _customActivityEntityEstimateSize,
  serialize: _customActivityEntitySerialize,
  deserialize: _customActivityEntityDeserialize,
  deserializeProp: _customActivityEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {r'MetaEmb': MetaEmbSchema},

  getId: _customActivityEntityGetId,
  getLinks: _customActivityEntityGetLinks,
  attach: _customActivityEntityAttach,
  version: '3.3.2',
);

int _customActivityEntityEstimateSize(
  CustomActivityEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.fields.length * 3;
  {
    for (var i = 0; i < object.fields.length; i++) {
      final value = object.fields[i];
      bytesCount += value.name.length * 3;
    }
  }
  bytesCount += 3 + object.iconKey.length * 3;
  bytesCount +=
      3 +
      MetaEmbSchema.estimateSize(object.meta, allOffsets[MetaEmb]!, allOffsets);
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _customActivityEntitySerialize(
  CustomActivityEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeStringList(offsets[1], object.fields.map((e) => e.name).toList());
  writer.writeString(offsets[2], object.iconKey);
  writer.writeObject<MetaEmb>(
    offsets[3],
    allOffsets,
    MetaEmbSchema.serialize,
    object.meta,
  );
  writer.writeString(offsets[4], object.name);
  writer.writeLong(offsets[5], object.restSeconds);
  writer.writeLong(offsets[6], object.roundSeconds);
  writer.writeLong(offsets[7], object.rounds);
  writer.writeString(offsets[8], object.uid);
}

CustomActivityEntity _customActivityEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomActivityEntity();
  object.category = reader.readString(offsets[0]);
  object.fields =
      reader
          .readStringList(offsets[1])
          ?.map(
            (e) =>
                _CustomActivityEntityfieldsValueEnumMap[e] ??
                CardioField.duration,
          )
          .toList() ??
      [];
  object.iconKey = reader.readString(offsets[2]);
  object.id = id;
  object.meta =
      reader.readObjectOrNull<MetaEmb>(
        offsets[3],
        MetaEmbSchema.deserialize,
        allOffsets,
      ) ??
      MetaEmb();
  object.name = reader.readString(offsets[4]);
  object.restSeconds = reader.readLongOrNull(offsets[5]);
  object.roundSeconds = reader.readLongOrNull(offsets[6]);
  object.rounds = reader.readLongOrNull(offsets[7]);
  object.uid = reader.readString(offsets[8]);
  return object;
}

P _customActivityEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader
                  .readStringList(offset)
                  ?.map(
                    (e) =>
                        _CustomActivityEntityfieldsValueEnumMap[e] ??
                        CardioField.duration,
                  )
                  .toList() ??
              [])
          as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readObjectOrNull<MetaEmb>(
                offset,
                MetaEmbSchema.deserialize,
                allOffsets,
              ) ??
              MetaEmb())
          as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CustomActivityEntityfieldsEnumValueMap = {
  r'duration': r'duration',
  r'distance': r'distance',
  r'pace': r'pace',
  r'speed': r'speed',
  r'incline': r'incline',
  r'resistance': r'resistance',
  r'calories': r'calories',
  r'heartRate': r'heartRate',
  r'rpe': r'rpe',
};
const _CustomActivityEntityfieldsValueEnumMap = {
  r'duration': CardioField.duration,
  r'distance': CardioField.distance,
  r'pace': CardioField.pace,
  r'speed': CardioField.speed,
  r'incline': CardioField.incline,
  r'resistance': CardioField.resistance,
  r'calories': CardioField.calories,
  r'heartRate': CardioField.heartRate,
  r'rpe': CardioField.rpe,
};

Id _customActivityEntityGetId(CustomActivityEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _customActivityEntityGetLinks(
  CustomActivityEntity object,
) {
  return [];
}

void _customActivityEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  CustomActivityEntity object,
) {
  object.id = id;
}

extension CustomActivityEntityByIndex on IsarCollection<CustomActivityEntity> {
  Future<CustomActivityEntity?> getByUid(String uid) {
    return getByIndex(r'uid', [uid]);
  }

  CustomActivityEntity? getByUidSync(String uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<CustomActivityEntity?>> getAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<CustomActivityEntity?> getAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(CustomActivityEntity object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(CustomActivityEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<CustomActivityEntity> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(
    List<CustomActivityEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension CustomActivityEntityQueryWhereSort
    on QueryBuilder<CustomActivityEntity, CustomActivityEntity, QWhere> {
  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CustomActivityEntityQueryWhere
    on QueryBuilder<CustomActivityEntity, CustomActivityEntity, QWhereClause> {
  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterWhereClause>
  uidEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uid', value: [uid]),
      );
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterWhereClause>
  uidNotEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension CustomActivityEntityQueryFilter
    on
        QueryBuilder<
          CustomActivityEntity,
          CustomActivityEntity,
          QFilterCondition
        > {
  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  categoryEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  categoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  categoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'category',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsElementEqualTo(CardioField value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fields',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsElementGreaterThan(
    CardioField value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fields',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsElementLessThan(
    CardioField value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fields',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsElementBetween(
    CardioField lower,
    CardioField upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fields',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fields',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fields',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fields',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fields',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fields', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fields', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fields', length, true, length, true);
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fields', 0, true, 0, true);
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fields', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fields', 0, true, length, include);
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fields', length, include, 999999, true);
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  fieldsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fields',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  iconKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'iconKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  iconKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'iconKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  iconKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'iconKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  iconKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'iconKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  iconKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'iconKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  iconKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'iconKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  iconKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'iconKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  iconKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'iconKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  iconKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'iconKey', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  iconKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'iconKey', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  nameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  restSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'restSeconds'),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  restSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'restSeconds'),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  restSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'restSeconds', value: value),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  restSecondsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'restSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  restSecondsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'restSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  restSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'restSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'roundSeconds'),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'roundSeconds'),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'roundSeconds', value: value),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundSecondsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'roundSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundSecondsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'roundSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'roundSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'rounds'),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'rounds'),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rounds', value: value),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rounds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rounds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  roundsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rounds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  uidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  uidLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  uidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }
}

extension CustomActivityEntityQueryObject
    on
        QueryBuilder<
          CustomActivityEntity,
          CustomActivityEntity,
          QFilterCondition
        > {
  QueryBuilder<
    CustomActivityEntity,
    CustomActivityEntity,
    QAfterFilterCondition
  >
  meta(FilterQuery<MetaEmb> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'meta');
    });
  }
}

extension CustomActivityEntityQueryLinks
    on
        QueryBuilder<
          CustomActivityEntity,
          CustomActivityEntity,
          QFilterCondition
        > {}

extension CustomActivityEntityQuerySortBy
    on QueryBuilder<CustomActivityEntity, CustomActivityEntity, QSortBy> {
  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByIconKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconKey', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByIconKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconKey', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByRestSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restSeconds', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByRestSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restSeconds', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByRoundSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundSeconds', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByRoundSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundSeconds', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByRounds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rounds', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByRoundsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rounds', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension CustomActivityEntityQuerySortThenBy
    on QueryBuilder<CustomActivityEntity, CustomActivityEntity, QSortThenBy> {
  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByIconKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconKey', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByIconKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconKey', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByRestSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restSeconds', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByRestSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restSeconds', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByRoundSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundSeconds', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByRoundSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundSeconds', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByRounds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rounds', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByRoundsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rounds', Sort.desc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QAfterSortBy>
  thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension CustomActivityEntityQueryWhereDistinct
    on QueryBuilder<CustomActivityEntity, CustomActivityEntity, QDistinct> {
  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QDistinct>
  distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QDistinct>
  distinctByFields() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fields');
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QDistinct>
  distinctByIconKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QDistinct>
  distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QDistinct>
  distinctByRestSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restSeconds');
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QDistinct>
  distinctByRoundSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'roundSeconds');
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QDistinct>
  distinctByRounds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rounds');
    });
  }

  QueryBuilder<CustomActivityEntity, CustomActivityEntity, QDistinct>
  distinctByUid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension CustomActivityEntityQueryProperty
    on
        QueryBuilder<
          CustomActivityEntity,
          CustomActivityEntity,
          QQueryProperty
        > {
  QueryBuilder<CustomActivityEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CustomActivityEntity, String, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<CustomActivityEntity, List<CardioField>, QQueryOperations>
  fieldsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fields');
    });
  }

  QueryBuilder<CustomActivityEntity, String, QQueryOperations>
  iconKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconKey');
    });
  }

  QueryBuilder<CustomActivityEntity, MetaEmb, QQueryOperations> metaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meta');
    });
  }

  QueryBuilder<CustomActivityEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CustomActivityEntity, int?, QQueryOperations>
  restSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restSeconds');
    });
  }

  QueryBuilder<CustomActivityEntity, int?, QQueryOperations>
  roundSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'roundSeconds');
    });
  }

  QueryBuilder<CustomActivityEntity, int?, QQueryOperations> roundsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rounds');
    });
  }

  QueryBuilder<CustomActivityEntity, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProfileEntityCollection on Isar {
  IsarCollection<ProfileEntity> get profileEntitys => this.collection();
}

const ProfileEntitySchema = CollectionSchema(
  name: r'ProfileEntity',
  id: 2239510315175863988,
  properties: {
    r'age': PropertySchema(id: 0, name: r'age', type: IsarType.long),
    r'autoRestSeconds': PropertySchema(
      id: 1,
      name: r'autoRestSeconds',
      type: IsarType.long,
    ),
    r'cardioDistanceUnitKm': PropertySchema(
      id: 2,
      name: r'cardioDistanceUnitKm',
      type: IsarType.bool,
    ),
    r'defaultRepMax': PropertySchema(
      id: 3,
      name: r'defaultRepMax',
      type: IsarType.long,
    ),
    r'defaultRepMin': PropertySchema(
      id: 4,
      name: r'defaultRepMin',
      type: IsarType.long,
    ),
    r'defaultSets': PropertySchema(
      id: 5,
      name: r'defaultSets',
      type: IsarType.long,
    ),
    r'email': PropertySchema(id: 6, name: r'email', type: IsarType.string),
    r'heightCm': PropertySchema(
      id: 7,
      name: r'heightCm',
      type: IsarType.double,
    ),
    r'isGuest': PropertySchema(id: 8, name: r'isGuest', type: IsarType.bool),
    r'name': PropertySchema(id: 9, name: r'name', type: IsarType.string),
    r'progressionEnabled': PropertySchema(
      id: 10,
      name: r'progressionEnabled',
      type: IsarType.bool,
    ),
    r'themeMode': PropertySchema(
      id: 11,
      name: r'themeMode',
      type: IsarType.string,
      enumMap: _ProfileEntitythemeModeEnumValueMap,
    ),
    r'unit': PropertySchema(
      id: 12,
      name: r'unit',
      type: IsarType.string,
      enumMap: _ProfileEntityunitEnumValueMap,
    ),
    r'weeklySessionTarget': PropertySchema(
      id: 13,
      name: r'weeklySessionTarget',
      type: IsarType.long,
    ),
    r'weightKg': PropertySchema(
      id: 14,
      name: r'weightKg',
      type: IsarType.double,
    ),
  },

  estimateSize: _profileEntityEstimateSize,
  serialize: _profileEntitySerialize,
  deserialize: _profileEntityDeserialize,
  deserializeProp: _profileEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _profileEntityGetId,
  getLinks: _profileEntityGetLinks,
  attach: _profileEntityAttach,
  version: '3.3.2',
);

int _profileEntityEstimateSize(
  ProfileEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.email.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.themeMode.name.length * 3;
  bytesCount += 3 + object.unit.name.length * 3;
  return bytesCount;
}

void _profileEntitySerialize(
  ProfileEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.age);
  writer.writeLong(offsets[1], object.autoRestSeconds);
  writer.writeBool(offsets[2], object.cardioDistanceUnitKm);
  writer.writeLong(offsets[3], object.defaultRepMax);
  writer.writeLong(offsets[4], object.defaultRepMin);
  writer.writeLong(offsets[5], object.defaultSets);
  writer.writeString(offsets[6], object.email);
  writer.writeDouble(offsets[7], object.heightCm);
  writer.writeBool(offsets[8], object.isGuest);
  writer.writeString(offsets[9], object.name);
  writer.writeBool(offsets[10], object.progressionEnabled);
  writer.writeString(offsets[11], object.themeMode.name);
  writer.writeString(offsets[12], object.unit.name);
  writer.writeLong(offsets[13], object.weeklySessionTarget);
  writer.writeDouble(offsets[14], object.weightKg);
}

ProfileEntity _profileEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProfileEntity();
  object.age = reader.readLong(offsets[0]);
  object.autoRestSeconds = reader.readLong(offsets[1]);
  object.cardioDistanceUnitKm = reader.readBool(offsets[2]);
  object.defaultRepMax = reader.readLong(offsets[3]);
  object.defaultRepMin = reader.readLong(offsets[4]);
  object.defaultSets = reader.readLong(offsets[5]);
  object.email = reader.readString(offsets[6]);
  object.heightCm = reader.readDouble(offsets[7]);
  object.id = id;
  object.isGuest = reader.readBool(offsets[8]);
  object.name = reader.readString(offsets[9]);
  object.progressionEnabled = reader.readBool(offsets[10]);
  object.themeMode =
      _ProfileEntitythemeModeValueEnumMap[reader.readStringOrNull(
        offsets[11],
      )] ??
      SxThemeMode.dark;
  object.unit =
      _ProfileEntityunitValueEnumMap[reader.readStringOrNull(offsets[12])] ??
      WeightUnit.kg;
  object.weeklySessionTarget = reader.readLong(offsets[13]);
  object.weightKg = reader.readDouble(offsets[14]);
  return object;
}

P _profileEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (_ProfileEntitythemeModeValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              SxThemeMode.dark)
          as P;
    case 12:
      return (_ProfileEntityunitValueEnumMap[reader.readStringOrNull(offset)] ??
              WeightUnit.kg)
          as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ProfileEntitythemeModeEnumValueMap = {
  r'dark': r'dark',
  r'oled': r'oled',
  r'system': r'system',
};
const _ProfileEntitythemeModeValueEnumMap = {
  r'dark': SxThemeMode.dark,
  r'oled': SxThemeMode.oled,
  r'system': SxThemeMode.system,
};
const _ProfileEntityunitEnumValueMap = {r'kg': r'kg', r'lb': r'lb'};
const _ProfileEntityunitValueEnumMap = {
  r'kg': WeightUnit.kg,
  r'lb': WeightUnit.lb,
};

Id _profileEntityGetId(ProfileEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _profileEntityGetLinks(ProfileEntity object) {
  return [];
}

void _profileEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  ProfileEntity object,
) {
  object.id = id;
}

extension ProfileEntityQueryWhereSort
    on QueryBuilder<ProfileEntity, ProfileEntity, QWhere> {
  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProfileEntityQueryWhere
    on QueryBuilder<ProfileEntity, ProfileEntity, QWhereClause> {
  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ProfileEntityQueryFilter
    on QueryBuilder<ProfileEntity, ProfileEntity, QFilterCondition> {
  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> ageEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'age', value: value),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  ageGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'age',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> ageLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'age',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> ageBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'age',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  autoRestSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'autoRestSeconds', value: value),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  autoRestSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'autoRestSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  autoRestSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'autoRestSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  autoRestSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'autoRestSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  cardioDistanceUnitKmEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cardioDistanceUnitKm',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultRepMaxEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'defaultRepMax', value: value),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultRepMaxGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'defaultRepMax',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultRepMaxLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'defaultRepMax',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultRepMaxBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'defaultRepMax',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultRepMinEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'defaultRepMin', value: value),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultRepMinGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'defaultRepMin',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultRepMinLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'defaultRepMin',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultRepMinBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'defaultRepMin',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultSetsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'defaultSets', value: value),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultSetsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'defaultSets',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultSetsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'defaultSets',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  defaultSetsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'defaultSets',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  emailEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  emailGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  emailLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  emailBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'email',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  emailStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  emailEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  emailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  emailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'email',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'email', value: ''),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'email', value: ''),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  heightCmEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'heightCm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  heightCmGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'heightCm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  heightCmLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'heightCm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  heightCmBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'heightCm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  isGuestEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isGuest', value: value),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  progressionEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'progressionEnabled', value: value),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  themeModeEqualTo(SxThemeMode value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  themeModeGreaterThan(
    SxThemeMode value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  themeModeLessThan(
    SxThemeMode value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  themeModeBetween(
    SxThemeMode lower,
    SxThemeMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'themeMode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  themeModeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  themeModeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  themeModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'themeMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  themeModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'themeMode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  themeModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'themeMode', value: ''),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  themeModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'themeMode', value: ''),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> unitEqualTo(
    WeightUnit value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  unitGreaterThan(
    WeightUnit value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  unitLessThan(
    WeightUnit value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> unitBetween(
    WeightUnit lower,
    WeightUnit upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'unit',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  unitStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  unitEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  unitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> unitMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'unit',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  unitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'unit', value: ''),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  unitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'unit', value: ''),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  weeklySessionTargetEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'weeklySessionTarget', value: value),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  weeklySessionTargetGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'weeklySessionTarget',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  weeklySessionTargetLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'weeklySessionTarget',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  weeklySessionTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'weeklySessionTarget',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  weightKgEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'weightKg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  weightKgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'weightKg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  weightKgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'weightKg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
  weightKgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'weightKg',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension ProfileEntityQueryObject
    on QueryBuilder<ProfileEntity, ProfileEntity, QFilterCondition> {}

extension ProfileEntityQueryLinks
    on QueryBuilder<ProfileEntity, ProfileEntity, QFilterCondition> {}

extension ProfileEntityQuerySortBy
    on QueryBuilder<ProfileEntity, ProfileEntity, QSortBy> {
  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByAge() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByAgeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByAutoRestSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRestSeconds', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByAutoRestSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRestSeconds', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByCardioDistanceUnitKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardioDistanceUnitKm', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByCardioDistanceUnitKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardioDistanceUnitKm', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByDefaultRepMax() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultRepMax', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByDefaultRepMaxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultRepMax', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByDefaultRepMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultRepMin', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByDefaultRepMinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultRepMin', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByDefaultSets() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSets', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByDefaultSetsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSets', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByHeightCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heightCm', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByHeightCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heightCm', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByIsGuest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGuest', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByIsGuestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGuest', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByProgressionEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressionEnabled', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByProgressionEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressionEnabled', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByWeeklySessionTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklySessionTarget', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByWeeklySessionTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklySessionTarget', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  sortByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension ProfileEntityQuerySortThenBy
    on QueryBuilder<ProfileEntity, ProfileEntity, QSortThenBy> {
  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByAge() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByAgeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByAutoRestSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRestSeconds', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByAutoRestSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRestSeconds', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByCardioDistanceUnitKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardioDistanceUnitKm', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByCardioDistanceUnitKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardioDistanceUnitKm', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByDefaultRepMax() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultRepMax', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByDefaultRepMaxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultRepMax', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByDefaultRepMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultRepMin', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByDefaultRepMinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultRepMin', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByDefaultSets() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSets', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByDefaultSetsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSets', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByHeightCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heightCm', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByHeightCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heightCm', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByIsGuest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGuest', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByIsGuestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGuest', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByProgressionEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressionEnabled', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByProgressionEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressionEnabled', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByWeeklySessionTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklySessionTarget', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByWeeklySessionTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weeklySessionTarget', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
  thenByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension ProfileEntityQueryWhereDistinct
    on QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> {
  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByAge() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'age');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct>
  distinctByAutoRestSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoRestSeconds');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct>
  distinctByCardioDistanceUnitKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cardioDistanceUnitKm');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct>
  distinctByDefaultRepMax() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultRepMax');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct>
  distinctByDefaultRepMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultRepMin');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct>
  distinctByDefaultSets() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultSets');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByEmail({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByHeightCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'heightCm');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByIsGuest() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isGuest');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct>
  distinctByProgressionEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progressionEnabled');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByThemeMode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themeMode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByUnit({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct>
  distinctByWeeklySessionTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weeklySessionTarget');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weightKg');
    });
  }
}

extension ProfileEntityQueryProperty
    on QueryBuilder<ProfileEntity, ProfileEntity, QQueryProperty> {
  QueryBuilder<ProfileEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProfileEntity, int, QQueryOperations> ageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'age');
    });
  }

  QueryBuilder<ProfileEntity, int, QQueryOperations> autoRestSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoRestSeconds');
    });
  }

  QueryBuilder<ProfileEntity, bool, QQueryOperations>
  cardioDistanceUnitKmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cardioDistanceUnitKm');
    });
  }

  QueryBuilder<ProfileEntity, int, QQueryOperations> defaultRepMaxProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultRepMax');
    });
  }

  QueryBuilder<ProfileEntity, int, QQueryOperations> defaultRepMinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultRepMin');
    });
  }

  QueryBuilder<ProfileEntity, int, QQueryOperations> defaultSetsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultSets');
    });
  }

  QueryBuilder<ProfileEntity, String, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<ProfileEntity, double, QQueryOperations> heightCmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'heightCm');
    });
  }

  QueryBuilder<ProfileEntity, bool, QQueryOperations> isGuestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isGuest');
    });
  }

  QueryBuilder<ProfileEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<ProfileEntity, bool, QQueryOperations>
  progressionEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progressionEnabled');
    });
  }

  QueryBuilder<ProfileEntity, SxThemeMode, QQueryOperations>
  themeModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themeMode');
    });
  }

  QueryBuilder<ProfileEntity, WeightUnit, QQueryOperations> unitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unit');
    });
  }

  QueryBuilder<ProfileEntity, int, QQueryOperations>
  weeklySessionTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weeklySessionTarget');
    });
  }

  QueryBuilder<ProfileEntity, double, QQueryOperations> weightKgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weightKg');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppMetaEntityCollection on Isar {
  IsarCollection<AppMetaEntity> get appMetaEntitys => this.collection();
}

const AppMetaEntitySchema = CollectionSchema(
  name: r'AppMetaEntity',
  id: 4798171179488078482,
  properties: {
    r'healthConnected': PropertySchema(
      id: 0,
      name: r'healthConnected',
      type: IsarType.bool,
    ),
    r'schemaVersion': PropertySchema(
      id: 1,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'signedIn': PropertySchema(id: 2, name: r'signedIn', type: IsarType.bool),
  },

  estimateSize: _appMetaEntityEstimateSize,
  serialize: _appMetaEntitySerialize,
  deserialize: _appMetaEntityDeserialize,
  deserializeProp: _appMetaEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _appMetaEntityGetId,
  getLinks: _appMetaEntityGetLinks,
  attach: _appMetaEntityAttach,
  version: '3.3.2',
);

int _appMetaEntityEstimateSize(
  AppMetaEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _appMetaEntitySerialize(
  AppMetaEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.healthConnected);
  writer.writeLong(offsets[1], object.schemaVersion);
  writer.writeBool(offsets[2], object.signedIn);
}

AppMetaEntity _appMetaEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppMetaEntity();
  object.healthConnected = reader.readBool(offsets[0]);
  object.id = id;
  object.schemaVersion = reader.readLong(offsets[1]);
  object.signedIn = reader.readBool(offsets[2]);
  return object;
}

P _appMetaEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appMetaEntityGetId(AppMetaEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appMetaEntityGetLinks(AppMetaEntity object) {
  return [];
}

void _appMetaEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  AppMetaEntity object,
) {
  object.id = id;
}

extension AppMetaEntityQueryWhereSort
    on QueryBuilder<AppMetaEntity, AppMetaEntity, QWhere> {
  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppMetaEntityQueryWhere
    on QueryBuilder<AppMetaEntity, AppMetaEntity, QWhereClause> {
  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension AppMetaEntityQueryFilter
    on QueryBuilder<AppMetaEntity, AppMetaEntity, QFilterCondition> {
  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  healthConnectedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'healthConnected', value: value),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schemaVersion', value: value),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  schemaVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  schemaVersionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'schemaVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  signedInEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'signedIn', value: value),
      );
    });
  }
}

extension AppMetaEntityQueryObject
    on QueryBuilder<AppMetaEntity, AppMetaEntity, QFilterCondition> {}

extension AppMetaEntityQueryLinks
    on QueryBuilder<AppMetaEntity, AppMetaEntity, QFilterCondition> {}

extension AppMetaEntityQuerySortBy
    on QueryBuilder<AppMetaEntity, AppMetaEntity, QSortBy> {
  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  sortByHealthConnected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'healthConnected', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  sortByHealthConnectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'healthConnected', Sort.desc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy> sortBySignedIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedIn', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  sortBySignedInDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedIn', Sort.desc);
    });
  }
}

extension AppMetaEntityQuerySortThenBy
    on QueryBuilder<AppMetaEntity, AppMetaEntity, QSortThenBy> {
  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  thenByHealthConnected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'healthConnected', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  thenByHealthConnectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'healthConnected', Sort.desc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy> thenBySignedIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedIn', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  thenBySignedInDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedIn', Sort.desc);
    });
  }
}

extension AppMetaEntityQueryWhereDistinct
    on QueryBuilder<AppMetaEntity, AppMetaEntity, QDistinct> {
  QueryBuilder<AppMetaEntity, AppMetaEntity, QDistinct>
  distinctByHealthConnected() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'healthConnected');
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QDistinct> distinctBySignedIn() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'signedIn');
    });
  }
}

extension AppMetaEntityQueryProperty
    on QueryBuilder<AppMetaEntity, AppMetaEntity, QQueryProperty> {
  QueryBuilder<AppMetaEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppMetaEntity, bool, QQueryOperations>
  healthConnectedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'healthConnected');
    });
  }

  QueryBuilder<AppMetaEntity, int, QQueryOperations> schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<AppMetaEntity, bool, QQueryOperations> signedInProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'signedIn');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MetaEmbSchema = Schema(
  name: r'MetaEmb',
  id: 832288201771796914,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'syncStatus': PropertySchema(
      id: 1,
      name: r'syncStatus',
      type: IsarType.string,
      enumMap: _MetaEmbsyncStatusEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 2,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _metaEmbEstimateSize,
  serialize: _metaEmbSerialize,
  deserialize: _metaEmbDeserialize,
  deserializeProp: _metaEmbDeserializeProp,
);

int _metaEmbEstimateSize(
  MetaEmb object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.syncStatus.name.length * 3;
  return bytesCount;
}

void _metaEmbSerialize(
  MetaEmb object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.syncStatus.name);
  writer.writeDateTime(offsets[2], object.updatedAt);
}

MetaEmb _metaEmbDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MetaEmb();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.syncStatus =
      _MetaEmbsyncStatusValueEnumMap[reader.readStringOrNull(offsets[1])] ??
      SyncStatus.pending;
  object.updatedAt = reader.readDateTime(offsets[2]);
  return object;
}

P _metaEmbDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (_MetaEmbsyncStatusValueEnumMap[reader.readStringOrNull(offset)] ??
              SyncStatus.pending)
          as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _MetaEmbsyncStatusEnumValueMap = {
  r'pending': r'pending',
  r'synced': r'synced',
  r'failed': r'failed',
};
const _MetaEmbsyncStatusValueEnumMap = {
  r'pending': SyncStatus.pending,
  r'synced': SyncStatus.synced,
  r'failed': SyncStatus.failed,
};

extension MetaEmbQueryFilter
    on QueryBuilder<MetaEmb, MetaEmb, QFilterCondition> {
  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> syncStatusEqualTo(
    SyncStatus value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> syncStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> syncStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> syncStatusContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> syncStatusMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'syncStatus',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> syncStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: ''),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> syncStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'syncStatus', value: ''),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MetaEmb, MetaEmb, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension MetaEmbQueryObject
    on QueryBuilder<MetaEmb, MetaEmb, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const StepEmbSchema = Schema(
  name: r'StepEmb',
  id: -7091629696204296118,
  properties: {
    r'text': PropertySchema(id: 0, name: r'text', type: IsarType.string),
    r'title': PropertySchema(id: 1, name: r'title', type: IsarType.string),
  },

  estimateSize: _stepEmbEstimateSize,
  serialize: _stepEmbSerialize,
  deserialize: _stepEmbDeserialize,
  deserializeProp: _stepEmbDeserializeProp,
);

int _stepEmbEstimateSize(
  StepEmb object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.text.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _stepEmbSerialize(
  StepEmb object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.text);
  writer.writeString(offsets[1], object.title);
}

StepEmb _stepEmbDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StepEmb();
  object.text = reader.readString(offsets[0]);
  object.title = reader.readString(offsets[1]);
  return object;
}

P _stepEmbDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension StepEmbQueryFilter
    on QueryBuilder<StepEmb, StepEmb, QFilterCondition> {
  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> textContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> textMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> titleContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> titleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<StepEmb, StepEmb, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }
}

extension StepEmbQueryObject
    on QueryBuilder<StepEmb, StepEmb, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const RoutineExerciseEmbSchema = Schema(
  name: r'RoutineExerciseEmb',
  id: 3780392750435607854,
  properties: {
    r'exerciseId': PropertySchema(
      id: 0,
      name: r'exerciseId',
      type: IsarType.string,
    ),
    r'repMax': PropertySchema(id: 1, name: r'repMax', type: IsarType.long),
    r'repMin': PropertySchema(id: 2, name: r'repMin', type: IsarType.long),
    r'sets': PropertySchema(id: 3, name: r'sets', type: IsarType.long),
  },

  estimateSize: _routineExerciseEmbEstimateSize,
  serialize: _routineExerciseEmbSerialize,
  deserialize: _routineExerciseEmbDeserialize,
  deserializeProp: _routineExerciseEmbDeserializeProp,
);

int _routineExerciseEmbEstimateSize(
  RoutineExerciseEmb object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.exerciseId.length * 3;
  return bytesCount;
}

void _routineExerciseEmbSerialize(
  RoutineExerciseEmb object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.exerciseId);
  writer.writeLong(offsets[1], object.repMax);
  writer.writeLong(offsets[2], object.repMin);
  writer.writeLong(offsets[3], object.sets);
}

RoutineExerciseEmb _routineExerciseEmbDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RoutineExerciseEmb();
  object.exerciseId = reader.readString(offsets[0]);
  object.repMax = reader.readLong(offsets[1]);
  object.repMin = reader.readLong(offsets[2]);
  object.sets = reader.readLong(offsets[3]);
  return object;
}

P _routineExerciseEmbDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension RoutineExerciseEmbQueryFilter
    on QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QFilterCondition> {
  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  exerciseIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  exerciseIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  exerciseIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  exerciseIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'exerciseId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  exerciseIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  exerciseIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  exerciseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  exerciseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'exerciseId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  exerciseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'exerciseId', value: ''),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  exerciseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'exerciseId', value: ''),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  repMaxEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'repMax', value: value),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  repMaxGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'repMax',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  repMaxLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'repMax',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  repMaxBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'repMax',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  repMinEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'repMin', value: value),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  repMinGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'repMin',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  repMinLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'repMin',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  repMinBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'repMin',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  setsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sets', value: value),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  setsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sets',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  setsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sets',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QAfterFilterCondition>
  setsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sets',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension RoutineExerciseEmbQueryObject
    on QueryBuilder<RoutineExerciseEmb, RoutineExerciseEmb, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const CardioTargetEmbSchema = Schema(
  name: r'CardioTargetEmb',
  id: -7307660842910499873,
  properties: {
    r'distanceKm': PropertySchema(
      id: 0,
      name: r'distanceKm',
      type: IsarType.double,
    ),
    r'durationMinutes': PropertySchema(
      id: 1,
      name: r'durationMinutes',
      type: IsarType.long,
    ),
    r'inclinePct': PropertySchema(
      id: 2,
      name: r'inclinePct',
      type: IsarType.double,
    ),
    r'kind': PropertySchema(
      id: 3,
      name: r'kind',
      type: IsarType.string,
      enumMap: _CardioTargetEmbkindEnumValueMap,
    ),
    r'resistance': PropertySchema(
      id: 4,
      name: r'resistance',
      type: IsarType.long,
    ),
    r'speedKmh': PropertySchema(
      id: 5,
      name: r'speedKmh',
      type: IsarType.double,
    ),
  },

  estimateSize: _cardioTargetEmbEstimateSize,
  serialize: _cardioTargetEmbSerialize,
  deserialize: _cardioTargetEmbDeserialize,
  deserializeProp: _cardioTargetEmbDeserializeProp,
);

int _cardioTargetEmbEstimateSize(
  CardioTargetEmb object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.kind.name.length * 3;
  return bytesCount;
}

void _cardioTargetEmbSerialize(
  CardioTargetEmb object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.distanceKm);
  writer.writeLong(offsets[1], object.durationMinutes);
  writer.writeDouble(offsets[2], object.inclinePct);
  writer.writeString(offsets[3], object.kind.name);
  writer.writeLong(offsets[4], object.resistance);
  writer.writeDouble(offsets[5], object.speedKmh);
}

CardioTargetEmb _cardioTargetEmbDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CardioTargetEmb();
  object.distanceKm = reader.readDoubleOrNull(offsets[0]);
  object.durationMinutes = reader.readLongOrNull(offsets[1]);
  object.inclinePct = reader.readDoubleOrNull(offsets[2]);
  object.kind =
      _CardioTargetEmbkindValueEnumMap[reader.readStringOrNull(offsets[3])] ??
      CardioKind.outdoorRun;
  object.resistance = reader.readLongOrNull(offsets[4]);
  object.speedKmh = reader.readDoubleOrNull(offsets[5]);
  return object;
}

P _cardioTargetEmbDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (_CardioTargetEmbkindValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              CardioKind.outdoorRun)
          as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CardioTargetEmbkindEnumValueMap = {
  r'outdoorRun': r'outdoorRun',
  r'outdoorWalk': r'outdoorWalk',
  r'treadmill': r'treadmill',
  r'cycling': r'cycling',
  r'stationaryBike': r'stationaryBike',
  r'elliptical': r'elliptical',
  r'rowing': r'rowing',
  r'stairClimber': r'stairClimber',
  r'jumpRope': r'jumpRope',
  r'custom': r'custom',
};
const _CardioTargetEmbkindValueEnumMap = {
  r'outdoorRun': CardioKind.outdoorRun,
  r'outdoorWalk': CardioKind.outdoorWalk,
  r'treadmill': CardioKind.treadmill,
  r'cycling': CardioKind.cycling,
  r'stationaryBike': CardioKind.stationaryBike,
  r'elliptical': CardioKind.elliptical,
  r'rowing': CardioKind.rowing,
  r'stairClimber': CardioKind.stairClimber,
  r'jumpRope': CardioKind.jumpRope,
  r'custom': CardioKind.custom,
};

extension CardioTargetEmbQueryFilter
    on QueryBuilder<CardioTargetEmb, CardioTargetEmb, QFilterCondition> {
  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  distanceKmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'distanceKm'),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  distanceKmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'distanceKm'),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  distanceKmEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'distanceKm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  distanceKmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'distanceKm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  distanceKmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'distanceKm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  distanceKmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'distanceKm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  durationMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'durationMinutes'),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  durationMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'durationMinutes'),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  durationMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'durationMinutes', value: value),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  durationMinutesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'durationMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  durationMinutesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'durationMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  durationMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'durationMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  inclinePctIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'inclinePct'),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  inclinePctIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'inclinePct'),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  inclinePctEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'inclinePct',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  inclinePctGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'inclinePct',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  inclinePctLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'inclinePct',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  inclinePctBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'inclinePct',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  kindEqualTo(CardioKind value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  kindGreaterThan(
    CardioKind value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  kindLessThan(
    CardioKind value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  kindBetween(
    CardioKind lower,
    CardioKind upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  kindStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  kindEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  kindContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  kindMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'kind',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  kindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kind', value: ''),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  kindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'kind', value: ''),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  resistanceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'resistance'),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  resistanceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'resistance'),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  resistanceEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resistance', value: value),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  resistanceGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resistance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  resistanceLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resistance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  resistanceBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resistance',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  speedKmhIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'speedKmh'),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  speedKmhIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'speedKmh'),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  speedKmhEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'speedKmh',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  speedKmhGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'speedKmh',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  speedKmhLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'speedKmh',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioTargetEmb, CardioTargetEmb, QAfterFilterCondition>
  speedKmhBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'speedKmh',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension CardioTargetEmbQueryObject
    on QueryBuilder<CardioTargetEmb, CardioTargetEmb, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const SetLogEmbSchema = Schema(
  name: r'SetLogEmb',
  id: 7630904018311931470,
  properties: {
    r'done': PropertySchema(id: 0, name: r'done', type: IsarType.bool),
    r'reps': PropertySchema(id: 1, name: r'reps', type: IsarType.long),
    r'rpe': PropertySchema(id: 2, name: r'rpe', type: IsarType.double),
    r'weightKg': PropertySchema(
      id: 3,
      name: r'weightKg',
      type: IsarType.double,
    ),
  },

  estimateSize: _setLogEmbEstimateSize,
  serialize: _setLogEmbSerialize,
  deserialize: _setLogEmbDeserialize,
  deserializeProp: _setLogEmbDeserializeProp,
);

int _setLogEmbEstimateSize(
  SetLogEmb object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _setLogEmbSerialize(
  SetLogEmb object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.done);
  writer.writeLong(offsets[1], object.reps);
  writer.writeDouble(offsets[2], object.rpe);
  writer.writeDouble(offsets[3], object.weightKg);
}

SetLogEmb _setLogEmbDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SetLogEmb();
  object.done = reader.readBool(offsets[0]);
  object.reps = reader.readLong(offsets[1]);
  object.rpe = reader.readDoubleOrNull(offsets[2]);
  object.weightKg = reader.readDouble(offsets[3]);
  return object;
}

P _setLogEmbDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SetLogEmbQueryFilter
    on QueryBuilder<SetLogEmb, SetLogEmb, QFilterCondition> {
  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> doneEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'done', value: value),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> repsEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reps', value: value),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> repsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reps',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> repsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reps',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> repsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reps',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> rpeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'rpe'),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> rpeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'rpe'),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> rpeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rpe',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> rpeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rpe',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> rpeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rpe',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> rpeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rpe',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> weightKgEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'weightKg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> weightKgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'weightKg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> weightKgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'weightKg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SetLogEmb, SetLogEmb, QAfterFilterCondition> weightKgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'weightKg',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension SetLogEmbQueryObject
    on QueryBuilder<SetLogEmb, SetLogEmb, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ExerciseLogEmbSchema = Schema(
  name: r'ExerciseLogEmb',
  id: -1746134190011934259,
  properties: {
    r'exerciseId': PropertySchema(
      id: 0,
      name: r'exerciseId',
      type: IsarType.string,
    ),
    r'sets': PropertySchema(
      id: 1,
      name: r'sets',
      type: IsarType.objectList,

      target: r'SetLogEmb',
    ),
  },

  estimateSize: _exerciseLogEmbEstimateSize,
  serialize: _exerciseLogEmbSerialize,
  deserialize: _exerciseLogEmbDeserialize,
  deserializeProp: _exerciseLogEmbDeserializeProp,
);

int _exerciseLogEmbEstimateSize(
  ExerciseLogEmb object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.exerciseId.length * 3;
  bytesCount += 3 + object.sets.length * 3;
  {
    final offsets = allOffsets[SetLogEmb]!;
    for (var i = 0; i < object.sets.length; i++) {
      final value = object.sets[i];
      bytesCount += SetLogEmbSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _exerciseLogEmbSerialize(
  ExerciseLogEmb object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.exerciseId);
  writer.writeObjectList<SetLogEmb>(
    offsets[1],
    allOffsets,
    SetLogEmbSchema.serialize,
    object.sets,
  );
}

ExerciseLogEmb _exerciseLogEmbDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExerciseLogEmb();
  object.exerciseId = reader.readString(offsets[0]);
  object.sets =
      reader.readObjectList<SetLogEmb>(
        offsets[1],
        SetLogEmbSchema.deserialize,
        allOffsets,
        SetLogEmb(),
      ) ??
      [];
  return object;
}

P _exerciseLogEmbDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readObjectList<SetLogEmb>(
                offset,
                SetLogEmbSchema.deserialize,
                allOffsets,
                SetLogEmb(),
              ) ??
              [])
          as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ExerciseLogEmbQueryFilter
    on QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QFilterCondition> {
  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  exerciseIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  exerciseIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  exerciseIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  exerciseIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'exerciseId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  exerciseIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  exerciseIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  exerciseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'exerciseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  exerciseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'exerciseId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  exerciseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'exerciseId', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  exerciseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'exerciseId', value: ''),
      );
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  setsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'sets', length, true, length, true);
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  setsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'sets', 0, true, 0, true);
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  setsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'sets', 0, false, 999999, true);
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  setsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'sets', 0, true, length, include);
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  setsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'sets', length, include, 999999, true);
    });
  }

  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  setsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sets',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension ExerciseLogEmbQueryObject
    on QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QFilterCondition> {
  QueryBuilder<ExerciseLogEmb, ExerciseLogEmb, QAfterFilterCondition>
  setsElement(FilterQuery<SetLogEmb> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'sets');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const CardioSessionEmbSchema = Schema(
  name: r'CardioSessionEmb',
  id: 5491051560666319216,
  properties: {
    r'avgHeartRate': PropertySchema(
      id: 0,
      name: r'avgHeartRate',
      type: IsarType.long,
    ),
    r'calories': PropertySchema(id: 1, name: r'calories', type: IsarType.long),
    r'customActivityId': PropertySchema(
      id: 2,
      name: r'customActivityId',
      type: IsarType.string,
    ),
    r'distanceKm': PropertySchema(
      id: 3,
      name: r'distanceKm',
      type: IsarType.double,
    ),
    r'durationSeconds': PropertySchema(
      id: 4,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'inclinePct': PropertySchema(
      id: 5,
      name: r'inclinePct',
      type: IsarType.double,
    ),
    r'kind': PropertySchema(
      id: 6,
      name: r'kind',
      type: IsarType.string,
      enumMap: _CardioSessionEmbkindEnumValueMap,
    ),
    r'meta': PropertySchema(
      id: 7,
      name: r'meta',
      type: IsarType.object,

      target: r'MetaEmb',
    ),
    r'notes': PropertySchema(id: 8, name: r'notes', type: IsarType.string),
    r'resistance': PropertySchema(
      id: 9,
      name: r'resistance',
      type: IsarType.long,
    ),
    r'routeName': PropertySchema(
      id: 10,
      name: r'routeName',
      type: IsarType.string,
    ),
    r'rpe': PropertySchema(id: 11, name: r'rpe', type: IsarType.double),
    r'speedKmh': PropertySchema(
      id: 12,
      name: r'speedKmh',
      type: IsarType.double,
    ),
    r'uid': PropertySchema(id: 13, name: r'uid', type: IsarType.string),
    r'workoutDate': PropertySchema(
      id: 14,
      name: r'workoutDate',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _cardioSessionEmbEstimateSize,
  serialize: _cardioSessionEmbSerialize,
  deserialize: _cardioSessionEmbDeserialize,
  deserializeProp: _cardioSessionEmbDeserializeProp,
);

int _cardioSessionEmbEstimateSize(
  CardioSessionEmb object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.customActivityId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.kind.name.length * 3;
  bytesCount +=
      3 +
      MetaEmbSchema.estimateSize(object.meta, allOffsets[MetaEmb]!, allOffsets);
  bytesCount += 3 + object.notes.length * 3;
  bytesCount += 3 + object.routeName.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _cardioSessionEmbSerialize(
  CardioSessionEmb object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.avgHeartRate);
  writer.writeLong(offsets[1], object.calories);
  writer.writeString(offsets[2], object.customActivityId);
  writer.writeDouble(offsets[3], object.distanceKm);
  writer.writeLong(offsets[4], object.durationSeconds);
  writer.writeDouble(offsets[5], object.inclinePct);
  writer.writeString(offsets[6], object.kind.name);
  writer.writeObject<MetaEmb>(
    offsets[7],
    allOffsets,
    MetaEmbSchema.serialize,
    object.meta,
  );
  writer.writeString(offsets[8], object.notes);
  writer.writeLong(offsets[9], object.resistance);
  writer.writeString(offsets[10], object.routeName);
  writer.writeDouble(offsets[11], object.rpe);
  writer.writeDouble(offsets[12], object.speedKmh);
  writer.writeString(offsets[13], object.uid);
  writer.writeDateTime(offsets[14], object.workoutDate);
}

CardioSessionEmb _cardioSessionEmbDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CardioSessionEmb();
  object.avgHeartRate = reader.readLongOrNull(offsets[0]);
  object.calories = reader.readLongOrNull(offsets[1]);
  object.customActivityId = reader.readStringOrNull(offsets[2]);
  object.distanceKm = reader.readDoubleOrNull(offsets[3]);
  object.durationSeconds = reader.readLong(offsets[4]);
  object.inclinePct = reader.readDoubleOrNull(offsets[5]);
  object.kind =
      _CardioSessionEmbkindValueEnumMap[reader.readStringOrNull(offsets[6])] ??
      CardioKind.outdoorRun;
  object.meta =
      reader.readObjectOrNull<MetaEmb>(
        offsets[7],
        MetaEmbSchema.deserialize,
        allOffsets,
      ) ??
      MetaEmb();
  object.notes = reader.readString(offsets[8]);
  object.resistance = reader.readLongOrNull(offsets[9]);
  object.routeName = reader.readString(offsets[10]);
  object.rpe = reader.readDoubleOrNull(offsets[11]);
  object.speedKmh = reader.readDoubleOrNull(offsets[12]);
  object.uid = reader.readString(offsets[13]);
  object.workoutDate = reader.readDateTime(offsets[14]);
  return object;
}

P _cardioSessionEmbDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (_CardioSessionEmbkindValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              CardioKind.outdoorRun)
          as P;
    case 7:
      return (reader.readObjectOrNull<MetaEmb>(
                offset,
                MetaEmbSchema.deserialize,
                allOffsets,
              ) ??
              MetaEmb())
          as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CardioSessionEmbkindEnumValueMap = {
  r'outdoorRun': r'outdoorRun',
  r'outdoorWalk': r'outdoorWalk',
  r'treadmill': r'treadmill',
  r'cycling': r'cycling',
  r'stationaryBike': r'stationaryBike',
  r'elliptical': r'elliptical',
  r'rowing': r'rowing',
  r'stairClimber': r'stairClimber',
  r'jumpRope': r'jumpRope',
  r'custom': r'custom',
};
const _CardioSessionEmbkindValueEnumMap = {
  r'outdoorRun': CardioKind.outdoorRun,
  r'outdoorWalk': CardioKind.outdoorWalk,
  r'treadmill': CardioKind.treadmill,
  r'cycling': CardioKind.cycling,
  r'stationaryBike': CardioKind.stationaryBike,
  r'elliptical': CardioKind.elliptical,
  r'rowing': CardioKind.rowing,
  r'stairClimber': CardioKind.stairClimber,
  r'jumpRope': CardioKind.jumpRope,
  r'custom': CardioKind.custom,
};

extension CardioSessionEmbQueryFilter
    on QueryBuilder<CardioSessionEmb, CardioSessionEmb, QFilterCondition> {
  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  avgHeartRateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'avgHeartRate'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  avgHeartRateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'avgHeartRate'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  avgHeartRateEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'avgHeartRate', value: value),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  avgHeartRateGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'avgHeartRate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  avgHeartRateLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'avgHeartRate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  avgHeartRateBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'avgHeartRate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  caloriesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'calories'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  caloriesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'calories'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  caloriesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'calories', value: value),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  caloriesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'calories',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  caloriesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'calories',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  caloriesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'calories',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customActivityId'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customActivityId'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'customActivityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'customActivityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'customActivityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'customActivityId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'customActivityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'customActivityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'customActivityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'customActivityId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customActivityId', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  customActivityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customActivityId', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  distanceKmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'distanceKm'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  distanceKmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'distanceKm'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  distanceKmEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'distanceKm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  distanceKmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'distanceKm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  distanceKmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'distanceKm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  distanceKmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'distanceKm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  durationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'durationSeconds', value: value),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  durationSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'durationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  durationSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'durationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  durationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'durationSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  inclinePctIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'inclinePct'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  inclinePctIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'inclinePct'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  inclinePctEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'inclinePct',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  inclinePctGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'inclinePct',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  inclinePctLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'inclinePct',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  inclinePctBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'inclinePct',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  kindEqualTo(CardioKind value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  kindGreaterThan(
    CardioKind value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  kindLessThan(
    CardioKind value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  kindBetween(
    CardioKind lower,
    CardioKind upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  kindStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  kindEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  kindContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  kindMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'kind',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  kindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kind', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  kindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'kind', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  notesEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  notesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  notesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  notesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  notesStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  notesEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'notes',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  resistanceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'resistance'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  resistanceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'resistance'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  resistanceEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resistance', value: value),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  resistanceGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resistance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  resistanceLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resistance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  resistanceBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resistance',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  routeNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'routeName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  routeNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'routeName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  routeNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'routeName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  routeNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'routeName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  routeNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'routeName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  routeNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'routeName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  routeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'routeName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  routeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'routeName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  routeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'routeName', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  routeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'routeName', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  rpeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'rpe'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  rpeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'rpe'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  rpeEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rpe',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  rpeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rpe',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  rpeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rpe',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  rpeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rpe',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  speedKmhIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'speedKmh'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  speedKmhIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'speedKmh'),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  speedKmhEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'speedKmh',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  speedKmhGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'speedKmh',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  speedKmhLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'speedKmh',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  speedKmhBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'speedKmh',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  uidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  uidLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  uidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  workoutDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'workoutDate', value: value),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  workoutDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'workoutDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  workoutDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'workoutDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition>
  workoutDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'workoutDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CardioSessionEmbQueryObject
    on QueryBuilder<CardioSessionEmb, CardioSessionEmb, QFilterCondition> {
  QueryBuilder<CardioSessionEmb, CardioSessionEmb, QAfterFilterCondition> meta(
    FilterQuery<MetaEmb> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'meta');
    });
  }
}
