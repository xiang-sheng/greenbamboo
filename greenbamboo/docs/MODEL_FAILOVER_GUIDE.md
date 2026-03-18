# 🔄 模型故障转移配置指南

> 当主模型不可用时，自动切换到备用模型

---

## 📋 什么是模型故障转移？

当你的主模型（如 Qwen）遇到以下问题时，故障转移会自动切换到备用模型：

- API 认证失败（Token 过期）
- 网络连接问题
- 服务不可用
- 速率限制

---

## ⚙️ 配置方法

### 方法 1: 编辑配置文件（推荐）

编辑 `~/.openclaw/openclaw.json`：

```json5
{
  "agents": {
    "defaults": {
      // 模型目录（允许使用的模型）
      "models": {
        "qwen-portal/coder-model": {
          "alias": "qwen"
        },
        "openai/gpt-4.1": {
          "alias": "gpt"
        },
        "anthropic/claude-sonnet-4-5": {
          "alias": "sonnet"
        },
        "google/gemini-2.0-flash-preview": {
          "alias": "gemini"
        }
      },
      
      // 主模型 + 故障转移列表
      "model": {
        "primary": "qwen-portal/coder-model",
        "fallbacks": [
          "openai/gpt-4.1",
          "anthropic/claude-sonnet-4-5",
          "google/gemini-2.0-flash-preview"
        ]
      },
      
      // 视觉模型故障转移
      "imageModel": {
        "primary": "qwen-portal/vision-model",
        "fallbacks": [
          "openai/gpt-4.1",
          "openrouter/google/gemini-2.0-flash-vision:free"
        ]
      }
    }
  }
}
```

---

### 方法 2: 使用 CLI 命令

```bash
# 设置主模型和故障转移
openclaw models set qwen-portal/coder-model \
  --fallbacks openai/gpt-4.1,anthropic/claude-sonnet-4-5

# 设置视觉模型故障转移
openclaw models set-image qwen-portal/vision-model \
  --fallbacks openai/gpt-4.1

# 添加单个故障转移模型
openclaw models fallback add google/gemini-2.0-flash-preview

# 查看当前配置
openclaw models list
```

---

### 方法 3: 使用 Control UI

