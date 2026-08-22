# dsh-workspace-digest

DeepSeek Harness 组合包（bundle）：注册工具 `workspace_digest`，按目录列出文件名。

符合官方「打包与安装插件」：`package.json` 声明 `dsh.bundle`，用 `dsh plugin add` 装进 profile，无需 `--patch`。

## 安装

本机 checkout：

```bash
dsh plugin --profile web add /path/to/dsh-workspace-digest
```

tarball（不跑 `prepare`，也不需要 npm 登录）：

```bash
pnpm pack
dsh plugin --profile web add ./dsh-workspace-digest-0.1.0.tgz
```

GitHub（需允许该包的 `prepare`，本包是纯 JS，无 prepare）：

```bash
dsh plugin --profile web add github:cui-stack/dsh-workspace-digest
```

然后：

```bash
dsh --profile web --dump-config   # 应出现 # == dsh-workspace-digest
dsh web
```

## 配置

`cordis.patch.yml` 里的 `maxEntries`（默认 20）。用户可在 profile 的 `cordis.patch.yml` 按 `id: workspace-digest` 整行覆盖。

## 验证

Web UI 选一个 workspace，标准模式发送：

`用 workspace_digest 工具列出当前 workspace 目录的文件`

Trajectory 里应有 `workspace_digest` 调用。
