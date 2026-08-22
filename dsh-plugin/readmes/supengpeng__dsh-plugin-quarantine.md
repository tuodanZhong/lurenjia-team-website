# dsh-plugin-quarantine

DeepSeek Harness 插件崩溃隔离与安全启动恢复工具集。

> 📖 完整安装与使用说明见 [INSTALL.md](INSTALL.md)

## 组成

- `src/plugin-quarantine.ts` — 进程内看护插件：捕获 `uncaughtException` / `unhandledRejection` / `process.exit`，自动隔离肇事插件并保活。
- `supervisor.ts` — 外部 supervisor / 安全模式：解决“插件安装后下次启动服务起不来”，自动隔离可疑 bundle / patch entry 并重启。
- `test-quarantine.ts` + `fixtures/` — 冒烟测试与坏插件夹具。
- `cordis.example.yml` — 挂载示例。

## 快速开始

```bash
# 放入 DeepSeek Harness scratch-plugin 后
pnpm dsh web --patch ./scratch-plugin/cordis.example.yml

# 冒烟测试
pnpm exec tsx scratch-plugin/test-quarantine.ts

# 外部 supervisor
pnpm exec tsx scratch-plugin/supervisor.ts --profile web
```

更多配置、命令、故障排查见 [INSTALL.md](INSTALL.md)。

## 能力

- 运行时热装插件崩溃：异常 / 未处理拒绝 / `process.exit` 自动隔离
- 官方 `@deepseek-ai/dsh-*` 插件保护
- 重复崩溃冷却
- 手动隔离 Loader / 动态 Cordis 插件
- 启动崩溃安全模式：自动禁用可疑 bundle / patch entry 并重启
- 重启退避，避免重启风暴
- 崩溃原因与日志落盘，支持 `--report` 查看

## 边界

进程内看护无法阻止原生崩溃或死循环；这类场景由外部 supervisor 负责。
