import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../database/local_database.dart';

/// 记录状态提供者
class RecordProvider extends ChangeNotifier {
  final ApiService _apiService;
  final LocalDatabase _localDb;

  List<dynamic> _records = [];
  List<dynamic> _metrics = [];
  bool _isLoading = false;
  String? _error;
  DateTime _lastSync = DateTime.now();

  RecordProvider(this._apiService, this._localDb);

  // ==================== Getters ====================

  List<dynamic> get records => _records;
  List<dynamic> get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get lastSync => _lastSync;

  // ==================== 数据加载 ====================

  /// 加载指标列表
  Future<void> loadMetrics() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 先从本地加载
      final localMetrics = await _localDb.getMetrics();
      if (localMetrics.isNotEmpty) {
        _metrics = localMetrics;
      }

      // 从服务器获取
      _metrics = await _apiService.getMetrics();

      // 保存到本地
      await _localDb.clearMetrics();
      for (var metric in _metrics) {
        await _localDb.insertMetric({
          'id': metric['id'],
          'name': metric['name'],
          'type': metric['type'],
          'unit': metric['unit'] ?? '',
          'is_preset': metric['is_preset'] ? 1 : 0,
          'created_at': metric['created_at'],
        });
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load metrics: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 加载记录列表
  Future<void> loadRecords({String? metricId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 从服务器获取
      _records = await _apiService.getRecords(
        metricId: metricId,
        limit: 100,
      );

      // 保存到本地
      await _localDb.clearRecords();
      for (var record in _records) {
        await _localDb.insertRecord({
          'id': record['id'],
          'metric_id': record['metric_id'],
          'metric_name': record['metric_name'] ?? '',
          'value': record['value'] ?? 0.0,
          'text_value': record['text_value'] ?? '',
          'note': record['note'] ?? '',
          'recorded_at': record['recorded_at'],
          'is_synced': 1,
          'created_at': record['created_at'],
        });
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load records: ${e.toString()}';
      notifyListeners();
    }
  }

  // ==================== 记录操作 ====================

  /// 创建记录（先存本地，后同步）
  Future<bool> createRecord({
    required String metricId,
    required double value,
    String? note,
    DateTime? recordedAt,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final now = DateTime.now();
      final recordId = '${now.millisecondsSinceEpoch}_${_generateId(8)}';

      // 保存到本地数据库
      await _localDb.insertRecord({
        'id': recordId,
        'metric_id': metricId,
        'value': value,
        'text_value': '',
        'note': note ?? '',
        'recorded_at': (recordedAt ?? now).millisecondsSinceEpoch ~/ 1000,
        'is_synced': 0,
        'created_at': now.millisecondsSinceEpoch ~/ 1000,
      });

      // 尝试同步到服务器
      try {
        await _apiService.createRecord(
          metricId: metricId,
          value: value,
          note: note,
          recordedAt: recordedAt,
        );
        // 同步成功，标记为已同步
        await _localDb.markAsSynced(recordId);
        // 重新加载记录
        await loadRecords();
      } catch (e) {
        // 同步失败，保留在本地待同步
        debugPrint('Sync failed, will sync later: $e');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to create record: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// 删除记录
  Future<bool> deleteRecord(String recordId) async {
    try {
      await _localDb.deleteRecord(recordId);
      await loadRecords();
      return true;
    } catch (e) {
      _error = 'Failed to delete record: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ==================== 同步 ====================

  /// 同步数据
  Future<void> sync() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 获取待同步记录
      final pendingRecords = await _localDb.getPendingSync();
      if (pendingRecords.isNotEmpty) {
        // 转换为 API 格式
        final localChanges = pendingRecords.map((r) => {
          'metric_id': r['metric_id'],
          'value': r['value'],
          'note': r['note'],
          'recorded_at': r['recorded_at'],
        }).toList();

        // 调用同步 API
        await _apiService.sync(
          lastSync: _lastSync,
          localChanges: localChanges,
          deviceId: 'android_${_generateId(8)}',
          deviceName: 'Android Phone',
        );

        // 标记为已同步
        for (var record in pendingRecords) {
          await _localDb.markAsSynced(record['id']);
        }
      }

      // 重新加载记录
      await loadRecords();

      _lastSync = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Sync failed: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ==================== 工具方法 ====================

  String _generateId(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(DateTime.now().millisecondsSinceEpoch % chars.length),
      ),
    );
  }
}
