# 贡献指南

感谢您对 OpenClaw Multi-Instance 项目的关注！

## 如何贡献

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

## 开发环境设置

```bash
# 克隆仓库
git clone https://github.com/yourusername/openclaw-multi.git
cd openclaw-multi

# 创建测试实例
./scripts/generate-instance.sh --id test-001 --port 18001 --role "测试" --name "测试龙虾"

# 验证配置
./scripts/manage-instances.sh validate test-001
```

## 代码规范

- 使用 2 空格缩进
- 脚本添加适当的错误处理
- 更新相关文档

## 报告问题

请使用 GitHub Issues 报告问题，并提供：
- 问题描述
- 复现步骤
- 环境信息（OS, Docker版本等）
- 相关日志
