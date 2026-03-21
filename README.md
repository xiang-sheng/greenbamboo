# 🎋 青竹 GreenBamboo

> 健康如竹，节节高

一款**隐私优先**的个人健康追踪应用，支持本地存储和服务器同步两种模式。

---

## ✨ 特性

### 🛡️ 隐私优先
- **本地存储模式**：数据完全保存在你的设备上，无需联网，无需注册
- **服务器同步模式**：可选部署私有服务器，支持多设备同步
- **数据自主**：随时导出、删除你的数据

### 📊 核心功能
- **自定义指标**：创建你想追踪的任何健康指标（体重、睡眠、心情、血压...）
- **快速记录**：点击指标卡片即可添加记录
- **历史补填**：支持补填过去 365 天的历史记录
- **数据统计**：图表展示趋势变化
- **完全免费**：无广告、无订阅、无内购

### 🎨 设计亮点
- Material 3 设计语言
- 简洁直观的界面
- 流畅的动画效果
- 支持深色模式

---

## 📱 下载安装

### Android

1. 访问 [Releases](https://github.com/xiang-sheng/greenbamboo/releases)
2. 下载最新版本的 APK 文件
3. 安装到手机（需要允许"未知来源"安装）

### iOS

> 计划中，敬请期待

### Web

> 计划中，敬请期待

---

## 🚀 快速开始

### 首次使用

1. **选择存储模式**
   - 推荐选择"本地存储"（隐私优先）
   - 如需多设备同步，选择"服务器同步"

2. **创建指标**
   - 点击底部导航栏的"指标"Tab
   - 点击右上角 `+` 按钮
   - 输入指标名称（如：体重）和单位（如：kg）

3. **添加记录**
   - 点击首页的指标卡片
   - 选择日期（支持补填历史）
   - 输入数值和备注
   - 保存

### 使用场景示例

#### 追踪体重
```
指标名称：体重
单位：kg
记录频率：每天早晨空腹
```

#### 追踪睡眠
```
指标名称：睡眠时长
单位：小时
记录频率：每天起床后
备注：可记录睡眠质量（如：深睡、多梦）
```

#### 追踪心情
```
指标名称：心情指数
单位：无（1-5 分）
记录频率：随时
备注：记录当天的心情状态
```

---

## 🖥️ 服务器部署（可选）

如果你需要多设备同步功能，可以部署私有服务器。

### 要求

- 一台 Linux 服务器（Ubuntu/Debian）
- Docker 和 Docker Compose

### 一键部署

```bash
# 克隆项目
git clone https://github.com/xiang-sheng/greenbamboo.git
cd greenbamboo/server

# 运行安装脚本
chmod +x install.sh
./install.sh
```

### 手动部署

```bash
# 使用 Docker Compose
cd greenbamboo/server
docker-compose up -d
```

详细部署指南请参考 [服务器文档](server/README.md)

---

## 📖 文档

- [快速开始指南](QUICKSTART.md)
- [项目总结](PROJECT_SUMMARY.md)
- [验证报告](VERIFICATION_REPORT.md)
- [用户痛点分析](docs/USER_PAIN_POINTS.md)
- [API 文档](server/docs/API.md)
- [开发指南](app/DEVELOPMENT.md)

---

## 🛠️ 技术栈

### 客户端（App）
- **框架**：Flutter 3.19.0
- **语言**：Dart
- **本地存储**：SQLite (sqflite)
- **状态管理**：Provider
- **图表**：fl_chart

### 服务端
- **语言**：Go 1.21+
- **数据库**：SQLite
- **Web 框架**：Gin
- **部署**：Docker

---

## 📦 项目结构

```
greenbamboo/
├── app/                     # Flutter 客户端
│   ├── lib/
│   │   ├── core/           # 核心服务
│   │   │   ├── database/   # 本地数据库
│   │   │   ├── providers/  # 状态管理
│   │   │   └── services/   # API 服务
│   │   ├── screens/        # 页面
│   │   └── widgets/        # 组件
│   └── pubspec.yaml
├── server/                  # Go 服务端
│   ├── internal/           # 内部包
│   │   ├── database/       # 数据库操作
│   │   └── handlers/       # HTTP 处理器
│   └── main.go
├── docs/                    # 文档
└── README.md
```

---

## 🔒 安全与隐私

### 数据安全
- 本地数据使用 SQLite 加密存储
- 服务器通信使用 HTTPS 加密
- 不收集任何个人信息
- 不上传任何遥测数据

### 权限说明
- **存储权限**：用于备份和导出数据（可选）
- **网络权限**：仅在使用服务器同步时需要

---

## 🤝 贡献

欢迎贡献代码、报告 Bug 或提出新功能建议！

### 开发环境搭建

```bash
# 克隆项目
git clone https://github.com/xiang-sheng/greenbamboo.git
cd greenbamboo

# 安装依赖
cd app
flutter pub get

# 运行应用
flutter run
```

详细开发指南请参考 [app/DEVELOPMENT.md](app/DEVELOPMENT.md)

---

## 📝 更新日志

### v1.0.0+1 (2026-03-20)
- ✨ 初始版本发布
- 🛡️ 支持本地存储和服务器同步
- 📊 自定义指标管理
- 📅 历史数据补填
- 📈 数据统计图表

---

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)

---

## 🙏 致谢

- 感谢所有贡献者
- 灵感来源于对隐私和简洁的追求

---

## 📬 联系方式

- **项目地址**：https://github.com/xiang-sheng/greenbamboo
- **问题反馈**：https://github.com/xiang-sheng/greenbamboo/issues
- **讨论区**：https://github.com/xiang-sheng/greenbamboo/discussions

---

<div align="center">

**健康如竹，节节高** 🎋

Made with ❤️ by GreenBamboo Team

</div>
