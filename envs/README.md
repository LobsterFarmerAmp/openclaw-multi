# OpenClaw Multi-Instance 密钥配置

此目录存放每个实例的环境变量配置文件。

## 命名规则

每个实例对应一个 `.env` 文件，文件名与实例 ID 一致：
- `lobster-001.env` → 对应 lobster-001 实例
- `lobster-002.env` → 对应 lobster-002 实例

## 密钥命名（通用格式）

使用通用命名，**不要**加实例ID前缀：

```bash
# AI 模型
MOONSHOT_API_KEY=your_moonshot_api_key

# 渠道配置
FEISHU_APP_ID=your_feishu_app_id
FEISHU_APP_SECRET=your_feishu_app_secret
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
DISCORD_BOT_TOKEN=your_discord_bot_token

# Skill 配置
TAVILY_API_KEY=your_tavily_api_key
ANTHROPIC_API_KEY=your_anthropic_api_key
GITHUB_TOKEN=your_github_token
```

## 示例

### lobster-001.env (大管家 - 飞书)
```bash
# AI 模型
MOONSHOT_API_KEY=sk-xxx

# 飞书渠道
FEISHU_APP_ID=cli_xxx
FEISHU_APP_SECRET=xxx

# Skills
TAVILY_API_KEY=tvly-xxx
```

### lobster-002.env (小助手 - Telegram)
```bash
# AI 模型
MOONSHOT_API_KEY=sk-xxx

# Telegram 渠道
TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11

# Skills
TAVILY_API_KEY=tvly-xxx
```

### lobster-003.env (技术专家 - Discord)
```bash
# AI 模型
MOONSHOT_API_KEY=sk-xxx

# Discord 渠道
DISCORD_BOT_TOKEN=MTAxMDI0...xxx

# Skills
TAVILY_API_KEY=tvly-xxx
ANTHROPIC_API_KEY=sk-ant-xxx
GITHUB_TOKEN=ghp_xxx
```

## 注意事项

1. **每个实例独立配置** - 不同实例可以用不同的密钥
2. **通用命名** - 不要在密钥名中加实例ID
3. **安全** - 此目录已加入 .gitignore，不会被提交到 git
4. **必需密钥** - 根据实例启用的 channels 和 skills 配置对应密钥
