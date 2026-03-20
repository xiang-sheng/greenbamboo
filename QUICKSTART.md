# 🎋 GreenBamboo 快速开始指南

> 5 分钟部署你的私人健康追踪系统

---

## 📋 系统组成

```
┌─────────────────┐         ┌─────────────────┐
│   后端服务器     │ ◄─────► │  Android App    │
│  (Docker 运行)   │  HTTP   │  (Flutter)      │
└─────────────────┘         └─────────────────┘
```

---

## 🚀 第一步：部署后端（2 分钟）

### 1. 启动 Docker 服务

```bash
cd /home/ubuntu/.openclaw/workspace/greenbamboo-server
sudo docker-compose up -d
```

### 2. 验证服务

```bash
# 查看状态
sudo docker-compose ps

# 应该看到：
# Name          Command              State        Ports
# -------------------------------------------------------------------
# greenbamboo   ./greenbamboo   Up (healthy)   0.0.0.0:3000->3000/tcp
```

### 3. 测试 API

```bash
# 健康检查
curl http://localhost:3000/api/v1/health

# 应该返回：
# {"status":"ok","message":"GreenBamboo server is running"}
```

### 4. 获取服务器地址

**局域网访问：**
```bash
hostname -I | awk '{print $1}'
# 例如：192.168.1.100
```

**完整地址：** `http://192.168.1.100:3000`

---

## 📱 第二步：运行 Android App（3 分钟）

### 方式 A：使用模拟器（推荐开发）

1. **启动 Android 模拟器**
   - Android Studio → Device Manager
   - 创建或启动现有模拟器

2. **运行 App**
   ```bash
   cd /home/ubuntu/.openclaw/workspace/greenbamboo-app
   flutter pub get
   flutter run
   ```

### 方式 B：真机调试

1. **启用 USB 调试**
   - 手机设置 → 开发者选项 → USB 调试

2. **连接手机**
   ```bash
   adb devices
   # 应该看到设备列表
   ```

3. **运行 App**
   ```bash
   cd /home/ubuntu/.openclaw/workspace/greenbamboo-app
   flutter run
   ```

### 方式 C：安装 APK

1. **构建 APK**
   ```bash
   cd /home/ubuntu/.openclaw/workspace/greenbamboo-app
   flutter build apk --release
   ```

2. **安装到手机**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 🔐 第三步：登录使用

### 1. 打开 App

看到登录界面：
```
🎋 青竹
健康如竹，节节高

服务器地址：[http://192.168.1.100:3000]
邮箱：[your@email.com]
密码：[••••••••]

[登录] [注册]
```

### 2. 注册账号

- 输入服务器地址（你的后端地址）
- 输入邮箱和密码
- 点击"注册"

### 3. 开始记录

注册成功后进入首页：
```
┌─────────────────────────┐
│  🎋 青竹            [+] │
├─────────────────────────┤
│  欢迎语卡片              │
│                         │
│  快速记录                │
│  [体重] [睡眠] [运动]... │
│                         │
│  今日概览                │
│  体重 睡眠 步数 心情     │
└─────────────────────────┘
```

### 4. 记录健康数据

**快速记录：**
- 点击"体重"图标
- 输入数值（如：65.5）
- 点击"保存"

**详细记录：**
- 点击右上角"+"
- 选择指标
- 输入数值、日期、备注
- 点击"保存"

---

## ✅ 验证清单

### 后端
- [ ] Docker 容器运行中
- [ ] 健康检查通过
- [ ] 可以注册账号
- [ ] 可以登录

### App
- [ ] App 成功启动
- [ ] 可以连接服务器
- [ ] 可以注册/登录
- [ ] 可以创建记录
- [ ] 记录显示在列表

### 数据同步
- [ ] 记录保存到本地数据库
- [ ] 记录同步到服务器
- [ ] 刷新后数据一致

---

## 🔧 常见问题

### Q1: Docker 容器启动失败

**解决：**
```bash
# 查看日志
sudo docker-compose logs

# 重启服务
sudo docker-compose down
sudo docker-compose up -d
```

### Q2: App 无法连接服务器

**检查：**
1. 服务器地址是否正确
2. 手机/模拟器是否能访问服务器 IP
3. 防火墙是否开放 3000 端口

**测试：**
```bash
# 在手机上用浏览器访问
http://192.168.1.100:3000/api/v1/health
```

### Q3: 数据不同步

**解决：**
1. 检查网络连接
2. 在设置页点击"同步数据"
3. 查看 App 日志

---

## 📊 测试数据

### 注册测试账号
```
邮箱：test@example.com
密码：password123
```

### 创建测试记录
```
体重：65.5 kg
睡眠：7.5 小时
心情：4/5
```

---

## 🎯 下一步

### 功能探索
- [ ] 查看所有指标
- [ ] 查看记录列表
- [ ] 查看统计图表
- [ ] 自定义指标
- [ ] 导出数据

### 高级配置
- [ ] 配置域名 + HTTPS
- [ ] 设置提醒功能
- [ ] 备份数据
- [ ] 多设备同步

---

## 📞 获取帮助

### 文档
- [README.md](greenbamboo-server/README.md) - 后端说明
- [API.md](greenbamboo-server/docs/API.md) - API 文档
- [DEVELOPMENT.md](greenbamboo-app/DEVELOPMENT.md) - 开发文档

### 查看日志
```bash
# 后端日志
sudo docker-compose logs -f

# App 日志
adb logcat | grep greenbamboo
```

---

## 🎋 项目信息

- **名称**: GreenBamboo (青竹)
- **版本**: v1.0.0-beta
- **理念**: 健康如竹，节节高
- **特点**: 隐私优先、开源自部署

---

**祝你使用愉快！** 🌱
