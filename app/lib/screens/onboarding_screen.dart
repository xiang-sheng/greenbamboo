import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/storage_mode_provider.dart';

/// 首次启动 - 存储模式选择页面
/// 
/// 用户可以选择：
/// 1. 本地存储 - 数据仅保存在设备上，隐私优先
/// 2. 服务器存储 - 多设备同步，需要部署服务器
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onServerModeSelected;
  
  const OnboardingScreen({super.key, this.onServerModeSelected});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;

  Future<void> _selectLocalMode() async {
    setState(() => _isLoading = true);
    
    try {
      final storageProvider = context.read<StorageModeProvider>();
      await storageProvider.setMode(StorageMode.local);
      
      // 本地模式不需要登录，直接进入主界面
      // Navigator 会在 main.dart 中处理
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectServerMode() {
    // 跳转到登录页面
    widget.onServerModeSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Logo
              const Icon(
                Icons.eco,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              // 标题
              const Text(
                '🎋 青竹',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '健康追踪 · 隐私优先',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              
              // 欢迎文字
              const Text(
                '首次使用，请选择数据存储方式：',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              // 本地存储选项
              _buildOptionCard(
                icon: Icons.phone_android,
                iconColor: Colors.green,
                title: '本地存储',
                subtitle: '数据仅保存在本设备',
                features: [
                  '✓ 完全离线使用',
                  '✓ 数据不离开设备',
                  '✓ 无需服务器',
                  '✓ 最高隐私保护',
                ],
                limitations: [
                  '✗ 仅限单设备使用',
                  '✗ 换机需手动迁移',
                ],
                onTap: _isLoading ? null : _selectLocalMode,
                isRecommended: true,
              ),
              
              const SizedBox(height: 16),
              
              // 服务器存储选项
              _buildOptionCard(
                icon: Icons.cloud_sync,
                iconColor: Colors.blue,
                title: '服务器同步',
                subtitle: '多设备数据同步',
                features: [
                  '✓ 多设备实时同步',
                  '✓ 家庭成员共享',
                  '✓ 数据备份',
                  '✓ 远程访问',
                ],
                limitations: [
                  '✗ 需要部署服务器',
                  '✗ 需要网络连接',
                ],
                onTap: _isLoading ? null : _selectServerMode,
                isRecommended: false,
              ),
              
              const SizedBox(height: 32),
              
              // 说明文字
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '提示：随时可以在设置中切换存储模式',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '选择"本地存储"后，可随时迁移到服务器以实现多设备同步',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 加载指示器
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> features,
    required List<String> limitations,
    required VoidCallback? onTap,
    required bool isRecommended,
  }) {
    return Card(
      elevation: isRecommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRecommended 
          ? BorderSide(color: Colors.green, width: 2)
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 推荐标签
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '推荐',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              if (isRecommended) const SizedBox(height: 12),
              
              // 标题行
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 28, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 功能列表
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: features.map((f) => Text(
                  f,
                  style: TextStyle(fontSize: 13, color: Colors.green[700]),
                )).toList(),
              ),
              
              const SizedBox(height: 8),
              
              // 限制列表
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: limitations.map((l) => Text(
                  l,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
