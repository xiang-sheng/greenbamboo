import 'dart:convert';
import 'package:dio/dio.dart';

/// API 服务类
class ApiService {
  late Dio _dio;
  String? _baseUrl;
  String? _token;

  ApiService() {
    _dio = Dio();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// 设置服务器地址
  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// 设置 Token
  void setToken(String? token) {
    _token = token;
  }

  /// 获取拦截器
  InterceptorsWrapper get interceptors => InterceptorsWrapper(
    onRequest: (options, handler) {
      if (_token != null) {
        options.headers['Authorization'] = 'Bearer $_token';
      }
      return handler.next(options);
    },
    onResponse: (response, handler) {
      return handler.next(response);
    },
    onError: (error, handler) {
      return handler.next(error);
    },
  );

  // ==================== 认证接口 ====================

  /// 注册
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/v1/auth/register',
      data: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return response.data as Map<String, dynamic>;
  }

  /// 登录
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/v1/auth/login',
      data: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return response.data as Map<String, dynamic>;
  }

  // ==================== 指标接口 ====================

  /// 获取指标列表
  Future<List<dynamic>> getMetrics() async {
    final response = await _dio.get('$_baseUrl/api/v1/metrics');
    final data = response.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  /// 创建指标
  Future<Map<String, dynamic>> createMetric({
    required String name,
    required String type,
    String? unit,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/v1/metrics',
      data: jsonEncode({
        'name': name,
        'type': type,
        'unit': unit,
      }),
    );
    return response.data as Map<String, dynamic>;
  }

  // ==================== 记录接口 ====================

  /// 获取记录列表
  Future<List<dynamic>> getRecords({
    String? metricId,
    DateTime? since,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };
    if (metricId != null) {
      queryParams['metric_id'] = metricId;
    }
    if (since != null) {
      queryParams['since'] = since.toIso8601String();
    }

    final response = await _dio.get(
      '$_baseUrl/api/v1/records',
      queryParameters: queryParams,
    );
    final data = response.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  /// 创建记录
  Future<Map<String, dynamic>> createRecord({
    required String metricId,
    required double value,
    String? note,
    DateTime? recordedAt,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/v1/records',
      data: jsonEncode({
        'metric_id': metricId,
        'value': value,
        'note': note,
        'recorded_at': (recordedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000,
      }),
    );
    return response.data as Map<String, dynamic>;
  }

  /// 批量创建记录
  Future<Map<String, dynamic>> createRecordsBulk({
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/v1/records/bulk',
      data: jsonEncode({
        'records': records,
      }),
    );
    return response.data as Map<String, dynamic>;
  }

  /// 删除记录
  Future<void> deleteRecord(String recordId) async {
    await _dio.delete('$_baseUrl/api/v1/records/$recordId');
  }

  // ==================== 统计接口 ====================

  /// 获取趋势数据
  Future<Map<String, dynamic>> getTrendStats({
    required String metricId,
    int days = 30,
  }) async {
    final response = await _dio.get(
      '$_baseUrl/api/v1/stats/trend',
      queryParameters: {
        'metric_id': metricId,
        'days': days,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取汇总统计
  Future<Map<String, dynamic>> getSummaryStats({
    String? metricId,
    int days = 30,
  }) async {
    final response = await _dio.get(
      '$_baseUrl/api/v1/stats/summary',
      queryParameters: {
        if (metricId != null) 'metric_id': metricId,
        'days': days,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ==================== 同步接口 ====================

  /// 数据同步
  Future<Map<String, dynamic>> sync({
    required DateTime lastSync,
    required List<Map<String, dynamic>> localChanges,
    String? deviceId,
    String? deviceName,
    String? appVersion,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/v1/sync',
      data: jsonEncode({
        'last_sync': lastSync.millisecondsSinceEpoch ~/ 1000,
        'local_changes': localChanges,
        'device_id': deviceId,
        'device_name': deviceName,
        'app_version': appVersion ?? '1.0.0',
      }),
    );
    return response.data as Map<String, dynamic>;
  }

  // ==================== 工具方法 ====================

  /// 健康检查
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('$_baseUrl/api/v1/health');
      return response.data['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }
}
