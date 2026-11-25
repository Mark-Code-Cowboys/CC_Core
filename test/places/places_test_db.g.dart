// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places_test_db.dart';

// ignore_for_file: type=lint
class $TestVenuesTable extends TestVenues
    with TableInfo<$TestVenuesTable, TestVenue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TestVenuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinAccuracyMMeta = const VerificationMeta(
    'pinAccuracyM',
  );
  @override
  late final GeneratedColumn<double> pinAccuracyM = GeneratedColumn<double>(
    'pin_accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinCapturedAtMeta = const VerificationMeta(
    'pinCapturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pinCapturedAt =
      GeneratedColumn<DateTime>(
        'pin_captured_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TestVenueKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TestVenueKind>($TestVenuesTable.$converterkind);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    lat,
    lng,
    pinAccuracyM,
    pinCapturedAt,
    createdAt,
    kind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'test_venues';
  @override
  VerificationContext validateIntegrity(
    Insertable<TestVenue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('pin_accuracy_m')) {
      context.handle(
        _pinAccuracyMMeta,
        pinAccuracyM.isAcceptableOrUnknown(
          data['pin_accuracy_m']!,
          _pinAccuracyMMeta,
        ),
      );
    }
    if (data.containsKey('pin_captured_at')) {
      context.handle(
        _pinCapturedAtMeta,
        pinCapturedAt.isAcceptableOrUnknown(
          data['pin_captured_at']!,
          _pinCapturedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TestVenue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TestVenue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      pinAccuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pin_accuracy_m'],
      ),
      pinCapturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pin_captured_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      kind: $TestVenuesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
    );
  }

  @override
  $TestVenuesTable createAlias(String alias) {
    return $TestVenuesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TestVenueKind, int, int> $converterkind =
      const EnumIndexConverter<TestVenueKind>(TestVenueKind.values);
}

class TestVenue extends DataClass implements Insertable<TestVenue> {
  /// Row id.
  final int id;

  /// What the place is called.
  final String name;

  /// Pin latitude; null for a pinless place.
  final double? lat;

  /// Pin longitude; null for a pinless place.
  final double? lng;

  /// Accuracy of the fix that set the pin, so a better fix can refine
  /// it; null when unknown.
  final double? pinAccuracyM;

  /// When the pin was set; travels with [pinAccuracyM].
  final DateTime? pinCapturedAt;

  /// Audit timestamp.
  final DateTime createdAt;
  final TestVenueKind kind;
  const TestVenue({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
    this.pinAccuracyM,
    this.pinCapturedAt,
    required this.createdAt,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    if (!nullToAbsent || pinAccuracyM != null) {
      map['pin_accuracy_m'] = Variable<double>(pinAccuracyM);
    }
    if (!nullToAbsent || pinCapturedAt != null) {
      map['pin_captured_at'] = Variable<DateTime>(pinCapturedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    {
      map['kind'] = Variable<int>($TestVenuesTable.$converterkind.toSql(kind));
    }
    return map;
  }

  TestVenuesCompanion toCompanion(bool nullToAbsent) {
    return TestVenuesCompanion(
      id: Value(id),
      name: Value(name),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      pinAccuracyM: pinAccuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(pinAccuracyM),
      pinCapturedAt: pinCapturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinCapturedAt),
      createdAt: Value(createdAt),
      kind: Value(kind),
    );
  }

  factory TestVenue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TestVenue(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      pinAccuracyM: serializer.fromJson<double?>(json['pinAccuracyM']),
      pinCapturedAt: serializer.fromJson<DateTime?>(json['pinCapturedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      kind: $TestVenuesTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'pinAccuracyM': serializer.toJson<double?>(pinAccuracyM),
      'pinCapturedAt': serializer.toJson<DateTime?>(pinCapturedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'kind': serializer.toJson<int>(
        $TestVenuesTable.$converterkind.toJson(kind),
      ),
    };
  }

  TestVenue copyWith({
    int? id,
    String? name,
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    Value<double?> pinAccuracyM = const Value.absent(),
    Value<DateTime?> pinCapturedAt = const Value.absent(),
    DateTime? createdAt,
    TestVenueKind? kind,
  }) => TestVenue(
    id: id ?? this.id,
    name: name ?? this.name,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    pinAccuracyM: pinAccuracyM.present ? pinAccuracyM.value : this.pinAccuracyM,
    pinCapturedAt: pinCapturedAt.present
        ? pinCapturedAt.value
        : this.pinCapturedAt,
    createdAt: createdAt ?? this.createdAt,
    kind: kind ?? this.kind,
  );
  TestVenue copyWithCompanion(TestVenuesCompanion data) {
    return TestVenue(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      pinAccuracyM: data.pinAccuracyM.present
          ? data.pinAccuracyM.value
          : this.pinAccuracyM,
      pinCapturedAt: data.pinCapturedAt.present
          ? data.pinCapturedAt.value
          : this.pinCapturedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TestVenue(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('pinAccuracyM: $pinAccuracyM, ')
          ..write('pinCapturedAt: $pinCapturedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    lat,
    lng,
    pinAccuracyM,
    pinCapturedAt,
    createdAt,
    kind,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TestVenue &&
          other.id == this.id &&
          other.name == this.name &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.pinAccuracyM == this.pinAccuracyM &&
          other.pinCapturedAt == this.pinCapturedAt &&
          other.createdAt == this.createdAt &&
          other.kind == this.kind);
}

class TestVenuesCompanion extends UpdateCompanion<TestVenue> {
  final Value<int> id;
  final Value<String> name;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<double?> pinAccuracyM;
  final Value<DateTime?> pinCapturedAt;
  final Value<DateTime> createdAt;
  final Value<TestVenueKind> kind;
  const TestVenuesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.pinAccuracyM = const Value.absent(),
    this.pinCapturedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.kind = const Value.absent(),
  });
  TestVenuesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.pinAccuracyM = const Value.absent(),
    this.pinCapturedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    required TestVenueKind kind,
  }) : name = Value(name),
       kind = Value(kind);
  static Insertable<TestVenue> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? pinAccuracyM,
    Expression<DateTime>? pinCapturedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? kind,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (pinAccuracyM != null) 'pin_accuracy_m': pinAccuracyM,
      if (pinCapturedAt != null) 'pin_captured_at': pinCapturedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (kind != null) 'kind': kind,
    });
  }

  TestVenuesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<double?>? pinAccuracyM,
    Value<DateTime?>? pinCapturedAt,
    Value<DateTime>? createdAt,
    Value<TestVenueKind>? kind,
  }) {
    return TestVenuesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      pinAccuracyM: pinAccuracyM ?? this.pinAccuracyM,
      pinCapturedAt: pinCapturedAt ?? this.pinCapturedAt,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (pinAccuracyM.present) {
      map['pin_accuracy_m'] = Variable<double>(pinAccuracyM.value);
    }
    if (pinCapturedAt.present) {
      map['pin_captured_at'] = Variable<DateTime>(pinCapturedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $TestVenuesTable.$converterkind.toSql(kind.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TestVenuesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('pinAccuracyM: $pinAccuracyM, ')
          ..write('pinCapturedAt: $pinCapturedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    check: () => ComparableExpr(rating).isBetweenValues(1, 5),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, notes, rating, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntry> {
  final Value<int> id;
  final Value<String?> notes;
  final Value<int?> rating;
  final Value<DateTime> createdAt;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.notes = const Value.absent(),
    this.rating = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.notes = const Value.absent(),
    this.rating = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  static Insertable<JournalEntry> custom({
    Expression<int>? id,
    Expression<String>? notes,
    Expression<int>? rating,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notes != null) 'notes': notes,
      if (rating != null) 'rating': rating,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<int>? id,
    Value<String?>? notes,
    Value<int?>? rating,
    Value<DateTime>? createdAt,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('notes: $notes, ')
          ..write('rating: $rating, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TestVisitsTable extends TestVisits
    with TableInfo<$TestVisitsTable, TestVisit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TestVisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _placeIdMeta = const VerificationMeta(
    'placeId',
  );
  @override
  late final GeneratedColumn<int> placeId = GeneratedColumn<int>(
    'place_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitedAtMeta = const VerificationMeta(
    'visitedAt',
  );
  @override
  late final GeneratedColumn<DateTime> visitedAt = GeneratedColumn<DateTime>(
    'visited_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _journalEntryIdMeta = const VerificationMeta(
    'journalEntryId',
  );
  @override
  late final GeneratedColumn<int> journalEntryId = GeneratedColumn<int>(
    'journal_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    placeId,
    visitedAt,
    journalEntryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'test_visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<TestVisit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('place_id')) {
      context.handle(
        _placeIdMeta,
        placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_placeIdMeta);
    }
    if (data.containsKey('visited_at')) {
      context.handle(
        _visitedAtMeta,
        visitedAt.isAcceptableOrUnknown(data['visited_at']!, _visitedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_visitedAtMeta);
    }
    if (data.containsKey('journal_entry_id')) {
      context.handle(
        _journalEntryIdMeta,
        journalEntryId.isAcceptableOrUnknown(
          data['journal_entry_id']!,
          _journalEntryIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TestVisit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TestVisit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      placeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}place_id'],
      )!,
      visitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visited_at'],
      )!,
      journalEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}journal_entry_id'],
      ),
    );
  }

  @override
  $TestVisitsTable createAlias(String alias) {
    return $TestVisitsTable(attachedDatabase, alias);
  }
}

class TestVisit extends DataClass implements Insertable<TestVisit> {
  /// Row id.
  final int id;

  /// The place visited.
  final int placeId;

  /// When the visit happened.
  final DateTime visitedAt;

  /// The visit's journal entry (notes, rating, photos), if it has one.
  final int? journalEntryId;
  const TestVisit({
    required this.id,
    required this.placeId,
    required this.visitedAt,
    this.journalEntryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['place_id'] = Variable<int>(placeId);
    map['visited_at'] = Variable<DateTime>(visitedAt);
    if (!nullToAbsent || journalEntryId != null) {
      map['journal_entry_id'] = Variable<int>(journalEntryId);
    }
    return map;
  }

  TestVisitsCompanion toCompanion(bool nullToAbsent) {
    return TestVisitsCompanion(
      id: Value(id),
      placeId: Value(placeId),
      visitedAt: Value(visitedAt),
      journalEntryId: journalEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(journalEntryId),
    );
  }

  factory TestVisit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TestVisit(
      id: serializer.fromJson<int>(json['id']),
      placeId: serializer.fromJson<int>(json['placeId']),
      visitedAt: serializer.fromJson<DateTime>(json['visitedAt']),
      journalEntryId: serializer.fromJson<int?>(json['journalEntryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'placeId': serializer.toJson<int>(placeId),
      'visitedAt': serializer.toJson<DateTime>(visitedAt),
      'journalEntryId': serializer.toJson<int?>(journalEntryId),
    };
  }

  TestVisit copyWith({
    int? id,
    int? placeId,
    DateTime? visitedAt,
    Value<int?> journalEntryId = const Value.absent(),
  }) => TestVisit(
    id: id ?? this.id,
    placeId: placeId ?? this.placeId,
    visitedAt: visitedAt ?? this.visitedAt,
    journalEntryId: journalEntryId.present
        ? journalEntryId.value
        : this.journalEntryId,
  );
  TestVisit copyWithCompanion(TestVisitsCompanion data) {
    return TestVisit(
      id: data.id.present ? data.id.value : this.id,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      visitedAt: data.visitedAt.present ? data.visitedAt.value : this.visitedAt,
      journalEntryId: data.journalEntryId.present
          ? data.journalEntryId.value
          : this.journalEntryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TestVisit(')
          ..write('id: $id, ')
          ..write('placeId: $placeId, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('journalEntryId: $journalEntryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, placeId, visitedAt, journalEntryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TestVisit &&
          other.id == this.id &&
          other.placeId == this.placeId &&
          other.visitedAt == this.visitedAt &&
          other.journalEntryId == this.journalEntryId);
}

class TestVisitsCompanion extends UpdateCompanion<TestVisit> {
  final Value<int> id;
  final Value<int> placeId;
  final Value<DateTime> visitedAt;
  final Value<int?> journalEntryId;
  const TestVisitsCompanion({
    this.id = const Value.absent(),
    this.placeId = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.journalEntryId = const Value.absent(),
  });
  TestVisitsCompanion.insert({
    this.id = const Value.absent(),
    required int placeId,
    required DateTime visitedAt,
    this.journalEntryId = const Value.absent(),
  }) : placeId = Value(placeId),
       visitedAt = Value(visitedAt);
  static Insertable<TestVisit> custom({
    Expression<int>? id,
    Expression<int>? placeId,
    Expression<DateTime>? visitedAt,
    Expression<int>? journalEntryId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (placeId != null) 'place_id': placeId,
      if (visitedAt != null) 'visited_at': visitedAt,
      if (journalEntryId != null) 'journal_entry_id': journalEntryId,
    });
  }

  TestVisitsCompanion copyWith({
    Value<int>? id,
    Value<int>? placeId,
    Value<DateTime>? visitedAt,
    Value<int?>? journalEntryId,
  }) {
    return TestVisitsCompanion(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      visitedAt: visitedAt ?? this.visitedAt,
      journalEntryId: journalEntryId ?? this.journalEntryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<int>(placeId.value);
    }
    if (visitedAt.present) {
      map['visited_at'] = Variable<DateTime>(visitedAt.value);
    }
    if (journalEntryId.present) {
      map['journal_entry_id'] = Variable<int>(journalEntryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TestVisitsCompanion(')
          ..write('id: $id, ')
          ..write('placeId: $placeId, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('journalEntryId: $journalEntryId')
          ..write(')'))
        .toString();
  }
}

class $JournalPhotosTable extends JournalPhotos
    with TableInfo<$JournalPhotosTable, JournalPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, entryId, path, caption];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalPhoto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
    );
  }

  @override
  $JournalPhotosTable createAlias(String alias) {
    return $JournalPhotosTable(attachedDatabase, alias);
  }
}

class JournalPhotosCompanion extends UpdateCompanion<JournalPhoto> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<String> path;
  final Value<String?> caption;
  const JournalPhotosCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.path = const Value.absent(),
    this.caption = const Value.absent(),
  });
  JournalPhotosCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required String path,
    this.caption = const Value.absent(),
  }) : entryId = Value(entryId),
       path = Value(path);
  static Insertable<JournalPhoto> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<String>? path,
    Expression<String>? caption,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (path != null) 'path': path,
      if (caption != null) 'caption': caption,
    });
  }

  JournalPhotosCompanion copyWith({
    Value<int>? id,
    Value<int>? entryId,
    Value<String>? path,
    Value<String?>? caption,
  }) {
    return JournalPhotosCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      path: path ?? this.path,
      caption: caption ?? this.caption,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalPhotosCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('path: $path, ')
          ..write('caption: $caption')
          ..write(')'))
        .toString();
  }
}

