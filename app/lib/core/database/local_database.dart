import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 本地 SQLite 数据库
/// 
/// 支持两种存储模式：
/// - 本地模式：数据仅存储在本地 SQLite
/// - 服务器模式：数据同步到远程服务器
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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        is_migrated INTEGER DEFAULT 0,
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
    await db.execute('CREATE INDEX idx_records_migrated ON records(is_migrated)');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加迁移标记字段
      await db.execute('ALTER TABLE records ADD COLUMN is_migrated INTEGER DEFAULT 0');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_records_migrated ON records(is_migrated)');
    }
  }

  // ==================== 记录操作 ====================

  /// 插入记录
  Future<String> insertRecord({
    required String id,
    required String metricId,
    String? metricName,
    double? value,
    String? textValue,
    String? note,
    required DateTime recordedAt,
    bool isSynced = false,
  }) async {
    final db = await database;
    final data = {
      'id': id,
      'metric_id': metricId,
      'metric_name': metricName,
      'value': value,
      'text_value': textValue,
      'note': note,
      'recorded_at': recordedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
      'is_migrated': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    await db.insert('records', data);
    return id;
  }

  /// 批量插入记录（用于从服务器下载）
  Future<void> insertRecords(List<Map<String, dynamic>> records) async {
    final db = await database;
    final batch = db.batch();
    for (var record in records) {
      batch.insert('records', {
        ...record,
        'is_synced': 1, // 从服务器下载的数据标记为已同步
        'is_migrated': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// 获取所有记录（用于迁移到服务器）
  Future<List<Map<String, dynamic>>> getAllRecords({
    bool excludeMigrated = true,
  }) async {
    final db = await database;
    if (excludeMigrated) {
      return await db.query(
        'records',
        where: 'is_migrated = ?',
        whereArgs: [0],
        orderBy: 'recorded_at ASC',
      );
    }
    return await db.query('records', orderBy: 'recorded_at ASC');
  }

  /// 获取记录数量
  Future<int> getRecordCount({bool onlyUnmigrated = false}) async {
    final db = await database;
    if (onlyUnmigrated) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM records WHERE is_migrated = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM records');
    return Sqflite.firstIntValue(result) ?? 0;
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

  /// 获取记录（可按指标筛选）
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

  /// 标记所有记录为已迁移
  Future<void> markRecordsAsMigrated() async {
    final db = await database;
    await db.update(
      'records',
      {'is_migrated': 1, 'is_synced': 1},
      where: 'is_migrated = ?',
      whereArgs: [0],
    );
  }

  /// 删除单条记录
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
      batch.insert('metrics', metric, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// 获取所有指标
  Future<List<Map<String, dynamic>>> getMetrics() async {
    final db = await database;
    return await db.query('metrics', orderBy: 'created_at DESC');
  }

  /// 删除指标
  Future<int> deleteMetric(String id) async {
    final db = await database;
    return await db.delete(
      'metrics',
      where: 'id = ?',
      whereArgs: [id],
    );
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

  /// 导出数据（用于备份）
  Future<Map<String, dynamic>> exportData() async {
    final records = await getAllRecords(excludeMigrated: false);
    final metrics = await getMetrics();
    return {
      'records': records,
      'metrics': metrics,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// 导入数据（用于恢复）
  Future<void> importData(Map<String, dynamic> data) async {
    if (data['records'] != null) {
      await insertRecords(List<Map<String, dynamic>>.from(data['records']));
    }
    if (data['metrics'] != null) {
      await insertMetrics(List<Map<String, dynamic>>.from(data['metrics']));
    }
  }
}
