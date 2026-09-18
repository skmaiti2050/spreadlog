// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AircraftModelsTableTable extends AircraftModelsTable
    with TableInfo<$AircraftModelsTableTable, AircraftModelsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AircraftModelsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aircraftClassMeta = const VerificationMeta(
    'aircraftClass',
  );
  @override
  late final GeneratedColumn<int> aircraftClass = GeneratedColumn<int>(
    'aircraft_class',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<int> category = GeneratedColumn<int>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    manufacturer,
    model,
    aircraftClass,
    category,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aircraft_models_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AircraftModelsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manufacturerMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('aircraft_class')) {
      context.handle(
        _aircraftClassMeta,
        aircraftClass.isAcceptableOrUnknown(
          data['aircraft_class']!,
          _aircraftClassMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aircraftClassMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AircraftModelsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AircraftModelsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      aircraftClass: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aircraft_class'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AircraftModelsTableTable createAlias(String alias) {
    return $AircraftModelsTableTable(attachedDatabase, alias);
  }
}

class AircraftModelsTableData extends DataClass
    implements Insertable<AircraftModelsTableData> {
  final String id;
  final String manufacturer;
  final String model;
  final int aircraftClass;
  final int category;
  final DateTime createdAt;
  const AircraftModelsTableData({
    required this.id,
    required this.manufacturer,
    required this.model,
    required this.aircraftClass,
    required this.category,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['manufacturer'] = Variable<String>(manufacturer);
    map['model'] = Variable<String>(model);
    map['aircraft_class'] = Variable<int>(aircraftClass);
    map['category'] = Variable<int>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AircraftModelsTableCompanion toCompanion(bool nullToAbsent) {
    return AircraftModelsTableCompanion(
      id: Value(id),
      manufacturer: Value(manufacturer),
      model: Value(model),
      aircraftClass: Value(aircraftClass),
      category: Value(category),
      createdAt: Value(createdAt),
    );
  }

  factory AircraftModelsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AircraftModelsTableData(
      id: serializer.fromJson<String>(json['id']),
      manufacturer: serializer.fromJson<String>(json['manufacturer']),
      model: serializer.fromJson<String>(json['model']),
      aircraftClass: serializer.fromJson<int>(json['aircraftClass']),
      category: serializer.fromJson<int>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'manufacturer': serializer.toJson<String>(manufacturer),
      'model': serializer.toJson<String>(model),
      'aircraftClass': serializer.toJson<int>(aircraftClass),
      'category': serializer.toJson<int>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AircraftModelsTableData copyWith({
    String? id,
    String? manufacturer,
    String? model,
    int? aircraftClass,
    int? category,
    DateTime? createdAt,
  }) => AircraftModelsTableData(
    id: id ?? this.id,
    manufacturer: manufacturer ?? this.manufacturer,
    model: model ?? this.model,
    aircraftClass: aircraftClass ?? this.aircraftClass,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
  );
  AircraftModelsTableData copyWithCompanion(AircraftModelsTableCompanion data) {
    return AircraftModelsTableData(
      id: data.id.present ? data.id.value : this.id,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      model: data.model.present ? data.model.value : this.model,
      aircraftClass: data.aircraftClass.present
          ? data.aircraftClass.value
          : this.aircraftClass,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AircraftModelsTableData(')
          ..write('id: $id, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, manufacturer, model, aircraftClass, category, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AircraftModelsTableData &&
          other.id == this.id &&
          other.manufacturer == this.manufacturer &&
          other.model == this.model &&
          other.aircraftClass == this.aircraftClass &&
          other.category == this.category &&
          other.createdAt == this.createdAt);
}

class AircraftModelsTableCompanion
    extends UpdateCompanion<AircraftModelsTableData> {
  final Value<String> id;
  final Value<String> manufacturer;
  final Value<String> model;
  final Value<int> aircraftClass;
  final Value<int> category;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AircraftModelsTableCompanion({
    this.id = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.aircraftClass = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AircraftModelsTableCompanion.insert({
    required String id,
    required String manufacturer,
    required String model,
    required int aircraftClass,
    required int category,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       manufacturer = Value(manufacturer),
       model = Value(model),
       aircraftClass = Value(aircraftClass),
       category = Value(category),
       createdAt = Value(createdAt);
  static Insertable<AircraftModelsTableData> custom({
    Expression<String>? id,
    Expression<String>? manufacturer,
    Expression<String>? model,
    Expression<int>? aircraftClass,
    Expression<int>? category,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (aircraftClass != null) 'aircraft_class': aircraftClass,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AircraftModelsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? manufacturer,
    Value<String>? model,
    Value<int>? aircraftClass,
    Value<int>? category,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AircraftModelsTableCompanion(
      id: id ?? this.id,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      aircraftClass: aircraftClass ?? this.aircraftClass,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (aircraftClass.present) {
      map['aircraft_class'] = Variable<int>(aircraftClass.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AircraftModelsTableCompanion(')
          ..write('id: $id, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlightsTableTable extends FlightsTable
    with TableInfo<$FlightsTableTable, FlightsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlightsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aircraftModelIdMeta = const VerificationMeta(
    'aircraftModelId',
  );
  @override
  late final GeneratedColumn<String> aircraftModelId = GeneratedColumn<String>(
    'aircraft_model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES aircraft_models_table (id)',
    ),
  );
  static const VerificationMeta _registrationMeta = const VerificationMeta(
    'registration',
  );
  @override
  late final GeneratedColumn<String> registration = GeneratedColumn<String>(
    'registration',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _picNameMeta = const VerificationMeta(
    'picName',
  );
  @override
  late final GeneratedColumn<String> picName = GeneratedColumn<String>(
    'pic_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _soloCrossCountryMeta = const VerificationMeta(
    'soloCrossCountry',
  );
  @override
  late final GeneratedColumn<bool> soloCrossCountry = GeneratedColumn<bool>(
    'solo_cross_country',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("solo_cross_country" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fstdActualMinutesMeta = const VerificationMeta(
    'fstdActualMinutes',
  );
  @override
  late final GeneratedColumn<int> fstdActualMinutes = GeneratedColumn<int>(
    'fstd_actual_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    aircraftModelId,
    registration,
    picName,
    remarks,
    soloCrossCountry,
    fstdActualMinutes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flights_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlightsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('aircraft_model_id')) {
      context.handle(
        _aircraftModelIdMeta,
        aircraftModelId.isAcceptableOrUnknown(
          data['aircraft_model_id']!,
          _aircraftModelIdMeta,
        ),
      );
    }
    if (data.containsKey('registration')) {
      context.handle(
        _registrationMeta,
        registration.isAcceptableOrUnknown(
          data['registration']!,
          _registrationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registrationMeta);
    }
    if (data.containsKey('pic_name')) {
      context.handle(
        _picNameMeta,
        picName.isAcceptableOrUnknown(data['pic_name']!, _picNameMeta),
      );
    } else if (isInserting) {
      context.missing(_picNameMeta);
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('solo_cross_country')) {
      context.handle(
        _soloCrossCountryMeta,
        soloCrossCountry.isAcceptableOrUnknown(
          data['solo_cross_country']!,
          _soloCrossCountryMeta,
        ),
      );
    }
    if (data.containsKey('fstd_actual_minutes')) {
      context.handle(
        _fstdActualMinutesMeta,
        fstdActualMinutes.isAcceptableOrUnknown(
          data['fstd_actual_minutes']!,
          _fstdActualMinutesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FlightsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlightsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      aircraftModelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aircraft_model_id'],
      ),
      registration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration'],
      )!,
      picName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pic_name'],
      )!,
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      )!,
      soloCrossCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}solo_cross_country'],
      )!,
      fstdActualMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fstd_actual_minutes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FlightsTableTable createAlias(String alias) {
    return $FlightsTableTable(attachedDatabase, alias);
  }
}

class FlightsTableData extends DataClass
    implements Insertable<FlightsTableData> {
  final String id;
  final DateTime date;
  final String? aircraftModelId;
  final String registration;
  final String picName;
  final String remarks;
  final bool soloCrossCountry;
  final int fstdActualMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FlightsTableData({
    required this.id,
    required this.date,
    this.aircraftModelId,
    required this.registration,
    required this.picName,
    required this.remarks,
    required this.soloCrossCountry,
    required this.fstdActualMinutes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || aircraftModelId != null) {
      map['aircraft_model_id'] = Variable<String>(aircraftModelId);
    }
    map['registration'] = Variable<String>(registration);
    map['pic_name'] = Variable<String>(picName);
    map['remarks'] = Variable<String>(remarks);
    map['solo_cross_country'] = Variable<bool>(soloCrossCountry);
    map['fstd_actual_minutes'] = Variable<int>(fstdActualMinutes);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FlightsTableCompanion toCompanion(bool nullToAbsent) {
    return FlightsTableCompanion(
      id: Value(id),
      date: Value(date),
      aircraftModelId: aircraftModelId == null && nullToAbsent
          ? const Value.absent()
          : Value(aircraftModelId),
      registration: Value(registration),
      picName: Value(picName),
      remarks: Value(remarks),
      soloCrossCountry: Value(soloCrossCountry),
      fstdActualMinutes: Value(fstdActualMinutes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FlightsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlightsTableData(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      aircraftModelId: serializer.fromJson<String?>(json['aircraftModelId']),
      registration: serializer.fromJson<String>(json['registration']),
      picName: serializer.fromJson<String>(json['picName']),
      remarks: serializer.fromJson<String>(json['remarks']),
      soloCrossCountry: serializer.fromJson<bool>(json['soloCrossCountry']),
      fstdActualMinutes: serializer.fromJson<int>(json['fstdActualMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'aircraftModelId': serializer.toJson<String?>(aircraftModelId),
      'registration': serializer.toJson<String>(registration),
      'picName': serializer.toJson<String>(picName),
      'remarks': serializer.toJson<String>(remarks),
      'soloCrossCountry': serializer.toJson<bool>(soloCrossCountry),
      'fstdActualMinutes': serializer.toJson<int>(fstdActualMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FlightsTableData copyWith({
    String? id,
    DateTime? date,
    Value<String?> aircraftModelId = const Value.absent(),
    String? registration,
    String? picName,
    String? remarks,
    bool? soloCrossCountry,
    int? fstdActualMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FlightsTableData(
    id: id ?? this.id,
    date: date ?? this.date,
    aircraftModelId: aircraftModelId.present
        ? aircraftModelId.value
        : this.aircraftModelId,
    registration: registration ?? this.registration,
    picName: picName ?? this.picName,
    remarks: remarks ?? this.remarks,
    soloCrossCountry: soloCrossCountry ?? this.soloCrossCountry,
    fstdActualMinutes: fstdActualMinutes ?? this.fstdActualMinutes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FlightsTableData copyWithCompanion(FlightsTableCompanion data) {
    return FlightsTableData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      aircraftModelId: data.aircraftModelId.present
          ? data.aircraftModelId.value
          : this.aircraftModelId,
      registration: data.registration.present
          ? data.registration.value
          : this.registration,
      picName: data.picName.present ? data.picName.value : this.picName,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      soloCrossCountry: data.soloCrossCountry.present
          ? data.soloCrossCountry.value
          : this.soloCrossCountry,
      fstdActualMinutes: data.fstdActualMinutes.present
          ? data.fstdActualMinutes.value
          : this.fstdActualMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlightsTableData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('aircraftModelId: $aircraftModelId, ')
          ..write('registration: $registration, ')
          ..write('picName: $picName, ')
          ..write('remarks: $remarks, ')
          ..write('soloCrossCountry: $soloCrossCountry, ')
          ..write('fstdActualMinutes: $fstdActualMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    aircraftModelId,
    registration,
    picName,
    remarks,
    soloCrossCountry,
    fstdActualMinutes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlightsTableData &&
          other.id == this.id &&
          other.date == this.date &&
          other.aircraftModelId == this.aircraftModelId &&
          other.registration == this.registration &&
          other.picName == this.picName &&
          other.remarks == this.remarks &&
          other.soloCrossCountry == this.soloCrossCountry &&
          other.fstdActualMinutes == this.fstdActualMinutes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FlightsTableCompanion extends UpdateCompanion<FlightsTableData> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<String?> aircraftModelId;
  final Value<String> registration;
  final Value<String> picName;
  final Value<String> remarks;
  final Value<bool> soloCrossCountry;
  final Value<int> fstdActualMinutes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FlightsTableCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.aircraftModelId = const Value.absent(),
    this.registration = const Value.absent(),
    this.picName = const Value.absent(),
    this.remarks = const Value.absent(),
    this.soloCrossCountry = const Value.absent(),
    this.fstdActualMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlightsTableCompanion.insert({
    required String id,
    required DateTime date,
    this.aircraftModelId = const Value.absent(),
    required String registration,
    required String picName,
    this.remarks = const Value.absent(),
    this.soloCrossCountry = const Value.absent(),
    this.fstdActualMinutes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       registration = Value(registration),
       picName = Value(picName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FlightsTableData> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? aircraftModelId,
    Expression<String>? registration,
    Expression<String>? picName,
    Expression<String>? remarks,
    Expression<bool>? soloCrossCountry,
    Expression<int>? fstdActualMinutes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (aircraftModelId != null) 'aircraft_model_id': aircraftModelId,
      if (registration != null) 'registration': registration,
      if (picName != null) 'pic_name': picName,
      if (remarks != null) 'remarks': remarks,
      if (soloCrossCountry != null) 'solo_cross_country': soloCrossCountry,
      if (fstdActualMinutes != null) 'fstd_actual_minutes': fstdActualMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlightsTableCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<String?>? aircraftModelId,
    Value<String>? registration,
    Value<String>? picName,
    Value<String>? remarks,
    Value<bool>? soloCrossCountry,
    Value<int>? fstdActualMinutes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FlightsTableCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      aircraftModelId: aircraftModelId ?? this.aircraftModelId,
      registration: registration ?? this.registration,
      picName: picName ?? this.picName,
      remarks: remarks ?? this.remarks,
      soloCrossCountry: soloCrossCountry ?? this.soloCrossCountry,
      fstdActualMinutes: fstdActualMinutes ?? this.fstdActualMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (aircraftModelId.present) {
      map['aircraft_model_id'] = Variable<String>(aircraftModelId.value);
    }
    if (registration.present) {
      map['registration'] = Variable<String>(registration.value);
    }
    if (picName.present) {
      map['pic_name'] = Variable<String>(picName.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (soloCrossCountry.present) {
      map['solo_cross_country'] = Variable<bool>(soloCrossCountry.value);
    }
    if (fstdActualMinutes.present) {
      map['fstd_actual_minutes'] = Variable<int>(fstdActualMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlightsTableCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('aircraftModelId: $aircraftModelId, ')
          ..write('registration: $registration, ')
          ..write('picName: $picName, ')
          ..write('remarks: $remarks, ')
          ..write('soloCrossCountry: $soloCrossCountry, ')
          ..write('fstdActualMinutes: $fstdActualMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlightTimesTableTable extends FlightTimesTable
    with TableInfo<$FlightTimesTableTable, FlightTimesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlightTimesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flightIdMeta = const VerificationMeta(
    'flightId',
  );
  @override
  late final GeneratedColumn<String> flightId = GeneratedColumn<String>(
    'flight_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES flights_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _aircraftClassMeta = const VerificationMeta(
    'aircraftClass',
  );
  @override
  late final GeneratedColumn<int> aircraftClass = GeneratedColumn<int>(
    'aircraft_class',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<int> period = GeneratedColumn<int>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<int> role = GeneratedColumn<int>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    flightId,
    aircraftClass,
    period,
    role,
    durationMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flight_times_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlightTimesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('flight_id')) {
      context.handle(
        _flightIdMeta,
        flightId.isAcceptableOrUnknown(data['flight_id']!, _flightIdMeta),
      );
    } else if (isInserting) {
      context.missing(_flightIdMeta);
    }
    if (data.containsKey('aircraft_class')) {
      context.handle(
        _aircraftClassMeta,
        aircraftClass.isAcceptableOrUnknown(
          data['aircraft_class']!,
          _aircraftClassMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aircraftClassMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FlightTimesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlightTimesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      flightId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flight_id'],
      )!,
      aircraftClass: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aircraft_class'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}role'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
    );
  }

  @override
  $FlightTimesTableTable createAlias(String alias) {
    return $FlightTimesTableTable(attachedDatabase, alias);
  }
}

class FlightTimesTableData extends DataClass
    implements Insertable<FlightTimesTableData> {
  final String id;
  final String flightId;
  final int aircraftClass;
  final int period;
  final int role;
  final int durationMinutes;
  const FlightTimesTableData({
    required this.id,
    required this.flightId,
    required this.aircraftClass,
    required this.period,
    required this.role,
    required this.durationMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['flight_id'] = Variable<String>(flightId);
    map['aircraft_class'] = Variable<int>(aircraftClass);
    map['period'] = Variable<int>(period);
    map['role'] = Variable<int>(role);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    return map;
  }

  FlightTimesTableCompanion toCompanion(bool nullToAbsent) {
    return FlightTimesTableCompanion(
      id: Value(id),
      flightId: Value(flightId),
      aircraftClass: Value(aircraftClass),
      period: Value(period),
      role: Value(role),
      durationMinutes: Value(durationMinutes),
    );
  }

  factory FlightTimesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlightTimesTableData(
      id: serializer.fromJson<String>(json['id']),
      flightId: serializer.fromJson<String>(json['flightId']),
      aircraftClass: serializer.fromJson<int>(json['aircraftClass']),
      period: serializer.fromJson<int>(json['period']),
      role: serializer.fromJson<int>(json['role']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'flightId': serializer.toJson<String>(flightId),
      'aircraftClass': serializer.toJson<int>(aircraftClass),
      'period': serializer.toJson<int>(period),
      'role': serializer.toJson<int>(role),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
    };
  }

  FlightTimesTableData copyWith({
    String? id,
    String? flightId,
    int? aircraftClass,
    int? period,
    int? role,
    int? durationMinutes,
  }) => FlightTimesTableData(
    id: id ?? this.id,
    flightId: flightId ?? this.flightId,
    aircraftClass: aircraftClass ?? this.aircraftClass,
    period: period ?? this.period,
    role: role ?? this.role,
    durationMinutes: durationMinutes ?? this.durationMinutes,
  );
  FlightTimesTableData copyWithCompanion(FlightTimesTableCompanion data) {
    return FlightTimesTableData(
      id: data.id.present ? data.id.value : this.id,
      flightId: data.flightId.present ? data.flightId.value : this.flightId,
      aircraftClass: data.aircraftClass.present
          ? data.aircraftClass.value
          : this.aircraftClass,
      period: data.period.present ? data.period.value : this.period,
      role: data.role.present ? data.role.value : this.role,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlightTimesTableData(')
          ..write('id: $id, ')
          ..write('flightId: $flightId, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('period: $period, ')
          ..write('role: $role, ')
          ..write('durationMinutes: $durationMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, flightId, aircraftClass, period, role, durationMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlightTimesTableData &&
          other.id == this.id &&
          other.flightId == this.flightId &&
          other.aircraftClass == this.aircraftClass &&
          other.period == this.period &&
          other.role == this.role &&
          other.durationMinutes == this.durationMinutes);
}

class FlightTimesTableCompanion extends UpdateCompanion<FlightTimesTableData> {
  final Value<String> id;
  final Value<String> flightId;
  final Value<int> aircraftClass;
  final Value<int> period;
  final Value<int> role;
  final Value<int> durationMinutes;
  final Value<int> rowid;
  const FlightTimesTableCompanion({
    this.id = const Value.absent(),
    this.flightId = const Value.absent(),
    this.aircraftClass = const Value.absent(),
    this.period = const Value.absent(),
    this.role = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlightTimesTableCompanion.insert({
    required String id,
    required String flightId,
    required int aircraftClass,
    required int period,
    required int role,
    required int durationMinutes,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       flightId = Value(flightId),
       aircraftClass = Value(aircraftClass),
       period = Value(period),
       role = Value(role),
       durationMinutes = Value(durationMinutes);
  static Insertable<FlightTimesTableData> custom({
    Expression<String>? id,
    Expression<String>? flightId,
    Expression<int>? aircraftClass,
    Expression<int>? period,
    Expression<int>? role,
    Expression<int>? durationMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (flightId != null) 'flight_id': flightId,
      if (aircraftClass != null) 'aircraft_class': aircraftClass,
      if (period != null) 'period': period,
      if (role != null) 'role': role,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlightTimesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? flightId,
    Value<int>? aircraftClass,
    Value<int>? period,
    Value<int>? role,
    Value<int>? durationMinutes,
    Value<int>? rowid,
  }) {
    return FlightTimesTableCompanion(
      id: id ?? this.id,
      flightId: flightId ?? this.flightId,
      aircraftClass: aircraftClass ?? this.aircraftClass,
      period: period ?? this.period,
      role: role ?? this.role,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (flightId.present) {
      map['flight_id'] = Variable<String>(flightId.value);
    }
    if (aircraftClass.present) {
      map['aircraft_class'] = Variable<int>(aircraftClass.value);
    }
    if (period.present) {
      map['period'] = Variable<int>(period.value);
    }
    if (role.present) {
      map['role'] = Variable<int>(role.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlightTimesTableCompanion(')
          ..write('id: $id, ')
          ..write('flightId: $flightId, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('period: $period, ')
          ..write('role: $role, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstrumentTimesTableTable extends InstrumentTimesTable
    with TableInfo<$InstrumentTimesTableTable, InstrumentTimesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstrumentTimesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flightIdMeta = const VerificationMeta(
    'flightId',
  );
  @override
  late final GeneratedColumn<String> flightId = GeneratedColumn<String>(
    'flight_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES flights_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _navaidsMeta = const VerificationMeta(
    'navaids',
  );
  @override
  late final GeneratedColumn<String> navaids = GeneratedColumn<String>(
    'navaids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeMeta = const VerificationMeta('place');
  @override
  late final GeneratedColumn<String> place = GeneratedColumn<String>(
    'place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualMinutesMeta = const VerificationMeta(
    'actualMinutes',
  );
  @override
  late final GeneratedColumn<int> actualMinutes = GeneratedColumn<int>(
    'actual_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fstdMinutesMeta = const VerificationMeta(
    'fstdMinutes',
  );
  @override
  late final GeneratedColumn<int> fstdMinutes = GeneratedColumn<int>(
    'fstd_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    flightId,
    navaids,
    place,
    actualMinutes,
    fstdMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instrument_times_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstrumentTimesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('flight_id')) {
      context.handle(
        _flightIdMeta,
        flightId.isAcceptableOrUnknown(data['flight_id']!, _flightIdMeta),
      );
    } else if (isInserting) {
      context.missing(_flightIdMeta);
    }
    if (data.containsKey('navaids')) {
      context.handle(
        _navaidsMeta,
        navaids.isAcceptableOrUnknown(data['navaids']!, _navaidsMeta),
      );
    }
    if (data.containsKey('place')) {
      context.handle(
        _placeMeta,
        place.isAcceptableOrUnknown(data['place']!, _placeMeta),
      );
    }
    if (data.containsKey('actual_minutes')) {
      context.handle(
        _actualMinutesMeta,
        actualMinutes.isAcceptableOrUnknown(
          data['actual_minutes']!,
          _actualMinutesMeta,
        ),
      );
    }
    if (data.containsKey('fstd_minutes')) {
      context.handle(
        _fstdMinutesMeta,
        fstdMinutes.isAcceptableOrUnknown(
          data['fstd_minutes']!,
          _fstdMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstrumentTimesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstrumentTimesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      flightId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flight_id'],
      )!,
      navaids: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}navaids'],
      ),
      place: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place'],
      ),
      actualMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_minutes'],
      )!,
      fstdMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fstd_minutes'],
      )!,
    );
  }

  @override
  $InstrumentTimesTableTable createAlias(String alias) {
    return $InstrumentTimesTableTable(attachedDatabase, alias);
  }
}

class InstrumentTimesTableData extends DataClass
    implements Insertable<InstrumentTimesTableData> {
  final String id;
  final String flightId;
  final String? navaids;
  final String? place;
  final int actualMinutes;
  final int fstdMinutes;
  const InstrumentTimesTableData({
    required this.id,
    required this.flightId,
    this.navaids,
    this.place,
    required this.actualMinutes,
    required this.fstdMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['flight_id'] = Variable<String>(flightId);
    if (!nullToAbsent || navaids != null) {
      map['navaids'] = Variable<String>(navaids);
    }
    if (!nullToAbsent || place != null) {
      map['place'] = Variable<String>(place);
    }
    map['actual_minutes'] = Variable<int>(actualMinutes);
    map['fstd_minutes'] = Variable<int>(fstdMinutes);
    return map;
  }

  InstrumentTimesTableCompanion toCompanion(bool nullToAbsent) {
    return InstrumentTimesTableCompanion(
      id: Value(id),
      flightId: Value(flightId),
      navaids: navaids == null && nullToAbsent
          ? const Value.absent()
          : Value(navaids),
      place: place == null && nullToAbsent
          ? const Value.absent()
          : Value(place),
      actualMinutes: Value(actualMinutes),
      fstdMinutes: Value(fstdMinutes),
    );
  }

  factory InstrumentTimesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstrumentTimesTableData(
      id: serializer.fromJson<String>(json['id']),
      flightId: serializer.fromJson<String>(json['flightId']),
      navaids: serializer.fromJson<String?>(json['navaids']),
      place: serializer.fromJson<String?>(json['place']),
      actualMinutes: serializer.fromJson<int>(json['actualMinutes']),
      fstdMinutes: serializer.fromJson<int>(json['fstdMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'flightId': serializer.toJson<String>(flightId),
      'navaids': serializer.toJson<String?>(navaids),
      'place': serializer.toJson<String?>(place),
      'actualMinutes': serializer.toJson<int>(actualMinutes),
      'fstdMinutes': serializer.toJson<int>(fstdMinutes),
    };
  }

  InstrumentTimesTableData copyWith({
    String? id,
    String? flightId,
    Value<String?> navaids = const Value.absent(),
    Value<String?> place = const Value.absent(),
    int? actualMinutes,
    int? fstdMinutes,
  }) => InstrumentTimesTableData(
    id: id ?? this.id,
    flightId: flightId ?? this.flightId,
    navaids: navaids.present ? navaids.value : this.navaids,
    place: place.present ? place.value : this.place,
    actualMinutes: actualMinutes ?? this.actualMinutes,
    fstdMinutes: fstdMinutes ?? this.fstdMinutes,
  );
  InstrumentTimesTableData copyWithCompanion(
    InstrumentTimesTableCompanion data,
  ) {
    return InstrumentTimesTableData(
      id: data.id.present ? data.id.value : this.id,
      flightId: data.flightId.present ? data.flightId.value : this.flightId,
      navaids: data.navaids.present ? data.navaids.value : this.navaids,
      place: data.place.present ? data.place.value : this.place,
      actualMinutes: data.actualMinutes.present
          ? data.actualMinutes.value
          : this.actualMinutes,
      fstdMinutes: data.fstdMinutes.present
          ? data.fstdMinutes.value
          : this.fstdMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentTimesTableData(')
          ..write('id: $id, ')
          ..write('flightId: $flightId, ')
          ..write('navaids: $navaids, ')
          ..write('place: $place, ')
          ..write('actualMinutes: $actualMinutes, ')
          ..write('fstdMinutes: $fstdMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, flightId, navaids, place, actualMinutes, fstdMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstrumentTimesTableData &&
          other.id == this.id &&
          other.flightId == this.flightId &&
          other.navaids == this.navaids &&
          other.place == this.place &&
          other.actualMinutes == this.actualMinutes &&
          other.fstdMinutes == this.fstdMinutes);
}

class InstrumentTimesTableCompanion
    extends UpdateCompanion<InstrumentTimesTableData> {
  final Value<String> id;
  final Value<String> flightId;
  final Value<String?> navaids;
  final Value<String?> place;
  final Value<int> actualMinutes;
  final Value<int> fstdMinutes;
  final Value<int> rowid;
  const InstrumentTimesTableCompanion({
    this.id = const Value.absent(),
    this.flightId = const Value.absent(),
    this.navaids = const Value.absent(),
    this.place = const Value.absent(),
    this.actualMinutes = const Value.absent(),
    this.fstdMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstrumentTimesTableCompanion.insert({
    required String id,
    required String flightId,
    this.navaids = const Value.absent(),
    this.place = const Value.absent(),
    this.actualMinutes = const Value.absent(),
    this.fstdMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       flightId = Value(flightId);
  static Insertable<InstrumentTimesTableData> custom({
    Expression<String>? id,
    Expression<String>? flightId,
    Expression<String>? navaids,
    Expression<String>? place,
    Expression<int>? actualMinutes,
    Expression<int>? fstdMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (flightId != null) 'flight_id': flightId,
      if (navaids != null) 'navaids': navaids,
      if (place != null) 'place': place,
      if (actualMinutes != null) 'actual_minutes': actualMinutes,
      if (fstdMinutes != null) 'fstd_minutes': fstdMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstrumentTimesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? flightId,
    Value<String?>? navaids,
    Value<String?>? place,
    Value<int>? actualMinutes,
    Value<int>? fstdMinutes,
    Value<int>? rowid,
  }) {
    return InstrumentTimesTableCompanion(
      id: id ?? this.id,
      flightId: flightId ?? this.flightId,
      navaids: navaids ?? this.navaids,
      place: place ?? this.place,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      fstdMinutes: fstdMinutes ?? this.fstdMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (flightId.present) {
      map['flight_id'] = Variable<String>(flightId.value);
    }
    if (navaids.present) {
      map['navaids'] = Variable<String>(navaids.value);
    }
    if (place.present) {
      map['place'] = Variable<String>(place.value);
    }
    if (actualMinutes.present) {
      map['actual_minutes'] = Variable<int>(actualMinutes.value);
    }
    if (fstdMinutes.present) {
      map['fstd_minutes'] = Variable<int>(fstdMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentTimesTableCompanion(')
          ..write('id: $id, ')
          ..write('flightId: $flightId, ')
          ..write('navaids: $navaids, ')
          ..write('place: $place, ')
          ..write('actualMinutes: $actualMinutes, ')
          ..write('fstdMinutes: $fstdMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstructionTimesTableTable extends InstructionTimesTable
    with TableInfo<$InstructionTimesTableTable, InstructionTimesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstructionTimesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flightIdMeta = const VerificationMeta(
    'flightId',
  );
  @override
  late final GeneratedColumn<String> flightId = GeneratedColumn<String>(
    'flight_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES flights_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<int> category = GeneratedColumn<int>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    flightId,
    category,
    durationMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instruction_times_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstructionTimesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('flight_id')) {
      context.handle(
        _flightIdMeta,
        flightId.isAcceptableOrUnknown(data['flight_id']!, _flightIdMeta),
      );
    } else if (isInserting) {
      context.missing(_flightIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstructionTimesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstructionTimesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      flightId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flight_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
    );
  }

  @override
  $InstructionTimesTableTable createAlias(String alias) {
    return $InstructionTimesTableTable(attachedDatabase, alias);
  }
}

class InstructionTimesTableData extends DataClass
    implements Insertable<InstructionTimesTableData> {
  final String id;
  final String flightId;
  final int category;
  final int durationMinutes;
  const InstructionTimesTableData({
    required this.id,
    required this.flightId,
    required this.category,
    required this.durationMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['flight_id'] = Variable<String>(flightId);
    map['category'] = Variable<int>(category);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    return map;
  }

  InstructionTimesTableCompanion toCompanion(bool nullToAbsent) {
    return InstructionTimesTableCompanion(
      id: Value(id),
      flightId: Value(flightId),
      category: Value(category),
      durationMinutes: Value(durationMinutes),
    );
  }

  factory InstructionTimesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstructionTimesTableData(
      id: serializer.fromJson<String>(json['id']),
      flightId: serializer.fromJson<String>(json['flightId']),
      category: serializer.fromJson<int>(json['category']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'flightId': serializer.toJson<String>(flightId),
      'category': serializer.toJson<int>(category),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
    };
  }

  InstructionTimesTableData copyWith({
    String? id,
    String? flightId,
    int? category,
    int? durationMinutes,
  }) => InstructionTimesTableData(
    id: id ?? this.id,
    flightId: flightId ?? this.flightId,
    category: category ?? this.category,
    durationMinutes: durationMinutes ?? this.durationMinutes,
  );
  InstructionTimesTableData copyWithCompanion(
    InstructionTimesTableCompanion data,
  ) {
    return InstructionTimesTableData(
      id: data.id.present ? data.id.value : this.id,
      flightId: data.flightId.present ? data.flightId.value : this.flightId,
      category: data.category.present ? data.category.value : this.category,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstructionTimesTableData(')
          ..write('id: $id, ')
          ..write('flightId: $flightId, ')
          ..write('category: $category, ')
          ..write('durationMinutes: $durationMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, flightId, category, durationMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstructionTimesTableData &&
          other.id == this.id &&
          other.flightId == this.flightId &&
          other.category == this.category &&
          other.durationMinutes == this.durationMinutes);
}

class InstructionTimesTableCompanion
    extends UpdateCompanion<InstructionTimesTableData> {
  final Value<String> id;
  final Value<String> flightId;
  final Value<int> category;
  final Value<int> durationMinutes;
  final Value<int> rowid;
  const InstructionTimesTableCompanion({
    this.id = const Value.absent(),
    this.flightId = const Value.absent(),
    this.category = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstructionTimesTableCompanion.insert({
    required String id,
    required String flightId,
    required int category,
    required int durationMinutes,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       flightId = Value(flightId),
       category = Value(category),
       durationMinutes = Value(durationMinutes);
  static Insertable<InstructionTimesTableData> custom({
    Expression<String>? id,
    Expression<String>? flightId,
    Expression<int>? category,
    Expression<int>? durationMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (flightId != null) 'flight_id': flightId,
      if (category != null) 'category': category,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstructionTimesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? flightId,
    Value<int>? category,
    Value<int>? durationMinutes,
    Value<int>? rowid,
  }) {
    return InstructionTimesTableCompanion(
      id: id ?? this.id,
      flightId: flightId ?? this.flightId,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (flightId.present) {
      map['flight_id'] = Variable<String>(flightId.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(category.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstructionTimesTableCompanion(')
          ..write('id: $id, ')
          ..write('flightId: $flightId, ')
          ..write('category: $category, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LandingsTableTable extends LandingsTable
    with TableInfo<$LandingsTableTable, LandingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LandingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flightIdMeta = const VerificationMeta(
    'flightId',
  );
  @override
  late final GeneratedColumn<String> flightId = GeneratedColumn<String>(
    'flight_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES flights_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayCountMeta = const VerificationMeta(
    'dayCount',
  );
  @override
  late final GeneratedColumn<int> dayCount = GeneratedColumn<int>(
    'day_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nightCountMeta = const VerificationMeta(
    'nightCount',
  );
  @override
  late final GeneratedColumn<int> nightCount = GeneratedColumn<int>(
    'night_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, flightId, dayCount, nightCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'landings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LandingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('flight_id')) {
      context.handle(
        _flightIdMeta,
        flightId.isAcceptableOrUnknown(data['flight_id']!, _flightIdMeta),
      );
    } else if (isInserting) {
      context.missing(_flightIdMeta);
    }
    if (data.containsKey('day_count')) {
      context.handle(
        _dayCountMeta,
        dayCount.isAcceptableOrUnknown(data['day_count']!, _dayCountMeta),
      );
    }
    if (data.containsKey('night_count')) {
      context.handle(
        _nightCountMeta,
        nightCount.isAcceptableOrUnknown(data['night_count']!, _nightCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LandingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LandingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      flightId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flight_id'],
      )!,
      dayCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_count'],
      )!,
      nightCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}night_count'],
      )!,
    );
  }

  @override
  $LandingsTableTable createAlias(String alias) {
    return $LandingsTableTable(attachedDatabase, alias);
  }
}

class LandingsTableData extends DataClass
    implements Insertable<LandingsTableData> {
  final String id;
  final String flightId;
  final int dayCount;
  final int nightCount;
  const LandingsTableData({
    required this.id,
    required this.flightId,
    required this.dayCount,
    required this.nightCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['flight_id'] = Variable<String>(flightId);
    map['day_count'] = Variable<int>(dayCount);
    map['night_count'] = Variable<int>(nightCount);
    return map;
  }

  LandingsTableCompanion toCompanion(bool nullToAbsent) {
    return LandingsTableCompanion(
      id: Value(id),
      flightId: Value(flightId),
      dayCount: Value(dayCount),
      nightCount: Value(nightCount),
    );
  }

  factory LandingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LandingsTableData(
      id: serializer.fromJson<String>(json['id']),
      flightId: serializer.fromJson<String>(json['flightId']),
      dayCount: serializer.fromJson<int>(json['dayCount']),
      nightCount: serializer.fromJson<int>(json['nightCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'flightId': serializer.toJson<String>(flightId),
      'dayCount': serializer.toJson<int>(dayCount),
      'nightCount': serializer.toJson<int>(nightCount),
    };
  }

  LandingsTableData copyWith({
    String? id,
    String? flightId,
    int? dayCount,
    int? nightCount,
  }) => LandingsTableData(
    id: id ?? this.id,
    flightId: flightId ?? this.flightId,
    dayCount: dayCount ?? this.dayCount,
    nightCount: nightCount ?? this.nightCount,
  );
  LandingsTableData copyWithCompanion(LandingsTableCompanion data) {
    return LandingsTableData(
      id: data.id.present ? data.id.value : this.id,
      flightId: data.flightId.present ? data.flightId.value : this.flightId,
      dayCount: data.dayCount.present ? data.dayCount.value : this.dayCount,
      nightCount: data.nightCount.present
          ? data.nightCount.value
          : this.nightCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LandingsTableData(')
          ..write('id: $id, ')
          ..write('flightId: $flightId, ')
          ..write('dayCount: $dayCount, ')
          ..write('nightCount: $nightCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, flightId, dayCount, nightCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LandingsTableData &&
          other.id == this.id &&
          other.flightId == this.flightId &&
          other.dayCount == this.dayCount &&
          other.nightCount == this.nightCount);
}

class LandingsTableCompanion extends UpdateCompanion<LandingsTableData> {
  final Value<String> id;
  final Value<String> flightId;
  final Value<int> dayCount;
  final Value<int> nightCount;
  final Value<int> rowid;
  const LandingsTableCompanion({
    this.id = const Value.absent(),
    this.flightId = const Value.absent(),
    this.dayCount = const Value.absent(),
    this.nightCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LandingsTableCompanion.insert({
    required String id,
    required String flightId,
    this.dayCount = const Value.absent(),
    this.nightCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       flightId = Value(flightId);
  static Insertable<LandingsTableData> custom({
    Expression<String>? id,
    Expression<String>? flightId,
    Expression<int>? dayCount,
    Expression<int>? nightCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (flightId != null) 'flight_id': flightId,
      if (dayCount != null) 'day_count': dayCount,
      if (nightCount != null) 'night_count': nightCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LandingsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? flightId,
    Value<int>? dayCount,
    Value<int>? nightCount,
    Value<int>? rowid,
  }) {
    return LandingsTableCompanion(
      id: id ?? this.id,
      flightId: flightId ?? this.flightId,
      dayCount: dayCount ?? this.dayCount,
      nightCount: nightCount ?? this.nightCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (flightId.present) {
      map['flight_id'] = Variable<String>(flightId.value);
    }
    if (dayCount.present) {
      map['day_count'] = Variable<int>(dayCount.value);
    }
    if (nightCount.present) {
      map['night_count'] = Variable<int>(nightCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LandingsTableCompanion(')
          ..write('id: $id, ')
          ..write('flightId: $flightId, ')
          ..write('dayCount: $dayCount, ')
          ..write('nightCount: $nightCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AircraftModelsTableTable aircraftModelsTable =
      $AircraftModelsTableTable(this);
  late final $FlightsTableTable flightsTable = $FlightsTableTable(this);
  late final $FlightTimesTableTable flightTimesTable = $FlightTimesTableTable(
    this,
  );
  late final $InstrumentTimesTableTable instrumentTimesTable =
      $InstrumentTimesTableTable(this);
  late final $InstructionTimesTableTable instructionTimesTable =
      $InstructionTimesTableTable(this);
  late final $LandingsTableTable landingsTable = $LandingsTableTable(this);
  late final FlightsDao flightsDao = FlightsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    aircraftModelsTable,
    flightsTable,
    flightTimesTable,
    instrumentTimesTable,
    instructionTimesTable,
    landingsTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'flights_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('flight_times_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'flights_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('instrument_times_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'flights_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('instruction_times_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'flights_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('landings_table', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AircraftModelsTableTableCreateCompanionBuilder =
    AircraftModelsTableCompanion Function({
      required String id,
      required String manufacturer,
      required String model,
      required int aircraftClass,
      required int category,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AircraftModelsTableTableUpdateCompanionBuilder =
    AircraftModelsTableCompanion Function({
      Value<String> id,
      Value<String> manufacturer,
      Value<String> model,
      Value<int> aircraftClass,
      Value<int> category,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AircraftModelsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AircraftModelsTableTable,
          AircraftModelsTableData
        > {
  $$AircraftModelsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$FlightsTableTable, List<FlightsTableData>>
  _flightsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.flightsTable,
    aliasName: 'aircraft_models_table__id__flights_table__aircraft_model_id',
  );

  $$FlightsTableTableProcessedTableManager get flightsTableRefs {
    final manager = $$FlightsTableTableTableManager($_db, $_db.flightsTable)
        .filter(
          (f) => f.aircraftModelId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_flightsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AircraftModelsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AircraftModelsTableTable> {
  $$AircraftModelsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> flightsTableRefs(
    Expression<bool> Function($$FlightsTableTableFilterComposer f) f,
  ) {
    final $$FlightsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.aircraftModelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableFilterComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AircraftModelsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AircraftModelsTableTable> {
  $$AircraftModelsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AircraftModelsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AircraftModelsTableTable> {
  $$AircraftModelsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => column,
  );

  GeneratedColumn<int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> flightsTableRefs<T extends Object>(
    Expression<T> Function($$FlightsTableTableAnnotationComposer a) f,
  ) {
    final $$FlightsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.aircraftModelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AircraftModelsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AircraftModelsTableTable,
          AircraftModelsTableData,
          $$AircraftModelsTableTableFilterComposer,
          $$AircraftModelsTableTableOrderingComposer,
          $$AircraftModelsTableTableAnnotationComposer,
          $$AircraftModelsTableTableCreateCompanionBuilder,
          $$AircraftModelsTableTableUpdateCompanionBuilder,
          (AircraftModelsTableData, $$AircraftModelsTableTableReferences),
          AircraftModelsTableData,
          PrefetchHooks Function({bool flightsTableRefs})
        > {
  $$AircraftModelsTableTableTableManager(
    _$AppDatabase db,
    $AircraftModelsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AircraftModelsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AircraftModelsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AircraftModelsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> manufacturer = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int> aircraftClass = const Value.absent(),
                Value<int> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AircraftModelsTableCompanion(
                id: id,
                manufacturer: manufacturer,
                model: model,
                aircraftClass: aircraftClass,
                category: category,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String manufacturer,
                required String model,
                required int aircraftClass,
                required int category,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AircraftModelsTableCompanion.insert(
                id: id,
                manufacturer: manufacturer,
                model: model,
                aircraftClass: aircraftClass,
                category: category,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AircraftModelsTableTable,
                    AircraftModelsTableData
                  >(table),
                  $$AircraftModelsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flightsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (flightsTableRefs) db.flightsTable],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (flightsTableRefs)
                    await $_getPrefetchedData<
                      AircraftModelsTableData,
                      $AircraftModelsTableTable,
                      FlightsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$AircraftModelsTableTableReferences
                          ._flightsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AircraftModelsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).flightsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.aircraftModelId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AircraftModelsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AircraftModelsTableTable,
      AircraftModelsTableData,
      $$AircraftModelsTableTableFilterComposer,
      $$AircraftModelsTableTableOrderingComposer,
      $$AircraftModelsTableTableAnnotationComposer,
      $$AircraftModelsTableTableCreateCompanionBuilder,
      $$AircraftModelsTableTableUpdateCompanionBuilder,
      (AircraftModelsTableData, $$AircraftModelsTableTableReferences),
      AircraftModelsTableData,
      PrefetchHooks Function({bool flightsTableRefs})
    >;
typedef $$FlightsTableTableCreateCompanionBuilder =
    FlightsTableCompanion Function({
      required String id,
      required DateTime date,
      Value<String?> aircraftModelId,
      required String registration,
      required String picName,
      Value<String> remarks,
      Value<bool> soloCrossCountry,
      Value<int> fstdActualMinutes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FlightsTableTableUpdateCompanionBuilder =
    FlightsTableCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<String?> aircraftModelId,
      Value<String> registration,
      Value<String> picName,
      Value<String> remarks,
      Value<bool> soloCrossCountry,
      Value<int> fstdActualMinutes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FlightsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $FlightsTableTable, FlightsTableData> {
  $$FlightsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AircraftModelsTableTable _aircraftModelIdTable(_$AppDatabase db) =>
      db.aircraftModelsTable.createAlias(
        'flights_table__aircraft_model_id__aircraft_models_table__id',
      );

  $$AircraftModelsTableTableProcessedTableManager? get aircraftModelId {
    final $_column = $_itemColumn<String>('aircraft_model_id');
    if ($_column == null) return null;
    final manager = $$AircraftModelsTableTableTableManager(
      $_db,
      $_db.aircraftModelsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_aircraftModelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FlightTimesTableTable, List<FlightTimesTableData>>
  _flightTimesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.flightTimesTable,
    aliasName: 'flights_table__id__flight_times_table__flight_id',
  );

  $$FlightTimesTableTableProcessedTableManager get flightTimesTableRefs {
    final manager = $$FlightTimesTableTableTableManager(
      $_db,
      $_db.flightTimesTable,
    ).filter((f) => f.flightId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _flightTimesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $InstrumentTimesTableTable,
    List<InstrumentTimesTableData>
  >
  _instrumentTimesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.instrumentTimesTable,
        aliasName: 'flights_table__id__instrument_times_table__flight_id',
      );

  $$InstrumentTimesTableTableProcessedTableManager
  get instrumentTimesTableRefs {
    final manager = $$InstrumentTimesTableTableTableManager(
      $_db,
      $_db.instrumentTimesTable,
    ).filter((f) => f.flightId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _instrumentTimesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $InstructionTimesTableTable,
    List<InstructionTimesTableData>
  >
  _instructionTimesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.instructionTimesTable,
        aliasName: 'flights_table__id__instruction_times_table__flight_id',
      );

  $$InstructionTimesTableTableProcessedTableManager
  get instructionTimesTableRefs {
    final manager = $$InstructionTimesTableTableTableManager(
      $_db,
      $_db.instructionTimesTable,
    ).filter((f) => f.flightId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _instructionTimesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LandingsTableTable, List<LandingsTableData>>
  _landingsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.landingsTable,
    aliasName: 'flights_table__id__landings_table__flight_id',
  );

  $$LandingsTableTableProcessedTableManager get landingsTableRefs {
    final manager = $$LandingsTableTableTableManager(
      $_db,
      $_db.landingsTable,
    ).filter((f) => f.flightId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_landingsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FlightsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FlightsTableTable> {
  $$FlightsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registration => $composableBuilder(
    column: $table.registration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get picName => $composableBuilder(
    column: $table.picName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get soloCrossCountry => $composableBuilder(
    column: $table.soloCrossCountry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fstdActualMinutes => $composableBuilder(
    column: $table.fstdActualMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AircraftModelsTableTableFilterComposer get aircraftModelId {
    final $$AircraftModelsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.aircraftModelId,
      referencedTable: $db.aircraftModelsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AircraftModelsTableTableFilterComposer(
            $db: $db,
            $table: $db.aircraftModelsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> flightTimesTableRefs(
    Expression<bool> Function($$FlightTimesTableTableFilterComposer f) f,
  ) {
    final $$FlightTimesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flightTimesTable,
      getReferencedColumn: (t) => t.flightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightTimesTableTableFilterComposer(
            $db: $db,
            $table: $db.flightTimesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> instrumentTimesTableRefs(
    Expression<bool> Function($$InstrumentTimesTableTableFilterComposer f) f,
  ) {
    final $$InstrumentTimesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.instrumentTimesTable,
      getReferencedColumn: (t) => t.flightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentTimesTableTableFilterComposer(
            $db: $db,
            $table: $db.instrumentTimesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> instructionTimesTableRefs(
    Expression<bool> Function($$InstructionTimesTableTableFilterComposer f) f,
  ) {
    final $$InstructionTimesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.instructionTimesTable,
          getReferencedColumn: (t) => t.flightId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstructionTimesTableTableFilterComposer(
                $db: $db,
                $table: $db.instructionTimesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> landingsTableRefs(
    Expression<bool> Function($$LandingsTableTableFilterComposer f) f,
  ) {
    final $$LandingsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.landingsTable,
      getReferencedColumn: (t) => t.flightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingsTableTableFilterComposer(
            $db: $db,
            $table: $db.landingsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlightsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FlightsTableTable> {
  $$FlightsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registration => $composableBuilder(
    column: $table.registration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get picName => $composableBuilder(
    column: $table.picName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get soloCrossCountry => $composableBuilder(
    column: $table.soloCrossCountry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fstdActualMinutes => $composableBuilder(
    column: $table.fstdActualMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AircraftModelsTableTableOrderingComposer get aircraftModelId {
    final $$AircraftModelsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.aircraftModelId,
          referencedTable: $db.aircraftModelsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AircraftModelsTableTableOrderingComposer(
                $db: $db,
                $table: $db.aircraftModelsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$FlightsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlightsTableTable> {
  $$FlightsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get registration => $composableBuilder(
    column: $table.registration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get picName =>
      $composableBuilder(column: $table.picName, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<bool> get soloCrossCountry => $composableBuilder(
    column: $table.soloCrossCountry,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fstdActualMinutes => $composableBuilder(
    column: $table.fstdActualMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AircraftModelsTableTableAnnotationComposer get aircraftModelId {
    final $$AircraftModelsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.aircraftModelId,
          referencedTable: $db.aircraftModelsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AircraftModelsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.aircraftModelsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> flightTimesTableRefs<T extends Object>(
    Expression<T> Function($$FlightTimesTableTableAnnotationComposer a) f,
  ) {
    final $$FlightTimesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flightTimesTable,
      getReferencedColumn: (t) => t.flightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightTimesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.flightTimesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> instrumentTimesTableRefs<T extends Object>(
    Expression<T> Function($$InstrumentTimesTableTableAnnotationComposer a) f,
  ) {
    final $$InstrumentTimesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.instrumentTimesTable,
          getReferencedColumn: (t) => t.flightId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstrumentTimesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.instrumentTimesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> instructionTimesTableRefs<T extends Object>(
    Expression<T> Function($$InstructionTimesTableTableAnnotationComposer a) f,
  ) {
    final $$InstructionTimesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.instructionTimesTable,
          getReferencedColumn: (t) => t.flightId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstructionTimesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.instructionTimesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> landingsTableRefs<T extends Object>(
    Expression<T> Function($$LandingsTableTableAnnotationComposer a) f,
  ) {
    final $$LandingsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.landingsTable,
      getReferencedColumn: (t) => t.flightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.landingsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlightsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlightsTableTable,
          FlightsTableData,
          $$FlightsTableTableFilterComposer,
          $$FlightsTableTableOrderingComposer,
          $$FlightsTableTableAnnotationComposer,
          $$FlightsTableTableCreateCompanionBuilder,
          $$FlightsTableTableUpdateCompanionBuilder,
          (FlightsTableData, $$FlightsTableTableReferences),
          FlightsTableData,
          PrefetchHooks Function({
            bool aircraftModelId,
            bool flightTimesTableRefs,
            bool instrumentTimesTableRefs,
            bool instructionTimesTableRefs,
            bool landingsTableRefs,
          })
        > {
  $$FlightsTableTableTableManager(_$AppDatabase db, $FlightsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlightsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlightsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlightsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> aircraftModelId = const Value.absent(),
                Value<String> registration = const Value.absent(),
                Value<String> picName = const Value.absent(),
                Value<String> remarks = const Value.absent(),
                Value<bool> soloCrossCountry = const Value.absent(),
                Value<int> fstdActualMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlightsTableCompanion(
                id: id,
                date: date,
                aircraftModelId: aircraftModelId,
                registration: registration,
                picName: picName,
                remarks: remarks,
                soloCrossCountry: soloCrossCountry,
                fstdActualMinutes: fstdActualMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                Value<String?> aircraftModelId = const Value.absent(),
                required String registration,
                required String picName,
                Value<String> remarks = const Value.absent(),
                Value<bool> soloCrossCountry = const Value.absent(),
                Value<int> fstdActualMinutes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FlightsTableCompanion.insert(
                id: id,
                date: date,
                aircraftModelId: aircraftModelId,
                registration: registration,
                picName: picName,
                remarks: remarks,
                soloCrossCountry: soloCrossCountry,
                fstdActualMinutes: fstdActualMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FlightsTableTable, FlightsTableData>(table),
                  $$FlightsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                aircraftModelId = false,
                flightTimesTableRefs = false,
                instrumentTimesTableRefs = false,
                instructionTimesTableRefs = false,
                landingsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (flightTimesTableRefs) db.flightTimesTable,
                    if (instrumentTimesTableRefs) db.instrumentTimesTable,
                    if (instructionTimesTableRefs) db.instructionTimesTable,
                    if (landingsTableRefs) db.landingsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (aircraftModelId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.aircraftModelId,
                            referencedTable: $$FlightsTableTableReferences
                                ._aircraftModelIdTable(db),
                            referencedColumn: $$FlightsTableTableReferences
                                ._aircraftModelIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (flightTimesTableRefs)
                        await $_getPrefetchedData<
                          FlightsTableData,
                          $FlightsTableTable,
                          FlightTimesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$FlightsTableTableReferences
                              ._flightTimesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FlightsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).flightTimesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.flightId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (instrumentTimesTableRefs)
                        await $_getPrefetchedData<
                          FlightsTableData,
                          $FlightsTableTable,
                          InstrumentTimesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$FlightsTableTableReferences
                              ._instrumentTimesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FlightsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).instrumentTimesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.flightId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (instructionTimesTableRefs)
                        await $_getPrefetchedData<
                          FlightsTableData,
                          $FlightsTableTable,
                          InstructionTimesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$FlightsTableTableReferences
                              ._instructionTimesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FlightsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).instructionTimesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.flightId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (landingsTableRefs)
                        await $_getPrefetchedData<
                          FlightsTableData,
                          $FlightsTableTable,
                          LandingsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$FlightsTableTableReferences
                              ._landingsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FlightsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).landingsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.flightId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FlightsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlightsTableTable,
      FlightsTableData,
      $$FlightsTableTableFilterComposer,
      $$FlightsTableTableOrderingComposer,
      $$FlightsTableTableAnnotationComposer,
      $$FlightsTableTableCreateCompanionBuilder,
      $$FlightsTableTableUpdateCompanionBuilder,
      (FlightsTableData, $$FlightsTableTableReferences),
      FlightsTableData,
      PrefetchHooks Function({
        bool aircraftModelId,
        bool flightTimesTableRefs,
        bool instrumentTimesTableRefs,
        bool instructionTimesTableRefs,
        bool landingsTableRefs,
      })
    >;
typedef $$FlightTimesTableTableCreateCompanionBuilder =
    FlightTimesTableCompanion Function({
      required String id,
      required String flightId,
      required int aircraftClass,
      required int period,
      required int role,
      required int durationMinutes,
      Value<int> rowid,
    });
typedef $$FlightTimesTableTableUpdateCompanionBuilder =
    FlightTimesTableCompanion Function({
      Value<String> id,
      Value<String> flightId,
      Value<int> aircraftClass,
      Value<int> period,
      Value<int> role,
      Value<int> durationMinutes,
      Value<int> rowid,
    });

final class $$FlightTimesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FlightTimesTableTable,
          FlightTimesTableData
        > {
  $$FlightTimesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FlightsTableTable _flightIdTable(_$AppDatabase db) => db.flightsTable
      .createAlias('flight_times_table__flight_id__flights_table__id');

  $$FlightsTableTableProcessedTableManager get flightId {
    final $_column = $_itemColumn<String>('flight_id')!;

    final manager = $$FlightsTableTableTableManager(
      $_db,
      $_db.flightsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_flightIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FlightTimesTableTableFilterComposer
    extends Composer<_$AppDatabase, $FlightTimesTableTable> {
  $$FlightTimesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$FlightsTableTableFilterComposer get flightId {
    final $$FlightsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableFilterComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlightTimesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FlightTimesTableTable> {
  $$FlightTimesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$FlightsTableTableOrderingComposer get flightId {
    final $$FlightsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableOrderingComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlightTimesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlightTimesTableTable> {
  $$FlightTimesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => column,
  );

  GeneratedColumn<int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<int> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  $$FlightsTableTableAnnotationComposer get flightId {
    final $$FlightsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlightTimesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlightTimesTableTable,
          FlightTimesTableData,
          $$FlightTimesTableTableFilterComposer,
          $$FlightTimesTableTableOrderingComposer,
          $$FlightTimesTableTableAnnotationComposer,
          $$FlightTimesTableTableCreateCompanionBuilder,
          $$FlightTimesTableTableUpdateCompanionBuilder,
          (FlightTimesTableData, $$FlightTimesTableTableReferences),
          FlightTimesTableData,
          PrefetchHooks Function({bool flightId})
        > {
  $$FlightTimesTableTableTableManager(
    _$AppDatabase db,
    $FlightTimesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlightTimesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlightTimesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlightTimesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> flightId = const Value.absent(),
                Value<int> aircraftClass = const Value.absent(),
                Value<int> period = const Value.absent(),
                Value<int> role = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlightTimesTableCompanion(
                id: id,
                flightId: flightId,
                aircraftClass: aircraftClass,
                period: period,
                role: role,
                durationMinutes: durationMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String flightId,
                required int aircraftClass,
                required int period,
                required int role,
                required int durationMinutes,
                Value<int> rowid = const Value.absent(),
              }) => FlightTimesTableCompanion.insert(
                id: id,
                flightId: flightId,
                aircraftClass: aircraftClass,
                period: period,
                role: role,
                durationMinutes: durationMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FlightTimesTableTable, FlightTimesTableData>(
                    table,
                  ),
                  $$FlightTimesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flightId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (flightId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.flightId,
                        referencedTable: $$FlightTimesTableTableReferences
                            ._flightIdTable(db),
                        referencedColumn: $$FlightTimesTableTableReferences
                            ._flightIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FlightTimesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlightTimesTableTable,
      FlightTimesTableData,
      $$FlightTimesTableTableFilterComposer,
      $$FlightTimesTableTableOrderingComposer,
      $$FlightTimesTableTableAnnotationComposer,
      $$FlightTimesTableTableCreateCompanionBuilder,
      $$FlightTimesTableTableUpdateCompanionBuilder,
      (FlightTimesTableData, $$FlightTimesTableTableReferences),
      FlightTimesTableData,
      PrefetchHooks Function({bool flightId})
    >;
typedef $$InstrumentTimesTableTableCreateCompanionBuilder =
    InstrumentTimesTableCompanion Function({
      required String id,
      required String flightId,
      Value<String?> navaids,
      Value<String?> place,
      Value<int> actualMinutes,
      Value<int> fstdMinutes,
      Value<int> rowid,
    });
typedef $$InstrumentTimesTableTableUpdateCompanionBuilder =
    InstrumentTimesTableCompanion Function({
      Value<String> id,
      Value<String> flightId,
      Value<String?> navaids,
      Value<String?> place,
      Value<int> actualMinutes,
      Value<int> fstdMinutes,
      Value<int> rowid,
    });

final class $$InstrumentTimesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InstrumentTimesTableTable,
          InstrumentTimesTableData
        > {
  $$InstrumentTimesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FlightsTableTable _flightIdTable(_$AppDatabase db) => db.flightsTable
      .createAlias('instrument_times_table__flight_id__flights_table__id');

  $$FlightsTableTableProcessedTableManager get flightId {
    final $_column = $_itemColumn<String>('flight_id')!;

    final manager = $$FlightsTableTableTableManager(
      $_db,
      $_db.flightsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_flightIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InstrumentTimesTableTableFilterComposer
    extends Composer<_$AppDatabase, $InstrumentTimesTableTable> {
  $$InstrumentTimesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get navaids => $composableBuilder(
    column: $table.navaids,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fstdMinutes => $composableBuilder(
    column: $table.fstdMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$FlightsTableTableFilterComposer get flightId {
    final $$FlightsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableFilterComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstrumentTimesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InstrumentTimesTableTable> {
  $$InstrumentTimesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get navaids => $composableBuilder(
    column: $table.navaids,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fstdMinutes => $composableBuilder(
    column: $table.fstdMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$FlightsTableTableOrderingComposer get flightId {
    final $$FlightsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableOrderingComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstrumentTimesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstrumentTimesTableTable> {
  $$InstrumentTimesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get navaids =>
      $composableBuilder(column: $table.navaids, builder: (column) => column);

  GeneratedColumn<String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumn<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fstdMinutes => $composableBuilder(
    column: $table.fstdMinutes,
    builder: (column) => column,
  );

  $$FlightsTableTableAnnotationComposer get flightId {
    final $$FlightsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstrumentTimesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstrumentTimesTableTable,
          InstrumentTimesTableData,
          $$InstrumentTimesTableTableFilterComposer,
          $$InstrumentTimesTableTableOrderingComposer,
          $$InstrumentTimesTableTableAnnotationComposer,
          $$InstrumentTimesTableTableCreateCompanionBuilder,
          $$InstrumentTimesTableTableUpdateCompanionBuilder,
          (InstrumentTimesTableData, $$InstrumentTimesTableTableReferences),
          InstrumentTimesTableData,
          PrefetchHooks Function({bool flightId})
        > {
  $$InstrumentTimesTableTableTableManager(
    _$AppDatabase db,
    $InstrumentTimesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstrumentTimesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstrumentTimesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstrumentTimesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> flightId = const Value.absent(),
                Value<String?> navaids = const Value.absent(),
                Value<String?> place = const Value.absent(),
                Value<int> actualMinutes = const Value.absent(),
                Value<int> fstdMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstrumentTimesTableCompanion(
                id: id,
                flightId: flightId,
                navaids: navaids,
                place: place,
                actualMinutes: actualMinutes,
                fstdMinutes: fstdMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String flightId,
                Value<String?> navaids = const Value.absent(),
                Value<String?> place = const Value.absent(),
                Value<int> actualMinutes = const Value.absent(),
                Value<int> fstdMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstrumentTimesTableCompanion.insert(
                id: id,
                flightId: flightId,
                navaids: navaids,
                place: place,
                actualMinutes: actualMinutes,
                fstdMinutes: fstdMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $InstrumentTimesTableTable,
                    InstrumentTimesTableData
                  >(table),
                  $$InstrumentTimesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flightId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (flightId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.flightId,
                        referencedTable: $$InstrumentTimesTableTableReferences
                            ._flightIdTable(db),
                        referencedColumn: $$InstrumentTimesTableTableReferences
                            ._flightIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InstrumentTimesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstrumentTimesTableTable,
      InstrumentTimesTableData,
      $$InstrumentTimesTableTableFilterComposer,
      $$InstrumentTimesTableTableOrderingComposer,
      $$InstrumentTimesTableTableAnnotationComposer,
      $$InstrumentTimesTableTableCreateCompanionBuilder,
      $$InstrumentTimesTableTableUpdateCompanionBuilder,
      (InstrumentTimesTableData, $$InstrumentTimesTableTableReferences),
      InstrumentTimesTableData,
      PrefetchHooks Function({bool flightId})
    >;
typedef $$InstructionTimesTableTableCreateCompanionBuilder =
    InstructionTimesTableCompanion Function({
      required String id,
      required String flightId,
      required int category,
      required int durationMinutes,
      Value<int> rowid,
    });
typedef $$InstructionTimesTableTableUpdateCompanionBuilder =
    InstructionTimesTableCompanion Function({
      Value<String> id,
      Value<String> flightId,
      Value<int> category,
      Value<int> durationMinutes,
      Value<int> rowid,
    });

final class $$InstructionTimesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InstructionTimesTableTable,
          InstructionTimesTableData
        > {
  $$InstructionTimesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FlightsTableTable _flightIdTable(_$AppDatabase db) => db.flightsTable
      .createAlias('instruction_times_table__flight_id__flights_table__id');

  $$FlightsTableTableProcessedTableManager get flightId {
    final $_column = $_itemColumn<String>('flight_id')!;

    final manager = $$FlightsTableTableTableManager(
      $_db,
      $_db.flightsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_flightIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InstructionTimesTableTableFilterComposer
    extends Composer<_$AppDatabase, $InstructionTimesTableTable> {
  $$InstructionTimesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$FlightsTableTableFilterComposer get flightId {
    final $$FlightsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableFilterComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstructionTimesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InstructionTimesTableTable> {
  $$InstructionTimesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$FlightsTableTableOrderingComposer get flightId {
    final $$FlightsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableOrderingComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstructionTimesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstructionTimesTableTable> {
  $$InstructionTimesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  $$FlightsTableTableAnnotationComposer get flightId {
    final $$FlightsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstructionTimesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstructionTimesTableTable,
          InstructionTimesTableData,
          $$InstructionTimesTableTableFilterComposer,
          $$InstructionTimesTableTableOrderingComposer,
          $$InstructionTimesTableTableAnnotationComposer,
          $$InstructionTimesTableTableCreateCompanionBuilder,
          $$InstructionTimesTableTableUpdateCompanionBuilder,
          (InstructionTimesTableData, $$InstructionTimesTableTableReferences),
          InstructionTimesTableData,
          PrefetchHooks Function({bool flightId})
        > {
  $$InstructionTimesTableTableTableManager(
    _$AppDatabase db,
    $InstructionTimesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstructionTimesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InstructionTimesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstructionTimesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> flightId = const Value.absent(),
                Value<int> category = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstructionTimesTableCompanion(
                id: id,
                flightId: flightId,
                category: category,
                durationMinutes: durationMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String flightId,
                required int category,
                required int durationMinutes,
                Value<int> rowid = const Value.absent(),
              }) => InstructionTimesTableCompanion.insert(
                id: id,
                flightId: flightId,
                category: category,
                durationMinutes: durationMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $InstructionTimesTableTable,
                    InstructionTimesTableData
                  >(table),
                  $$InstructionTimesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flightId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (flightId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.flightId,
                        referencedTable: $$InstructionTimesTableTableReferences
                            ._flightIdTable(db),
                        referencedColumn: $$InstructionTimesTableTableReferences
                            ._flightIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InstructionTimesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstructionTimesTableTable,
      InstructionTimesTableData,
      $$InstructionTimesTableTableFilterComposer,
      $$InstructionTimesTableTableOrderingComposer,
      $$InstructionTimesTableTableAnnotationComposer,
      $$InstructionTimesTableTableCreateCompanionBuilder,
      $$InstructionTimesTableTableUpdateCompanionBuilder,
      (InstructionTimesTableData, $$InstructionTimesTableTableReferences),
      InstructionTimesTableData,
      PrefetchHooks Function({bool flightId})
    >;
typedef $$LandingsTableTableCreateCompanionBuilder =
    LandingsTableCompanion Function({
      required String id,
      required String flightId,
      Value<int> dayCount,
      Value<int> nightCount,
      Value<int> rowid,
    });
typedef $$LandingsTableTableUpdateCompanionBuilder =
    LandingsTableCompanion Function({
      Value<String> id,
      Value<String> flightId,
      Value<int> dayCount,
      Value<int> nightCount,
      Value<int> rowid,
    });

final class $$LandingsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $LandingsTableTable, LandingsTableData> {
  $$LandingsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FlightsTableTable _flightIdTable(_$AppDatabase db) => db.flightsTable
      .createAlias('landings_table__flight_id__flights_table__id');

  $$FlightsTableTableProcessedTableManager get flightId {
    final $_column = $_itemColumn<String>('flight_id')!;

    final manager = $$FlightsTableTableTableManager(
      $_db,
      $_db.flightsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_flightIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LandingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LandingsTableTable> {
  $$LandingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayCount => $composableBuilder(
    column: $table.dayCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nightCount => $composableBuilder(
    column: $table.nightCount,
    builder: (column) => ColumnFilters(column),
  );

  $$FlightsTableTableFilterComposer get flightId {
    final $$FlightsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableFilterComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LandingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LandingsTableTable> {
  $$LandingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayCount => $composableBuilder(
    column: $table.dayCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nightCount => $composableBuilder(
    column: $table.nightCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$FlightsTableTableOrderingComposer get flightId {
    final $$FlightsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableOrderingComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LandingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LandingsTableTable> {
  $$LandingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayCount =>
      $composableBuilder(column: $table.dayCount, builder: (column) => column);

  GeneratedColumn<int> get nightCount => $composableBuilder(
    column: $table.nightCount,
    builder: (column) => column,
  );

  $$FlightsTableTableAnnotationComposer get flightId {
    final $$FlightsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flightsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.flightsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LandingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LandingsTableTable,
          LandingsTableData,
          $$LandingsTableTableFilterComposer,
          $$LandingsTableTableOrderingComposer,
          $$LandingsTableTableAnnotationComposer,
          $$LandingsTableTableCreateCompanionBuilder,
          $$LandingsTableTableUpdateCompanionBuilder,
          (LandingsTableData, $$LandingsTableTableReferences),
          LandingsTableData,
          PrefetchHooks Function({bool flightId})
        > {
  $$LandingsTableTableTableManager(_$AppDatabase db, $LandingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LandingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LandingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LandingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> flightId = const Value.absent(),
                Value<int> dayCount = const Value.absent(),
                Value<int> nightCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LandingsTableCompanion(
                id: id,
                flightId: flightId,
                dayCount: dayCount,
                nightCount: nightCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String flightId,
                Value<int> dayCount = const Value.absent(),
                Value<int> nightCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LandingsTableCompanion.insert(
                id: id,
                flightId: flightId,
                dayCount: dayCount,
                nightCount: nightCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LandingsTableTable, LandingsTableData>(table),
                  $$LandingsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flightId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (flightId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.flightId,
                        referencedTable: $$LandingsTableTableReferences
                            ._flightIdTable(db),
                        referencedColumn: $$LandingsTableTableReferences
                            ._flightIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LandingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LandingsTableTable,
      LandingsTableData,
      $$LandingsTableTableFilterComposer,
      $$LandingsTableTableOrderingComposer,
      $$LandingsTableTableAnnotationComposer,
      $$LandingsTableTableCreateCompanionBuilder,
      $$LandingsTableTableUpdateCompanionBuilder,
      (LandingsTableData, $$LandingsTableTableReferences),
      LandingsTableData,
      PrefetchHooks Function({bool flightId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AircraftModelsTableTableTableManager get aircraftModelsTable =>
      $$AircraftModelsTableTableTableManager(_db, _db.aircraftModelsTable);
  $$FlightsTableTableTableManager get flightsTable =>
      $$FlightsTableTableTableManager(_db, _db.flightsTable);
  $$FlightTimesTableTableTableManager get flightTimesTable =>
      $$FlightTimesTableTableTableManager(_db, _db.flightTimesTable);
  $$InstrumentTimesTableTableTableManager get instrumentTimesTable =>
      $$InstrumentTimesTableTableTableManager(_db, _db.instrumentTimesTable);
  $$InstructionTimesTableTableTableManager get instructionTimesTable =>
      $$InstructionTimesTableTableTableManager(_db, _db.instructionTimesTable);
  $$LandingsTableTableTableManager get landingsTable =>
      $$LandingsTableTableTableManager(_db, _db.landingsTable);
}
