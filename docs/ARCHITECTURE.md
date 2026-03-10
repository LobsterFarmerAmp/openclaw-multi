# 架构设计文档 v2

## 概述

OpenClaw Multi-Instance 方案允许在一台物理机上运行多个完全独立的 OpenClaw 实例。**v2 架构采用配置文件驱动设计**，通过 YAML 配置文件定义实例，实现灵活的多实例部署。

## 设计目标

1. **配置驱动** - YAML 文件定义所有实例，无需修改脚本
2. **完全隔离** - 每个实例独立运行，互不干扰
3. **动态生成** - docker-compose 根据配置自动生成
4. **易于扩展** - 新增实例只需添加配置文件
5. **数据安全** - 独立的数据存储和备份机制

## 架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Docker Host                                │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    configs/ 目录                              │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐               │   │
│  │  │butler.yaml│  │expert.yaml│  │custom.yaml│  ...          │   │
│  │  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘               │   │
│  │        │              │              │                       │   │
│  │        └──────────────┼──────────────┘                       │   │
│  │                       ▼                                      │   │
│  │            ┌──────────────────────┐                         │   │
│  │            │ generate-instances.sh│                         │   │
│  │            │   (读取配置→生成实例)  │                         │   │
│  │            └──────────┬───────────┘                         │   │
│  │                       │                                      │   │
│  │         ┌─────────────┼─────────────┐                        │   │
│  │         ▼             ▼             ▼                        │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐                │   │
│  │  │instances/ │  │docker-    │  │instance-  │                │   │
│  │  │butler/    │  │compose.   │  │info.json  │                │   │
│  │  │expert/    │  │multi.yml  │  │           │                │   │
│  │  │custom/    │  │(自动生成) │  │           │                │   │
│  │  └───────────┘  └───────────┘  └───────────┘                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Docker Compose (运行时)                         │   │
│  │                                                              │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │   │
│  │  │ butler      │  │ expert      │  │ custom      │         │   │
│  │  │ :18001      │  │ :18002      │  │ :18099      │         │   │
│  │  │ 🎯管家      │  │ 💡专家      │  │ 🌟自定义    │         │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘         │   │
│  │       │                │                │                    │   │
│  │  ┌────┴────┐     ┌────┴────┐     ┌────┴────┐               │   │
│  │  │config   │     │config   │     │config   │               │   │
│  │  │workspace│     │workspace│     │workspace│               │   │
│  │  │data     │     │data     │     │data     │               │   │
│  │  └─────────┘     └─────────┘     └─────────┘               │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## 核心组件

### 1. 配置文件 (configs/*.yaml)

**核心创新**：配置与代码分离，每个实例一个 YAML 文件

```yaml
# configs/butler.yaml
id: butler
name: 大管家
role: 管家
emoji: "🎯"
port: 18001
channels:
  - feishu
autostart: true
```

### 2. 实例生成器 (generate-instances.sh v2)

```
输入：configs/*.yaml
       ↓
    解析配置
       ↓
    验证 (ID 唯一性、端口冲突)
       ↓
    生成实例目录结构
       ↓
    生成 workspace 文件 (SOUL.md, IDENTITY.md 等)
       ↓
    生成 config/openclaw.json
       ↓
    生成 docker-compose.multi.yml
       ↓
输出：instances/<id>/
      docker-compose.multi.yml
```

### 3. 实例目录结构

```
instances/<id>/
├── .env                    # 实例环境变量
├── instance-info.json      # 实例元数据
├── config/
│   └── openclaw.json       # OpenClaw 配置
├── workspace/
│   ├── SOUL.md            # 性格、价值观
│   ├── IDENTITY.md        # 身份标识
│   ├── USER.md            # 用户信息
│   ├── AGENTS.md          # 工作区指南
│   ├── TOOLS.md           # 本地工具配置
│   ├── MEMORY.md          # 长期记忆
│   └── HEARTBEAT.md       # 定期检查任务
└── data/
    ├── sessions/          # 会话数据
    ├── credentials/       # 凭证存储
    └── logs/              # 日志文件
```

### 4. Docker Compose 编排

**动态生成**，每个配置对应两个服务：

