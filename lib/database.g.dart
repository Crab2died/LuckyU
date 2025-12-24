// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SavedTicketsTable extends SavedTickets
    with TableInfo<$SavedTicketsTable, SavedTicketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedTicketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frontNumbersMeta = const VerificationMeta(
    'frontNumbers',
  );
  @override
  late final GeneratedColumn<String> frontNumbers = GeneratedColumn<String>(
    'front_numbers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backNumbersMeta = const VerificationMeta(
    'backNumbers',
  );
  @override
  late final GeneratedColumn<String> backNumbers = GeneratedColumn<String>(
    'back_numbers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetIssueMeta = const VerificationMeta(
    'targetIssue',
  );
  @override
  late final GeneratedColumn<String> targetIssue = GeneratedColumn<String>(
    'target_issue',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    frontNumbers,
    backNumbers,
    savedAt,
    note,
    targetIssue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_tickets';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedTicketRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('front_numbers')) {
      context.handle(
        _frontNumbersMeta,
        frontNumbers.isAcceptableOrUnknown(
          data['front_numbers']!,
          _frontNumbersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_frontNumbersMeta);
    }
    if (data.containsKey('back_numbers')) {
      context.handle(
        _backNumbersMeta,
        backNumbers.isAcceptableOrUnknown(
          data['back_numbers']!,
          _backNumbersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_backNumbersMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('target_issue')) {
      context.handle(
        _targetIssueMeta,
        targetIssue.isAcceptableOrUnknown(
          data['target_issue']!,
          _targetIssueMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedTicketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedTicketRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      frontNumbers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front_numbers'],
      )!,
      backNumbers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back_numbers'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      targetIssue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_issue'],
      ),
    );
  }

  @override
  $SavedTicketsTable createAlias(String alias) {
    return $SavedTicketsTable(attachedDatabase, alias);
  }
}

class SavedTicketRow extends DataClass implements Insertable<SavedTicketRow> {
  /// 唯一标识符
  final String id;

  /// 彩票类型: 'SSQ' 或 'DLT'
  final String type;

  /// 前区号码 (JSON数组格式存储)
  final String frontNumbers;

  /// 后区号码 (JSON数组格式存储)
  final String backNumbers;

  /// 保存时间
  final DateTime savedAt;

  /// 备注
  final String? note;

