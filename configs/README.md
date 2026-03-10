# OpenClaw 多实例配置目录

此目录存放所有 OpenClaw 实例的配置文件。每个 `.yaml` 文件对应一个实例配置。

## 配置文件格式

```yaml
# 实例唯一标识
id: lobster-001

# 基础信息
name: 大管家
role: 管家
emoji: "🎯"

# 服务端口（宿主机端口）
port: 18001

# AI 模型配置
model: moonshot/kimi-k2.5

# 接入渠道（可选）
channels:
  - feishu
  # - telegram
  # - discord

# 性格描述（可选，默认根据 role 自动生成）
personality: "高效干练，简洁直接，办事利落，注重效率"

# 说话风格（可选，默认根据 role 自动生成）
voice: "专业、直接、不废话，行动导向"

# 环境变量（可选，会合并到容器的 environment 中）
env:
  CUSTOM_VAR: "value"

# 数据卷额外挂载（可选）
volumes:
  - /host/path:/container/path:ro

# 是否自动启动（可选，默认 true）
autostart: true
```

## 示例配置

### 管家角色（飞书）
```yaml
id: lobster-butler
name: 大管家
role: 管家
emoji: "🎯"
port: 18001
model: moonshot/kimi-k2.5
channels:
  - feishu
```

### 技术专家（Telegram + Discord）
```yaml
id: lobster-expert
name: 技术专家
role: 专家
emoji: "💡"
port: 18002
model: openai/gpt-5.1-codex
channels:
  - telegram
  - discord
personality: "严谨专业，深入浅出，注重细节，追求精确"
```

### 自定义角色
```yaml
id: my-custom-bot
name: 小助手
role: 生活助手
emoji: "🌟"
port: 18099
model: moonshot/kimi-k2.5
channels:
  - telegram
personality: "温暖贴心，善于倾听，提供生活建议"
voice: "亲切自然，像朋友一样聊天"
```

## 使用流程

1. **创建配置**：在此目录新建 `.yaml` 文件
2. **生成实例**：运行 `./scripts/generate-instances.sh`
3. **启动服务**：运行 `docker compose up -d`

## 注意事项

- `id` 必须唯一，只能包含小写字母、数字和连字符
- `port` 必须唯一，避免冲突
- 修改配置后需要重新生成实例（会保留已有数据）
- 删除配置文件不会自动删除已有实例，需手动清理