1. 打开 [http://127.0.0.1:18789](http://127.0.0.1:18789)
2. 点击 **Config** 标签
3. 找到 `agents.defaults.model`
4. 编辑为对象格式：
   ```json
   {
     "primary": "qwen-portal/coder-model",
     "fallbacks": ["openai/gpt-4.1"]
   }
   ```
5. 保存配置

---

## 🎯 推荐配置方案

### 方案 A: 免费模型故障转移

```json5
{
  "agents": {
    "defaults": {
      "models": {
        "qwen-portal/coder-model": { "alias": "qwen" },
        "openrouter/google/gemini-2.0-flash:free": { "alias": "gemini-free" },
        "openrouter/meta/llama-3.1-405b-instruct:free": { "alias": "llama-free" }
      },
      "model": {
        "primary": "qwen-portal/coder-model",
        "fallbacks": [
          "openrouter/google/gemini-2.0-flash:free",
          "openrouter/meta/llama-3.1-405b-instruct:free"
        ]
      }
    }
  }
}
```

**优点**: 完全免费  
**缺点**: 免费模型可能有限速

---

### 方案 B: 商业模型故障转移

```json5
{
  "agents": {
    "defaults": {
      "models": {
        "qwen-portal/coder-model": { "alias": "qwen" },
        "openai/gpt-4.1": { "alias": "gpt" },
        "anthropic/claude-sonnet-4-5": { "alias": "sonnet" }
      },
      "model": {
        "primary": "qwen-portal/coder-model",
        "fallbacks": [
          "openai/gpt-4.1",
          "anthropic/claude-sonnet-4-5"
        ]
      }
    }
  }
}
```

**优点**: 质量稳定，速度快  
**缺点**: 需要付费 API Key

---

### 方案 C: 混合方案（推荐）

```json5
{
  "agents": {
    "defaults": {
      "models": {
        "qwen-portal/coder-model": { "alias": "qwen" },
        "openai/gpt-4.1": { "alias": "gpt" },
        "openrouter/google/gemini-2.0-flash:free": { "alias": "gemini-free" }
      },
      "model": {
        "primary": "qwen-portal/coder-model",
        "fallbacks": [
          "openai/gpt-4.1",              // 第一备用（商业）
          "openrouter/google/gemini-2.0-flash:free"  // 第二备用（免费）
        ]
      }
    }
  }
}
```

**优点**: 平衡质量和成本  
**缺点**: 需要配置多个 API

---

## 🔑 API Key 配置

在 `~/.openclaw/openclaw.json` 添加：

```json5
{
  "auth": {
    "profiles": {
      // Qwen (当前使用)
      "qwen-portal:default": {
        "provider": "qwen-portal",
        "mode": "oauth"
      },
      
      // OpenAI
      "openai:default": {
        "provider": "openai",
        "apiKey": "sk-xxxxxxxxxxxxx"
      },
      
      // Anthropic
      "anthropic:default": {
        "provider": "anthropic",
        "apiKey": "sk-ant-xxxxxxxxxxxxx"
      },
      
      // Google
      "google:default": {
        "provider": "google",
        "apiKey": "xxxxxxxxxxxxx"
      }
    }
  }
}
```

或使用环境变量：

```bash
export OPENAI_API_KEY="sk-xxxxxxxxxxxxx"
export ANTHROPIC_API_KEY="sk-ant-xxxxxxxxxxxxx"
export GOOGLE_API_KEY="xxxxxxxxxxxxx"
```

---

## 🧪 测试故障转移

### 测试方法 1: 临时禁用主模型

```bash
# 临时设置一个不存在的模型为主模型
openclaw models set invalid/model

# 发送消息，应该自动切换到 fallback

# 恢复配置
openclaw models set qwen-portal/coder-model
```

### 测试方法 2: 查看日志

```bash
# 查看故障转移日志
openclaw logs | grep -i "fallback\|failover"
```

### 测试方法 3: 使用 /status 命令

在聊天中发送：
```
/status
```

查看当前使用的模型和故障转移状态。

---

## 📊 故障转移优先级

```
主模型 (primary)
    ↓ 失败
备用 1 (fallbacks[0])
    ↓ 失败
备用 2 (fallbacks[1])
    ↓ 失败
备用 3 (fallbacks[2])
    ↓ 失败
CLI 后端 (如果配置)
    ↓ 失败
错误提示用户
```

---

## ⚠️ 注意事项

### 1. 故障转移触发条件

- ✅ API 认证失败（401/403）
- ✅ 网络连接超时
- ✅ 服务不可用（5xx）
- ✅ 速率限制（429）
- ❌ 模型返回错误内容（不会触发）
- ❌ 用户取消请求（不会触发）

### 2. 故障转移限制

- 每次请求最多尝试 3 个模型
- 故障转移仅在当前会话有效
- 不会自动切换回主模型（需要新会话）

### 3. 性能影响

- 故障转移会增加响应时间
- 每次切换约增加 2-5 秒延迟
- 建议设置 2-3 个备用模型

---

## 🔧 高级配置

### 按频道配置不同模型

```json5
{
  "channels": {
    "modelByChannel": {
      "telegram": {
        "*": "openai/gpt-4.1"  // Telegram 使用 GPT-4
      },
      "discord": {
        "123456789": "anthropic/claude-sonnet-4-5"  // 特定频道使用 Claude
      }
    }
  }
}
```

### 按任务配置模型

```json5
{
  "agents": {
    "list": [
      {
        "id": "main",
        "model": {
          "primary": "qwen-portal/coder-model",
          "fallbacks": ["openai/gpt-4.1"]
        }
      },
      {
        "id": "vision",
        "model": {
          "primary": "qwen-portal/vision-model",
          "fallbacks": ["openai/gpt-4.1"]
        }
      },
      {
        "id": "coding",
        "model": {
          "primary": "openai/gpt-4.1",
          "fallbacks": ["anthropic/claude-sonnet-4-5"]
        }
      }
    ]
  }
}
```

### 配置 CLI 后端作为最后备用

```json5
{
  "agents": {
    "defaults": {
      "cliBackends": {
        "claude-cli": {
          "command": "/usr/local/bin/claude",
          "modelArg": "--model",
          "sessionArg": "--session"
        }
      }
    }
  }
}
```

---

## 📝 快速配置模板

### 复制即用（免费方案）

```bash
cat >> ~/.openclaw/openclaw.json << 'EOF'

// 在 agents.defaults 中添加或修改：
"model": {
  "primary": "qwen-portal/coder-model",
  "fallbacks": [
    "openrouter/google/gemini-2.0-flash:free",
    "openrouter/meta/llama-3.1-405b-instruct:free"
  ]
}
EOF
```

### 复制即用（商业方案）

```bash
cat >> ~/.openclaw/openclaw.json << 'EOF'

// 在 agents.defaults 中添加或修改：
"model": {
  "primary": "qwen-portal/coder-model",
  "fallbacks": [
    "openai/gpt-4.1",
    "anthropic/claude-sonnet-4-5"
  ]
}
EOF
```

---

## 🆘 故障排除

### 问题 1: 故障转移不生效

**检查**:
```bash
# 验证配置
openclaw config get agents.defaults.model

# 检查模型是否在允许列表
openclaw models list
```

**解决**: 确保 fallbacks 中的模型在 `agents.defaults.models` 中定义

### 问题 2: API Key 错误

**检查**:
```bash
# 查看认证配置
openclaw config get auth.profiles

# 检查环境变量
echo $OPENAI_API_KEY
```

**解决**: 在 `auth.profiles` 中添加对应的 API Key

### 问题 3: 配置不生效

**解决**:
```bash
# 重启 Gateway
openclaw gateway restart

# 或重新加载配置
openclaw config reload
```

---

## 📚 相关文档

- [配置参考](https://docs.openclaw.ai/gateway/configuration-reference)
- [模型管理](https://docs.openclaw.ai/concepts/models)
- [故障转移机制](https://docs.openclaw.ai/concepts/model-failover)

---

**最后更新**: 2026-03-15  
**适用版本**: OpenClaw 2026.2+
