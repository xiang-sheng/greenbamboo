# 🎋 GreenBamboo Server

青竹 - 隐私优先的个人健康数据追踪服务

> 健康如竹，节节高

## ✨ 特性

- 🔒 **隐私优先** - 数据完全在你自己的服务器上
- 📱 **多端同步** - 支持 Web、Android、iOS（计划中）
- 🐳 **一键部署** - Docker 一键安装，无需复杂配置
- 📊 **数据可视化** - 趋势图表、统计分析
- 💾 **数据导出** - 支持 CSV/JSON 格式导出
- 🔓 **完全开源** - 代码透明，可审计，可定制

## 🚀 快速开始

### 方式一：Docker Compose（推荐）

```bash
# 克隆项目
git clone https://github.com/greenbamboo/server.git
cd server

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，修改 JWT_SECRET

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

服务启动后访问：http://localhost:3000

### 方式二：一键安装脚本

```bash
curl -fsSL https://get.greenbamboo.io/install.sh | bash
```

### 方式三：源码编译

```bash
# 安装 Go 1.21+
go mod download

# 编译
go build -o greenbamboo .

# 运行
./greenbamboo
```

## 📖 API 文档

### 认证

```bash
# 注册
POST /api/v1/auth/register
{
  "email": "user@example.com",
  "password": "password123"
}

# 登录
POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}
```

### 健康指标

```bash
# 获取指标列表
GET /api/v1/metrics
Authorization: Bearer <token>

# 创建指标
POST /api/v1/metrics
Authorization: Bearer <token>
{
  "name": "体重",
  "type": "number",
  "unit": "kg"
}
```

### 健康记录

```bash
# 创建记录
POST /api/v1/records
Authorization: Bearer <token>
{
  "metric_id": "xxx",
  "value": 65.5,
  "note": "晨起空腹",
  "recorded_at": 1710234567
}

# 批量创建（同步用）
POST /api/v1/records/bulk
Authorization: Bearer <token>
{
  "records": [...]
}
```

### 数据统计

```bash
# 趋势数据
GET /api/v1/stats/trend?metric_id=xxx&days=30
Authorization: Bearer <token>

# 汇总统计
GET /api/v1/stats/summary?metric_id=xxx&days=30
Authorization: Bearer <token>
```

完整 API 文档：[API.md](docs/API.md)

## 📱 客户端

- **Android App**: [greenbamboo-app](https://github.com/greenbamboo/app)
- **Web PWA**: 直接访问服务器地址
- **iOS App**: 开发中

## 🔧 配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `PORT` | 服务端口 | 3000 |
| `DB_PATH` | 数据库路径 | /app/data/health.db |
| `JWT_SECRET` | JWT 密钥 | 必须修改 |
| `GIN_MODE` | Gin 模式 | release |

## 💾 数据备份

数据库文件位于 `./data/health.db`，直接复制即可备份：

```bash
# 备份
cp ./data/health.db ./backup/health_$(date +%Y%m%d).db

# 恢复
cp ./backup/health_20260312.db ./data/health.db
```

## 🛡️ 安全建议

1. **修改 JWT_SECRET** - 使用强随机密钥
2. **使用 HTTPS** - 通过 Nginx 反向代理
3. **防火墙配置** - 仅开放必要端口
4. **定期备份** - 防止数据丢失

### Nginx 配置示例

```nginx
server {
    listen 443 ssl;
    server_name health.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📊 预置健康指标

系统会自动为每个新用户创建以下预置指标：

| 指标 | 类型 | 单位 |
|------|------|------|
| 体重 | number | kg |
| 睡眠时长 | number | hours |
| 睡眠质量 | number | 1-5 |
| 步数 | number | steps |
| 心情 | number | 1-5 |
| 血压（收缩压） | number | mmHg |
| 血压（舒张压） | number | mmHg |
| 心率 | number | bpm |

## 🤝 开发

```bash
# 安装依赖
go mod download

# 运行（开发模式）
GIN_MODE=debug go run .

# 测试
go test ./...

# 构建
go build -o greenbamboo .
```

## 📝 更新日志

- **v0.1.0** (2026-03) - 初始版本
  - 用户认证
  - 指标管理
  - 健康记录
  - 数据统计
  - Docker 部署

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
