import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/storage_mode_provider.dart';

/// 首次启动 - 存储模式选择页面
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onServerModeSelected;
  final VoidCallback? onLocalModeSelected;

  const OnboardingScreen({
    super.key,
    this.onServerModeSelected,
    this.onLocalModeSelected,
  });

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
      if (mounted) {
        widget.onLocalModeSelected?.call();
      }
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
              const Icon(Icons.eco, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              // 标题
              const Text(
                '🎋 青竹',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '健康追踪 · 隐私优先',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                features: ['✓ 完全离线使用', '✓ 数据不离开设备', '✓ 无需服务器'],
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
                features: ['✓ 多设备实时同步', '✓ 家庭成员共享', '✓ 数据备份'],
                onTap: _isLoading ? null : _selectServerMode,
                isRecommended: false,
              ),
              const SizedBox(height: 32),
              // 说明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '提示：随时可以在设置中切换存储模式',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
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
    required VoidCallback? onTap,
    required bool isRecommended,
  }) {
    return Card(
      elevation: isRecommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRecommended ? BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('推荐', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              if (isRecommended) const SizedBox(height: 12),
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
                        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: features.map((f) => Text(f, style: TextStyle(fontSize: 13, color: Colors.green[700]))).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
