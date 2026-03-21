import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/record_provider.dart';
import 'core/providers/storage_mode_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/data_migration_service.dart';
import 'core/database/local_database.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const GreenBambooApp());
}

class GreenBambooApp extends StatelessWidget {
  const GreenBambooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // API 服务
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        // 本地数据库
        Provider<LocalDatabase>(
          create: (_) => LocalDatabase(),
        ),
        // 存储模式状态
        ChangeNotifierProvider<StorageModeProvider>(
          create: (_) => StorageModeProvider(),
        ),
        // 认证状态
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<ApiService>(),
            context.read<LocalDatabase>(),
          ),
        ),
        // 记录状态
        ChangeNotifierProvider<RecordProvider>(
          create: (context) => RecordProvider(
            context.read<ApiService>(),
            context.read<LocalDatabase>(),
          ),
        ),
        // 数据迁移服务
        Provider<DataMigrationService>(
          create: (context) => DataMigrationService(
            context.read<LocalDatabase>(),
            context.read<ApiService>(),
            context.read<AuthProvider>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'GreenBamboo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        home: const AppStartup(),
      ),
    );
  }
}

/// 应用启动页面
/// 
/// 根据用户状态决定显示哪个页面：
/// 1. 首次启动 → OnboardingScreen（选择存储模式）
/// 2. 本地模式 → 直接进入 HomeScreen
/// 3. 服务器模式但未登录 → LoginScreen
/// 4. 已登录 → HomeScreen
class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool _isLoading = true;
  bool _needsOnboarding = false;
  bool _showLogin = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final storageProvider = context.read<StorageModeProvider>();
    final authProvider = context.read<AuthProvider>();
    
    // 等待 Provider 初始化完成
    while (storageProvider.isLoading || authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    // 检查是否需要 onboarding
    final needsOnboarding = await storageProvider.needsOnboarding();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _needsOnboarding = needsOnboarding;
        // 如果是服务器模式且未登录，显示登录页面
        _showLogin = storageProvider.isServerMode && !authProvider.isLoggedIn;
      });
    }
  }

  void _handleServerModeSelected() {
    setState(() {
      _needsOnboarding = false;
      _showLogin = true;
    });
  }

  void _handleLocalModeSelected() {
    setState(() {
      _needsOnboarding = false;
      _showLogin = false;
    });
  }

  void _handleLoginSuccess() {
    setState(() {
      _showLogin = false;
    });
  }

  void _handleLoginBack() {
    // 用户从登录页面返回，重新显示 onboarding
    setState(() {
      _needsOnboarding = true;
      _showLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 加载中
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    
    // 需要选择存储模式
    if (_needsOnboarding) {
      return OnboardingScreen(
        onServerModeSelected: _handleServerModeSelected,
        onLocalModeSelected: _handleLocalModeSelected,
      );
    }
    
    // 需要登录
    if (_showLogin) {
      return LoginScreen(
        onLoginSuccess: _handleLoginSuccess,
        onBack: _handleLoginBack,
      );
    }
    
    // 正常进入主页
    return const HomeScreen();
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '🎋 青竹',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '健康如竹，节节高',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
