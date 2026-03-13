# OpenClaw Multi-Session Architecture

单 Gateway + 多 Session 架构，在同一 Gateway 内运行多个独立人格。

## 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenClaw Gateway                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Session    │  │  Session    │  │  Session    │         │
│  │  lobster-001│  │  butler     │  │  custom     │         │
│  │  (小博士)   │  │  (大管家)   │  │  (自定义)   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
│  共享: skills/ | tools/ | extensions/ | channels config     │
└─────────────────────────────────────────────────────────────┘
```

## 目录结构

```
openclaw-multi/
├── personas/                   # 角色定义
│   └── lobster-001.yaml        # 小博士 - 博士研究生
│
├── sessions/                   # Session 工作区（自动生成）
│   └── lobster-001/            # 每个角色的独立记忆
│       ├── SOUL.md
│       ├── IDENTITY.md
│       ├── MEMORY.md
│       └── USER.md
│
├── shared/                     # 共享资源
│   ├── skills/                 # 全局 skills
│   └── extensions/             # 扩展
│
├── scripts/
│   ├── init-persona.sh         # 初始化角色 Session
│   ├── list-personas.sh        # 列出所有角色
│   └── migrate-from-docker.sh  # 从旧架构迁移
│
└── README.md
```

## 快速开始

### 1. 定义角色

在 `personas/` 创建 YAML 配置：

```yaml
# personas/my-assistant.yaml
id: my-assistant
name: 我的助手
emoji: "🌟"
model: moonshot/kimi-k2.5

role: 助手

personality: |
  友好热情，耐心细致，乐于助人...

voice: |
  温和、耐心、鼓励性...

channels:
  telegram:
    enabled: true

skills:
  - github
  - tavily-search
```

### 2. 初始化 Session

```bash
# 初始化单个角色
./scripts/init-persona.sh personas/lobster-001.yaml

# 或初始化所有角色
./scripts/init-persona.sh --all
```

这会创建 `sessions/<id>/` 目录，包含独立的记忆文件。

### 3. 查看角色列表

```bash
./scripts/list-personas.sh
```

### 4. 使用 Session

通过 `session_key` 指定角色：

```bash
# 与小博士对话
openclaw chat --session lobster-001

# 或大管家
openclaw chat --session butler
```

## Channel 路由

在 Gateway 配置中指定默认 Session：

```json
{
  "channels": {
    "feishu": {
      "enabled": true,
      "defaultSession": "lobster-001"
    },
    "telegram": {
      "enabled": true,
      "defaultSession": "butler"
    }
  }
}
```

## 与旧 Docker 架构对比

| 特性 | 旧架构 (Docker) | 新架构 (Multi-Session) |
|------|----------------|----------------------|
| 进程数 | N 个容器 | 1 个 Gateway |
| 内存 | N × 500MB | 500MB + Session 开销 |
| 端口 | N 个 | 1 个 |
| 扩展性 | 需新建容器 | 新增 YAML 即可 |
| 数据共享 | 需手动复制 skills | 全局共享 |

## 迁移指南

1. 备份现有数据
2. 运行迁移脚本：
   ```bash
   ./scripts/migrate-from-docker.sh
   ```
3. 初始化新 Session：
   ```bash
   ./scripts/init-persona.sh --all
   ```
4. 停止旧容器，使用新架构

## License

MIT
