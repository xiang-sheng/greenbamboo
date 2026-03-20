# 🎋 GreenBamboo App

青竹 Android 客户端 - 隐私优先的个人健康追踪器

> 健康如竹，节节高

## ✨ 特性

- 🔒 **隐私优先** - 数据存储在你自己的服务器
- 📱 **离线可用** - 支持离线记录，联网自动同步
- 🎨 **Material 3** - 现代简洁的 UI 设计
- 📊 **数据可视化** - 趋势图表、统计分析
- 🔄 **自动同步** - 本地数据库 + 云端同步

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Android SDK
- Dart SDK >= 3.0.0

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
flutter run
```

### 构建 APK

```bash
# 调试版
flutter build apk --debug

# 发布版
flutter build apk --release

# 输出位置：build/app/outputs/flutter-apk/app-release.apk
```

## 📁 项目结构

```
lib/
├── main.dart                     # 应用入口
├── core/
│   ├── services/
│   │   └── api_service.dart      # API 客户端
│   ├── providers/
│   │   ├── auth_provider.dart    # 认证状态
│   │   └── record_provider.dart  # 记录状态
│   └── database/
│       └── local_database.dart   # 本地 SQLite
├── screens/
│   ├── login_screen.dart         # 登录页
│   ├── home_screen.dart          # 首页
│   ├── record_list_screen.dart   # 记录列表
│   ├── stats_screen.dart         # 统计页
│   └── settings_screen.dart      # 设置页
└── ui/
    └── widgets/
        └── record_input_dialog.dart  # 记录输入对话框
```

## 🔧 配置

### 服务器地址

在登录界面输入你的 GreenBamboo 服务器地址：
- 局域网：`http://192.168.1.100:3000`
- 公网：`https://health.yourdomain.com`

### 权限配置

在 `android/app/src/main/AndroidManifest.xml` 添加：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## 📊 功能模块

### 认证模块
- [x] 用户注册
- [x] 用户登录
- [x] JWT Token 管理
- [x] 安全存储（flutter_secure_storage）

### 记录模块
- [x] 快速记录（一键输入）
- [x] 详细记录（日期 + 时间 + 备注）
- [x] 记录列表（查看/删除）
- [x] 本地数据库（SQLite）

### 统计模块
- [ ] 趋势图表（fl_chart）
- [x] 汇总统计（平均/最高/最低）
- [ ] 时间范围切换（7 天/30 天/90 天）

### 同步模块
- [x] 离线记录
- [x] 自动同步
- [x] 冲突处理

## 🎨 UI 设计

### 配色方案
- 主色：Green (#4CAF50)
- 背景：White (#FFFFFF)
- 卡片：White + Shadow

### 设计原则
- Material 3
- 简洁直观
- 易于操作

## 🧪 测试

```bash
# 运行测试
flutter test

# 代码分析
flutter analyze
```

## 📦 依赖说明

| 依赖 | 用途 |
|------|------|
| provider | 状态管理 |
| dio | HTTP 请求 |
| sqflite | 本地数据库 |
| flutter_secure_storage | 安全存储 Token |
| fl_chart | 图表库 |
| intl | 日期格式化 |

## 🐛 已知问题

- [ ] 图表功能待实现
- [ ] 备份/恢复功能待实现
- [ ] iOS 版本待开发

## 📝 开发计划

### v1.0 (当前版本)
- [x] 登录/注册
- [x] 记录功能
- [x] 本地数据库
- [x] 数据同步
- [ ] 图表展示

### v1.1
- [ ] 图表功能
- [ ] 提醒功能
- [ ] 数据导出

### v1.2
- [ ] iOS 版本
- [ ] 小组件
- [ ] 健康数据导入（Google Fit）

## 📄 许可证

MIT License

## 🌱 理念

GreenBamboo（青竹）寓意健康如竹，节节高升。

我们相信：
- 健康数据应该完全由个人掌控
- 开源软件更值得信赖
- 自部署是最安全的隐私保护方式

---

**Made with ❤️ by GreenBamboo Team**
