# GreenBamboo API 文档

## 基础信息

- **Base URL**: `http://localhost:3000/api/v1`
- **认证方式**: JWT Bearer Token
- **响应格式**: JSON

## 响应格式

### 成功响应
```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

### 错误响应
```json
{
  "code": 40000,
  "message": "error message",
  "data": null
}
```

### 错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 40000 | 请求参数错误 |
| 40100 | 认证失败 |
| 40400 | 资源不存在 |
| 40900 | 资源冲突 |
| 50000 | 服务器错误 |

---

## 认证接口

### 注册

```http
POST /api/v1/auth/register
Content-Type: application/json
```

**请求体:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 604800,
    "user": {
      "id": "20260312120000_abc123",
      "email": "user@example.com"
    }
  }
}
```

---

### 登录

```http
POST /api/v1/auth/login
Content-Type: application/json
```

**请求体:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 604800,
    "user": {
      "id": "20260312120000_abc123",
      "email": "user@example.com"
    }
  }
}
```

---

## 用户接口

### 获取个人信息

```http
GET /api/v1/user/profile
Authorization: Bearer <token>
```

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "20260312120000_abc123",
    "email": "user@example.com"
  }
}
```

---

## 指标接口

### 获取指标列表

```http
GET /api/v1/metrics
Authorization: Bearer <token>
```

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "20260312120000_def456",
      "name": "体重",
      "type": "number",
      "unit": "kg",
      "is_preset": true,
      "created_at": 1710234567
    }
  ]
}
```

---

### 创建指标

```http
POST /api/v1/metrics
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体:**
```json
{
  "name": "咖啡因摄入",
  "type": "number",
  "unit": "mg"
}
```

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "20260312120000_ghi789",
    "name": "咖啡因摄入",
    "type": "number",
    "unit": "mg",
    "is_preset": false,
    "created_at": 1710234567
  }
}
```

---

### 更新指标

```http
PUT /api/v1/metrics/:id
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体:**
```json
{
  "name": "咖啡因",
  "type": "number",
  "unit": "mg"
}
```

---

### 删除指标

```http
DELETE /api/v1/metrics/:id
Authorization: Bearer <token>
```

**响应:**
```json
{
  "code": 0,
  "message": "success"
}
```

---

## 记录接口

### 获取记录列表

```http
GET /api/v1/records?metric_id=xxx&since=2026-03-01T00:00:00Z&limit=50
Authorization: Bearer <token>
```

**查询参数:**
- `metric_id` (可选) - 按指标筛选
- `since` (可选) - 获取此时间之后的记录
- `limit` (可选) - 返回数量限制，默认 100，最大 500

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "20260312120000_jkl012",
      "metric_id": "20260312120000_def456",
      "metric_name": "体重",
      "value": 65.5,
      "text_value": "",
      "note": "晨起空腹",
      "recorded_at": 1710234567,
      "created_at": 1710234567
    }
  ]
}
```

---

### 创建记录

```http
POST /api/v1/records
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体:**
```json
{
  "metric_id": "20260312120000_def456",
  "value": 65.5,
  "text_value": "",
  "note": "晨起空腹",
  "recorded_at": 1710234567
}
```

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "20260312120000_jkl012",
    "metric_id": "20260312120000_def456",
    "metric_name": "体重",
    "value": 65.5,
    "text_value": "",
    "note": "晨起空腹",
    "recorded_at": 1710234567,
    "created_at": 1710234567
  }
}
```

---

### 批量创建记录

```http
POST /api/v1/records/bulk
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体:**
```json
{
  "records": [
    {
      "metric_id": "20260312120000_def456",
      "value": 65.5,
      "recorded_at": 1710234567
    },
    {
      "metric_id": "20260312120000_def456",
      "value": 65.8,
      "recorded_at": 1710320967
    }
  ]
}
```

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "created": 2
  }
}
```

---

### 更新记录

```http
PUT /api/v1/records/:id
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体:**
```json
{
  "metric_id": "20260312120000_def456",
  "value": 66.0,
  "note": "更新后的备注"
}
```

---

### 删除记录

```http
DELETE /api/v1/records/:id
Authorization: Bearer <token>
```

---

## 统计接口

### 获取趋势数据

```http
GET /api/v1/stats/trend?metric_id=xxx&days=30
Authorization: Bearer <token>
```

**查询参数:**
- `metric_id` (必填) - 指标 ID
- `days` (可选) - 天数，默认 30，最大 365

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "metric_id": "20260312120000_def456",
    "days": 30,
    "points": [
      {
        "time": 1710234567,
        "value": 65.5
      },
      {
        "time": 1710320967,
        "value": 65.8
      }
    ]
  }
}
```

---

### 获取汇总统计

```http
GET /api/v1/stats/summary?metric_id=xxx&days=30
Authorization: Bearer <token>
```

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "count": 30,
    "avg": 65.5,
    "min": 63.0,
    "max": 68.0,
    "latest": 66.0,
    "trend": "up"
  }
}
```

**trend 说明:**
- `up` - 上升趋势
- `down` - 下降趋势
- `stable` - 稳定

---

## 同步接口

### 数据同步

```http
POST /api/v1/sync
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体:**
```json
{
  "last_sync": 1710234567,
  "local_changes": [
    {
      "metric_id": "20260312120000_def456",
      "value": 65.5,
      "recorded_at": 1710234567
    }
  ],
  "device_id": "android_xxx",
  "device_name": "Samsung Galaxy S23",
  "app_version": "1.0.0"
}
```

**响应:**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "server_changes": [
      {
        "id": "20260312120000_mno345",
        "metric_id": "20260312120000_def456",
        "value": 65.8,
        "recorded_at": 1710320967,
        "created_at": 1710320967
      }
    ],
    "conflicts": [],
    "new_last_sync": 1710407367
  }
}
```

---

## 系统接口

### 健康检查

```http
GET /api/v1/health
```

**响应:**
```json
{
  "status": "ok",
  "message": "GreenBamboo server is running"
}
```

---

## 使用示例

### cURL

```bash
# 注册
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# 登录
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# 获取指标列表
curl -X GET http://localhost:3000/api/v1/metrics \
  -H "Authorization: Bearer <token>"

# 创建记录
curl -X POST http://localhost:3000/api/v1/records \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"metric_id":"xxx","value":65.5,"recorded_at":1710234567}'
```

---

**最后更新**: 2026-03-12
