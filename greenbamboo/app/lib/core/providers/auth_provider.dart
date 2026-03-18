import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../database/local_database.dart';

/// 认证状态提供者
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final LocalDatabase _localDb;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  String? _userId;
  String? _email;
  String? _serverUrl;
  bool _isLoading = true;
  String? _error;

  AuthProvider(this._apiService, this._localDb) {
    _init();
  }

  // ==================== Getters ====================

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get userId => _userId;
  String? get email => _email;
  String? get serverUrl => _serverUrl;
  String? get error => _error;

  // ==================== 初始化 ====================

  Future<void> _init() async {
    try {
      // 从安全存储加载数据
      _token = await _storage.read(key: 'auth_token');
      _userId = await _storage.read(key: 'user_id');
      _email = await _storage.read(key: 'user_email');
      _serverUrl = await _storage.read(key: 'server_url');

      if (_token != null && _serverUrl != null) {
        _apiService.setBaseUrl(_serverUrl!);
        _apiService.setToken(_token);
      }
    } catch (e) {
      _error = 'Failed to load auth data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 认证方法 ====================

  /// 登录
  Future<bool> login({
    required String serverUrl,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 设置服务器地址
      _apiService.setBaseUrl(serverUrl);

      // 调用登录 API
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      // 解析响应
      final data = response['data'] as Map<String, dynamic>;
      _token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;
      _userId = user['id'] as String;
      _email = user['email'] as String;
      _serverUrl = serverUrl;

      // 设置 Token 并保存
      _apiService.setToken(_token);
      await _storage.write(key: 'auth_token', value: _token);
      await _storage.write(key: 'user_id', value: _userId);
      await _storage.write(key: 'user_email', value: _email);
      await _storage.write(key: 'server_url', value: serverUrl);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// 注册
  Future<bool> register({
    required String serverUrl,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 设置服务器地址
      _apiService.setBaseUrl(serverUrl);

      // 调用注册 API
      final response = await _apiService.register(
        email: email,
        password: password,
      );

      // 解析响应
      final data = response['data'] as Map<String, dynamic>;
      _token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;
      _userId = user['id'] as String;
      _email = user['email'] as String;
      _serverUrl = serverUrl;

      // 设置 Token 并保存
      _apiService.setToken(_token);
      await _storage.write(key: 'auth_token', value: _token);
      await _storage.write(key: 'user_id', value: _userId);
      await _storage.write(key: 'user_email', value: _email);
      await _storage.write(key: 'server_url', value: serverUrl);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Registration failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    _token = null;
    _userId = null;
    _email = null;
    _serverUrl = null;
    _apiService.setToken(null);

    // 清除存储
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'server_url');

    // 清除本地数据库
    await _localDb.clearRecords();
    await _localDb.clearMetrics();

    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
