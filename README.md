# OpenClaw Multi-Instance Docker Deployment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)

在一台电脑上运行多个独立的 OpenClaw 实例，每个实例拥有独立的性格、记忆、技能和配置。

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

编辑全局 `.env` 文件：

```bash
# 基础配置
OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:latest

# 实例特定配置
MY_BOT_MOONSHOT_API_KEY=your_key_here
MY_BOT_TELEGRAM_BOT_TOKEN=your_token_here
```

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

### 管家角色 (飞书)
```yaml
# configs/butler.yaml
id: butler
name: 大管家
role: 管家
emoji: "🎯"
port: 18001
channels:
  - feishu
```

### 技术专家 (Discord + Telegram)
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
├── scripts/
│   ├── generate-instances.sh       # 实例生成脚本 (v2)
│   └── manage-instances.sh         # 实例管理脚本
├── instances/                      # 生成的实例数据 (自动生成)
│   ├── butler/
│   ├── expert/
│   └── ...
├── docker-compose.multi.yml        # 自动生成的 compose 文件
├── .env                            # 全局环境变量 (API Keys 等)
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
