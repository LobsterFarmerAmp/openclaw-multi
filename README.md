# OpenClaw Multi-Instance Docker Deployment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)

在一台电脑上运行多个独立的 OpenClaw 实例（多龙虾部署），每个实例拥有独立的性格、记忆、技能和配置。

## 特性

- 🦞 **多实例隔离** - 每个实例完全独立运行
- 🎭 **个性化配置** - 每个龙虾有独特的性格、角色和身份
- 🔌 **独立端口** - 自动分配端口，避免冲突
- 🧠 **独立记忆** - 每个实例有自己的长期记忆系统
- 🔧 **独立技能** - 可配置不同的技能组合
- 🔑 **独立API** - 支持不同的AI提供商配置
- 📱 **独立渠道** - 可接入不同的消息平台

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/yourusername/openclaw-multi.git
cd openclaw-multi
```

### 2. 创建个性化实例

```bash
# 创建管家龙虾（飞书渠道）
./scripts/generate-instance.sh \
  --id lobster-001 \
  --port 18001 \
  --role "管家" \
  --name "大管家" \
  --emoji "🎯" \
  --channels "feishu"

# 创建助手龙虾（Telegram渠道）
./scripts/generate-instance.sh \
  --id lobster-002 \
  --port 18002 \
  --role "助手" \
  --name "小助手" \
  --emoji "🤖" \
  --channels "telegram"
```

### 3. 配置 API Keys

编辑每个实例的 `.env` 文件：

```bash
vim instances/lobster-001/.env
```

添加你的 API Keys：
```bash
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

## 预定义角色

| 角色 | 性格特点 | 默认渠道 |
|------|----------|----------|
| 管家 | 高效干练，简洁直接，办事利落 | 飞书 |
| 助手 | 友好热情，耐心细致，乐于助人 | Telegram |
| 专家 | 严谨专业，深入浅出，注重细节 | Discord |
| 创意 | 富有创意，思维活跃，审美独特 | Slack |

## 管理命令

```bash
# 查看所有实例状态
./scripts/manage-instances.sh status-all

# 启动/停止/重启
./scripts/manage-instances.sh start lobster-001
./scripts/manage-instances.sh stop lobster-001
./scripts/manage-instances.sh restart lobster-001

# 查看日志
./scripts/manage-instances.sh logs lobster-001 -f

# 备份/恢复
./scripts/manage-instances.sh backup lobster-001
./scripts/manage-instances.sh restore lobster-001 backups/xxx.tar.gz

# 删除实例
./scripts/manage-instances.sh remove lobster-001
```

## 项目结构

```
openclaw-multi/
├── docker-compose.multi.yml      # 多实例编排文件
├── scripts/
│   ├── generate-instance.sh      # 实例生成脚本
│   └── manage-instances.sh       # 实例管理脚本
├── instances/                     # 实例数据目录（自动生成）
├── shared/
│   └── extensions/               # 共享扩展
├── README.md                      # 本文件
└── QUICKSTART.md                 # 快速开始指南
```

## 架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Host                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  lobster-001 │  │  lobster-002 │  │  lobster-003 │      │
│  │  Port:18001  │  │  Port:18002  │  │  Port:18003  │      │
│  │  大管家 🎯   │  │  小助手 🤖   │  │  技术专家 💡  │      │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
│  每个实例完全独立：独立配置、独立数据、独立网络              │
└─────────────────────────────────────────────────────────────┘
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

| 实例 | 端口 | 角色 |
|------|------|------|
| lobster-001 | 18001 | 管家 |
| lobster-002 | 18002 | 助手 |
| lobster-003 | 18003 | 专家 |
| lobster-004 | 18004 | 备用 |

## 环境要求

- Docker Engine 24.0+
- Docker Compose v2
- Bash 4.0+
- 至少 4GB RAM（每个实例约1GB）

## 许可证

MIT License

## 致谢

基于 [OpenClaw](https://github.com/openclaw/openclaw) 官方 Docker 方案扩展