  /// 目标期号
  final String? targetIssue;
  const SavedTicketRow({
    required this.id,
    required this.type,
    required this.frontNumbers,
    required this.backNumbers,
    required this.savedAt,
    this.note,
    this.targetIssue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['front_numbers'] = Variable<String>(frontNumbers);
    map['back_numbers'] = Variable<String>(backNumbers);
    map['saved_at'] = Variable<DateTime>(savedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || targetIssue != null) {
      map['target_issue'] = Variable<String>(targetIssue);
    }
    return map;
  }

  SavedTicketsCompanion toCompanion(bool nullToAbsent) {
    return SavedTicketsCompanion(
      id: Value(id),
      type: Value(type),
      frontNumbers: Value(frontNumbers),
      backNumbers: Value(backNumbers),
      savedAt: Value(savedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      targetIssue: targetIssue == null && nullToAbsent
          ? const Value.absent()
          : Value(targetIssue),
    );
  }

  factory SavedTicketRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedTicketRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      frontNumbers: serializer.fromJson<String>(json['frontNumbers']),
      backNumbers: serializer.fromJson<String>(json['backNumbers']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
      note: serializer.fromJson<String?>(json['note']),
      targetIssue: serializer.fromJson<String?>(json['targetIssue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'frontNumbers': serializer.toJson<String>(frontNumbers),
      'backNumbers': serializer.toJson<String>(backNumbers),
      'savedAt': serializer.toJson<DateTime>(savedAt),
      'note': serializer.toJson<String?>(note),
      'targetIssue': serializer.toJson<String?>(targetIssue),
    };
  }

  SavedTicketRow copyWith({
    String? id,
    String? type,
    String? frontNumbers,
    String? backNumbers,
    DateTime? savedAt,
    Value<String?> note = const Value.absent(),
    Value<String?> targetIssue = const Value.absent(),
  }) => SavedTicketRow(
    id: id ?? this.id,
    type: type ?? this.type,
    frontNumbers: frontNumbers ?? this.frontNumbers,
    backNumbers: backNumbers ?? this.backNumbers,
    savedAt: savedAt ?? this.savedAt,
    note: note.present ? note.value : this.note,
    targetIssue: targetIssue.present ? targetIssue.value : this.targetIssue,
  );
  SavedTicketRow copyWithCompanion(SavedTicketsCompanion data) {
    return SavedTicketRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      frontNumbers: data.frontNumbers.present
          ? data.frontNumbers.value
          : this.frontNumbers,
      backNumbers: data.backNumbers.present
          ? data.backNumbers.value
          : this.backNumbers,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      note: data.note.present ? data.note.value : this.note,
      targetIssue: data.targetIssue.present
          ? data.targetIssue.value
          : this.targetIssue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedTicketRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('frontNumbers: $frontNumbers, ')
          ..write('backNumbers: $backNumbers, ')
          ..write('savedAt: $savedAt, ')
          ..write('note: $note, ')
          ..write('targetIssue: $targetIssue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    frontNumbers,
    backNumbers,
    savedAt,
    note,
    targetIssue,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedTicketRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.frontNumbers == this.frontNumbers &&
          other.backNumbers == this.backNumbers &&
          other.savedAt == this.savedAt &&
          other.note == this.note &&
          other.targetIssue == this.targetIssue);
}

class SavedTicketsCompanion extends UpdateCompanion<SavedTicketRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> frontNumbers;
  final Value<String> backNumbers;
  final Value<DateTime> savedAt;
  final Value<String?> note;
  final Value<String?> targetIssue;
  final Value<int> rowid;
  const SavedTicketsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.frontNumbers = const Value.absent(),
    this.backNumbers = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.targetIssue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedTicketsCompanion.insert({
    required String id,
    required String type,
    required String frontNumbers,
    required String backNumbers,
    required DateTime savedAt,
    this.note = const Value.absent(),
    this.targetIssue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       frontNumbers = Value(frontNumbers),
       backNumbers = Value(backNumbers),
       savedAt = Value(savedAt);
  static Insertable<SavedTicketRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? frontNumbers,
    Expression<String>? backNumbers,
    Expression<DateTime>? savedAt,
    Expression<String>? note,
    Expression<String>? targetIssue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (frontNumbers != null) 'front_numbers': frontNumbers,
      if (backNumbers != null) 'back_numbers': backNumbers,
      if (savedAt != null) 'saved_at': savedAt,
      if (note != null) 'note': note,
      if (targetIssue != null) 'target_issue': targetIssue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedTicketsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? frontNumbers,
    Value<String>? backNumbers,
    Value<DateTime>? savedAt,
    Value<String?>? note,
    Value<String?>? targetIssue,
    Value<int>? rowid,
  }) {
    return SavedTicketsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      frontNumbers: frontNumbers ?? this.frontNumbers,
      backNumbers: backNumbers ?? this.backNumbers,
      savedAt: savedAt ?? this.savedAt,
      note: note ?? this.note,
      targetIssue: targetIssue ?? this.targetIssue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (frontNumbers.present) {
      map['front_numbers'] = Variable<String>(frontNumbers.value);
    }
    if (backNumbers.present) {
      map['back_numbers'] = Variable<String>(backNumbers.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (targetIssue.present) {
      map['target_issue'] = Variable<String>(targetIssue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedTicketsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('frontNumbers: $frontNumbers, ')
          ..write('backNumbers: $backNumbers, ')
          ..write('savedAt: $savedAt, ')
          ..write('note: $note, ')
          ..write('targetIssue: $targetIssue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SavedTicketsTable savedTickets = $SavedTicketsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [savedTickets];
}

typedef $$SavedTicketsTableCreateCompanionBuilder =
    SavedTicketsCompanion Function({
      required String id,
      required String type,
      required String frontNumbers,
      required String backNumbers,
      required DateTime savedAt,
      Value<String?> note,
      Value<String?> targetIssue,
      Value<int> rowid,
    });
typedef $$SavedTicketsTableUpdateCompanionBuilder =
    SavedTicketsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> frontNumbers,
      Value<String> backNumbers,
      Value<DateTime> savedAt,
      Value<String?> note,
      Value<String?> targetIssue,
      Value<int> rowid,
    });

class $$SavedTicketsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedTicketsTable> {
  $$SavedTicketsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frontNumbers => $composableBuilder(
    column: $table.frontNumbers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backNumbers => $composableBuilder(
    column: $table.backNumbers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetIssue => $composableBuilder(
    column: $table.targetIssue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedTicketsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedTicketsTable> {
  $$SavedTicketsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frontNumbers => $composableBuilder(
    column: $table.frontNumbers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backNumbers => $composableBuilder(
    column: $table.backNumbers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetIssue => $composableBuilder(
    column: $table.targetIssue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedTicketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedTicketsTable> {
  $$SavedTicketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get frontNumbers => $composableBuilder(
    column: $table.frontNumbers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backNumbers => $composableBuilder(
    column: $table.backNumbers,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get targetIssue => $composableBuilder(
    column: $table.targetIssue,
    builder: (column) => column,
  );
}

class $$SavedTicketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedTicketsTable,
          SavedTicketRow,
          $$SavedTicketsTableFilterComposer,
          $$SavedTicketsTableOrderingComposer,
          $$SavedTicketsTableAnnotationComposer,
          $$SavedTicketsTableCreateCompanionBuilder,
          $$SavedTicketsTableUpdateCompanionBuilder,
          (
            SavedTicketRow,
            BaseReferences<_$AppDatabase, $SavedTicketsTable, SavedTicketRow>,
          ),
          SavedTicketRow,
          PrefetchHooks Function()
        > {
  $$SavedTicketsTableTableManager(_$AppDatabase db, $SavedTicketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedTicketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedTicketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedTicketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> frontNumbers = const Value.absent(),
                Value<String> backNumbers = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> targetIssue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedTicketsCompanion(
                id: id,
                type: type,
                frontNumbers: frontNumbers,
                backNumbers: backNumbers,
                savedAt: savedAt,
                note: note,
                targetIssue: targetIssue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String frontNumbers,
                required String backNumbers,
                required DateTime savedAt,
                Value<String?> note = const Value.absent(),
                Value<String?> targetIssue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedTicketsCompanion.insert(
                id: id,
                type: type,
                frontNumbers: frontNumbers,
                backNumbers: backNumbers,
                savedAt: savedAt,
                note: note,
                targetIssue: targetIssue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedTicketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedTicketsTable,
      SavedTicketRow,
      $$SavedTicketsTableFilterComposer,
      $$SavedTicketsTableOrderingComposer,
      $$SavedTicketsTableAnnotationComposer,
      $$SavedTicketsTableCreateCompanionBuilder,
      $$SavedTicketsTableUpdateCompanionBuilder,
      (
        SavedTicketRow,
        BaseReferences<_$AppDatabase, $SavedTicketsTable, SavedTicketRow>,
      ),
      SavedTicketRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SavedTicketsTableTableManager get savedTickets =>
      $$SavedTicketsTableTableManager(_db, _db.savedTickets);
}
