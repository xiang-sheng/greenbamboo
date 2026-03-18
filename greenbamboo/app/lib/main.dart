import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/record_provider.dart';
import 'core/services/api_service.dart';
import 'core/database/local_database.dart';
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

class AppStartup extends StatelessWidget {
  const AppStartup({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
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

        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
