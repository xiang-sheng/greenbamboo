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
  final VoidCallback? onLocalModeSelected;
  
  const OnboardingScreen({super.key, this.onServerModeSelected, this.onLocalModeSelected});

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
      // 本地模式不需要登录，通知父组件刷新
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