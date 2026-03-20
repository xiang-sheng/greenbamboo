import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 存储模式枚举
enum StorageMode {
  /// 本地存储 - 数据仅保存在设备上
  local,
  
  /// 服务器存储 - 数据同步到服务器
  server,
}

/// 存储模式提供者
/// 
/// 管理用户的数据存储偏好：
/// - 本地模式：数据存储在 SQLite，无需服务器
/// - 服务器模式：数据同步到远程服务器，支持多设备
class StorageModeProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  StorageMode _mode = StorageMode.local;
  bool _isLoading = true;
  String? _error;
  
  // ==================== Getters ====================
  
  StorageMode get mode => _mode;
  bool get isLoading => _isLoading;
  bool get isServerMode => _mode == StorageMode.server;
  bool get isLocalMode => _mode == StorageMode.local;
  String? get error => _error;
  
  // ==================== 初始化 ====================
  
  StorageModeProvider() {
    _init();
  }
  
  Future<void> _init() async {
    try {
      final modeStr = await _storage.read(key: 'storage_mode');
      if (modeStr == 'server') {
        _mode = StorageMode.server;
      } else {
        _mode = StorageMode.local;
      }
    } catch (e) {
      // 默认本地模式
      _mode = StorageMode.local;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ==================== 模式切换 ====================
  
  /// 设置存储模式
  Future<void> setMode(StorageMode mode) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _storage.write(
        key: 'storage_mode',
        value: mode == StorageMode.server ? 'server' : 'local',
      );
      
      _mode = mode;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to set storage mode: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  /// 切换到本地模式
  Future<void> switchToLocal() async {
    await setMode(StorageMode.local);
  }
  
  /// 切换到服务器模式
  /// 
  /// 注意：切换到服务器模式后，需要处理数据迁移
  Future<void> switchToServer() async {
    await setMode(StorageMode.server);
  }
  
  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // ==================== 状态查询 ====================
  
  /// 是否需要显示 onboarding 页面
  /// 
  /// 首次启动时返回 true，选择存储模式后返回 false
  Future<bool> needsOnboarding() async {
    final hasChosen = await _storage.read(key: 'storage_mode');
    return hasChosen == null;
  }
  
  /// 标记已完成 onboarding
  Future<void> completeOnboarding() async {
    await _storage.write(key: 'onboarding_completed', value: 'true');
  }
}