class $JournalTagsTable extends JournalTags
    with TableInfo<$JournalTagsTable, JournalTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, entryId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entryId, tag},
  ];
  @override
  JournalTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $JournalTagsTable createAlias(String alias) {
    return $JournalTagsTable(attachedDatabase, alias);
  }
}

class JournalTagsCompanion extends UpdateCompanion<JournalTag> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<String> tag;
  const JournalTagsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.tag = const Value.absent(),
  });
  JournalTagsCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required String tag,
  }) : entryId = Value(entryId),
       tag = Value(tag);
  static Insertable<JournalTag> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<String>? tag,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (tag != null) 'tag': tag,
    });
  }

  JournalTagsCompanion copyWith({
    Value<int>? id,
    Value<int>? entryId,
    Value<String>? tag,
  }) {
    return JournalTagsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      tag: tag ?? this.tag,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalTagsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }
}

abstract class _$PlacesTestDb extends GeneratedDatabase {
  _$PlacesTestDb(QueryExecutor e) : super(e);
  $PlacesTestDbManager get managers => $PlacesTestDbManager(this);
  late final $TestVenuesTable testVenues = $TestVenuesTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $TestVisitsTable testVisits = $TestVisitsTable(this);
  late final $JournalPhotosTable journalPhotos = $JournalPhotosTable(this);
  late final $JournalTagsTable journalTags = $JournalTagsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    testVenues,
    journalEntries,
    testVisits,
    journalPhotos,
    journalTags,
  ];
}

