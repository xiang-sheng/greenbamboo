import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 本地 SQLite 数据库
class LocalDatabase {
  static Database? _database;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'greenbamboo.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    // 健康记录表
    await db.execute('''
      CREATE TABLE records (
        id TEXT PRIMARY KEY,
        metric_id TEXT NOT NULL,
        metric_name TEXT,
        value REAL,
        text_value TEXT,
        note TEXT,
        recorded_at INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // 指标表
    await db.execute('''
      CREATE TABLE metrics (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        unit TEXT,
        is_preset INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_records_metric ON records(metric_id)');
    await db.execute('CREATE INDEX idx_records_time ON records(recorded_at)');
    await db.execute('CREATE INDEX idx_records_sync ON records(is_synced)');
  }

  // ==================== 记录操作 ====================

  /// 插入记录
  Future<int> insertRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('records', record);
  }

  /// 批量插入记录
  Future<void> insertRecords(List<Map<String, dynamic>> records) async {
    final db = await database;
    final batch = db.batch();
    for (var record in records) {
      batch.insert('records', record);
    }
    await batch.commit(noResult: true);
  }

  /// 获取所有记录
  Future<List<Map<String, dynamic>>> getRecords({String? metricId}) async {
    final db = await database;
    if (metricId != null) {
      return await db.query(
        'records',
        where: 'metric_id = ?',
        whereArgs: [metricId],
        orderBy: 'recorded_at DESC',
      );
    }
    return await db.query('records', orderBy: 'recorded_at DESC');
  }

  /// 获取待同步记录
  Future<List<Map<String, dynamic>>> getPendingSync() async {
    final db = await database;
    return await db.query(
      'records',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  /// 标记记录为已同步
  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'records',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除记录
  Future<int> deleteRecord(String id) async {
    final db = await database;
    return await db.delete(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空所有记录
  Future<void> clearRecords() async {
    final db = await database;
    await db.delete('records');
  }

  // ==================== 指标操作 ====================

  /// 插入指标
  Future<int> insertMetric(Map<String, dynamic> metric) async {
    final db = await database;
    return await db.insert('metrics', metric);
  }

  /// 批量插入指标
  Future<void> insertMetrics(List<Map<String, dynamic>> metrics) async {
    final db = await database;
    final batch = db.batch();
    for (var metric in metrics) {
      batch.insert('metrics', metric);
    }
    await batch.commit(noResult: true);
  }

  /// 获取所有指标
  Future<List<Map<String, dynamic>>> getMetrics() async {
    final db = await database;
    return await db.query('metrics', orderBy: 'created_at DESC');
  }

  /// 清空指标
  Future<void> clearMetrics() async {
    final db = await database;
    await db.delete('metrics');
  }

  // ==================== 工具方法 ====================

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
