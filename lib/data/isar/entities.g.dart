// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entities.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

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
    r'ownerUserId': PropertySchema(
      id: 1,
      name: r'ownerUserId',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 2,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'workoutDraftJson': PropertySchema(
      id: 3,
      name: r'workoutDraftJson',
      type: IsarType.string,
    ),
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
  {
    final value = object.ownerUserId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.workoutDraftJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _appMetaEntitySerialize(
  AppMetaEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.healthConnected);
  writer.writeString(offsets[1], object.ownerUserId);
  writer.writeLong(offsets[2], object.schemaVersion);
  writer.writeString(offsets[3], object.workoutDraftJson);
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
  object.ownerUserId = reader.readStringOrNull(offsets[1]);
  object.schemaVersion = reader.readLong(offsets[2]);
  object.workoutDraftJson = reader.readStringOrNull(offsets[3]);
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
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
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
  ownerUserIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'ownerUserId'),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'ownerUserId'),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerUserId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ownerUserId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerUserId', value: ''),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  ownerUserIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerUserId', value: ''),
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
  workoutDraftJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'workoutDraftJson'),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'workoutDraftJson'),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'workoutDraftJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'workoutDraftJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'workoutDraftJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'workoutDraftJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'workoutDraftJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'workoutDraftJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'workoutDraftJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'workoutDraftJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'workoutDraftJson', value: ''),
      );
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterFilterCondition>
  workoutDraftJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'workoutDraftJson', value: ''),
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

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy> sortByOwnerUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  sortByOwnerUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.desc);
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

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  sortByWorkoutDraftJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDraftJson', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  sortByWorkoutDraftJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDraftJson', Sort.desc);
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

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy> thenByOwnerUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  thenByOwnerUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.desc);
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

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  thenByWorkoutDraftJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDraftJson', Sort.asc);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QAfterSortBy>
  thenByWorkoutDraftJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDraftJson', Sort.desc);
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

  QueryBuilder<AppMetaEntity, AppMetaEntity, QDistinct> distinctByOwnerUserId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUserId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<AppMetaEntity, AppMetaEntity, QDistinct>
  distinctByWorkoutDraftJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'workoutDraftJson',
        caseSensitive: caseSensitive,
      );
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

  QueryBuilder<AppMetaEntity, String?, QQueryOperations> ownerUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUserId');
    });
  }

  QueryBuilder<AppMetaEntity, int, QQueryOperations> schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<AppMetaEntity, String?, QQueryOperations>
  workoutDraftJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutDraftJson');
    });
  }
}
