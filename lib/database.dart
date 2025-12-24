import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'dart:convert';
import 'lottery_service.dart';

part 'database.g.dart';

/// 保存的彩票号码表
@DataClassName('SavedTicketRow')
class SavedTickets extends Table {
  /// 唯一标识符
  TextColumn get id => text()();
  
  /// 彩票类型: 'SSQ' 或 'DLT'
  TextColumn get type => text()();
  
  /// 前区号码 (JSON数组格式存储)
  TextColumn get frontNumbers => text()();
  
  /// 后区号码 (JSON数组格式存储)
  TextColumn get backNumbers => text()();
  
  /// 保存时间
  DateTimeColumn get savedAt => dateTime()();
  
  /// 备注
  TextColumn get note => text().nullable()();
  
  /// 目标期号
  TextColumn get targetIssue => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Drift 数据库定义
@DriftDatabase(tables: [SavedTickets])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  /// 打开数据库连接 (兼容所有平台)
  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'luckyu_database');
  }

  // ==================== SavedTicket CRUD 操作 ====================

  /// 获取所有保存的彩票
  Future<List<SavedTicket>> getAllTickets() async {
    final rows = await select(savedTickets).get();
    return rows.map(_rowToSavedTicket).toList();
  }

  /// 根据类型获取彩票
  Future<List<SavedTicket>> getTicketsByType(LotteryType type) async {
    final typeStr = type == LotteryType.SSQ ? 'SSQ' : 'DLT';
    final rows = await (select(savedTickets)
      ..where((t) => t.type.equals(typeStr)))
      .get();
    return rows.map(_rowToSavedTicket).toList();
  }

  /// 保存彩票
  Future<void> saveTicket(SavedTicket ticket) async {
    await into(savedTickets).insertOnConflictUpdate(
      SavedTicketsCompanion(
        id: Value(ticket.id),
        type: Value(ticket.type == LotteryType.SSQ ? 'SSQ' : 'DLT'),
        frontNumbers: Value(jsonEncode(ticket.frontNumbers)),
        backNumbers: Value(jsonEncode(ticket.backNumbers)),
        savedAt: Value(ticket.savedAt),
        note: Value(ticket.note),
        targetIssue: Value(ticket.targetIssue),
      ),
    );
  }

  /// 批量保存彩票 (用于迁移)
  Future<void> saveTickets(List<SavedTicket> tickets) async {
    await batch((batch) {
      for (final ticket in tickets) {
        batch.insert(
          savedTickets,
          SavedTicketsCompanion(
            id: Value(ticket.id),
            type: Value(ticket.type == LotteryType.SSQ ? 'SSQ' : 'DLT'),
            frontNumbers: Value(jsonEncode(ticket.frontNumbers)),
            backNumbers: Value(jsonEncode(ticket.backNumbers)),
            savedAt: Value(ticket.savedAt),
            note: Value(ticket.note),
            targetIssue: Value(ticket.targetIssue),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 删除彩票
  Future<void> deleteTicket(String id) async {
    await (delete(savedTickets)..where((t) => t.id.equals(id))).go();
  }

  /// 删除所有彩票
  Future<void> deleteAllTickets() async {
    await delete(savedTickets).go();
  }

  /// 检查是否有数据
  Future<bool> hasTickets() async {
    final count = await (selectOnly(savedTickets)
      ..addColumns([savedTickets.id.count()]))
      .map((row) => row.read(savedTickets.id.count()))
      .getSingle();
    return (count ?? 0) > 0;
  }

  /// 将数据库行转换为 SavedTicket 对象
  SavedTicket _rowToSavedTicket(SavedTicketRow row) {
    return SavedTicket(
      id: row.id,
      type: row.type == 'SSQ' ? LotteryType.SSQ : LotteryType.DLT,
      frontNumbers: List<int>.from(jsonDecode(row.frontNumbers)),
      backNumbers: List<int>.from(jsonDecode(row.backNumbers)),
      savedAt: row.savedAt,
      note: row.note,
      targetIssue: row.targetIssue,
    );
  }

  /// 监听所有彩票变化
  Stream<List<SavedTicket>> watchAllTickets() {
    return select(savedTickets).watch().map(
      (rows) => rows.map(_rowToSavedTicket).toList(),
    );
  }

  /// 监听特定类型的彩票变化
  Stream<List<SavedTicket>> watchTicketsByType(LotteryType type) {
    final typeStr = type == LotteryType.SSQ ? 'SSQ' : 'DLT';
    return (select(savedTickets)..where((t) => t.type.equals(typeStr)))
        .watch()
        .map((rows) => rows.map(_rowToSavedTicket).toList());
  }
}

