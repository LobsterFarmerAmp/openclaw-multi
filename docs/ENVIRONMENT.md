# 环境变量参考

## 全局环境变量

在 `.env` 文件中设置：

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `OPENCLAW_IMAGE` | Docker 镜像 | `ghcr.io/openclaw/openclaw:latest` |

## 实例特定环境变量

每个实例的 `.env` 文件：

### 基础配置

| 变量 | 说明 | 示例 |
|------|------|------|
| `INSTANCE_ID` | 实例唯一标识 | `lobster-001` |
| `INSTANCE_NAME` | 实例名称 | `大管家` |
| `INSTANCE_ROLE` | 实例角色 | `管家` |
| `INSTANCE_PORT` | 服务端口 | `18001` |

### API Keys

| 变量 | 说明 |
|------|------|
| `MOONSHOT_API_KEY` | Moonshot API Key |
| `OPENAI_API_KEY` | OpenAI API Key |
| `ANTHROPIC_API_KEY` | Anthropic API Key |

### 渠道配置

| 变量 | 说明 |
|------|------|
| `FEISHU_APP_ID` | 飞书应用 ID |
| `FEISHU_APP_SECRET` | 飞书应用密钥 |
| `TELEGRAM_BOT_TOKEN` | Telegram Bot Token |
| `DISCORD_BOT_TOKEN` | Discord Bot Token |
| `SLACK_BOT_TOKEN` | Slack Bot Token |
| `SLACK_APP_TOKEN` | Slack App Token |

## Docker Compose 环境变量

在 `docker-compose.multi.yml` 中使用：

```yaml
environment:
  - OPENCLAW_INSTANCE_ID=${INSTANCE_ID}
  - OPENCLAW_INSTANCE_NAME=${INSTANCE_NAME}
  - MOONSHOT_API_KEY=${MOONSHOT_API_KEY}
```
