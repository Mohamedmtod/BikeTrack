// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tsUtcMeta = const VerificationMeta('tsUtc');
  @override
  late final GeneratedColumn<int> tsUtc = GeneratedColumn<int>(
    'ts_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EventSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EventSource>($EventsTable.$convertersource);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processedMeta = const VerificationMeta(
    'processed',
  );
  @override
  late final GeneratedColumn<bool> processed = GeneratedColumn<bool>(
    'processed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("processed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tsUtc,
    source,
    type,
    payload,
    tripId,
    processed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ts_utc')) {
      context.handle(
        _tsUtcMeta,
        tsUtc.isAcceptableOrUnknown(data['ts_utc']!, _tsUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_tsUtcMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    }
    if (data.containsKey('processed')) {
      context.handle(
        _processedMeta,
        processed.isAcceptableOrUnknown(data['processed']!, _processedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tsUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts_utc'],
      )!,
      source: $EventsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      ),
      processed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}processed'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EventSource, String, String> $convertersource =
      const EnumNameConverter<EventSource>(EventSource.values);
}

class Event extends DataClass implements Insertable<Event> {
  final int id;
  final int tsUtc;
  final EventSource source;
  final String type;
  final String payload;
  final String? tripId;
  final bool processed;
  const Event({
    required this.id,
    required this.tsUtc,
    required this.source,
    required this.type,
    required this.payload,
    this.tripId,
    required this.processed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ts_utc'] = Variable<int>(tsUtc);
    {
      map['source'] = Variable<String>(
        $EventsTable.$convertersource.toSql(source),
      );
    }
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || tripId != null) {
      map['trip_id'] = Variable<String>(tripId);
    }
    map['processed'] = Variable<bool>(processed);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      tsUtc: Value(tsUtc),
      source: Value(source),
      type: Value(type),
      payload: Value(payload),
      tripId: tripId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripId),
      processed: Value(processed),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<int>(json['id']),
      tsUtc: serializer.fromJson<int>(json['tsUtc']),
      source: $EventsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      tripId: serializer.fromJson<String?>(json['tripId']),
      processed: serializer.fromJson<bool>(json['processed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tsUtc': serializer.toJson<int>(tsUtc),
      'source': serializer.toJson<String>(
        $EventsTable.$convertersource.toJson(source),
      ),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'tripId': serializer.toJson<String?>(tripId),
      'processed': serializer.toJson<bool>(processed),
    };
  }

  Event copyWith({
    int? id,
    int? tsUtc,
    EventSource? source,
    String? type,
    String? payload,
    Value<String?> tripId = const Value.absent(),
    bool? processed,
  }) => Event(
    id: id ?? this.id,
    tsUtc: tsUtc ?? this.tsUtc,
    source: source ?? this.source,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    tripId: tripId.present ? tripId.value : this.tripId,
    processed: processed ?? this.processed,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      tsUtc: data.tsUtc.present ? data.tsUtc.value : this.tsUtc,
      source: data.source.present ? data.source.value : this.source,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      processed: data.processed.present ? data.processed.value : this.processed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('tsUtc: $tsUtc, ')
          ..write('source: $source, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('tripId: $tripId, ')
          ..write('processed: $processed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tsUtc, source, type, payload, tripId, processed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.tsUtc == this.tsUtc &&
          other.source == this.source &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.tripId == this.tripId &&
          other.processed == this.processed);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> id;
  final Value<int> tsUtc;
  final Value<EventSource> source;
  final Value<String> type;
  final Value<String> payload;
  final Value<String?> tripId;
  final Value<bool> processed;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.tsUtc = const Value.absent(),
    this.source = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.tripId = const Value.absent(),
    this.processed = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    required int tsUtc,
    required EventSource source,
    required String type,
    required String payload,
    this.tripId = const Value.absent(),
    this.processed = const Value.absent(),
  }) : tsUtc = Value(tsUtc),
       source = Value(source),
       type = Value(type),
       payload = Value(payload);
  static Insertable<Event> custom({
    Expression<int>? id,
    Expression<int>? tsUtc,
    Expression<String>? source,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<String>? tripId,
    Expression<bool>? processed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tsUtc != null) 'ts_utc': tsUtc,
      if (source != null) 'source': source,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (tripId != null) 'trip_id': tripId,
      if (processed != null) 'processed': processed,
    });
  }

  EventsCompanion copyWith({
    Value<int>? id,
    Value<int>? tsUtc,
    Value<EventSource>? source,
    Value<String>? type,
    Value<String>? payload,
    Value<String?>? tripId,
    Value<bool>? processed,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      tsUtc: tsUtc ?? this.tsUtc,
      source: source ?? this.source,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      tripId: tripId ?? this.tripId,
      processed: processed ?? this.processed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tsUtc.present) {
      map['ts_utc'] = Variable<int>(tsUtc.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $EventsTable.$convertersource.toSql(source.value),
      );
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (processed.present) {
      map['processed'] = Variable<bool>(processed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('tsUtc: $tsUtc, ')
          ..write('source: $source, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('tripId: $tripId, ')
          ..write('processed: $processed')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TripStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TripStatus>($TripsTable.$converterstatus);
  static const VerificationMeta _startTimeUtcMeta = const VerificationMeta(
    'startTimeUtc',
  );
  @override
  late final GeneratedColumn<int> startTimeUtc = GeneratedColumn<int>(
    'start_time_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeUtcMeta = const VerificationMeta(
    'endTimeUtc',
  );
  @override
  late final GeneratedColumn<int> endTimeUtc = GeneratedColumn<int>(
    'end_time_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMovementUtcMeta = const VerificationMeta(
    'lastMovementUtc',
  );
  @override
  late final GeneratedColumn<int> lastMovementUtc = GeneratedColumn<int>(
    'last_movement_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bikeIdMeta = const VerificationMeta('bikeId');
  @override
  late final GeneratedColumn<String> bikeId = GeneratedColumn<String>(
    'bike_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nfcConfirmedMeta = const VerificationMeta(
    'nfcConfirmed',
  );
  @override
  late final GeneratedColumn<bool> nfcConfirmed = GeneratedColumn<bool>(
    'nfc_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("nfc_confirmed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _totalDistanceMMeta = const VerificationMeta(
    'totalDistanceM',
  );
  @override
  late final GeneratedColumn<double> totalDistanceM = GeneratedColumn<double>(
    'total_distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DistanceStatus, String>
  distanceStatus = GeneratedColumn<String>(
    'distance_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DistanceStatus>($TripsTable.$converterdistanceStatus);
  static const VerificationMeta _movingDurationSMeta = const VerificationMeta(
    'movingDurationS',
  );
  @override
  late final GeneratedColumn<int> movingDurationS = GeneratedColumn<int>(
    'moving_duration_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pausedDurationSMeta = const VerificationMeta(
    'pausedDurationS',
  );
  @override
  late final GeneratedColumn<int> pausedDurationS = GeneratedColumn<int>(
    'paused_duration_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _suspendedDurationSMeta =
      const VerificationMeta('suspendedDurationS');
  @override
  late final GeneratedColumn<int> suspendedDurationS = GeneratedColumn<int>(
    'suspended_duration_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewReasonMeta = const VerificationMeta(
    'reviewReason',
  );
  @override
  late final GeneratedColumn<String> reviewReason = GeneratedColumn<String>(
    'review_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tripId,
    status,
    startTimeUtc,
    endTimeUtc,
    lastMovementUtc,
    bikeId,
    nfcConfirmed,
    totalDistanceM,
    distanceStatus,
    movingDurationS,
    pausedDurationS,
    suspendedDurationS,
    reviewReason,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('start_time_utc')) {
      context.handle(
        _startTimeUtcMeta,
        startTimeUtc.isAcceptableOrUnknown(
          data['start_time_utc']!,
          _startTimeUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startTimeUtcMeta);
    }
    if (data.containsKey('end_time_utc')) {
      context.handle(
        _endTimeUtcMeta,
        endTimeUtc.isAcceptableOrUnknown(
          data['end_time_utc']!,
          _endTimeUtcMeta,
        ),
      );
    }
    if (data.containsKey('last_movement_utc')) {
      context.handle(
        _lastMovementUtcMeta,
        lastMovementUtc.isAcceptableOrUnknown(
          data['last_movement_utc']!,
          _lastMovementUtcMeta,
        ),
      );
    }
    if (data.containsKey('bike_id')) {
      context.handle(
        _bikeIdMeta,
        bikeId.isAcceptableOrUnknown(data['bike_id']!, _bikeIdMeta),
      );
    }
    if (data.containsKey('nfc_confirmed')) {
      context.handle(
        _nfcConfirmedMeta,
        nfcConfirmed.isAcceptableOrUnknown(
          data['nfc_confirmed']!,
          _nfcConfirmedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nfcConfirmedMeta);
    }
    if (data.containsKey('total_distance_m')) {
      context.handle(
        _totalDistanceMMeta,
        totalDistanceM.isAcceptableOrUnknown(
          data['total_distance_m']!,
          _totalDistanceMMeta,
        ),
      );
    }
    if (data.containsKey('moving_duration_s')) {
      context.handle(
        _movingDurationSMeta,
        movingDurationS.isAcceptableOrUnknown(
          data['moving_duration_s']!,
          _movingDurationSMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movingDurationSMeta);
    }
    if (data.containsKey('paused_duration_s')) {
      context.handle(
        _pausedDurationSMeta,
        pausedDurationS.isAcceptableOrUnknown(
          data['paused_duration_s']!,
          _pausedDurationSMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pausedDurationSMeta);
    }
    if (data.containsKey('suspended_duration_s')) {
      context.handle(
        _suspendedDurationSMeta,
        suspendedDurationS.isAcceptableOrUnknown(
          data['suspended_duration_s']!,
          _suspendedDurationSMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_suspendedDurationSMeta);
    }
    if (data.containsKey('review_reason')) {
      context.handle(
        _reviewReasonMeta,
        reviewReason.isAcceptableOrUnknown(
          data['review_reason']!,
          _reviewReasonMeta,
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
  Set<GeneratedColumn> get $primaryKey => {tripId};
  @override
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      status: $TripsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      startTimeUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time_utc'],
      )!,
      endTimeUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_time_utc'],
      ),
      lastMovementUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_movement_utc'],
      ),
      bikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bike_id'],
      ),
      nfcConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}nfc_confirmed'],
      )!,
      totalDistanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_distance_m'],
      ),
      distanceStatus: $TripsTable.$converterdistanceStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}distance_status'],
        )!,
      ),
      movingDurationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_duration_s'],
      )!,
      pausedDurationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_duration_s'],
      )!,
      suspendedDurationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}suspended_duration_s'],
      )!,
      reviewReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TripStatus, String, String> $converterstatus =
      const EnumNameConverter<TripStatus>(TripStatus.values);
  static JsonTypeConverter2<DistanceStatus, String, String>
  $converterdistanceStatus = const EnumNameConverter<DistanceStatus>(
    DistanceStatus.values,
  );
}

class Trip extends DataClass implements Insertable<Trip> {
  final String tripId;
  final TripStatus status;
  final int startTimeUtc;
  final int? endTimeUtc;
  final int? lastMovementUtc;
  final String? bikeId;
  final bool nfcConfirmed;
  final double? totalDistanceM;
  final DistanceStatus distanceStatus;
  final int movingDurationS;
  final int pausedDurationS;
  final int suspendedDurationS;
  final String? reviewReason;
  final int createdAt;
  final int updatedAt;
  const Trip({
    required this.tripId,
    required this.status,
    required this.startTimeUtc,
    this.endTimeUtc,
    this.lastMovementUtc,
    this.bikeId,
    required this.nfcConfirmed,
    this.totalDistanceM,
    required this.distanceStatus,
    required this.movingDurationS,
    required this.pausedDurationS,
    required this.suspendedDurationS,
    this.reviewReason,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trip_id'] = Variable<String>(tripId);
    {
      map['status'] = Variable<String>(
        $TripsTable.$converterstatus.toSql(status),
      );
    }
    map['start_time_utc'] = Variable<int>(startTimeUtc);
    if (!nullToAbsent || endTimeUtc != null) {
      map['end_time_utc'] = Variable<int>(endTimeUtc);
    }
    if (!nullToAbsent || lastMovementUtc != null) {
      map['last_movement_utc'] = Variable<int>(lastMovementUtc);
    }
    if (!nullToAbsent || bikeId != null) {
      map['bike_id'] = Variable<String>(bikeId);
    }
    map['nfc_confirmed'] = Variable<bool>(nfcConfirmed);
    if (!nullToAbsent || totalDistanceM != null) {
      map['total_distance_m'] = Variable<double>(totalDistanceM);
    }
    {
      map['distance_status'] = Variable<String>(
        $TripsTable.$converterdistanceStatus.toSql(distanceStatus),
      );
    }
    map['moving_duration_s'] = Variable<int>(movingDurationS);
    map['paused_duration_s'] = Variable<int>(pausedDurationS);
    map['suspended_duration_s'] = Variable<int>(suspendedDurationS);
    if (!nullToAbsent || reviewReason != null) {
      map['review_reason'] = Variable<String>(reviewReason);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      tripId: Value(tripId),
      status: Value(status),
      startTimeUtc: Value(startTimeUtc),
      endTimeUtc: endTimeUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(endTimeUtc),
      lastMovementUtc: lastMovementUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMovementUtc),
      bikeId: bikeId == null && nullToAbsent
          ? const Value.absent()
          : Value(bikeId),
      nfcConfirmed: Value(nfcConfirmed),
      totalDistanceM: totalDistanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDistanceM),
      distanceStatus: Value(distanceStatus),
      movingDurationS: Value(movingDurationS),
      pausedDurationS: Value(pausedDurationS),
      suspendedDurationS: Value(suspendedDurationS),
      reviewReason: reviewReason == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewReason),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Trip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      tripId: serializer.fromJson<String>(json['tripId']),
      status: $TripsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      startTimeUtc: serializer.fromJson<int>(json['startTimeUtc']),
      endTimeUtc: serializer.fromJson<int?>(json['endTimeUtc']),
      lastMovementUtc: serializer.fromJson<int?>(json['lastMovementUtc']),
      bikeId: serializer.fromJson<String?>(json['bikeId']),
      nfcConfirmed: serializer.fromJson<bool>(json['nfcConfirmed']),
      totalDistanceM: serializer.fromJson<double?>(json['totalDistanceM']),
      distanceStatus: $TripsTable.$converterdistanceStatus.fromJson(
        serializer.fromJson<String>(json['distanceStatus']),
      ),
      movingDurationS: serializer.fromJson<int>(json['movingDurationS']),
      pausedDurationS: serializer.fromJson<int>(json['pausedDurationS']),
      suspendedDurationS: serializer.fromJson<int>(json['suspendedDurationS']),
      reviewReason: serializer.fromJson<String?>(json['reviewReason']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tripId': serializer.toJson<String>(tripId),
      'status': serializer.toJson<String>(
        $TripsTable.$converterstatus.toJson(status),
      ),
      'startTimeUtc': serializer.toJson<int>(startTimeUtc),
      'endTimeUtc': serializer.toJson<int?>(endTimeUtc),
      'lastMovementUtc': serializer.toJson<int?>(lastMovementUtc),
      'bikeId': serializer.toJson<String?>(bikeId),
      'nfcConfirmed': serializer.toJson<bool>(nfcConfirmed),
      'totalDistanceM': serializer.toJson<double?>(totalDistanceM),
      'distanceStatus': serializer.toJson<String>(
        $TripsTable.$converterdistanceStatus.toJson(distanceStatus),
      ),
      'movingDurationS': serializer.toJson<int>(movingDurationS),
      'pausedDurationS': serializer.toJson<int>(pausedDurationS),
      'suspendedDurationS': serializer.toJson<int>(suspendedDurationS),
      'reviewReason': serializer.toJson<String?>(reviewReason),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Trip copyWith({
    String? tripId,
    TripStatus? status,
    int? startTimeUtc,
    Value<int?> endTimeUtc = const Value.absent(),
    Value<int?> lastMovementUtc = const Value.absent(),
    Value<String?> bikeId = const Value.absent(),
    bool? nfcConfirmed,
    Value<double?> totalDistanceM = const Value.absent(),
    DistanceStatus? distanceStatus,
    int? movingDurationS,
    int? pausedDurationS,
    int? suspendedDurationS,
    Value<String?> reviewReason = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Trip(
    tripId: tripId ?? this.tripId,
    status: status ?? this.status,
    startTimeUtc: startTimeUtc ?? this.startTimeUtc,
    endTimeUtc: endTimeUtc.present ? endTimeUtc.value : this.endTimeUtc,
    lastMovementUtc: lastMovementUtc.present
        ? lastMovementUtc.value
        : this.lastMovementUtc,
    bikeId: bikeId.present ? bikeId.value : this.bikeId,
    nfcConfirmed: nfcConfirmed ?? this.nfcConfirmed,
    totalDistanceM: totalDistanceM.present
        ? totalDistanceM.value
        : this.totalDistanceM,
    distanceStatus: distanceStatus ?? this.distanceStatus,
    movingDurationS: movingDurationS ?? this.movingDurationS,
    pausedDurationS: pausedDurationS ?? this.pausedDurationS,
    suspendedDurationS: suspendedDurationS ?? this.suspendedDurationS,
    reviewReason: reviewReason.present ? reviewReason.value : this.reviewReason,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      status: data.status.present ? data.status.value : this.status,
      startTimeUtc: data.startTimeUtc.present
          ? data.startTimeUtc.value
          : this.startTimeUtc,
      endTimeUtc: data.endTimeUtc.present
          ? data.endTimeUtc.value
          : this.endTimeUtc,
      lastMovementUtc: data.lastMovementUtc.present
          ? data.lastMovementUtc.value
          : this.lastMovementUtc,
      bikeId: data.bikeId.present ? data.bikeId.value : this.bikeId,
      nfcConfirmed: data.nfcConfirmed.present
          ? data.nfcConfirmed.value
          : this.nfcConfirmed,
      totalDistanceM: data.totalDistanceM.present
          ? data.totalDistanceM.value
          : this.totalDistanceM,
      distanceStatus: data.distanceStatus.present
          ? data.distanceStatus.value
          : this.distanceStatus,
      movingDurationS: data.movingDurationS.present
          ? data.movingDurationS.value
          : this.movingDurationS,
      pausedDurationS: data.pausedDurationS.present
          ? data.pausedDurationS.value
          : this.pausedDurationS,
      suspendedDurationS: data.suspendedDurationS.present
          ? data.suspendedDurationS.value
          : this.suspendedDurationS,
      reviewReason: data.reviewReason.present
          ? data.reviewReason.value
          : this.reviewReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trip(')
          ..write('tripId: $tripId, ')
          ..write('status: $status, ')
          ..write('startTimeUtc: $startTimeUtc, ')
          ..write('endTimeUtc: $endTimeUtc, ')
          ..write('lastMovementUtc: $lastMovementUtc, ')
          ..write('bikeId: $bikeId, ')
          ..write('nfcConfirmed: $nfcConfirmed, ')
          ..write('totalDistanceM: $totalDistanceM, ')
          ..write('distanceStatus: $distanceStatus, ')
          ..write('movingDurationS: $movingDurationS, ')
          ..write('pausedDurationS: $pausedDurationS, ')
          ..write('suspendedDurationS: $suspendedDurationS, ')
          ..write('reviewReason: $reviewReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tripId,
    status,
    startTimeUtc,
    endTimeUtc,
    lastMovementUtc,
    bikeId,
    nfcConfirmed,
    totalDistanceM,
    distanceStatus,
    movingDurationS,
    pausedDurationS,
    suspendedDurationS,
    reviewReason,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip &&
          other.tripId == this.tripId &&
          other.status == this.status &&
          other.startTimeUtc == this.startTimeUtc &&
          other.endTimeUtc == this.endTimeUtc &&
          other.lastMovementUtc == this.lastMovementUtc &&
          other.bikeId == this.bikeId &&
          other.nfcConfirmed == this.nfcConfirmed &&
          other.totalDistanceM == this.totalDistanceM &&
          other.distanceStatus == this.distanceStatus &&
          other.movingDurationS == this.movingDurationS &&
          other.pausedDurationS == this.pausedDurationS &&
          other.suspendedDurationS == this.suspendedDurationS &&
          other.reviewReason == this.reviewReason &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<String> tripId;
  final Value<TripStatus> status;
  final Value<int> startTimeUtc;
  final Value<int?> endTimeUtc;
  final Value<int?> lastMovementUtc;
  final Value<String?> bikeId;
  final Value<bool> nfcConfirmed;
  final Value<double?> totalDistanceM;
  final Value<DistanceStatus> distanceStatus;
  final Value<int> movingDurationS;
  final Value<int> pausedDurationS;
  final Value<int> suspendedDurationS;
  final Value<String?> reviewReason;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const TripsCompanion({
    this.tripId = const Value.absent(),
    this.status = const Value.absent(),
    this.startTimeUtc = const Value.absent(),
    this.endTimeUtc = const Value.absent(),
    this.lastMovementUtc = const Value.absent(),
    this.bikeId = const Value.absent(),
    this.nfcConfirmed = const Value.absent(),
    this.totalDistanceM = const Value.absent(),
    this.distanceStatus = const Value.absent(),
    this.movingDurationS = const Value.absent(),
    this.pausedDurationS = const Value.absent(),
    this.suspendedDurationS = const Value.absent(),
    this.reviewReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripsCompanion.insert({
    required String tripId,
    required TripStatus status,
    required int startTimeUtc,
    this.endTimeUtc = const Value.absent(),
    this.lastMovementUtc = const Value.absent(),
    this.bikeId = const Value.absent(),
    required bool nfcConfirmed,
    this.totalDistanceM = const Value.absent(),
    required DistanceStatus distanceStatus,
    required int movingDurationS,
    required int pausedDurationS,
    required int suspendedDurationS,
    this.reviewReason = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : tripId = Value(tripId),
       status = Value(status),
       startTimeUtc = Value(startTimeUtc),
       nfcConfirmed = Value(nfcConfirmed),
       distanceStatus = Value(distanceStatus),
       movingDurationS = Value(movingDurationS),
       pausedDurationS = Value(pausedDurationS),
       suspendedDurationS = Value(suspendedDurationS),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Trip> custom({
    Expression<String>? tripId,
    Expression<String>? status,
    Expression<int>? startTimeUtc,
    Expression<int>? endTimeUtc,
    Expression<int>? lastMovementUtc,
    Expression<String>? bikeId,
    Expression<bool>? nfcConfirmed,
    Expression<double>? totalDistanceM,
    Expression<String>? distanceStatus,
    Expression<int>? movingDurationS,
    Expression<int>? pausedDurationS,
    Expression<int>? suspendedDurationS,
    Expression<String>? reviewReason,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tripId != null) 'trip_id': tripId,
      if (status != null) 'status': status,
      if (startTimeUtc != null) 'start_time_utc': startTimeUtc,
      if (endTimeUtc != null) 'end_time_utc': endTimeUtc,
      if (lastMovementUtc != null) 'last_movement_utc': lastMovementUtc,
      if (bikeId != null) 'bike_id': bikeId,
      if (nfcConfirmed != null) 'nfc_confirmed': nfcConfirmed,
      if (totalDistanceM != null) 'total_distance_m': totalDistanceM,
      if (distanceStatus != null) 'distance_status': distanceStatus,
      if (movingDurationS != null) 'moving_duration_s': movingDurationS,
      if (pausedDurationS != null) 'paused_duration_s': pausedDurationS,
      if (suspendedDurationS != null)
        'suspended_duration_s': suspendedDurationS,
      if (reviewReason != null) 'review_reason': reviewReason,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripsCompanion copyWith({
    Value<String>? tripId,
    Value<TripStatus>? status,
    Value<int>? startTimeUtc,
    Value<int?>? endTimeUtc,
    Value<int?>? lastMovementUtc,
    Value<String?>? bikeId,
    Value<bool>? nfcConfirmed,
    Value<double?>? totalDistanceM,
    Value<DistanceStatus>? distanceStatus,
    Value<int>? movingDurationS,
    Value<int>? pausedDurationS,
    Value<int>? suspendedDurationS,
    Value<String?>? reviewReason,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return TripsCompanion(
      tripId: tripId ?? this.tripId,
      status: status ?? this.status,
      startTimeUtc: startTimeUtc ?? this.startTimeUtc,
      endTimeUtc: endTimeUtc ?? this.endTimeUtc,
      lastMovementUtc: lastMovementUtc ?? this.lastMovementUtc,
      bikeId: bikeId ?? this.bikeId,
      nfcConfirmed: nfcConfirmed ?? this.nfcConfirmed,
      totalDistanceM: totalDistanceM ?? this.totalDistanceM,
      distanceStatus: distanceStatus ?? this.distanceStatus,
      movingDurationS: movingDurationS ?? this.movingDurationS,
      pausedDurationS: pausedDurationS ?? this.pausedDurationS,
      suspendedDurationS: suspendedDurationS ?? this.suspendedDurationS,
      reviewReason: reviewReason ?? this.reviewReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TripsTable.$converterstatus.toSql(status.value),
      );
    }
    if (startTimeUtc.present) {
      map['start_time_utc'] = Variable<int>(startTimeUtc.value);
    }
    if (endTimeUtc.present) {
      map['end_time_utc'] = Variable<int>(endTimeUtc.value);
    }
    if (lastMovementUtc.present) {
      map['last_movement_utc'] = Variable<int>(lastMovementUtc.value);
    }
    if (bikeId.present) {
      map['bike_id'] = Variable<String>(bikeId.value);
    }
    if (nfcConfirmed.present) {
      map['nfc_confirmed'] = Variable<bool>(nfcConfirmed.value);
    }
    if (totalDistanceM.present) {
      map['total_distance_m'] = Variable<double>(totalDistanceM.value);
    }
    if (distanceStatus.present) {
      map['distance_status'] = Variable<String>(
        $TripsTable.$converterdistanceStatus.toSql(distanceStatus.value),
      );
    }
    if (movingDurationS.present) {
      map['moving_duration_s'] = Variable<int>(movingDurationS.value);
    }
    if (pausedDurationS.present) {
      map['paused_duration_s'] = Variable<int>(pausedDurationS.value);
    }
    if (suspendedDurationS.present) {
      map['suspended_duration_s'] = Variable<int>(suspendedDurationS.value);
    }
    if (reviewReason.present) {
      map['review_reason'] = Variable<String>(reviewReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('tripId: $tripId, ')
          ..write('status: $status, ')
          ..write('startTimeUtc: $startTimeUtc, ')
          ..write('endTimeUtc: $endTimeUtc, ')
          ..write('lastMovementUtc: $lastMovementUtc, ')
          ..write('bikeId: $bikeId, ')
          ..write('nfcConfirmed: $nfcConfirmed, ')
          ..write('totalDistanceM: $totalDistanceM, ')
          ..write('distanceStatus: $distanceStatus, ')
          ..write('movingDurationS: $movingDurationS, ')
          ..write('pausedDurationS: $pausedDurationS, ')
          ..write('suspendedDurationS: $suspendedDurationS, ')
          ..write('reviewReason: $reviewReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SegmentsTable extends Segments with TableInfo<$SegmentsTable, Segment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _segmentIdMeta = const VerificationMeta(
    'segmentId',
  );
  @override
  late final GeneratedColumn<String> segmentId = GeneratedColumn<String>(
    'segment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (trip_id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SegmentType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SegmentType>($SegmentsTable.$convertertype);
  static const VerificationMeta _startUtcMeta = const VerificationMeta(
    'startUtc',
  );
  @override
  late final GeneratedColumn<int> startUtc = GeneratedColumn<int>(
    'start_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endUtcMeta = const VerificationMeta('endUtc');
  @override
  late final GeneratedColumn<int> endUtc = GeneratedColumn<int>(
    'end_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DistanceStatus, String>
  distanceStatus = GeneratedColumn<String>(
    'distance_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DistanceStatus>($SegmentsTable.$converterdistanceStatus);
  static const VerificationMeta _movingSMeta = const VerificationMeta(
    'movingS',
  );
  @override
  late final GeneratedColumn<int> movingS = GeneratedColumn<int>(
    'moving_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classificationSourceMeta =
      const VerificationMeta('classificationSource');
  @override
  late final GeneratedColumn<String> classificationSource =
      GeneratedColumn<String>(
        'classification_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _userCorrectedMeta = const VerificationMeta(
    'userCorrected',
  );
  @override
  late final GeneratedColumn<bool> userCorrected = GeneratedColumn<bool>(
    'user_corrected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_corrected" IN (0, 1))',
    ),
  );
  static const VerificationMeta _needsReviewMeta = const VerificationMeta(
    'needsReview',
  );
  @override
  late final GeneratedColumn<bool> needsReview = GeneratedColumn<bool>(
    'needs_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_review" IN (0, 1))',
    ),
  );
  static const VerificationMeta _healthWorkoutUuidMeta = const VerificationMeta(
    'healthWorkoutUuid',
  );
  @override
  late final GeneratedColumn<String> healthWorkoutUuid =
      GeneratedColumn<String>(
        'health_workout_uuid',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _healthSyncedAtMeta = const VerificationMeta(
    'healthSyncedAt',
  );
  @override
  late final GeneratedColumn<int> healthSyncedAt = GeneratedColumn<int>(
    'health_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    segmentId,
    tripId,
    type,
    startUtc,
    endUtc,
    distanceM,
    distanceStatus,
    movingS,
    confidence,
    classificationSource,
    userCorrected,
    needsReview,
    healthWorkoutUuid,
    healthSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Segment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('start_utc')) {
      context.handle(
        _startUtcMeta,
        startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_startUtcMeta);
    }
    if (data.containsKey('end_utc')) {
      context.handle(
        _endUtcMeta,
        endUtc.isAcceptableOrUnknown(data['end_utc']!, _endUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_endUtcMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('moving_s')) {
      context.handle(
        _movingSMeta,
        movingS.isAcceptableOrUnknown(data['moving_s']!, _movingSMeta),
      );
    } else if (isInserting) {
      context.missing(_movingSMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('classification_source')) {
      context.handle(
        _classificationSourceMeta,
        classificationSource.isAcceptableOrUnknown(
          data['classification_source']!,
          _classificationSourceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classificationSourceMeta);
    }
    if (data.containsKey('user_corrected')) {
      context.handle(
        _userCorrectedMeta,
        userCorrected.isAcceptableOrUnknown(
          data['user_corrected']!,
          _userCorrectedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_userCorrectedMeta);
    }
    if (data.containsKey('needs_review')) {
      context.handle(
        _needsReviewMeta,
        needsReview.isAcceptableOrUnknown(
          data['needs_review']!,
          _needsReviewMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_needsReviewMeta);
    }
    if (data.containsKey('health_workout_uuid')) {
      context.handle(
        _healthWorkoutUuidMeta,
        healthWorkoutUuid.isAcceptableOrUnknown(
          data['health_workout_uuid']!,
          _healthWorkoutUuidMeta,
        ),
      );
    }
    if (data.containsKey('health_synced_at')) {
      context.handle(
        _healthSyncedAtMeta,
        healthSyncedAt.isAcceptableOrUnknown(
          data['health_synced_at']!,
          _healthSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {segmentId};
  @override
  Segment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Segment(
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      type: $SegmentsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      startUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_utc'],
      )!,
      endUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_utc'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      ),
      distanceStatus: $SegmentsTable.$converterdistanceStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}distance_status'],
        )!,
      ),
      movingS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_s'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      classificationSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classification_source'],
      )!,
      userCorrected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_corrected'],
      )!,
      needsReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_review'],
      )!,
      healthWorkoutUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_workout_uuid'],
      ),
      healthSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}health_synced_at'],
      ),
    );
  }

  @override
  $SegmentsTable createAlias(String alias) {
    return $SegmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SegmentType, String, String> $convertertype =
      const EnumNameConverter<SegmentType>(SegmentType.values);
  static JsonTypeConverter2<DistanceStatus, String, String>
  $converterdistanceStatus = const EnumNameConverter<DistanceStatus>(
    DistanceStatus.values,
  );
}

class Segment extends DataClass implements Insertable<Segment> {
  final String segmentId;
  final String tripId;
  final SegmentType type;
  final int startUtc;
  final int endUtc;
  final double? distanceM;
  final DistanceStatus distanceStatus;
  final int movingS;
  final double confidence;
  final String classificationSource;
  final bool userCorrected;
  final bool needsReview;
  final String? healthWorkoutUuid;
  final int? healthSyncedAt;
  const Segment({
    required this.segmentId,
    required this.tripId,
    required this.type,
    required this.startUtc,
    required this.endUtc,
    this.distanceM,
    required this.distanceStatus,
    required this.movingS,
    required this.confidence,
    required this.classificationSource,
    required this.userCorrected,
    required this.needsReview,
    this.healthWorkoutUuid,
    this.healthSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['segment_id'] = Variable<String>(segmentId);
    map['trip_id'] = Variable<String>(tripId);
    {
      map['type'] = Variable<String>($SegmentsTable.$convertertype.toSql(type));
    }
    map['start_utc'] = Variable<int>(startUtc);
    map['end_utc'] = Variable<int>(endUtc);
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<double>(distanceM);
    }
    {
      map['distance_status'] = Variable<String>(
        $SegmentsTable.$converterdistanceStatus.toSql(distanceStatus),
      );
    }
    map['moving_s'] = Variable<int>(movingS);
    map['confidence'] = Variable<double>(confidence);
    map['classification_source'] = Variable<String>(classificationSource);
    map['user_corrected'] = Variable<bool>(userCorrected);
    map['needs_review'] = Variable<bool>(needsReview);
    if (!nullToAbsent || healthWorkoutUuid != null) {
      map['health_workout_uuid'] = Variable<String>(healthWorkoutUuid);
    }
    if (!nullToAbsent || healthSyncedAt != null) {
      map['health_synced_at'] = Variable<int>(healthSyncedAt);
    }
    return map;
  }

  SegmentsCompanion toCompanion(bool nullToAbsent) {
    return SegmentsCompanion(
      segmentId: Value(segmentId),
      tripId: Value(tripId),
      type: Value(type),
      startUtc: Value(startUtc),
      endUtc: Value(endUtc),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      distanceStatus: Value(distanceStatus),
      movingS: Value(movingS),
      confidence: Value(confidence),
      classificationSource: Value(classificationSource),
      userCorrected: Value(userCorrected),
      needsReview: Value(needsReview),
      healthWorkoutUuid: healthWorkoutUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(healthWorkoutUuid),
      healthSyncedAt: healthSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(healthSyncedAt),
    );
  }

  factory Segment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Segment(
      segmentId: serializer.fromJson<String>(json['segmentId']),
      tripId: serializer.fromJson<String>(json['tripId']),
      type: $SegmentsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      startUtc: serializer.fromJson<int>(json['startUtc']),
      endUtc: serializer.fromJson<int>(json['endUtc']),
      distanceM: serializer.fromJson<double?>(json['distanceM']),
      distanceStatus: $SegmentsTable.$converterdistanceStatus.fromJson(
        serializer.fromJson<String>(json['distanceStatus']),
      ),
      movingS: serializer.fromJson<int>(json['movingS']),
      confidence: serializer.fromJson<double>(json['confidence']),
      classificationSource: serializer.fromJson<String>(
        json['classificationSource'],
      ),
      userCorrected: serializer.fromJson<bool>(json['userCorrected']),
      needsReview: serializer.fromJson<bool>(json['needsReview']),
      healthWorkoutUuid: serializer.fromJson<String?>(
        json['healthWorkoutUuid'],
      ),
      healthSyncedAt: serializer.fromJson<int?>(json['healthSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'segmentId': serializer.toJson<String>(segmentId),
      'tripId': serializer.toJson<String>(tripId),
      'type': serializer.toJson<String>(
        $SegmentsTable.$convertertype.toJson(type),
      ),
      'startUtc': serializer.toJson<int>(startUtc),
      'endUtc': serializer.toJson<int>(endUtc),
      'distanceM': serializer.toJson<double?>(distanceM),
      'distanceStatus': serializer.toJson<String>(
        $SegmentsTable.$converterdistanceStatus.toJson(distanceStatus),
      ),
      'movingS': serializer.toJson<int>(movingS),
      'confidence': serializer.toJson<double>(confidence),
      'classificationSource': serializer.toJson<String>(classificationSource),
      'userCorrected': serializer.toJson<bool>(userCorrected),
      'needsReview': serializer.toJson<bool>(needsReview),
      'healthWorkoutUuid': serializer.toJson<String?>(healthWorkoutUuid),
      'healthSyncedAt': serializer.toJson<int?>(healthSyncedAt),
    };
  }

  Segment copyWith({
    String? segmentId,
    String? tripId,
    SegmentType? type,
    int? startUtc,
    int? endUtc,
    Value<double?> distanceM = const Value.absent(),
    DistanceStatus? distanceStatus,
    int? movingS,
    double? confidence,
    String? classificationSource,
    bool? userCorrected,
    bool? needsReview,
    Value<String?> healthWorkoutUuid = const Value.absent(),
    Value<int?> healthSyncedAt = const Value.absent(),
  }) => Segment(
    segmentId: segmentId ?? this.segmentId,
    tripId: tripId ?? this.tripId,
    type: type ?? this.type,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc ?? this.endUtc,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
    distanceStatus: distanceStatus ?? this.distanceStatus,
    movingS: movingS ?? this.movingS,
    confidence: confidence ?? this.confidence,
    classificationSource: classificationSource ?? this.classificationSource,
    userCorrected: userCorrected ?? this.userCorrected,
    needsReview: needsReview ?? this.needsReview,
    healthWorkoutUuid: healthWorkoutUuid.present
        ? healthWorkoutUuid.value
        : this.healthWorkoutUuid,
    healthSyncedAt: healthSyncedAt.present
        ? healthSyncedAt.value
        : this.healthSyncedAt,
  );
  Segment copyWithCompanion(SegmentsCompanion data) {
    return Segment(
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      type: data.type.present ? data.type.value : this.type,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      endUtc: data.endUtc.present ? data.endUtc.value : this.endUtc,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      distanceStatus: data.distanceStatus.present
          ? data.distanceStatus.value
          : this.distanceStatus,
      movingS: data.movingS.present ? data.movingS.value : this.movingS,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      classificationSource: data.classificationSource.present
          ? data.classificationSource.value
          : this.classificationSource,
      userCorrected: data.userCorrected.present
          ? data.userCorrected.value
          : this.userCorrected,
      needsReview: data.needsReview.present
          ? data.needsReview.value
          : this.needsReview,
      healthWorkoutUuid: data.healthWorkoutUuid.present
          ? data.healthWorkoutUuid.value
          : this.healthWorkoutUuid,
      healthSyncedAt: data.healthSyncedAt.present
          ? data.healthSyncedAt.value
          : this.healthSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Segment(')
          ..write('segmentId: $segmentId, ')
          ..write('tripId: $tripId, ')
          ..write('type: $type, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('distanceM: $distanceM, ')
          ..write('distanceStatus: $distanceStatus, ')
          ..write('movingS: $movingS, ')
          ..write('confidence: $confidence, ')
          ..write('classificationSource: $classificationSource, ')
          ..write('userCorrected: $userCorrected, ')
          ..write('needsReview: $needsReview, ')
          ..write('healthWorkoutUuid: $healthWorkoutUuid, ')
          ..write('healthSyncedAt: $healthSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    segmentId,
    tripId,
    type,
    startUtc,
    endUtc,
    distanceM,
    distanceStatus,
    movingS,
    confidence,
    classificationSource,
    userCorrected,
    needsReview,
    healthWorkoutUuid,
    healthSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Segment &&
          other.segmentId == this.segmentId &&
          other.tripId == this.tripId &&
          other.type == this.type &&
          other.startUtc == this.startUtc &&
          other.endUtc == this.endUtc &&
          other.distanceM == this.distanceM &&
          other.distanceStatus == this.distanceStatus &&
          other.movingS == this.movingS &&
          other.confidence == this.confidence &&
          other.classificationSource == this.classificationSource &&
          other.userCorrected == this.userCorrected &&
          other.needsReview == this.needsReview &&
          other.healthWorkoutUuid == this.healthWorkoutUuid &&
          other.healthSyncedAt == this.healthSyncedAt);
}

class SegmentsCompanion extends UpdateCompanion<Segment> {
  final Value<String> segmentId;
  final Value<String> tripId;
  final Value<SegmentType> type;
  final Value<int> startUtc;
  final Value<int> endUtc;
  final Value<double?> distanceM;
  final Value<DistanceStatus> distanceStatus;
  final Value<int> movingS;
  final Value<double> confidence;
  final Value<String> classificationSource;
  final Value<bool> userCorrected;
  final Value<bool> needsReview;
  final Value<String?> healthWorkoutUuid;
  final Value<int?> healthSyncedAt;
  final Value<int> rowid;
  const SegmentsCompanion({
    this.segmentId = const Value.absent(),
    this.tripId = const Value.absent(),
    this.type = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.distanceStatus = const Value.absent(),
    this.movingS = const Value.absent(),
    this.confidence = const Value.absent(),
    this.classificationSource = const Value.absent(),
    this.userCorrected = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.healthWorkoutUuid = const Value.absent(),
    this.healthSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SegmentsCompanion.insert({
    required String segmentId,
    required String tripId,
    required SegmentType type,
    required int startUtc,
    required int endUtc,
    this.distanceM = const Value.absent(),
    required DistanceStatus distanceStatus,
    required int movingS,
    required double confidence,
    required String classificationSource,
    required bool userCorrected,
    required bool needsReview,
    this.healthWorkoutUuid = const Value.absent(),
    this.healthSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : segmentId = Value(segmentId),
       tripId = Value(tripId),
       type = Value(type),
       startUtc = Value(startUtc),
       endUtc = Value(endUtc),
       distanceStatus = Value(distanceStatus),
       movingS = Value(movingS),
       confidence = Value(confidence),
       classificationSource = Value(classificationSource),
       userCorrected = Value(userCorrected),
       needsReview = Value(needsReview);
  static Insertable<Segment> custom({
    Expression<String>? segmentId,
    Expression<String>? tripId,
    Expression<String>? type,
    Expression<int>? startUtc,
    Expression<int>? endUtc,
    Expression<double>? distanceM,
    Expression<String>? distanceStatus,
    Expression<int>? movingS,
    Expression<double>? confidence,
    Expression<String>? classificationSource,
    Expression<bool>? userCorrected,
    Expression<bool>? needsReview,
    Expression<String>? healthWorkoutUuid,
    Expression<int>? healthSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (segmentId != null) 'segment_id': segmentId,
      if (tripId != null) 'trip_id': tripId,
      if (type != null) 'type': type,
      if (startUtc != null) 'start_utc': startUtc,
      if (endUtc != null) 'end_utc': endUtc,
      if (distanceM != null) 'distance_m': distanceM,
      if (distanceStatus != null) 'distance_status': distanceStatus,
      if (movingS != null) 'moving_s': movingS,
      if (confidence != null) 'confidence': confidence,
      if (classificationSource != null)
        'classification_source': classificationSource,
      if (userCorrected != null) 'user_corrected': userCorrected,
      if (needsReview != null) 'needs_review': needsReview,
      if (healthWorkoutUuid != null) 'health_workout_uuid': healthWorkoutUuid,
      if (healthSyncedAt != null) 'health_synced_at': healthSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SegmentsCompanion copyWith({
    Value<String>? segmentId,
    Value<String>? tripId,
    Value<SegmentType>? type,
    Value<int>? startUtc,
    Value<int>? endUtc,
    Value<double?>? distanceM,
    Value<DistanceStatus>? distanceStatus,
    Value<int>? movingS,
    Value<double>? confidence,
    Value<String>? classificationSource,
    Value<bool>? userCorrected,
    Value<bool>? needsReview,
    Value<String?>? healthWorkoutUuid,
    Value<int?>? healthSyncedAt,
    Value<int>? rowid,
  }) {
    return SegmentsCompanion(
      segmentId: segmentId ?? this.segmentId,
      tripId: tripId ?? this.tripId,
      type: type ?? this.type,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      distanceM: distanceM ?? this.distanceM,
      distanceStatus: distanceStatus ?? this.distanceStatus,
      movingS: movingS ?? this.movingS,
      confidence: confidence ?? this.confidence,
      classificationSource: classificationSource ?? this.classificationSource,
      userCorrected: userCorrected ?? this.userCorrected,
      needsReview: needsReview ?? this.needsReview,
      healthWorkoutUuid: healthWorkoutUuid ?? this.healthWorkoutUuid,
      healthSyncedAt: healthSyncedAt ?? this.healthSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (segmentId.present) {
      map['segment_id'] = Variable<String>(segmentId.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $SegmentsTable.$convertertype.toSql(type.value),
      );
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<int>(startUtc.value);
    }
    if (endUtc.present) {
      map['end_utc'] = Variable<int>(endUtc.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (distanceStatus.present) {
      map['distance_status'] = Variable<String>(
        $SegmentsTable.$converterdistanceStatus.toSql(distanceStatus.value),
      );
    }
    if (movingS.present) {
      map['moving_s'] = Variable<int>(movingS.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (classificationSource.present) {
      map['classification_source'] = Variable<String>(
        classificationSource.value,
      );
    }
    if (userCorrected.present) {
      map['user_corrected'] = Variable<bool>(userCorrected.value);
    }
    if (needsReview.present) {
      map['needs_review'] = Variable<bool>(needsReview.value);
    }
    if (healthWorkoutUuid.present) {
      map['health_workout_uuid'] = Variable<String>(healthWorkoutUuid.value);
    }
    if (healthSyncedAt.present) {
      map['health_synced_at'] = Variable<int>(healthSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SegmentsCompanion(')
          ..write('segmentId: $segmentId, ')
          ..write('tripId: $tripId, ')
          ..write('type: $type, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('distanceM: $distanceM, ')
          ..write('distanceStatus: $distanceStatus, ')
          ..write('movingS: $movingS, ')
          ..write('confidence: $confidence, ')
          ..write('classificationSource: $classificationSource, ')
          ..write('userCorrected: $userCorrected, ')
          ..write('needsReview: $needsReview, ')
          ..write('healthWorkoutUuid: $healthWorkoutUuid, ')
          ..write('healthSyncedAt: $healthSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GpsPointsTable extends GpsPoints
    with TableInfo<$GpsPointsTable, GpsPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GpsPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segmentIdMeta = const VerificationMeta(
    'segmentId',
  );
  @override
  late final GeneratedColumn<String> segmentId = GeneratedColumn<String>(
    'segment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES segments (segment_id)',
    ),
  );
  static const VerificationMeta _tsUtcMeta = const VerificationMeta('tsUtc');
  @override
  late final GeneratedColumn<int> tsUtc = GeneratedColumn<int>(
    'ts_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMMeta = const VerificationMeta(
    'altitudeM',
  );
  @override
  late final GeneratedColumn<double> altitudeM = GeneratedColumn<double>(
    'altitude_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hAccuracyMMeta = const VerificationMeta(
    'hAccuracyM',
  );
  @override
  late final GeneratedColumn<double> hAccuracyM = GeneratedColumn<double>(
    'h_accuracy_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vAccuracyMMeta = const VerificationMeta(
    'vAccuracyM',
  );
  @override
  late final GeneratedColumn<double> vAccuracyM = GeneratedColumn<double>(
    'v_accuracy_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedAccuracyMpsMeta = const VerificationMeta(
    'speedAccuracyMps',
  );
  @override
  late final GeneratedColumn<double> speedAccuracyMps = GeneratedColumn<double>(
    'speed_accuracy_mps',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseDegMeta = const VerificationMeta(
    'courseDeg',
  );
  @override
  late final GeneratedColumn<double> courseDeg = GeneratedColumn<double>(
    'course_deg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acceptedMeta = const VerificationMeta(
    'accepted',
  );
  @override
  late final GeneratedColumn<bool> accepted = GeneratedColumn<bool>(
    'accepted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("accepted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _rejectReasonMeta = const VerificationMeta(
    'rejectReason',
  );
  @override
  late final GeneratedColumn<String> rejectReason = GeneratedColumn<String>(
    'reject_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    segmentId,
    tsUtc,
    lat,
    lon,
    altitudeM,
    hAccuracyM,
    vAccuracyM,
    speedMps,
    speedAccuracyMps,
    courseDeg,
    accepted,
    rejectReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gps_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<GpsPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('ts_utc')) {
      context.handle(
        _tsUtcMeta,
        tsUtc.isAcceptableOrUnknown(data['ts_utc']!, _tsUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_tsUtcMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('altitude_m')) {
      context.handle(
        _altitudeMMeta,
        altitudeM.isAcceptableOrUnknown(data['altitude_m']!, _altitudeMMeta),
      );
    } else if (isInserting) {
      context.missing(_altitudeMMeta);
    }
    if (data.containsKey('h_accuracy_m')) {
      context.handle(
        _hAccuracyMMeta,
        hAccuracyM.isAcceptableOrUnknown(
          data['h_accuracy_m']!,
          _hAccuracyMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hAccuracyMMeta);
    }
    if (data.containsKey('v_accuracy_m')) {
      context.handle(
        _vAccuracyMMeta,
        vAccuracyM.isAcceptableOrUnknown(
          data['v_accuracy_m']!,
          _vAccuracyMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vAccuracyMMeta);
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    } else if (isInserting) {
      context.missing(_speedMpsMeta);
    }
    if (data.containsKey('speed_accuracy_mps')) {
      context.handle(
        _speedAccuracyMpsMeta,
        speedAccuracyMps.isAcceptableOrUnknown(
          data['speed_accuracy_mps']!,
          _speedAccuracyMpsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_speedAccuracyMpsMeta);
    }
    if (data.containsKey('course_deg')) {
      context.handle(
        _courseDegMeta,
        courseDeg.isAcceptableOrUnknown(data['course_deg']!, _courseDegMeta),
      );
    } else if (isInserting) {
      context.missing(_courseDegMeta);
    }
    if (data.containsKey('accepted')) {
      context.handle(
        _acceptedMeta,
        accepted.isAcceptableOrUnknown(data['accepted']!, _acceptedMeta),
      );
    } else if (isInserting) {
      context.missing(_acceptedMeta);
    }
    if (data.containsKey('reject_reason')) {
      context.handle(
        _rejectReasonMeta,
        rejectReason.isAcceptableOrUnknown(
          data['reject_reason']!,
          _rejectReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GpsPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GpsPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_id'],
      )!,
      tsUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts_utc'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      altitudeM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude_m'],
      )!,
      hAccuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}h_accuracy_m'],
      )!,
      vAccuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}v_accuracy_m'],
      )!,
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      )!,
      speedAccuracyMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_accuracy_mps'],
      )!,
      courseDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}course_deg'],
      )!,
      accepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}accepted'],
      )!,
      rejectReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reject_reason'],
      ),
    );
  }

  @override
  $GpsPointsTable createAlias(String alias) {
    return $GpsPointsTable(attachedDatabase, alias);
  }
}

class GpsPoint extends DataClass implements Insertable<GpsPoint> {
  final int id;
  final String segmentId;
  final int tsUtc;
  final double lat;
  final double lon;
  final double altitudeM;
  final double hAccuracyM;
  final double vAccuracyM;
  final double speedMps;
  final double speedAccuracyMps;
  final double courseDeg;
  final bool accepted;
  final String? rejectReason;
  const GpsPoint({
    required this.id,
    required this.segmentId,
    required this.tsUtc,
    required this.lat,
    required this.lon,
    required this.altitudeM,
    required this.hAccuracyM,
    required this.vAccuracyM,
    required this.speedMps,
    required this.speedAccuracyMps,
    required this.courseDeg,
    required this.accepted,
    this.rejectReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['segment_id'] = Variable<String>(segmentId);
    map['ts_utc'] = Variable<int>(tsUtc);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['altitude_m'] = Variable<double>(altitudeM);
    map['h_accuracy_m'] = Variable<double>(hAccuracyM);
    map['v_accuracy_m'] = Variable<double>(vAccuracyM);
    map['speed_mps'] = Variable<double>(speedMps);
    map['speed_accuracy_mps'] = Variable<double>(speedAccuracyMps);
    map['course_deg'] = Variable<double>(courseDeg);
    map['accepted'] = Variable<bool>(accepted);
    if (!nullToAbsent || rejectReason != null) {
      map['reject_reason'] = Variable<String>(rejectReason);
    }
    return map;
  }

  GpsPointsCompanion toCompanion(bool nullToAbsent) {
    return GpsPointsCompanion(
      id: Value(id),
      segmentId: Value(segmentId),
      tsUtc: Value(tsUtc),
      lat: Value(lat),
      lon: Value(lon),
      altitudeM: Value(altitudeM),
      hAccuracyM: Value(hAccuracyM),
      vAccuracyM: Value(vAccuracyM),
      speedMps: Value(speedMps),
      speedAccuracyMps: Value(speedAccuracyMps),
      courseDeg: Value(courseDeg),
      accepted: Value(accepted),
      rejectReason: rejectReason == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectReason),
    );
  }

  factory GpsPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GpsPoint(
      id: serializer.fromJson<int>(json['id']),
      segmentId: serializer.fromJson<String>(json['segmentId']),
      tsUtc: serializer.fromJson<int>(json['tsUtc']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      altitudeM: serializer.fromJson<double>(json['altitudeM']),
      hAccuracyM: serializer.fromJson<double>(json['hAccuracyM']),
      vAccuracyM: serializer.fromJson<double>(json['vAccuracyM']),
      speedMps: serializer.fromJson<double>(json['speedMps']),
      speedAccuracyMps: serializer.fromJson<double>(json['speedAccuracyMps']),
      courseDeg: serializer.fromJson<double>(json['courseDeg']),
      accepted: serializer.fromJson<bool>(json['accepted']),
      rejectReason: serializer.fromJson<String?>(json['rejectReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'segmentId': serializer.toJson<String>(segmentId),
      'tsUtc': serializer.toJson<int>(tsUtc),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'altitudeM': serializer.toJson<double>(altitudeM),
      'hAccuracyM': serializer.toJson<double>(hAccuracyM),
      'vAccuracyM': serializer.toJson<double>(vAccuracyM),
      'speedMps': serializer.toJson<double>(speedMps),
      'speedAccuracyMps': serializer.toJson<double>(speedAccuracyMps),
      'courseDeg': serializer.toJson<double>(courseDeg),
      'accepted': serializer.toJson<bool>(accepted),
      'rejectReason': serializer.toJson<String?>(rejectReason),
    };
  }

  GpsPoint copyWith({
    int? id,
    String? segmentId,
    int? tsUtc,
    double? lat,
    double? lon,
    double? altitudeM,
    double? hAccuracyM,
    double? vAccuracyM,
    double? speedMps,
    double? speedAccuracyMps,
    double? courseDeg,
    bool? accepted,
    Value<String?> rejectReason = const Value.absent(),
  }) => GpsPoint(
    id: id ?? this.id,
    segmentId: segmentId ?? this.segmentId,
    tsUtc: tsUtc ?? this.tsUtc,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    altitudeM: altitudeM ?? this.altitudeM,
    hAccuracyM: hAccuracyM ?? this.hAccuracyM,
    vAccuracyM: vAccuracyM ?? this.vAccuracyM,
    speedMps: speedMps ?? this.speedMps,
    speedAccuracyMps: speedAccuracyMps ?? this.speedAccuracyMps,
    courseDeg: courseDeg ?? this.courseDeg,
    accepted: accepted ?? this.accepted,
    rejectReason: rejectReason.present ? rejectReason.value : this.rejectReason,
  );
  GpsPoint copyWithCompanion(GpsPointsCompanion data) {
    return GpsPoint(
      id: data.id.present ? data.id.value : this.id,
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      tsUtc: data.tsUtc.present ? data.tsUtc.value : this.tsUtc,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      altitudeM: data.altitudeM.present ? data.altitudeM.value : this.altitudeM,
      hAccuracyM: data.hAccuracyM.present
          ? data.hAccuracyM.value
          : this.hAccuracyM,
      vAccuracyM: data.vAccuracyM.present
          ? data.vAccuracyM.value
          : this.vAccuracyM,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      speedAccuracyMps: data.speedAccuracyMps.present
          ? data.speedAccuracyMps.value
          : this.speedAccuracyMps,
      courseDeg: data.courseDeg.present ? data.courseDeg.value : this.courseDeg,
      accepted: data.accepted.present ? data.accepted.value : this.accepted,
      rejectReason: data.rejectReason.present
          ? data.rejectReason.value
          : this.rejectReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GpsPoint(')
          ..write('id: $id, ')
          ..write('segmentId: $segmentId, ')
          ..write('tsUtc: $tsUtc, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('hAccuracyM: $hAccuracyM, ')
          ..write('vAccuracyM: $vAccuracyM, ')
          ..write('speedMps: $speedMps, ')
          ..write('speedAccuracyMps: $speedAccuracyMps, ')
          ..write('courseDeg: $courseDeg, ')
          ..write('accepted: $accepted, ')
          ..write('rejectReason: $rejectReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    segmentId,
    tsUtc,
    lat,
    lon,
    altitudeM,
    hAccuracyM,
    vAccuracyM,
    speedMps,
    speedAccuracyMps,
    courseDeg,
    accepted,
    rejectReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GpsPoint &&
          other.id == this.id &&
          other.segmentId == this.segmentId &&
          other.tsUtc == this.tsUtc &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.altitudeM == this.altitudeM &&
          other.hAccuracyM == this.hAccuracyM &&
          other.vAccuracyM == this.vAccuracyM &&
          other.speedMps == this.speedMps &&
          other.speedAccuracyMps == this.speedAccuracyMps &&
          other.courseDeg == this.courseDeg &&
          other.accepted == this.accepted &&
          other.rejectReason == this.rejectReason);
}

class GpsPointsCompanion extends UpdateCompanion<GpsPoint> {
  final Value<int> id;
  final Value<String> segmentId;
  final Value<int> tsUtc;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double> altitudeM;
  final Value<double> hAccuracyM;
  final Value<double> vAccuracyM;
  final Value<double> speedMps;
  final Value<double> speedAccuracyMps;
  final Value<double> courseDeg;
  final Value<bool> accepted;
  final Value<String?> rejectReason;
  const GpsPointsCompanion({
    this.id = const Value.absent(),
    this.segmentId = const Value.absent(),
    this.tsUtc = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.altitudeM = const Value.absent(),
    this.hAccuracyM = const Value.absent(),
    this.vAccuracyM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.speedAccuracyMps = const Value.absent(),
    this.courseDeg = const Value.absent(),
    this.accepted = const Value.absent(),
    this.rejectReason = const Value.absent(),
  });
  GpsPointsCompanion.insert({
    this.id = const Value.absent(),
    required String segmentId,
    required int tsUtc,
    required double lat,
    required double lon,
    required double altitudeM,
    required double hAccuracyM,
    required double vAccuracyM,
    required double speedMps,
    required double speedAccuracyMps,
    required double courseDeg,
    required bool accepted,
    this.rejectReason = const Value.absent(),
  }) : segmentId = Value(segmentId),
       tsUtc = Value(tsUtc),
       lat = Value(lat),
       lon = Value(lon),
       altitudeM = Value(altitudeM),
       hAccuracyM = Value(hAccuracyM),
       vAccuracyM = Value(vAccuracyM),
       speedMps = Value(speedMps),
       speedAccuracyMps = Value(speedAccuracyMps),
       courseDeg = Value(courseDeg),
       accepted = Value(accepted);
  static Insertable<GpsPoint> custom({
    Expression<int>? id,
    Expression<String>? segmentId,
    Expression<int>? tsUtc,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? altitudeM,
    Expression<double>? hAccuracyM,
    Expression<double>? vAccuracyM,
    Expression<double>? speedMps,
    Expression<double>? speedAccuracyMps,
    Expression<double>? courseDeg,
    Expression<bool>? accepted,
    Expression<String>? rejectReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (segmentId != null) 'segment_id': segmentId,
      if (tsUtc != null) 'ts_utc': tsUtc,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (altitudeM != null) 'altitude_m': altitudeM,
      if (hAccuracyM != null) 'h_accuracy_m': hAccuracyM,
      if (vAccuracyM != null) 'v_accuracy_m': vAccuracyM,
      if (speedMps != null) 'speed_mps': speedMps,
      if (speedAccuracyMps != null) 'speed_accuracy_mps': speedAccuracyMps,
      if (courseDeg != null) 'course_deg': courseDeg,
      if (accepted != null) 'accepted': accepted,
      if (rejectReason != null) 'reject_reason': rejectReason,
    });
  }

  GpsPointsCompanion copyWith({
    Value<int>? id,
    Value<String>? segmentId,
    Value<int>? tsUtc,
    Value<double>? lat,
    Value<double>? lon,
    Value<double>? altitudeM,
    Value<double>? hAccuracyM,
    Value<double>? vAccuracyM,
    Value<double>? speedMps,
    Value<double>? speedAccuracyMps,
    Value<double>? courseDeg,
    Value<bool>? accepted,
    Value<String?>? rejectReason,
  }) {
    return GpsPointsCompanion(
      id: id ?? this.id,
      segmentId: segmentId ?? this.segmentId,
      tsUtc: tsUtc ?? this.tsUtc,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      altitudeM: altitudeM ?? this.altitudeM,
      hAccuracyM: hAccuracyM ?? this.hAccuracyM,
      vAccuracyM: vAccuracyM ?? this.vAccuracyM,
      speedMps: speedMps ?? this.speedMps,
      speedAccuracyMps: speedAccuracyMps ?? this.speedAccuracyMps,
      courseDeg: courseDeg ?? this.courseDeg,
      accepted: accepted ?? this.accepted,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (segmentId.present) {
      map['segment_id'] = Variable<String>(segmentId.value);
    }
    if (tsUtc.present) {
      map['ts_utc'] = Variable<int>(tsUtc.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (altitudeM.present) {
      map['altitude_m'] = Variable<double>(altitudeM.value);
    }
    if (hAccuracyM.present) {
      map['h_accuracy_m'] = Variable<double>(hAccuracyM.value);
    }
    if (vAccuracyM.present) {
      map['v_accuracy_m'] = Variable<double>(vAccuracyM.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (speedAccuracyMps.present) {
      map['speed_accuracy_mps'] = Variable<double>(speedAccuracyMps.value);
    }
    if (courseDeg.present) {
      map['course_deg'] = Variable<double>(courseDeg.value);
    }
    if (accepted.present) {
      map['accepted'] = Variable<bool>(accepted.value);
    }
    if (rejectReason.present) {
      map['reject_reason'] = Variable<String>(rejectReason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GpsPointsCompanion(')
          ..write('id: $id, ')
          ..write('segmentId: $segmentId, ')
          ..write('tsUtc: $tsUtc, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('hAccuracyM: $hAccuracyM, ')
          ..write('vAccuracyM: $vAccuracyM, ')
          ..write('speedMps: $speedMps, ')
          ..write('speedAccuracyMps: $speedAccuracyMps, ')
          ..write('courseDeg: $courseDeg, ')
          ..write('accepted: $accepted, ')
          ..write('rejectReason: $rejectReason')
          ..write(')'))
        .toString();
  }
}

class $ActivitySamplesTable extends ActivitySamples
    with TableInfo<$ActivitySamplesTable, ActivitySample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitySamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tsUtcMeta = const VerificationMeta('tsUtc');
  @override
  late final GeneratedColumn<int> tsUtc = GeneratedColumn<int>(
    'ts_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stationaryMeta = const VerificationMeta(
    'stationary',
  );
  @override
  late final GeneratedColumn<bool> stationary = GeneratedColumn<bool>(
    'stationary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("stationary" IN (0, 1))',
    ),
  );
  static const VerificationMeta _walkingMeta = const VerificationMeta(
    'walking',
  );
  @override
  late final GeneratedColumn<bool> walking = GeneratedColumn<bool>(
    'walking',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("walking" IN (0, 1))',
    ),
  );
  static const VerificationMeta _runningMeta = const VerificationMeta(
    'running',
  );
  @override
  late final GeneratedColumn<bool> running = GeneratedColumn<bool>(
    'running',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("running" IN (0, 1))',
    ),
  );
  static const VerificationMeta _cyclingMeta = const VerificationMeta(
    'cycling',
  );
  @override
  late final GeneratedColumn<bool> cycling = GeneratedColumn<bool>(
    'cycling',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cycling" IN (0, 1))',
    ),
  );
  static const VerificationMeta _automotiveMeta = const VerificationMeta(
    'automotive',
  );
  @override
  late final GeneratedColumn<bool> automotive = GeneratedColumn<bool>(
    'automotive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("automotive" IN (0, 1))',
    ),
  );
  static const VerificationMeta _unknownMeta = const VerificationMeta(
    'unknown',
  );
  @override
  late final GeneratedColumn<bool> unknown = GeneratedColumn<bool>(
    'unknown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("unknown" IN (0, 1))',
    ),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<int> confidence = GeneratedColumn<int>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tsUtc,
    stationary,
    walking,
    running,
    cycling,
    automotive,
    unknown,
    confidence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivitySample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ts_utc')) {
      context.handle(
        _tsUtcMeta,
        tsUtc.isAcceptableOrUnknown(data['ts_utc']!, _tsUtcMeta),
      );
    }
    if (data.containsKey('stationary')) {
      context.handle(
        _stationaryMeta,
        stationary.isAcceptableOrUnknown(data['stationary']!, _stationaryMeta),
      );
    } else if (isInserting) {
      context.missing(_stationaryMeta);
    }
    if (data.containsKey('walking')) {
      context.handle(
        _walkingMeta,
        walking.isAcceptableOrUnknown(data['walking']!, _walkingMeta),
      );
    } else if (isInserting) {
      context.missing(_walkingMeta);
    }
    if (data.containsKey('running')) {
      context.handle(
        _runningMeta,
        running.isAcceptableOrUnknown(data['running']!, _runningMeta),
      );
    } else if (isInserting) {
      context.missing(_runningMeta);
    }
    if (data.containsKey('cycling')) {
      context.handle(
        _cyclingMeta,
        cycling.isAcceptableOrUnknown(data['cycling']!, _cyclingMeta),
      );
    } else if (isInserting) {
      context.missing(_cyclingMeta);
    }
    if (data.containsKey('automotive')) {
      context.handle(
        _automotiveMeta,
        automotive.isAcceptableOrUnknown(data['automotive']!, _automotiveMeta),
      );
    } else if (isInserting) {
      context.missing(_automotiveMeta);
    }
    if (data.containsKey('unknown')) {
      context.handle(
        _unknownMeta,
        unknown.isAcceptableOrUnknown(data['unknown']!, _unknownMeta),
      );
    } else if (isInserting) {
      context.missing(_unknownMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tsUtc};
  @override
  ActivitySample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivitySample(
      tsUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts_utc'],
      )!,
      stationary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}stationary'],
      )!,
      walking: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}walking'],
      )!,
      running: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}running'],
      )!,
      cycling: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cycling'],
      )!,
      automotive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}automotive'],
      )!,
      unknown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unknown'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confidence'],
      )!,
    );
  }

  @override
  $ActivitySamplesTable createAlias(String alias) {
    return $ActivitySamplesTable(attachedDatabase, alias);
  }
}

class ActivitySample extends DataClass implements Insertable<ActivitySample> {
  final int tsUtc;
  final bool stationary;
  final bool walking;
  final bool running;
  final bool cycling;
  final bool automotive;
  final bool unknown;
  final int confidence;
  const ActivitySample({
    required this.tsUtc,
    required this.stationary,
    required this.walking,
    required this.running,
    required this.cycling,
    required this.automotive,
    required this.unknown,
    required this.confidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ts_utc'] = Variable<int>(tsUtc);
    map['stationary'] = Variable<bool>(stationary);
    map['walking'] = Variable<bool>(walking);
    map['running'] = Variable<bool>(running);
    map['cycling'] = Variable<bool>(cycling);
    map['automotive'] = Variable<bool>(automotive);
    map['unknown'] = Variable<bool>(unknown);
    map['confidence'] = Variable<int>(confidence);
    return map;
  }

  ActivitySamplesCompanion toCompanion(bool nullToAbsent) {
    return ActivitySamplesCompanion(
      tsUtc: Value(tsUtc),
      stationary: Value(stationary),
      walking: Value(walking),
      running: Value(running),
      cycling: Value(cycling),
      automotive: Value(automotive),
      unknown: Value(unknown),
      confidence: Value(confidence),
    );
  }

  factory ActivitySample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivitySample(
      tsUtc: serializer.fromJson<int>(json['tsUtc']),
      stationary: serializer.fromJson<bool>(json['stationary']),
      walking: serializer.fromJson<bool>(json['walking']),
      running: serializer.fromJson<bool>(json['running']),
      cycling: serializer.fromJson<bool>(json['cycling']),
      automotive: serializer.fromJson<bool>(json['automotive']),
      unknown: serializer.fromJson<bool>(json['unknown']),
      confidence: serializer.fromJson<int>(json['confidence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tsUtc': serializer.toJson<int>(tsUtc),
      'stationary': serializer.toJson<bool>(stationary),
      'walking': serializer.toJson<bool>(walking),
      'running': serializer.toJson<bool>(running),
      'cycling': serializer.toJson<bool>(cycling),
      'automotive': serializer.toJson<bool>(automotive),
      'unknown': serializer.toJson<bool>(unknown),
      'confidence': serializer.toJson<int>(confidence),
    };
  }

  ActivitySample copyWith({
    int? tsUtc,
    bool? stationary,
    bool? walking,
    bool? running,
    bool? cycling,
    bool? automotive,
    bool? unknown,
    int? confidence,
  }) => ActivitySample(
    tsUtc: tsUtc ?? this.tsUtc,
    stationary: stationary ?? this.stationary,
    walking: walking ?? this.walking,
    running: running ?? this.running,
    cycling: cycling ?? this.cycling,
    automotive: automotive ?? this.automotive,
    unknown: unknown ?? this.unknown,
    confidence: confidence ?? this.confidence,
  );
  ActivitySample copyWithCompanion(ActivitySamplesCompanion data) {
    return ActivitySample(
      tsUtc: data.tsUtc.present ? data.tsUtc.value : this.tsUtc,
      stationary: data.stationary.present
          ? data.stationary.value
          : this.stationary,
      walking: data.walking.present ? data.walking.value : this.walking,
      running: data.running.present ? data.running.value : this.running,
      cycling: data.cycling.present ? data.cycling.value : this.cycling,
      automotive: data.automotive.present
          ? data.automotive.value
          : this.automotive,
      unknown: data.unknown.present ? data.unknown.value : this.unknown,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivitySample(')
          ..write('tsUtc: $tsUtc, ')
          ..write('stationary: $stationary, ')
          ..write('walking: $walking, ')
          ..write('running: $running, ')
          ..write('cycling: $cycling, ')
          ..write('automotive: $automotive, ')
          ..write('unknown: $unknown, ')
          ..write('confidence: $confidence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tsUtc,
    stationary,
    walking,
    running,
    cycling,
    automotive,
    unknown,
    confidence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivitySample &&
          other.tsUtc == this.tsUtc &&
          other.stationary == this.stationary &&
          other.walking == this.walking &&
          other.running == this.running &&
          other.cycling == this.cycling &&
          other.automotive == this.automotive &&
          other.unknown == this.unknown &&
          other.confidence == this.confidence);
}

class ActivitySamplesCompanion extends UpdateCompanion<ActivitySample> {
  final Value<int> tsUtc;
  final Value<bool> stationary;
  final Value<bool> walking;
  final Value<bool> running;
  final Value<bool> cycling;
  final Value<bool> automotive;
  final Value<bool> unknown;
  final Value<int> confidence;
  const ActivitySamplesCompanion({
    this.tsUtc = const Value.absent(),
    this.stationary = const Value.absent(),
    this.walking = const Value.absent(),
    this.running = const Value.absent(),
    this.cycling = const Value.absent(),
    this.automotive = const Value.absent(),
    this.unknown = const Value.absent(),
    this.confidence = const Value.absent(),
  });
  ActivitySamplesCompanion.insert({
    this.tsUtc = const Value.absent(),
    required bool stationary,
    required bool walking,
    required bool running,
    required bool cycling,
    required bool automotive,
    required bool unknown,
    required int confidence,
  }) : stationary = Value(stationary),
       walking = Value(walking),
       running = Value(running),
       cycling = Value(cycling),
       automotive = Value(automotive),
       unknown = Value(unknown),
       confidence = Value(confidence);
  static Insertable<ActivitySample> custom({
    Expression<int>? tsUtc,
    Expression<bool>? stationary,
    Expression<bool>? walking,
    Expression<bool>? running,
    Expression<bool>? cycling,
    Expression<bool>? automotive,
    Expression<bool>? unknown,
    Expression<int>? confidence,
  }) {
    return RawValuesInsertable({
      if (tsUtc != null) 'ts_utc': tsUtc,
      if (stationary != null) 'stationary': stationary,
      if (walking != null) 'walking': walking,
      if (running != null) 'running': running,
      if (cycling != null) 'cycling': cycling,
      if (automotive != null) 'automotive': automotive,
      if (unknown != null) 'unknown': unknown,
      if (confidence != null) 'confidence': confidence,
    });
  }

  ActivitySamplesCompanion copyWith({
    Value<int>? tsUtc,
    Value<bool>? stationary,
    Value<bool>? walking,
    Value<bool>? running,
    Value<bool>? cycling,
    Value<bool>? automotive,
    Value<bool>? unknown,
    Value<int>? confidence,
  }) {
    return ActivitySamplesCompanion(
      tsUtc: tsUtc ?? this.tsUtc,
      stationary: stationary ?? this.stationary,
      walking: walking ?? this.walking,
      running: running ?? this.running,
      cycling: cycling ?? this.cycling,
      automotive: automotive ?? this.automotive,
      unknown: unknown ?? this.unknown,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tsUtc.present) {
      map['ts_utc'] = Variable<int>(tsUtc.value);
    }
    if (stationary.present) {
      map['stationary'] = Variable<bool>(stationary.value);
    }
    if (walking.present) {
      map['walking'] = Variable<bool>(walking.value);
    }
    if (running.present) {
      map['running'] = Variable<bool>(running.value);
    }
    if (cycling.present) {
      map['cycling'] = Variable<bool>(cycling.value);
    }
    if (automotive.present) {
      map['automotive'] = Variable<bool>(automotive.value);
    }
    if (unknown.present) {
      map['unknown'] = Variable<bool>(unknown.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<int>(confidence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitySamplesCompanion(')
          ..write('tsUtc: $tsUtc, ')
          ..write('stationary: $stationary, ')
          ..write('walking: $walking, ')
          ..write('running: $running, ')
          ..write('cycling: $cycling, ')
          ..write('automotive: $automotive, ')
          ..write('unknown: $unknown, ')
          ..write('confidence: $confidence')
          ..write(')'))
        .toString();
  }
}

class $BikesTable extends Bikes with TableInfo<$BikesTable, Bike> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BikesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bikeIdMeta = const VerificationMeta('bikeId');
  @override
  late final GeneratedColumn<String> bikeId = GeneratedColumn<String>(
    'bike_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nfcPayloadMeta = const VerificationMeta(
    'nfcPayload',
  );
  @override
  late final GeneratedColumn<String> nfcPayload = GeneratedColumn<String>(
    'nfc_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [bikeId, name, nfcPayload, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bikes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bike> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bike_id')) {
      context.handle(
        _bikeIdMeta,
        bikeId.isAcceptableOrUnknown(data['bike_id']!, _bikeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bikeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('nfc_payload')) {
      context.handle(
        _nfcPayloadMeta,
        nfcPayload.isAcceptableOrUnknown(data['nfc_payload']!, _nfcPayloadMeta),
      );
    } else if (isInserting) {
      context.missing(_nfcPayloadMeta);
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
  Set<GeneratedColumn> get $primaryKey => {bikeId};
  @override
  Bike map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bike(
      bikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bike_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nfcPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nfc_payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BikesTable createAlias(String alias) {
    return $BikesTable(attachedDatabase, alias);
  }
}

class Bike extends DataClass implements Insertable<Bike> {
  final String bikeId;
  final String name;
  final String nfcPayload;
  final int createdAt;
  const Bike({
    required this.bikeId,
    required this.name,
    required this.nfcPayload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bike_id'] = Variable<String>(bikeId);
    map['name'] = Variable<String>(name);
    map['nfc_payload'] = Variable<String>(nfcPayload);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  BikesCompanion toCompanion(bool nullToAbsent) {
    return BikesCompanion(
      bikeId: Value(bikeId),
      name: Value(name),
      nfcPayload: Value(nfcPayload),
      createdAt: Value(createdAt),
    );
  }

  factory Bike.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bike(
      bikeId: serializer.fromJson<String>(json['bikeId']),
      name: serializer.fromJson<String>(json['name']),
      nfcPayload: serializer.fromJson<String>(json['nfcPayload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bikeId': serializer.toJson<String>(bikeId),
      'name': serializer.toJson<String>(name),
      'nfcPayload': serializer.toJson<String>(nfcPayload),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Bike copyWith({
    String? bikeId,
    String? name,
    String? nfcPayload,
    int? createdAt,
  }) => Bike(
    bikeId: bikeId ?? this.bikeId,
    name: name ?? this.name,
    nfcPayload: nfcPayload ?? this.nfcPayload,
    createdAt: createdAt ?? this.createdAt,
  );
  Bike copyWithCompanion(BikesCompanion data) {
    return Bike(
      bikeId: data.bikeId.present ? data.bikeId.value : this.bikeId,
      name: data.name.present ? data.name.value : this.name,
      nfcPayload: data.nfcPayload.present
          ? data.nfcPayload.value
          : this.nfcPayload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bike(')
          ..write('bikeId: $bikeId, ')
          ..write('name: $name, ')
          ..write('nfcPayload: $nfcPayload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bikeId, name, nfcPayload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bike &&
          other.bikeId == this.bikeId &&
          other.name == this.name &&
          other.nfcPayload == this.nfcPayload &&
          other.createdAt == this.createdAt);
}

class BikesCompanion extends UpdateCompanion<Bike> {
  final Value<String> bikeId;
  final Value<String> name;
  final Value<String> nfcPayload;
  final Value<int> createdAt;
  final Value<int> rowid;
  const BikesCompanion({
    this.bikeId = const Value.absent(),
    this.name = const Value.absent(),
    this.nfcPayload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BikesCompanion.insert({
    required String bikeId,
    required String name,
    required String nfcPayload,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : bikeId = Value(bikeId),
       name = Value(name),
       nfcPayload = Value(nfcPayload),
       createdAt = Value(createdAt);
  static Insertable<Bike> custom({
    Expression<String>? bikeId,
    Expression<String>? name,
    Expression<String>? nfcPayload,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bikeId != null) 'bike_id': bikeId,
      if (name != null) 'name': name,
      if (nfcPayload != null) 'nfc_payload': nfcPayload,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BikesCompanion copyWith({
    Value<String>? bikeId,
    Value<String>? name,
    Value<String>? nfcPayload,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return BikesCompanion(
      bikeId: bikeId ?? this.bikeId,
      name: name ?? this.name,
      nfcPayload: nfcPayload ?? this.nfcPayload,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bikeId.present) {
      map['bike_id'] = Variable<String>(bikeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nfcPayload.present) {
      map['nfc_payload'] = Variable<String>(nfcPayload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BikesCompanion(')
          ..write('bikeId: $bikeId, ')
          ..write('name: $name, ')
          ..write('nfcPayload: $nfcPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConfigTable extends Config with TableInfo<$ConfigTable, ConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'config';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $ConfigTable createAlias(String alias) {
    return $ConfigTable(attachedDatabase, alias);
  }
}

class ConfigData extends DataClass implements Insertable<ConfigData> {
  final String key;
  final String value;
  const ConfigData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ConfigCompanion toCompanion(bool nullToAbsent) {
    return ConfigCompanion(key: Value(key), value: Value(value));
  }

  factory ConfigData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  ConfigData copyWith({String? key, String? value}) =>
      ConfigData(key: key ?? this.key, value: value ?? this.value);
  ConfigData copyWithCompanion(ConfigCompanion data) {
    return ConfigData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigData &&
          other.key == this.key &&
          other.value == this.value);
}

class ConfigCompanion extends UpdateCompanion<ConfigData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ConfigCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfigCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<ConfigData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfigCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ConfigCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $SegmentsTable segments = $SegmentsTable(this);
  late final $GpsPointsTable gpsPoints = $GpsPointsTable(this);
  late final $ActivitySamplesTable activitySamples = $ActivitySamplesTable(
    this,
  );
  late final $BikesTable bikes = $BikesTable(this);
  late final $ConfigTable config = $ConfigTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    events,
    trips,
    segments,
    gpsPoints,
    activitySamples,
    bikes,
    config,
  ];
}

typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  required int tsUtc,
  required EventSource source,
  required String type,
  required String payload,
  Value<String?> tripId,
  Value<bool> processed,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  Value<int> tsUtc,
  Value<EventSource> source,
  Value<String> type,
  Value<String> payload,
  Value<String?> tripId,
  Value<bool> processed,
});

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
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

  ColumnFilters<int> get tsUtc => $composableBuilder(
    column: $table.tsUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EventSource, EventSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get processed => $composableBuilder(
    column: $table.processed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
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

  ColumnOrderings<int> get tsUtc => $composableBuilder(
    column: $table.tsUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get processed => $composableBuilder(
    column: $table.processed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tsUtc =>
      $composableBuilder(column: $table.tsUtc, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EventSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<bool> get processed =>
      $composableBuilder(column: $table.processed, builder: (column) => column);
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
          Event,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tsUtc = const Value.absent(),
                Value<EventSource> source = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<bool> processed = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                tsUtc: tsUtc,
                source: source,
                type: type,
                payload: payload,
                tripId: tripId,
                processed: processed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tsUtc,
                required EventSource source,
                required String type,
                required String payload,
                Value<String?> tripId = const Value.absent(),
                Value<bool> processed = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                tsUtc: tsUtc,
                source: source,
                type: type,
                payload: payload,
                tripId: tripId,
                processed: processed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
      Event,
      PrefetchHooks Function()
    >;
typedef $$TripsTableCreateCompanionBuilder = TripsCompanion Function({
  required String tripId,
  required TripStatus status,
  required int startTimeUtc,
  Value<int?> endTimeUtc,
  Value<int?> lastMovementUtc,
  Value<String?> bikeId,
  required bool nfcConfirmed,
  Value<double?> totalDistanceM,
  required DistanceStatus distanceStatus,
  required int movingDurationS,
  required int pausedDurationS,
  required int suspendedDurationS,
  Value<String?> reviewReason,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$TripsTableUpdateCompanionBuilder = TripsCompanion Function({
  Value<String> tripId,
  Value<TripStatus> status,
  Value<int> startTimeUtc,
  Value<int?> endTimeUtc,
  Value<int?> lastMovementUtc,
  Value<String?> bikeId,
  Value<bool> nfcConfirmed,
  Value<double?> totalDistanceM,
  Value<DistanceStatus> distanceStatus,
  Value<int> movingDurationS,
  Value<int> pausedDurationS,
  Value<int> suspendedDurationS,
  Value<String?> reviewReason,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$TripsTableReferences
    extends BaseReferences<_$AppDatabase, $TripsTable, Trip> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SegmentsTable, List<Segment>> _segmentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.segments,
    aliasName: $_aliasNameGenerator(db.trips.tripId, db.segments.tripId),
  );

  $$SegmentsTableProcessedTableManager get segmentsRefs {
    final manager = $$SegmentsTableTableManager($_db, $_db.segments).filter(
      (f) => f.tripId.tripId.sqlEquals($_itemColumn<String>('trip_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_segmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TripStatus, TripStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get startTimeUtc => $composableBuilder(
    column: $table.startTimeUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTimeUtc => $composableBuilder(
    column: $table.endTimeUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMovementUtc => $composableBuilder(
    column: $table.lastMovementUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bikeId => $composableBuilder(
    column: $table.bikeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get nfcConfirmed => $composableBuilder(
    column: $table.nfcConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistanceM => $composableBuilder(
    column: $table.totalDistanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DistanceStatus, DistanceStatus, String>
  get distanceStatus => $composableBuilder(
    column: $table.distanceStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get movingDurationS => $composableBuilder(
    column: $table.movingDurationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedDurationS => $composableBuilder(
    column: $table.pausedDurationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get suspendedDurationS => $composableBuilder(
    column: $table.suspendedDurationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewReason => $composableBuilder(
    column: $table.reviewReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> segmentsRefs(
    Expression<bool> Function($$SegmentsTableFilterComposer f) f,
  ) {
    final $$SegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.segments,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SegmentsTableFilterComposer(
            $db: $db,
            $table: $db.segments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTimeUtc => $composableBuilder(
    column: $table.startTimeUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTimeUtc => $composableBuilder(
    column: $table.endTimeUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMovementUtc => $composableBuilder(
    column: $table.lastMovementUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bikeId => $composableBuilder(
    column: $table.bikeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get nfcConfirmed => $composableBuilder(
    column: $table.nfcConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistanceM => $composableBuilder(
    column: $table.totalDistanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distanceStatus => $composableBuilder(
    column: $table.distanceStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingDurationS => $composableBuilder(
    column: $table.movingDurationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedDurationS => $composableBuilder(
    column: $table.pausedDurationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get suspendedDurationS => $composableBuilder(
    column: $table.suspendedDurationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewReason => $composableBuilder(
    column: $table.reviewReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TripStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startTimeUtc => $composableBuilder(
    column: $table.startTimeUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endTimeUtc => $composableBuilder(
    column: $table.endTimeUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMovementUtc => $composableBuilder(
    column: $table.lastMovementUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bikeId =>
      $composableBuilder(column: $table.bikeId, builder: (column) => column);

  GeneratedColumn<bool> get nfcConfirmed => $composableBuilder(
    column: $table.nfcConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDistanceM => $composableBuilder(
    column: $table.totalDistanceM,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DistanceStatus, String> get distanceStatus =>
      $composableBuilder(
        column: $table.distanceStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get movingDurationS => $composableBuilder(
    column: $table.movingDurationS,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pausedDurationS => $composableBuilder(
    column: $table.pausedDurationS,
    builder: (column) => column,
  );

  GeneratedColumn<int> get suspendedDurationS => $composableBuilder(
    column: $table.suspendedDurationS,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewReason => $composableBuilder(
    column: $table.reviewReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> segmentsRefs<T extends Object>(
    Expression<T> Function($$SegmentsTableAnnotationComposer a) f,
  ) {
    final $$SegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.segments,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.segments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          Trip,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (Trip, $$TripsTableReferences),
          Trip,
          PrefetchHooks Function({bool segmentsRefs})
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tripId = const Value.absent(),
                Value<TripStatus> status = const Value.absent(),
                Value<int> startTimeUtc = const Value.absent(),
                Value<int?> endTimeUtc = const Value.absent(),
                Value<int?> lastMovementUtc = const Value.absent(),
                Value<String?> bikeId = const Value.absent(),
                Value<bool> nfcConfirmed = const Value.absent(),
                Value<double?> totalDistanceM = const Value.absent(),
                Value<DistanceStatus> distanceStatus = const Value.absent(),
                Value<int> movingDurationS = const Value.absent(),
                Value<int> pausedDurationS = const Value.absent(),
                Value<int> suspendedDurationS = const Value.absent(),
                Value<String?> reviewReason = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion(
                tripId: tripId,
                status: status,
                startTimeUtc: startTimeUtc,
                endTimeUtc: endTimeUtc,
                lastMovementUtc: lastMovementUtc,
                bikeId: bikeId,
                nfcConfirmed: nfcConfirmed,
                totalDistanceM: totalDistanceM,
                distanceStatus: distanceStatus,
                movingDurationS: movingDurationS,
                pausedDurationS: pausedDurationS,
                suspendedDurationS: suspendedDurationS,
                reviewReason: reviewReason,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tripId,
                required TripStatus status,
                required int startTimeUtc,
                Value<int?> endTimeUtc = const Value.absent(),
                Value<int?> lastMovementUtc = const Value.absent(),
                Value<String?> bikeId = const Value.absent(),
                required bool nfcConfirmed,
                Value<double?> totalDistanceM = const Value.absent(),
                required DistanceStatus distanceStatus,
                required int movingDurationS,
                required int pausedDurationS,
                required int suspendedDurationS,
                Value<String?> reviewReason = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion.insert(
                tripId: tripId,
                status: status,
                startTimeUtc: startTimeUtc,
                endTimeUtc: endTimeUtc,
                lastMovementUtc: lastMovementUtc,
                bikeId: bikeId,
                nfcConfirmed: nfcConfirmed,
                totalDistanceM: totalDistanceM,
                distanceStatus: distanceStatus,
                movingDurationS: movingDurationS,
                pausedDurationS: pausedDurationS,
                suspendedDurationS: suspendedDurationS,
                reviewReason: reviewReason,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TripsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({segmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (segmentsRefs) db.segments],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (segmentsRefs)
                    await $_getPrefetchedData<Trip, $TripsTable, Segment>(
                      currentTable: table,
                      referencedTable: $$TripsTableReferences
                          ._segmentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TripsTableReferences(db, table, p0).segmentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tripId == item.tripId),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      Trip,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (Trip, $$TripsTableReferences),
      Trip,
      PrefetchHooks Function({bool segmentsRefs})
    >;
typedef $$SegmentsTableCreateCompanionBuilder = SegmentsCompanion Function({
  required String segmentId,
  required String tripId,
  required SegmentType type,
  required int startUtc,
  required int endUtc,
  Value<double?> distanceM,
  required DistanceStatus distanceStatus,
  required int movingS,
  required double confidence,
  required String classificationSource,
  required bool userCorrected,
  required bool needsReview,
  Value<String?> healthWorkoutUuid,
  Value<int?> healthSyncedAt,
  Value<int> rowid,
});
typedef $$SegmentsTableUpdateCompanionBuilder = SegmentsCompanion Function({
  Value<String> segmentId,
  Value<String> tripId,
  Value<SegmentType> type,
  Value<int> startUtc,
  Value<int> endUtc,
  Value<double?> distanceM,
  Value<DistanceStatus> distanceStatus,
  Value<int> movingS,
  Value<double> confidence,
  Value<String> classificationSource,
  Value<bool> userCorrected,
  Value<bool> needsReview,
  Value<String?> healthWorkoutUuid,
  Value<int?> healthSyncedAt,
  Value<int> rowid,
});

final class $$SegmentsTableReferences
    extends BaseReferences<_$AppDatabase, $SegmentsTable, Segment> {
  $$SegmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips.createAlias(
    $_aliasNameGenerator(db.segments.tripId, db.trips.tripId),
  );

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.tripId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GpsPointsTable, List<GpsPoint>>
  _gpsPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gpsPoints,
    aliasName: $_aliasNameGenerator(
      db.segments.segmentId,
      db.gpsPoints.segmentId,
    ),
  );

  $$GpsPointsTableProcessedTableManager get gpsPointsRefs {
    final manager = $$GpsPointsTableTableManager($_db, $_db.gpsPoints).filter(
      (f) =>
          f.segmentId.segmentId.sqlEquals($_itemColumn<String>('segment_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_gpsPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SegmentType, SegmentType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DistanceStatus, DistanceStatus, String>
  get distanceStatus => $composableBuilder(
    column: $table.distanceStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get movingS => $composableBuilder(
    column: $table.movingS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classificationSource => $composableBuilder(
    column: $table.classificationSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userCorrected => $composableBuilder(
    column: $table.userCorrected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthWorkoutUuid => $composableBuilder(
    column: $table.healthWorkoutUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get healthSyncedAt => $composableBuilder(
    column: $table.healthSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> gpsPointsRefs(
    Expression<bool> Function($$GpsPointsTableFilterComposer f) f,
  ) {
    final $$GpsPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.segmentId,
      referencedTable: $db.gpsPoints,
      getReferencedColumn: (t) => t.segmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GpsPointsTableFilterComposer(
            $db: $db,
            $table: $db.gpsPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distanceStatus => $composableBuilder(
    column: $table.distanceStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingS => $composableBuilder(
    column: $table.movingS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classificationSource => $composableBuilder(
    column: $table.classificationSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userCorrected => $composableBuilder(
    column: $table.userCorrected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthWorkoutUuid => $composableBuilder(
    column: $table.healthWorkoutUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get healthSyncedAt => $composableBuilder(
    column: $table.healthSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get segmentId =>
      $composableBuilder(column: $table.segmentId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SegmentType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<int> get endUtc =>
      $composableBuilder(column: $table.endUtc, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DistanceStatus, String> get distanceStatus =>
      $composableBuilder(
        column: $table.distanceStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get movingS =>
      $composableBuilder(column: $table.movingS, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get classificationSource => $composableBuilder(
    column: $table.classificationSource,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get userCorrected => $composableBuilder(
    column: $table.userCorrected,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get healthWorkoutUuid => $composableBuilder(
    column: $table.healthWorkoutUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get healthSyncedAt => $composableBuilder(
    column: $table.healthSyncedAt,
    builder: (column) => column,
  );

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> gpsPointsRefs<T extends Object>(
    Expression<T> Function($$GpsPointsTableAnnotationComposer a) f,
  ) {
    final $$GpsPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.segmentId,
      referencedTable: $db.gpsPoints,
      getReferencedColumn: (t) => t.segmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GpsPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.gpsPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SegmentsTable,
          Segment,
          $$SegmentsTableFilterComposer,
          $$SegmentsTableOrderingComposer,
          $$SegmentsTableAnnotationComposer,
          $$SegmentsTableCreateCompanionBuilder,
          $$SegmentsTableUpdateCompanionBuilder,
          (Segment, $$SegmentsTableReferences),
          Segment,
          PrefetchHooks Function({bool tripId, bool gpsPointsRefs})
        > {
  $$SegmentsTableTableManager(_$AppDatabase db, $SegmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> segmentId = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<SegmentType> type = const Value.absent(),
                Value<int> startUtc = const Value.absent(),
                Value<int> endUtc = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<DistanceStatus> distanceStatus = const Value.absent(),
                Value<int> movingS = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String> classificationSource = const Value.absent(),
                Value<bool> userCorrected = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<String?> healthWorkoutUuid = const Value.absent(),
                Value<int?> healthSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SegmentsCompanion(
                segmentId: segmentId,
                tripId: tripId,
                type: type,
                startUtc: startUtc,
                endUtc: endUtc,
                distanceM: distanceM,
                distanceStatus: distanceStatus,
                movingS: movingS,
                confidence: confidence,
                classificationSource: classificationSource,
                userCorrected: userCorrected,
                needsReview: needsReview,
                healthWorkoutUuid: healthWorkoutUuid,
                healthSyncedAt: healthSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String segmentId,
                required String tripId,
                required SegmentType type,
                required int startUtc,
                required int endUtc,
                Value<double?> distanceM = const Value.absent(),
                required DistanceStatus distanceStatus,
                required int movingS,
                required double confidence,
                required String classificationSource,
                required bool userCorrected,
                required bool needsReview,
                Value<String?> healthWorkoutUuid = const Value.absent(),
                Value<int?> healthSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SegmentsCompanion.insert(
                segmentId: segmentId,
                tripId: tripId,
                type: type,
                startUtc: startUtc,
                endUtc: endUtc,
                distanceM: distanceM,
                distanceStatus: distanceStatus,
                movingS: movingS,
                confidence: confidence,
                classificationSource: classificationSource,
                userCorrected: userCorrected,
                needsReview: needsReview,
                healthWorkoutUuid: healthWorkoutUuid,
                healthSyncedAt: healthSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SegmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false, gpsPointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (gpsPointsRefs) db.gpsPoints],
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
                    if (tripId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tripId,
                        referencedTable: $$SegmentsTableReferences._tripIdTable(
                          db,
                        ),
                        referencedColumn: $$SegmentsTableReferences
                            ._tripIdTable(db)
                            .tripId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (gpsPointsRefs)
                    await $_getPrefetchedData<
                      Segment,
                      $SegmentsTable,
                      GpsPoint
                    >(
                      currentTable: table,
                      referencedTable: $$SegmentsTableReferences
                          ._gpsPointsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SegmentsTableReferences(
                        db,
                        table,
                        p0,
                      ).gpsPointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.segmentId == item.segmentId,
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

typedef $$SegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SegmentsTable,
      Segment,
      $$SegmentsTableFilterComposer,
      $$SegmentsTableOrderingComposer,
      $$SegmentsTableAnnotationComposer,
      $$SegmentsTableCreateCompanionBuilder,
      $$SegmentsTableUpdateCompanionBuilder,
      (Segment, $$SegmentsTableReferences),
      Segment,
      PrefetchHooks Function({bool tripId, bool gpsPointsRefs})
    >;
typedef $$GpsPointsTableCreateCompanionBuilder = GpsPointsCompanion Function({
  Value<int> id,
  required String segmentId,
  required int tsUtc,
  required double lat,
  required double lon,
  required double altitudeM,
  required double hAccuracyM,
  required double vAccuracyM,
  required double speedMps,
  required double speedAccuracyMps,
  required double courseDeg,
  required bool accepted,
  Value<String?> rejectReason,
});
typedef $$GpsPointsTableUpdateCompanionBuilder = GpsPointsCompanion Function({
  Value<int> id,
  Value<String> segmentId,
  Value<int> tsUtc,
  Value<double> lat,
  Value<double> lon,
  Value<double> altitudeM,
  Value<double> hAccuracyM,
  Value<double> vAccuracyM,
  Value<double> speedMps,
  Value<double> speedAccuracyMps,
  Value<double> courseDeg,
  Value<bool> accepted,
  Value<String?> rejectReason,
});

final class $$GpsPointsTableReferences
    extends BaseReferences<_$AppDatabase, $GpsPointsTable, GpsPoint> {
  $$GpsPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SegmentsTable _segmentIdTable(_$AppDatabase db) =>
      db.segments.createAlias(
        $_aliasNameGenerator(db.gpsPoints.segmentId, db.segments.segmentId),
      );

  $$SegmentsTableProcessedTableManager get segmentId {
    final $_column = $_itemColumn<String>('segment_id')!;

    final manager = $$SegmentsTableTableManager(
      $_db,
      $_db.segments,
    ).filter((f) => f.segmentId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_segmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GpsPointsTableFilterComposer
    extends Composer<_$AppDatabase, $GpsPointsTable> {
  $$GpsPointsTableFilterComposer({
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

  ColumnFilters<int> get tsUtc => $composableBuilder(
    column: $table.tsUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hAccuracyM => $composableBuilder(
    column: $table.hAccuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vAccuracyM => $composableBuilder(
    column: $table.vAccuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedAccuracyMps => $composableBuilder(
    column: $table.speedAccuracyMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get courseDeg => $composableBuilder(
    column: $table.courseDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get accepted => $composableBuilder(
    column: $table.accepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectReason => $composableBuilder(
    column: $table.rejectReason,
    builder: (column) => ColumnFilters(column),
  );

  $$SegmentsTableFilterComposer get segmentId {
    final $$SegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.segmentId,
      referencedTable: $db.segments,
      getReferencedColumn: (t) => t.segmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SegmentsTableFilterComposer(
            $db: $db,
            $table: $db.segments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GpsPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $GpsPointsTable> {
  $$GpsPointsTableOrderingComposer({
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

  ColumnOrderings<int> get tsUtc => $composableBuilder(
    column: $table.tsUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hAccuracyM => $composableBuilder(
    column: $table.hAccuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vAccuracyM => $composableBuilder(
    column: $table.vAccuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedAccuracyMps => $composableBuilder(
    column: $table.speedAccuracyMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get courseDeg => $composableBuilder(
    column: $table.courseDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get accepted => $composableBuilder(
    column: $table.accepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectReason => $composableBuilder(
    column: $table.rejectReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$SegmentsTableOrderingComposer get segmentId {
    final $$SegmentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.segmentId,
      referencedTable: $db.segments,
      getReferencedColumn: (t) => t.segmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SegmentsTableOrderingComposer(
            $db: $db,
            $table: $db.segments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GpsPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GpsPointsTable> {
  $$GpsPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tsUtc =>
      $composableBuilder(column: $table.tsUtc, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get altitudeM =>
      $composableBuilder(column: $table.altitudeM, builder: (column) => column);

  GeneratedColumn<double> get hAccuracyM => $composableBuilder(
    column: $table.hAccuracyM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vAccuracyM => $composableBuilder(
    column: $table.vAccuracyM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<double> get speedAccuracyMps => $composableBuilder(
    column: $table.speedAccuracyMps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get courseDeg =>
      $composableBuilder(column: $table.courseDeg, builder: (column) => column);

  GeneratedColumn<bool> get accepted =>
      $composableBuilder(column: $table.accepted, builder: (column) => column);

  GeneratedColumn<String> get rejectReason => $composableBuilder(
    column: $table.rejectReason,
    builder: (column) => column,
  );

  $$SegmentsTableAnnotationComposer get segmentId {
    final $$SegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.segmentId,
      referencedTable: $db.segments,
      getReferencedColumn: (t) => t.segmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.segments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GpsPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GpsPointsTable,
          GpsPoint,
          $$GpsPointsTableFilterComposer,
          $$GpsPointsTableOrderingComposer,
          $$GpsPointsTableAnnotationComposer,
          $$GpsPointsTableCreateCompanionBuilder,
          $$GpsPointsTableUpdateCompanionBuilder,
          (GpsPoint, $$GpsPointsTableReferences),
          GpsPoint,
          PrefetchHooks Function({bool segmentId})
        > {
  $$GpsPointsTableTableManager(_$AppDatabase db, $GpsPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GpsPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GpsPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GpsPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> segmentId = const Value.absent(),
                Value<int> tsUtc = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double> altitudeM = const Value.absent(),
                Value<double> hAccuracyM = const Value.absent(),
                Value<double> vAccuracyM = const Value.absent(),
                Value<double> speedMps = const Value.absent(),
                Value<double> speedAccuracyMps = const Value.absent(),
                Value<double> courseDeg = const Value.absent(),
                Value<bool> accepted = const Value.absent(),
                Value<String?> rejectReason = const Value.absent(),
              }) => GpsPointsCompanion(
                id: id,
                segmentId: segmentId,
                tsUtc: tsUtc,
                lat: lat,
                lon: lon,
                altitudeM: altitudeM,
                hAccuracyM: hAccuracyM,
                vAccuracyM: vAccuracyM,
                speedMps: speedMps,
                speedAccuracyMps: speedAccuracyMps,
                courseDeg: courseDeg,
                accepted: accepted,
                rejectReason: rejectReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String segmentId,
                required int tsUtc,
                required double lat,
                required double lon,
                required double altitudeM,
                required double hAccuracyM,
                required double vAccuracyM,
                required double speedMps,
                required double speedAccuracyMps,
                required double courseDeg,
                required bool accepted,
                Value<String?> rejectReason = const Value.absent(),
              }) => GpsPointsCompanion.insert(
                id: id,
                segmentId: segmentId,
                tsUtc: tsUtc,
                lat: lat,
                lon: lon,
                altitudeM: altitudeM,
                hAccuracyM: hAccuracyM,
                vAccuracyM: vAccuracyM,
                speedMps: speedMps,
                speedAccuracyMps: speedAccuracyMps,
                courseDeg: courseDeg,
                accepted: accepted,
                rejectReason: rejectReason,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GpsPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({segmentId = false}) {
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
                    if (segmentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.segmentId,
                        referencedTable: $$GpsPointsTableReferences
                            ._segmentIdTable(db),
                        referencedColumn: $$GpsPointsTableReferences
                            ._segmentIdTable(db)
                            .segmentId,
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

typedef $$GpsPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GpsPointsTable,
      GpsPoint,
      $$GpsPointsTableFilterComposer,
      $$GpsPointsTableOrderingComposer,
      $$GpsPointsTableAnnotationComposer,
      $$GpsPointsTableCreateCompanionBuilder,
      $$GpsPointsTableUpdateCompanionBuilder,
      (GpsPoint, $$GpsPointsTableReferences),
      GpsPoint,
      PrefetchHooks Function({bool segmentId})
    >;
typedef $$ActivitySamplesTableCreateCompanionBuilder =
    ActivitySamplesCompanion Function({
      Value<int> tsUtc,
      required bool stationary,
      required bool walking,
      required bool running,
      required bool cycling,
      required bool automotive,
      required bool unknown,
      required int confidence,
    });
typedef $$ActivitySamplesTableUpdateCompanionBuilder =
    ActivitySamplesCompanion Function({
      Value<int> tsUtc,
      Value<bool> stationary,
      Value<bool> walking,
      Value<bool> running,
      Value<bool> cycling,
      Value<bool> automotive,
      Value<bool> unknown,
      Value<int> confidence,
    });

class $$ActivitySamplesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitySamplesTable> {
  $$ActivitySamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tsUtc => $composableBuilder(
    column: $table.tsUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get stationary => $composableBuilder(
    column: $table.stationary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get walking => $composableBuilder(
    column: $table.walking,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get running => $composableBuilder(
    column: $table.running,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cycling => $composableBuilder(
    column: $table.cycling,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get automotive => $composableBuilder(
    column: $table.automotive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unknown => $composableBuilder(
    column: $table.unknown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivitySamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitySamplesTable> {
  $$ActivitySamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tsUtc => $composableBuilder(
    column: $table.tsUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get stationary => $composableBuilder(
    column: $table.stationary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get walking => $composableBuilder(
    column: $table.walking,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get running => $composableBuilder(
    column: $table.running,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cycling => $composableBuilder(
    column: $table.cycling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get automotive => $composableBuilder(
    column: $table.automotive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unknown => $composableBuilder(
    column: $table.unknown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitySamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitySamplesTable> {
  $$ActivitySamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tsUtc =>
      $composableBuilder(column: $table.tsUtc, builder: (column) => column);

  GeneratedColumn<bool> get stationary => $composableBuilder(
    column: $table.stationary,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get walking =>
      $composableBuilder(column: $table.walking, builder: (column) => column);

  GeneratedColumn<bool> get running =>
      $composableBuilder(column: $table.running, builder: (column) => column);

  GeneratedColumn<bool> get cycling =>
      $composableBuilder(column: $table.cycling, builder: (column) => column);

  GeneratedColumn<bool> get automotive => $composableBuilder(
    column: $table.automotive,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get unknown =>
      $composableBuilder(column: $table.unknown, builder: (column) => column);

  GeneratedColumn<int> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );
}

class $$ActivitySamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivitySamplesTable,
          ActivitySample,
          $$ActivitySamplesTableFilterComposer,
          $$ActivitySamplesTableOrderingComposer,
          $$ActivitySamplesTableAnnotationComposer,
          $$ActivitySamplesTableCreateCompanionBuilder,
          $$ActivitySamplesTableUpdateCompanionBuilder,
          (
            ActivitySample,
            BaseReferences<
              _$AppDatabase,
              $ActivitySamplesTable,
              ActivitySample
            >,
          ),
          ActivitySample,
          PrefetchHooks Function()
        > {
  $$ActivitySamplesTableTableManager(
    _$AppDatabase db,
    $ActivitySamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitySamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitySamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitySamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> tsUtc = const Value.absent(),
                Value<bool> stationary = const Value.absent(),
                Value<bool> walking = const Value.absent(),
                Value<bool> running = const Value.absent(),
                Value<bool> cycling = const Value.absent(),
                Value<bool> automotive = const Value.absent(),
                Value<bool> unknown = const Value.absent(),
                Value<int> confidence = const Value.absent(),
              }) => ActivitySamplesCompanion(
                tsUtc: tsUtc,
                stationary: stationary,
                walking: walking,
                running: running,
                cycling: cycling,
                automotive: automotive,
                unknown: unknown,
                confidence: confidence,
              ),
          createCompanionCallback:
              ({
                Value<int> tsUtc = const Value.absent(),
                required bool stationary,
                required bool walking,
                required bool running,
                required bool cycling,
                required bool automotive,
                required bool unknown,
                required int confidence,
              }) => ActivitySamplesCompanion.insert(
                tsUtc: tsUtc,
                stationary: stationary,
                walking: walking,
                running: running,
                cycling: cycling,
                automotive: automotive,
                unknown: unknown,
                confidence: confidence,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivitySamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivitySamplesTable,
      ActivitySample,
      $$ActivitySamplesTableFilterComposer,
      $$ActivitySamplesTableOrderingComposer,
      $$ActivitySamplesTableAnnotationComposer,
      $$ActivitySamplesTableCreateCompanionBuilder,
      $$ActivitySamplesTableUpdateCompanionBuilder,
      (
        ActivitySample,
        BaseReferences<_$AppDatabase, $ActivitySamplesTable, ActivitySample>,
      ),
      ActivitySample,
      PrefetchHooks Function()
    >;
typedef $$BikesTableCreateCompanionBuilder = BikesCompanion Function({
  required String bikeId,
  required String name,
  required String nfcPayload,
  required int createdAt,
  Value<int> rowid,
});
typedef $$BikesTableUpdateCompanionBuilder = BikesCompanion Function({
  Value<String> bikeId,
  Value<String> name,
  Value<String> nfcPayload,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$BikesTableFilterComposer extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bikeId => $composableBuilder(
    column: $table.bikeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nfcPayload => $composableBuilder(
    column: $table.nfcPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BikesTableOrderingComposer
    extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bikeId => $composableBuilder(
    column: $table.bikeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nfcPayload => $composableBuilder(
    column: $table.nfcPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BikesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bikeId =>
      $composableBuilder(column: $table.bikeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nfcPayload => $composableBuilder(
    column: $table.nfcPayload,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BikesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BikesTable,
          Bike,
          $$BikesTableFilterComposer,
          $$BikesTableOrderingComposer,
          $$BikesTableAnnotationComposer,
          $$BikesTableCreateCompanionBuilder,
          $$BikesTableUpdateCompanionBuilder,
          (Bike, BaseReferences<_$AppDatabase, $BikesTable, Bike>),
          Bike,
          PrefetchHooks Function()
        > {
  $$BikesTableTableManager(_$AppDatabase db, $BikesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BikesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BikesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BikesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bikeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nfcPayload = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BikesCompanion(
                bikeId: bikeId,
                name: name,
                nfcPayload: nfcPayload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bikeId,
                required String name,
                required String nfcPayload,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BikesCompanion.insert(
                bikeId: bikeId,
                name: name,
                nfcPayload: nfcPayload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BikesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BikesTable,
      Bike,
      $$BikesTableFilterComposer,
      $$BikesTableOrderingComposer,
      $$BikesTableAnnotationComposer,
      $$BikesTableCreateCompanionBuilder,
      $$BikesTableUpdateCompanionBuilder,
      (Bike, BaseReferences<_$AppDatabase, $BikesTable, Bike>),
      Bike,
      PrefetchHooks Function()
    >;
typedef $$ConfigTableCreateCompanionBuilder = ConfigCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$ConfigTableUpdateCompanionBuilder = ConfigCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$ConfigTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigTable> {
  $$ConfigTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigTable> {
  $$ConfigTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigTable> {
  $$ConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$ConfigTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigTable,
          ConfigData,
          $$ConfigTableFilterComposer,
          $$ConfigTableOrderingComposer,
          $$ConfigTableAnnotationComposer,
          $$ConfigTableCreateCompanionBuilder,
          $$ConfigTableUpdateCompanionBuilder,
          (ConfigData, BaseReferences<_$AppDatabase, $ConfigTable, ConfigData>),
          ConfigData,
          PrefetchHooks Function()
        > {
  $$ConfigTableTableManager(_$AppDatabase db, $ConfigTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ConfigCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => ConfigCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfigTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigTable,
      ConfigData,
      $$ConfigTableFilterComposer,
      $$ConfigTableOrderingComposer,
      $$ConfigTableAnnotationComposer,
      $$ConfigTableCreateCompanionBuilder,
      $$ConfigTableUpdateCompanionBuilder,
      (ConfigData, BaseReferences<_$AppDatabase, $ConfigTable, ConfigData>),
      ConfigData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$SegmentsTableTableManager get segments =>
      $$SegmentsTableTableManager(_db, _db.segments);
  $$GpsPointsTableTableManager get gpsPoints =>
      $$GpsPointsTableTableManager(_db, _db.gpsPoints);
  $$ActivitySamplesTableTableManager get activitySamples =>
      $$ActivitySamplesTableTableManager(_db, _db.activitySamples);
  $$BikesTableTableManager get bikes =>
      $$BikesTableTableManager(_db, _db.bikes);
  $$ConfigTableTableManager get config =>
      $$ConfigTableTableManager(_db, _db.config);
}
