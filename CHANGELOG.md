# Changelog

所有重要的更改都将记录在此文件中。

## [2.0.0] - 2026-03-10

### 🎯 重大变更 - 配置文件驱动架构

**配置与代码分离** - 不再硬编码实例配置，改用 YAML 配置文件驱动

### 新增
- **配置目录** (`configs/`) - 每个实例一个 YAML 配置文件
- **新脚本** (`generate-instances.sh`) - 读取配置动态生成实例和 docker-compose
- **配置验证** - 自动检测 ID 冲突和端口冲突
- **自动生成 docker-compose** - 根据配置动态生成服务定义
- **无限实例支持** - 不再限制实例数量
- **autostart 控制** - 通过 `autostart: false` 控制哪些实例默认启动

### 配置文件格式
```yaml
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

### 改进
- 新增实例只需添加配置文件，无需修改脚本
- docker-compose.yml 自动生成，无需手动维护
- 配置即文档，更清晰直观
- 支持自定义角色，不再局限于预定义模板

### 弃用
- `generate-instance.sh` (命令行参数方式) - 迁移到 `generate-instances.sh` (配置文件方式)
- 硬编码的 docker-compose.multi.yml - 现在由脚本自动生成

### 迁移指南
1. 为现有实例创建 YAML 配置文件 (参考 `configs/lobster-*.yaml`)
2. 运行 `./scripts/generate-instances.sh --all --force --compose`
3. 验证后删除旧的硬编码配置

---

## [1.0.0] - 2026-03-09

### 新增
- 初始版本发布
- 支持多实例 Docker 部署
- 实例生成脚本 (`generate-instance.sh`)
- 实例管理脚本 (`manage-instances.sh`)
- 预定义角色模板（管家、助手、专家、创意）
- 独立端口分配机制
- 个性化配置文件生成
- 完整的文档和快速开始指南

### 特性
- 每个实例完全隔离运行
- 独立的性格、记忆、技能配置
- 支持多种消息渠道（飞书、Telegram、Discord 等）
- 灵活的角色自定义
- 备份和恢复功能