```yaml
services:
  openclaw-<id>:
    # 主服务 - OpenClaw Gateway
    ports: ["<port>:18789"]
    volumes:
      - ./instances/<id>/config:/home/node/.openclaw
      - ./instances/<id>/workspace:/home/node/.openclaw/workspace
      - ./instances/<id>/data:/home/node/.openclaw/data

  openclaw-cli-<id>:
    # CLI 服务 - 用于命令行操作
    network_mode: "service:openclaw-<id>"
    profiles: ["cli-<id>"]
```

## 工作流程

### 新增实例

```bash
# 1. 创建配置文件
cat > configs/my-bot.yaml <<EOF
id: my-bot
name: 我的助手
port: 18099
channels:
  - telegram
EOF

# 2. 生成实例
./scripts/generate-instances.sh --all --compose

# 3. 配置 API Keys
# 编辑 .env 添加 MY_BOT_TELEGRAM_BOT_TOKEN=xxx

# 4. 启动
docker compose -f docker-compose.multi.yml up -d
```

### 修改配置

```bash
# 1. 编辑配置文件
vim configs/my-bot.yaml

# 2. 重新生成 (保留数据)
./scripts/generate-instances.sh --config configs/my-bot.yaml --force

# 3. 重启实例
docker compose -f docker-compose.multi.yml restart openclaw-my-bot
```

### 删除实例

```bash
# 1. 删除配置文件
rm configs/my-bot.yaml

# 2. 停止并删除容器
docker compose -f docker-compose.multi.yml rm -sf openclaw-my-bot openclaw-cli-my-bot

# 3. 删除实例数据
rm -rf instances/my-bot

# 4. 重新生成 compose
./scripts/generate-instances.sh --compose
```

## 数据流

```
用户消息 → Channel(飞书/Telegram/Discord) 
              ↓
         Gateway(:18789)
              ↓
    实例独立处理流程
    ┌─────────────────┐
    │  Agent Core     │
    │  + Memory       │
    │  + Skills       │
    │  + Tools        │
    └─────────────────┘
              ↓
         响应返回
```

## 配置字段说明

| 字段 | 必需 | 类型 | 说明 |
|------|------|------|------|
| id | ✓ | string | 实例唯一标识，只能包含小写字母、数字、连字符 |
| name | ✓ | string | 实例显示名称 |
| port | ✓ | number | 服务端口 (1024-65535) |
| role | ✗ | string | 角色类型，影响默认性格 |
| emoji | ✗ | string | 表情符号 |
| model | ✗ | string | AI 模型 (默认：moonshot/kimi-k2.5) |
| channels | ✗ | array | 接入渠道列表 |
| personality | ✗ | string | 性格描述 (不填则根据 role 生成) |
| voice | ✗ | string | 说话风格 (不填则根据 role 生成) |
| autostart | ✗ | boolean | 是否自动启动 (默认：true) |

## 安全设计

1. **网络隔离** - 每个实例独立的 Docker 网络
2. **数据隔离** - 独立的卷挂载，实例间无法访问彼此数据
3. **配置隔离** - 每个实例独立的 API Keys 和凭证
4. **权限控制** - CLI 容器使用 `no-new-privileges` 和 `cap_drop`

## 版本对比

| 特性 | v1 (旧) | v2 (新) |
|------|---------|---------|
| 配置方式 | 命令行参数 | YAML 配置文件 |
| 实例上限 | 4 个硬编码 | 无限 |
| docker-compose | 手动维护 | 自动生成 |
| 新增实例 | 修改脚本 + compose | 添加配置文件 |
| 配置验证 | 无 | ID/端口冲突检测 |
| 文档化 | 分散 | 配置即文档 |

## 扩展性

- **无限实例** - 只受服务器资源限制
- **自定义角色** - 通过 personality/voice 自由定义
- **多模型支持** - 每个实例可使用不同 AI 模型
- **混合渠道** - 单个实例可接入多个渠道
- **Profile 控制** - 通过 autostart 控制哪些实例默认启动

## 故障排查

### 配置验证失败
```bash
# 检查 YAML 格式
yq eval '.' configs/my-bot.yaml

# 检查 ID 合法性
# id 必须匹配：^[a-z0-9-]+$，长度 3-32

# 检查端口冲突
# 确保没有其他配置使用相同端口
```

### 实例启动失败
```bash
# 查看日志
docker compose -f docker-compose.multi.yml logs openclaw-<id>

# 验证配置
./scripts/manage-instances.sh validate <id>

# 检查 .env 配置
cat instances/<id>/.env
```
