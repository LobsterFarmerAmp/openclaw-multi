# 常见问题

## 部署问题

### Q: 端口被占用怎么办？

A: 使用不同的端口创建实例：
```bash
./scripts/generate-instance.sh --id lobster-005 --port 18005 ...
```

### Q: 如何查看端口使用情况？

A: 
```bash
./scripts/manage-instances.sh ports
```

### Q: 容器启动失败？

A: 检查日志：
```bash
./scripts/manage-instances.sh logs lobster-001
```

## 配置问题

### Q: 如何修改实例的性格？

A: 编辑 `instances/<实例ID>/workspace/SOUL.md`

### Q: 如何更换 AI 模型？

A: 编辑 `instances/<实例ID>/config/openclaw.json` 中的 `agent.model`

### Q: 如何添加新的消息渠道？

A: 编辑 `instances/<实例ID>/config/openclaw.json` 的 `channels` 部分

## 数据管理

### Q: 如何备份所有实例？

A:
```bash
./scripts/manage-instances.sh backup-all
```

### Q: 如何迁移实例到另一台机器？

A:
1. 在原机器备份：`./scripts/manage-instances.sh backup lobster-001`
2. 复制备份文件到新机器
3. 在新机器恢复：`./scripts/manage-instances.sh restore lobster-001 backups/xxx.tar.gz`

### Q: 实例数据存储在哪里？

A: 每个实例的数据在 `instances/<实例ID>/` 目录下：
- `config/` - 配置文件
- `workspace/` - 工作空间（性格、记忆等）
- `data/` - 运行时数据

## 性能问题

### Q: 运行多个实例需要多少内存？

A: 建议每个实例分配至少 1GB RAM，4个实例建议 4-6GB。

### Q: 如何限制实例资源使用？

A: 在 `docker-compose.multi.yml` 中添加资源限制：
```yaml
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '1.0'
```
