import '../database/local_database.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

/// 数据迁移服务
/// 
/// 处理本地数据到服务器的迁移，支持：
/// - 本地 → 服务器：上传本地数据到服务器
/// - 服务器 → 本地：下载服务器数据到本地（可选）
class DataMigrationService {
  final LocalDatabase _localDb;
  final ApiService _apiService;
  final AuthProvider _authProvider;
  
  DataMigrationService(this._localDb, this._apiService, this._authProvider);
  
  /// 迁移结果
  MigrationResult lastResult = MigrationResult();
  
  /// 将本地数据迁移到服务器
  /// 
  /// 步骤：
  /// 1. 读取本地所有健康记录
  /// 2. 批量上传到服务器
  /// 3. 验证上传成功
  /// 4. 可选：清除本地数据（保留一段时间以防万一）
  Future<MigrationResult> migrateLocalToServer({
    bool keepLocalBackup = true,
    Function(int current, int total)? onProgress,
  }) async {
    final result = MigrationResult();
    
    try {
      // 检查是否已登录
      if (!_authProvider.isLoggedIn) {
        result.error = '请先登录服务器';
        return result;
      }
      
      // 1. 读取本地记录（排除已迁移的）
      final records = await _localDb.getAllRecords(excludeMigrated: true);
      result.totalRecords = records.length;
      
      if (records.isEmpty) {
        result.success = true;
        result.message = '本地无数据需要迁移';
        return result;
      }
      
      // 2. 批量上传
      int uploaded = 0;
      for (final record in records) {
        try {
          await _apiService.createRecord(
            metricId: record['metric_id'] as String,
            value: (record['value'] as num).toDouble(),
            note: record['note'] as String?,
            recordedAt: DateTime.fromMillisecondsSinceEpoch(
              record['recorded_at'] as int,
            ),
          );
          uploaded++;
          onProgress?.call(uploaded, records.length);
        } catch (e) {
          result.failedRecords++;
          result.failedRecordIds.add(record['id'] as String);
        }
      }
      
      result.uploadedRecords = uploaded;
      
      // 3. 验证
      if (result.failedRecords == 0) {
        result.success = true;
        result.message = '成功迁移 $uploaded 条记录';
        
        // 4. 处理本地数据
        if (!keepLocalBackup) {
          await _localDb.clearRecords();
          result.localDataCleared = true;
        } else {
          // 标记为已迁移，但保留本地备份
          await _localDb.markRecordsAsMigrated();
          result.localDataCleared = false;
        }
      } else {
        result.success = false;
        result.message = '部分记录迁移失败：成功 $uploaded，失败 ${result.failedRecords}';
      }
      
    } catch (e) {
      result.success = false;
      result.error = '迁移失败: $e';
    }
    
    lastResult = result;
    return result;
  }
  
  /// 从服务器下载数据到本地
  /// 
  /// 用于：
  /// - 服务器 → 本地模式切换
  /// - 离线数据缓存
  Future<MigrationResult> downloadServerToLocal({
    Function(int current, int total)? onProgress,
  }) async {
    final result = MigrationResult();
    
    try {
      if (!_authProvider.isLoggedIn) {
        result.error = '请先登录';
        return result;
      }
      
      // 从服务器获取所有记录
      final records = await _apiService.getRecords(limit: 10000);
      
      result.totalRecords = records.length;
      
      // 插入本地数据库
      int downloaded = 0;
      for (final record in records) {
        try {
          // 转换服务器格式为本地格式
          final localRecord = {
            'id': record['id'] as String,
            'metric_id': record['metric_id'] as String,
            'metric_name': record['metric_name'] as String?,
            'value': (record['value'] as num).toDouble(),
            'note': record['note'] as String?,
            'recorded_at': (record['recorded_at'] is int)
                ? record['recorded_at'] as int
                : DateTime.parse(record['recorded_at'] as String).millisecondsSinceEpoch,
          };
          
          await _localDb.insertRecords([localRecord]);
          downloaded++;
          onProgress?.call(downloaded, records.length);
        } catch (e) {
          result.failedRecords++;
        }
      }
      
      result.uploadedRecords = downloaded;
      result.success = true;
      result.message = '成功下载 $downloaded 条记录到本地';
      
    } catch (e) {
      result.success = false;
      result.error = '下载失败: $e';
    }
    
    lastResult = result;
    return result;
  }
}

/// 迁移结果
class MigrationResult {
  bool success = false;
  String? error;
  String? message;
  
  int totalRecords = 0;
  int uploadedRecords = 0;
  int failedRecords = 0;
  List<String> failedRecordIds = [];
  bool localDataCleared = false;
  
  double get progress => totalRecords > 0 
    ? uploadedRecords / totalRecords 
    : 0;
  
  @override
  String toString() {
    if (success) {
      return message ?? '迁移成功';
    } else {
      return error ?? message ?? '迁移失败';
    }
  }
}
