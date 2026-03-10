# OpenClaw Multi-Instance Docker Deployment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)

在一台电脑上运行多个独立的 OpenClaw 实例，每个实例拥有独立的性格、记忆、技能和配置。

## ✨ 最新特性 (v2.3)

**独立密钥管理** - 每个实例有独立的 env 文件，使用通用命名

- 🔐 `envs/<instance>.env` 单独管理每个实例的密钥
- 📝 通用命名（如 `MOONSHOT_API_KEY`），不加实例ID前缀
- 🚀 docker-compose 自动挂载为容器环境变量
- 🛡️ envs/*.env 已加入 .gitignore，保护密钥安全

**Skill 自动继承** - 实例可自动复制主 workspace 中的 skills

- 🧠 配置文件中指定需要的 skills 列表
- 📁 生成时自动从主 workspace 复制到实例
- ⚠️ 主 workspace 中不存在的 skill 会自动跳过
- 🎯 每个实例可以有独立的 skill 组合

## 🎯 新架构特性

**配置文件驱动** - 每种配置独立成 YAML 文件，灵活自定义，不再硬编码

- 📄 **配置即代码** - `configs/*.yaml` 定义所有实例
- 🔄 **动态生成** - 脚本自动读取配置生成实例和 docker-compose
- 🧩 **灵活扩展** - 新增实例只需添加配置文件
- 🗂️ **清晰分离** - 配置、实例、数据完全解耦

## 快速开始

### 1. 准备环境

```bash
# 安装 yq (YAML 解析器)
# macOS: brew install yq
# Linux: wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod +x /usr/local/bin/yq
```

### 2. 创建配置文件

在 `configs/` 目录创建 YAML 配置：

```yaml
# configs/my-bot.yaml
id: my-bot
name: 我的助手
role: 助手
emoji: "🌟"
port: 18099
model: moonshot/kimi-k2.5
channels:
  - telegram
personality: "温暖贴心，善于倾听"
autostart: true
```

### 3. 生成实例

```bash
# 生成所有配置对应的实例
./scripts/generate-instances.sh --all --compose

# 或生成单个配置
./scripts/generate-instances.sh --config configs/my-bot.yaml
```

### 4. 配置 API Keys

为每个实例编辑 `envs/<instance-id>.env` 文件：

```bash
# envs/lobster-001.env - 大管家 (飞书)
MOONSHOT_API_KEY=sk-xxx
FEISHU_APP_ID=cli-xxx
FEISHU_APP_SECRET=xxx
TAVILY_API_KEY=tvly-xxx
```

使用**通用命名**（不加实例ID前缀）：
- `MOONSHOT_API_KEY` - AI模型
- `FEISHU_APP_ID` / `FEISHU_APP_SECRET` - 飞书
- `TELEGRAM_BOT_TOKEN` - Telegram
- `DISCORD_BOT_TOKEN` - Discord
- `TAVILY_API_KEY` - Tavily搜索
- `ANTHROPIC_API_KEY` - Claude Code
- `GITHUB_TOKEN` - GitHub API

### 5. 启动服务

```bash
docker compose -f docker-compose.multi.yml up -d
```

### 6. 访问

```
http://localhost:18099
```

## 配置文件格式

```yaml
# 必需字段
id: unique-id          # 实例唯一标识 (小写字母、数字、连字符)
name: 实例名称          # 显示名称
port: 18001            # 服务端口 (1024-65535)

# 可选字段
role: 助手             # 角色类型 (管家/助手/专家/创意/自定义)
emoji: "🤖"            # 表情符号
model: moonshot/kimi-k2.5  # AI 模型
channels:              # 接入渠道
  - feishu
  - telegram
personality: "性格描述"   # 性格特点 (不填则根据 role 自动生成)
voice: "说话风格"       # 说话风格 (不填则根据 role 自动生成)
autostart: true        # 是否自动启动 (默认 true，false 需用 profile 手动启动)
```

## 配置示例

### 管家角色 (飞书) + Skills
```yaml
# configs/butler.yaml
id: butler
name: 大管家
role: 管家
emoji: "🎯"
port: 18001
channels:
  - feishu

# Skill 配置 - 从主 workspace 复制指定的 skills
# 如果主 workspace 中不存在该 skill，则跳过
skills:
  - github
  - tavily-search
```

### 技术专家 (Discord + Telegram) + Skills
```yaml
# configs/expert.yaml
id: tech-expert
name: 技术专家
role: 专家
emoji: "💡"
port: 18002
model: openai/gpt-5.1-codex
channels:
  - discord
  - telegram

skills:
  - github
  - code-with-claude
  - tavily-search
```

### 自定义角色
```yaml
# configs/companion.yaml
id: companion
name: 陪伴助手
role: 生活助手
emoji: "🌙"
port: 18099
personality: "温柔耐心，善于倾听，提供情感支持"
voice: "温暖柔和，像朋友一样聊天"
channels:
  - telegram
```

## Skill 配置说明

实例可以自动继承主 workspace 中的 skills，实现技能复用。

### 工作原理

1. 在配置文件中通过 `skills` 字段指定需要的 skills 列表
2. 生成实例时，脚本会检查主 workspace (`../skills/` 或 `--skills-dir` 指定路径)
3. 存在的 skill 会被复制到实例的 `workspace/skills/` 目录
4. 不存在的 skill 会被跳过并输出警告

### 配置示例

```yaml
# configs/my-bot.yaml
id: my-bot
name: 我的助手
port: 18099

# 指定需要的 skills
skills:
  - github          # 会从 ../skills/github/ 复制
  - tavily-search   # 会从 ../skills/tavily-search/ 复制
  - custom-skill    # 如果不存在，会跳过并警告
```

### 指定 Skills 目录

```bash
# 使用环境变量
export MASTER_SKILLS_DIR=/path/to/your/skills
./scripts/generate-instances.sh --all --compose

# 使用命令行参数
./scripts/generate-instances.sh --all --compose --skills-dir /path/to/your/skills
```

## 管理命令

```bash
# 生成所有实例 + docker-compose
./scripts/generate-instances.sh --all --compose

# 生成单个配置
./scripts/generate-instances.sh --config configs/custom.yaml

# 强制重新生成 (保留数据)
./scripts/generate-instances.sh --all --force --compose

# 预览操作
./scripts/generate-instances.sh --dry-run

# 指定 skills 目录
./scripts/generate-instances.sh --all --compose --skills-dir /path/to/skills

# 管理运行中的实例
./scripts/manage-instances.sh status-all
./scripts/manage-instances.sh start butler
./scripts/manage-instances.sh stop butler
./scripts/manage-instances.sh logs butler -f
```

## 项目结构

```
openclaw-multi/
├── configs/                        # 配置文件目录 (你主要在这里工作)
│   ├── README.md                   # 配置格式说明
│   ├── lobster-001.yaml            # 管家配置
│   ├── lobster-002.yaml            # 助手配置
│   └── custom.yaml                 # 你的自定义配置
├── envs/                           # 密钥配置文件 (每个实例一个)
│   ├── README.md                   # 密钥配置说明
│   ├── lobster-001.env             # 大管家密钥
│   ├── lobster-002.env             # 小助手密钥
│   └── ...
├── scripts/
│   ├── generate-instances.sh       # 实例生成脚本 (v2.3)
│   └── manage-instances.sh         # 实例管理脚本
├── instances/                      # 生成的实例数据 (自动生成)
│   ├── butler/
│   ├── expert/
│   └── ...
├── docker-compose.multi.yml        # 自动生成的 compose 文件
└── README.md                       # 本文件
```

## 架构对比

### 旧架构 (已废弃)
- ❌ 实例配置硬编码在 docker-compose.multi.yml
- ❌ 新增实例需要修改脚本和 compose 文件
- ❌ 最多支持 4 个预定义实例

### 新架构 (当前)
- ✅ 配置文件驱动，每个实例一个 YAML 文件
- ✅ 新增实例只需添加配置文件
- ✅ 支持无限数量实例
- ✅ docker-compose 自动生成
- ✅ **独立密钥管理** - `envs/<instance>.env` 通用命名
- ✅ **Skill 自动继承** - 从主 workspace 复制 skills

## 预定义角色

| 角色 | 性格特点 | 说话风格 |
|------|----------|----------|
| 管家 | 高效干练，简洁直接，办事利落 | 专业、直接、不废话 |
| 助手 | 友好热情，耐心细致，乐于助人 | 温和、耐心、鼓励性 |
| 专家 | 严谨专业，深入浅出，注重细节 | 严谨、准确、条理清晰 |
| 创意 | 富有创意，思维活跃，审美独特 | 生动、形象、富有感染力 |

## 环境要求

- Docker Engine 24.0+
- Docker Compose v2
- Bash 4.0+
- yq (YAML 解析器)
- 至少 2GB RAM (每个实例约 500MB-1GB)

## 迁移指南

如果你使用的是旧版本：

1. 备份现有实例数据：
```bash
cp -r instances/ instances.backup/
```

2. 为现有实例创建配置文件：
```bash
# 参考 configs/lobster-001.yaml 等示例
```

3. 重新生成：
```bash
./scripts/generate-instances.sh --all --force --compose
```

4. 验证后删除备份：
```bash
docker compose -f docker-compose.multi.yml up -d
# 验证正常运行后
rm -rf instances.backup/
```

## 许可证

MIT License

## 致谢

基于 [OpenClaw](https://github.com/openclaw/openclaw) 官方 Docker 方案扩展
