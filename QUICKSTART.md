# OpenClaw 多实例部署方案

## 快速开始

### 1. 克隆仓库并进入目录

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

### 2. 创建多个个性化实例

```bash
# 创建管家龙虾（飞书渠道）
./scripts/generate-instance.sh \
  --id lobster-001 \
  --port 18001 \
  --role "管家" \
  --name "大管家" \
  --emoji "🎯" \
  --personality "高效干练，简洁直接，办事利落，注重效率" \
  --channels "feishu"

# 创建助手龙虾（Telegram渠道）
./scripts/generate-instance.sh \
  --id lobster-002 \
  --port 18002 \
  --role "助手" \
  --name "小助手" \
  --emoji "🤖" \
  --personality "友好热情，耐心细致，乐于助人，善于倾听" \
  --channels "telegram"

# 创建专家龙虾（Discord渠道）
./scripts/generate-instance.sh \
  --id lobster-003 \
  --port 18003 \
  --role "专家" \
  --name "技术专家" \
  --emoji "💡" \
  --personality "严谨专业，深入浅出，注重细节，追求精确" \
  --channels "discord"
```

### 3. 配置 API Keys

编辑每个实例的 `.env` 文件：

```bash
# 管家龙虾
vim instances/lobster-001/.env

# 添加你的 API Keys
MOONSHOT_API_KEY=your_key_here
FEISHU_APP_ID=your_app_id
FEISHU_APP_SECRET=your_app_secret
```

### 4. 启动所有实例

```bash
docker compose -f docker-compose.multi.yml up -d
```

### 5. 访问控制面板

- 大管家: http://localhost:18001
- 小助手: http://localhost:18002
- 技术专家: http://localhost:18003

## 管理命令

```bash
# 查看状态
./scripts/manage-instances.sh status-all

# 启动/停止/重启单个实例
./scripts/manage-instances.sh start lobster-001
./scripts/manage-instances.sh stop lobster-001
./scripts/manage-instances.sh restart lobster-001

# 查看日志
./scripts/manage-instances.sh logs lobster-001 -f

# 备份/恢复
./scripts/manage-instances.sh backup lobster-001
./scripts/manage-instances.sh restore lobster-001 backups/lobster-001_20260309_120000.tar.gz

# 删除实例
./scripts/manage-instances.sh remove lobster-001
```

## 个性化配置

每个实例都有独立的配置文件：

| 文件 | 用途 |
|------|------|
| `workspace/SOUL.md` | 性格、价值观、行为准则 |
| `workspace/IDENTITY.md` | 身份标识（名字、表情等） |
| `workspace/USER.md` | 用户信息 |
| `workspace/MEMORY.md` | 长期记忆 |
| `config/openclaw.json` | 系统配置（API、渠道等） |

## 端口规划

| 实例 | 端口 | 角色 | 渠道 |
|------|------|------|------|
| lobster-001 | 18001 | 管家 | 飞书 |
| lobster-002 | 18002 | 助手 | Telegram |
| lobster-003 | 18003 | 专家 | Discord |
| lobster-004 | 18004 | 备用 | 自定义 |

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Host                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  lobster-001 │  │  lobster-002 │  │  lobster-003 │      │
│  │  Port:18001  │  │  Port:18002  │  │  Port:18003  │      │
│  │  大管家 🎯   │  │  小助手 🤖   │  │  技术专家 💡  │      │
│  │  飞书        │  │  Telegram   │  │  Discord    │       │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
│  每个实例完全独立：                                          │
│  - 独立配置                                                  │
│  - 独立数据                                                  │
│  - 独立网络                                                  │
│  - 独立性格                                                  │
└─────────────────────────────────────────────────────────────┘
```
