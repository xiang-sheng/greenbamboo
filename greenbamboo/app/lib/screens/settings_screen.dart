import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/storage_mode_provider.dart';
import '../core/database/local_database.dart';
import '../core/services/data_migration_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _localRecordCount = 0;
  bool _isLoading = true;
  bool _isMigrating = false;
  double _migrationProgress = 0;
  String? _migrationMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final localDb = context.read<LocalDatabase>();
    final count = await localDb.getRecordCount(onlyUnmigrated: false);
    if (mounted) {
      setState(() {
        _localRecordCount = count;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final storageProvider = context.watch<StorageModeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 存储模式
          _buildSectionTitle('存储模式'),
          Card(
            child: Column(
              children: [
                _buildStorageModeTile(
                  icon: Icons.phone_android,
                  title: '本地存储',
                  subtitle: '数据仅保存在本设备',
                  mode: StorageMode.local,
                  currentMode: storageProvider.mode,
                  onTap: () => _handleStorageModeChange(StorageMode.local),
                ),
                const Divider(height: 1),
                _buildStorageModeTile(
                  icon: Icons.cloud_sync,
                  title: '服务器同步',
                  subtitle: '多设备数据同步',
                  mode: StorageMode.server,
                  currentMode: storageProvider.mode,
                  onTap: () => _handleStorageModeChange(StorageMode.server),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 数据管理
          _buildSectionTitle('数据管理'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.storage,
                    color: Colors.grey[600],
                  ),
                  title: const Text('本地数据'),
                  subtitle: Text('$_localRecordCount 条记录'),
                  trailing: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                const Divider(height: 1),
                
                // 迁移按钮（仅本地模式显示）
                if (storageProvider.isLocalMode && _localRecordCount > 0) ...[
                  ListTile(
                    leading: const Icon(Icons.upload, color: Colors.blue),
                    title: const Text('迁移到服务器'),
                    subtitle: const Text('上传本地数据到服务器'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _isMigrating ? null : _handleMigration,
                  ),
                  const Divider(height: 1),
                ],

                // 同步按钮（仅服务器模式显示）
                if (storageProvider.isServerMode) ...[
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('同步数据'),
                    subtitle: const Text('与服务器同步数据'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _syncData(context),
                  ),
                  const Divider(height: 1),
                ],

                ListTile(
                  leading: Icon(Icons.backup, color: Colors.grey[600]),
                  title: const Text('备份数据'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _handleBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.restore, color: Colors.grey[600]),
                  title: const Text('恢复数据'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _handleRestore,
                ),
              ],
            ),
          ),

          // 迁移进度（正在迁移时显示）
          if (_isMigrating) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '正在迁移数据...',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (_migrationMessage != null)
                                Text(
                                  _migrationMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${(_migrationProgress * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _migrationProgress),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 账户信息（仅服务器模式显示）
          if (storageProvider.isServerMode) ...[
            _buildSectionTitle('账户'),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: const Icon(Icons.person, color: Colors.green),
                ),
                title: Text(authProvider.email ?? '未登录'),
                subtitle: Text('服务器: ${authProvider.serverUrl ?? '-'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAccountDialog(context),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 关于
          _buildSectionTitle('关于'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('版本'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('用户协议'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('隐私政策'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 退出登录（仅服务器模式显示）
          if (storageProvider.isServerMode && authProvider.isLoggedIn)
            ElevatedButton(
              onPressed: () => _showLogoutDialog(context, authProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '退出登录',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

          const SizedBox(height: 32),

          // 版权信息
          Center(
            child: Text(
              '🎋 青竹 · GreenBamboo',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '健康如竹，节节高',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildStorageModeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required StorageMode mode,
    required StorageMode currentMode,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == currentMode;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.green : Colors.grey[600],
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.radio_button_off),
      onTap: onTap,
    );
  }

  Future<void> _handleStorageModeChange(StorageMode newMode) async {
    final storageProvider = context.read<StorageModeProvider>();
    final currentMode = storageProvider.mode;

    if (newMode == currentMode) return;

    // 切换到服务器模式需要确认
    if (newMode == StorageMode.server) {
      final confirmed = await _showConfirmDialog(
        title: '切换到服务器模式',
        content: '切换到服务器模式后，需要登录服务器。\n\n确定要切换吗？',
      );
      if (!confirmed) return;

      // 切换模式
      await storageProvider.switchToServer();

      // 跳转到登录页面
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              onLoginSuccess: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } else {
      // 切换到本地模式
      final confirmed = await _showConfirmDialog(
        title: '切换到本地模式',
        content: '切换到本地模式后，数据将仅保存在本设备。\n\n确定要切换吗？',
      );
      if (!confirmed) return;

      await storageProvider.switchToLocal();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已切换到本地模式')),
        );
      }
    }
  }

  Future<void> _handleMigration() async {
    final storageProvider = context.read<StorageModeProvider>();
    final authProvider = context.read<AuthProvider>();

    // 确认迁移
    final confirmed = await _showConfirmDialog(
      title: '迁移数据到服务器',
      content: '将本地 $_localRecordCount 条记录上传到服务器。\n\n'
          '迁移后本地数据将保留备份。\n\n确定要迁移吗？',
    );
    if (!confirmed) return;

    // 检查是否已登录服务器
    if (!authProvider.isLoggedIn) {
      // 先登录
      await storageProvider.switchToServer();
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              onLoginSuccess: () {
                Navigator.of(context).pop();
                // 登录成功后开始迁移
                _startMigration();
              },
            ),
          ),
        );
      }
    } else {
      _startMigration();
    }
  }

  void _startMigration() async {
    setState(() {
      _isMigrating = true;
      _migrationProgress = 0;
      _migrationMessage = '准备迁移...';
    });

    final migrationService = context.read<DataMigrationService>();
    
    final result = await migrationService.migrateLocalToServer(
      keepLocalBackup: true,
      onProgress: (current, total) {
        setState(() {
          _migrationProgress = current / total;
          _migrationMessage = '正在上传 $current / $total 条记录';
        });
      },
    );

    if (mounted) {
      setState(() {
        _isMigrating = false;
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '迁移成功'),
            backgroundColor: Colors.green,
          ),
        );
        // 切换到服务器模式
        context.read<StorageModeProvider>().switchToServer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? result.message ?? '迁移失败'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // 刷新数据
      _loadData();
    }
  }

  void _handleBackup() async {
    final localDb = context.read<LocalDatabase>();
    
    try {
      final data = await localDb.exportData();
      // TODO: 保存到文件或分享
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('备份成功：${data['records']?.length ?? 0} 条记录'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleRestore() {
    // TODO: 从文件恢复数据
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('恢复功能开发中')),
    );
  }

  void _syncData(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在同步数据...')),
    );
    // TODO: 调用同步 API
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('账户信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('邮箱: ${context.read<AuthProvider>().email ?? "-"}'),
            const SizedBox(height: 8),
            Text('服务器: ${context.read<AuthProvider>().serverUrl ?? "-"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pop(context);
                // 返回设置页面，由 AppStartup 处理跳转
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