typedef $$TestVenuesTableCreateCompanionBuilder =
    TestVenuesCompanion Function({
      Value<int> id,
      required String name,
      Value<double?> lat,
      Value<double?> lng,
      Value<double?> pinAccuracyM,
      Value<DateTime?> pinCapturedAt,
      Value<DateTime> createdAt,
      required TestVenueKind kind,
    });
typedef $$TestVenuesTableUpdateCompanionBuilder =
    TestVenuesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double?> lat,
      Value<double?> lng,
      Value<double?> pinAccuracyM,
      Value<DateTime?> pinCapturedAt,
      Value<DateTime> createdAt,
      Value<TestVenueKind> kind,
    });

class $$TestVenuesTableFilterComposer
    extends Composer<_$PlacesTestDb, $TestVenuesTable> {
  $$TestVenuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pinAccuracyM => $composableBuilder(
    column: $table.pinAccuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pinCapturedAt => $composableBuilder(
    column: $table.pinCapturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TestVenueKind, TestVenueKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$TestVenuesTableOrderingComposer
    extends Composer<_$PlacesTestDb, $TestVenuesTable> {
  $$TestVenuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pinAccuracyM => $composableBuilder(
    column: $table.pinAccuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pinCapturedAt => $composableBuilder(
    column: $table.pinCapturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TestVenuesTableAnnotationComposer
    extends Composer<_$PlacesTestDb, $TestVenuesTable> {
  $$TestVenuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get pinAccuracyM => $composableBuilder(
    column: $table.pinAccuracyM,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pinCapturedAt => $composableBuilder(
    column: $table.pinCapturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TestVenueKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$TestVenuesTableTableManager
    extends
        RootTableManager<
          _$PlacesTestDb,
          $TestVenuesTable,
          TestVenue,
          $$TestVenuesTableFilterComposer,
          $$TestVenuesTableOrderingComposer,
          $$TestVenuesTableAnnotationComposer,
          $$TestVenuesTableCreateCompanionBuilder,
          $$TestVenuesTableUpdateCompanionBuilder,
          (
            TestVenue,
            BaseReferences<_$PlacesTestDb, $TestVenuesTable, TestVenue>,
          ),
          TestVenue,
          PrefetchHooks Function()
        > {
  $$TestVenuesTableTableManager(_$PlacesTestDb db, $TestVenuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TestVenuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TestVenuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TestVenuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<double?> pinAccuracyM = const Value.absent(),
                Value<DateTime?> pinCapturedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<TestVenueKind> kind = const Value.absent(),
              }) => TestVenuesCompanion(
                id: id,
                name: name,
                lat: lat,
                lng: lng,
                pinAccuracyM: pinAccuracyM,
                pinCapturedAt: pinCapturedAt,
                createdAt: createdAt,
                kind: kind,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<double?> pinAccuracyM = const Value.absent(),
                Value<DateTime?> pinCapturedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                required TestVenueKind kind,
              }) => TestVenuesCompanion.insert(
                id: id,
                name: name,
                lat: lat,
                lng: lng,
                pinAccuracyM: pinAccuracyM,
                pinCapturedAt: pinCapturedAt,
                createdAt: createdAt,
                kind: kind,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TestVenuesTableProcessedTableManager =
    ProcessedTableManager<
      _$PlacesTestDb,
      $TestVenuesTable,
      TestVenue,
      $$TestVenuesTableFilterComposer,
      $$TestVenuesTableOrderingComposer,
      $$TestVenuesTableAnnotationComposer,
      $$TestVenuesTableCreateCompanionBuilder,
      $$TestVenuesTableUpdateCompanionBuilder,
      (TestVenue, BaseReferences<_$PlacesTestDb, $TestVenuesTable, TestVenue>),
      TestVenue,
      PrefetchHooks Function()
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      Value<String?> notes,
      Value<int?> rating,
      Value<DateTime> createdAt,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      Value<String?> notes,
      Value<int?> rating,
      Value<DateTime> createdAt,
    });

class $$JournalEntriesTableFilterComposer
    extends Composer<_$PlacesTestDb, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$PlacesTestDb, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$PlacesTestDb, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$PlacesTestDb,
          $JournalEntriesTable,
          JournalEntry,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (
            JournalEntry,
            BaseReferences<_$PlacesTestDb, $JournalEntriesTable, JournalEntry>,
          ),
          JournalEntry,
          PrefetchHooks Function()
        > {
  $$JournalEntriesTableTableManager(
    _$PlacesTestDb db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => JournalEntriesCompanion(
                id: id,
                notes: notes,
                rating: rating,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => JournalEntriesCompanion.insert(
                id: id,
                notes: notes,
                rating: rating,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$PlacesTestDb,
      $JournalEntriesTable,
      JournalEntry,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (
        JournalEntry,
        BaseReferences<_$PlacesTestDb, $JournalEntriesTable, JournalEntry>,
      ),
      JournalEntry,
      PrefetchHooks Function()
    >;
typedef $$TestVisitsTableCreateCompanionBuilder =
    TestVisitsCompanion Function({
      Value<int> id,
      required int placeId,
      required DateTime visitedAt,
      Value<int?> journalEntryId,
    });
typedef $$TestVisitsTableUpdateCompanionBuilder =
    TestVisitsCompanion Function({
      Value<int> id,
      Value<int> placeId,
      Value<DateTime> visitedAt,
      Value<int?> journalEntryId,
    });

class $$TestVisitsTableFilterComposer
    extends Composer<_$PlacesTestDb, $TestVisitsTable> {
  $$TestVisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get placeId => $composableBuilder(
    column: $table.placeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get journalEntryId => $composableBuilder(
    column: $table.journalEntryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TestVisitsTableOrderingComposer
    extends Composer<_$PlacesTestDb, $TestVisitsTable> {
  $$TestVisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get placeId => $composableBuilder(
    column: $table.placeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get journalEntryId => $composableBuilder(
    column: $table.journalEntryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TestVisitsTableAnnotationComposer
    extends Composer<_$PlacesTestDb, $TestVisitsTable> {
  $$TestVisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get placeId =>
      $composableBuilder(column: $table.placeId, builder: (column) => column);

  GeneratedColumn<DateTime> get visitedAt =>
      $composableBuilder(column: $table.visitedAt, builder: (column) => column);

  GeneratedColumn<int> get journalEntryId => $composableBuilder(
    column: $table.journalEntryId,
    builder: (column) => column,
  );
}

class $$TestVisitsTableTableManager
    extends
        RootTableManager<
          _$PlacesTestDb,
          $TestVisitsTable,
          TestVisit,
          $$TestVisitsTableFilterComposer,
          $$TestVisitsTableOrderingComposer,
          $$TestVisitsTableAnnotationComposer,
          $$TestVisitsTableCreateCompanionBuilder,
          $$TestVisitsTableUpdateCompanionBuilder,
          (
            TestVisit,
            BaseReferences<_$PlacesTestDb, $TestVisitsTable, TestVisit>,
          ),
          TestVisit,
          PrefetchHooks Function()
        > {
  $$TestVisitsTableTableManager(_$PlacesTestDb db, $TestVisitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TestVisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TestVisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TestVisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> placeId = const Value.absent(),
                Value<DateTime> visitedAt = const Value.absent(),
                Value<int?> journalEntryId = const Value.absent(),
              }) => TestVisitsCompanion(
                id: id,
                placeId: placeId,
                visitedAt: visitedAt,
                journalEntryId: journalEntryId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int placeId,
                required DateTime visitedAt,
                Value<int?> journalEntryId = const Value.absent(),
              }) => TestVisitsCompanion.insert(
                id: id,
                placeId: placeId,
                visitedAt: visitedAt,
                journalEntryId: journalEntryId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TestVisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlacesTestDb,
      $TestVisitsTable,
      TestVisit,
      $$TestVisitsTableFilterComposer,
      $$TestVisitsTableOrderingComposer,
      $$TestVisitsTableAnnotationComposer,
      $$TestVisitsTableCreateCompanionBuilder,
      $$TestVisitsTableUpdateCompanionBuilder,
      (TestVisit, BaseReferences<_$PlacesTestDb, $TestVisitsTable, TestVisit>),
      TestVisit,
      PrefetchHooks Function()
    >;
typedef $$JournalPhotosTableCreateCompanionBuilder =
    JournalPhotosCompanion Function({
      Value<int> id,
      required int entryId,
      required String path,
      Value<String?> caption,
    });
typedef $$JournalPhotosTableUpdateCompanionBuilder =
    JournalPhotosCompanion Function({
      Value<int> id,
      Value<int> entryId,
      Value<String> path,
      Value<String?> caption,
    });

class $$JournalPhotosTableFilterComposer
    extends Composer<_$PlacesTestDb, $JournalPhotosTable> {
  $$JournalPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalPhotosTableOrderingComposer
    extends Composer<_$PlacesTestDb, $JournalPhotosTable> {
  $$JournalPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalPhotosTableAnnotationComposer
    extends Composer<_$PlacesTestDb, $JournalPhotosTable> {
  $$JournalPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);
}

class $$JournalPhotosTableTableManager
    extends
        RootTableManager<
          _$PlacesTestDb,
          $JournalPhotosTable,
          JournalPhoto,
          $$JournalPhotosTableFilterComposer,
          $$JournalPhotosTableOrderingComposer,
          $$JournalPhotosTableAnnotationComposer,
          $$JournalPhotosTableCreateCompanionBuilder,
          $$JournalPhotosTableUpdateCompanionBuilder,
          (
            JournalPhoto,
            BaseReferences<_$PlacesTestDb, $JournalPhotosTable, JournalPhoto>,
          ),
          JournalPhoto,
          PrefetchHooks Function()
        > {
  $$JournalPhotosTableTableManager(_$PlacesTestDb db, $JournalPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> caption = const Value.absent(),
              }) => JournalPhotosCompanion(
                id: id,
                entryId: entryId,
                path: path,
                caption: caption,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int entryId,
                required String path,
                Value<String?> caption = const Value.absent(),
              }) => JournalPhotosCompanion.insert(
                id: id,
                entryId: entryId,
                path: path,
                caption: caption,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$PlacesTestDb,
      $JournalPhotosTable,
      JournalPhoto,
      $$JournalPhotosTableFilterComposer,
      $$JournalPhotosTableOrderingComposer,
      $$JournalPhotosTableAnnotationComposer,
      $$JournalPhotosTableCreateCompanionBuilder,
      $$JournalPhotosTableUpdateCompanionBuilder,
      (
        JournalPhoto,
        BaseReferences<_$PlacesTestDb, $JournalPhotosTable, JournalPhoto>,
      ),
      JournalPhoto,
      PrefetchHooks Function()
    >;
typedef $$JournalTagsTableCreateCompanionBuilder =
    JournalTagsCompanion Function({
      Value<int> id,
      required int entryId,
      required String tag,
    });
typedef $$JournalTagsTableUpdateCompanionBuilder =
    JournalTagsCompanion Function({
      Value<int> id,
      Value<int> entryId,
      Value<String> tag,
    });

class $$JournalTagsTableFilterComposer
    extends Composer<_$PlacesTestDb, $JournalTagsTable> {
  $$JournalTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalTagsTableOrderingComposer
    extends Composer<_$PlacesTestDb, $JournalTagsTable> {
  $$JournalTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalTagsTableAnnotationComposer
    extends Composer<_$PlacesTestDb, $JournalTagsTable> {
  $$JournalTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);
}

class $$JournalTagsTableTableManager
    extends
        RootTableManager<
          _$PlacesTestDb,
          $JournalTagsTable,
          JournalTag,
          $$JournalTagsTableFilterComposer,
          $$JournalTagsTableOrderingComposer,
          $$JournalTagsTableAnnotationComposer,
          $$JournalTagsTableCreateCompanionBuilder,
          $$JournalTagsTableUpdateCompanionBuilder,
          (
            JournalTag,
            BaseReferences<_$PlacesTestDb, $JournalTagsTable, JournalTag>,
          ),
          JournalTag,
          PrefetchHooks Function()
        > {
  $$JournalTagsTableTableManager(_$PlacesTestDb db, $JournalTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<String> tag = const Value.absent(),
              }) => JournalTagsCompanion(id: id, entryId: entryId, tag: tag),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int entryId,
                required String tag,
              }) => JournalTagsCompanion.insert(
                id: id,
                entryId: entryId,
                tag: tag,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlacesTestDb,
      $JournalTagsTable,
      JournalTag,
      $$JournalTagsTableFilterComposer,
      $$JournalTagsTableOrderingComposer,
      $$JournalTagsTableAnnotationComposer,
      $$JournalTagsTableCreateCompanionBuilder,
      $$JournalTagsTableUpdateCompanionBuilder,
      (
        JournalTag,
        BaseReferences<_$PlacesTestDb, $JournalTagsTable, JournalTag>,
      ),
      JournalTag,
      PrefetchHooks Function()
    >;

class $PlacesTestDbManager {
  final _$PlacesTestDb _db;
  $PlacesTestDbManager(this._db);
  $$TestVenuesTableTableManager get testVenues =>
      $$TestVenuesTableTableManager(_db, _db.testVenues);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$TestVisitsTableTableManager get testVisits =>
      $$TestVisitsTableTableManager(_db, _db.testVisits);
  $$JournalPhotosTableTableManager get journalPhotos =>
      $$JournalPhotosTableTableManager(_db, _db.journalPhotos);
  $$JournalTagsTableTableManager get journalTags =>
      $$JournalTagsTableTableManager(_db, _db.journalTags);
}
