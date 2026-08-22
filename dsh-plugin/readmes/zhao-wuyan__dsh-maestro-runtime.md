# dsh-maestro-runtime

[English](README.md) | 中文

**仓库地址**：https://github.com/zhao-wuyan/dsh-maestro-runtime

**相关项目**：
- [Maestro Flow 源码仓库](https://github.com/catlog22/maestro-flow)
- [Maestro Flow 中文文档](https://catlog22.github.io/maestro-flow)

一个 [DSH (DeepSeek Harness)](https://github.com/deepseek-ai/deepseek-harness) 宿主插件，把 Maestro-Flow 的运行时能力接入 DSH 会话。

已覆盖 P0 + P1：guard（守卫）、workflow context（工作流上下文注入）、新工作区引导、后台 KG 同步、delegate 通知、team 心跳、coordinator 桥接。

## 功能

- **guard**
  - 拦截危险的 `bash` / `pwsh` 命令（递归删除、硬 git reset、强制 push、格式化磁盘等）
  - 阻止模型直接写 Maestro 受保护状态（`.workflow/state.json`、`.workflow/config.json`、`.workflow/sessions/**`、`.workflow/runs/**`、`.workflow/.maestro/**`）
  - 执行 `.workflow/config.json` 的 PathGuard 边界规则
  - 校验 `.workflow/specs/*.md` 的 `<spec-entry>` 格式
- **context**
  - 用户输入或调用 `/maestro*` 技能时，注入去重后的 `<maestro-context>` 快照
  - 包含 workflow 状态、当前 session、项目标题、specs 索引、knowhow 索引、delegate 通知
- **onboarding**
  - 在没有有效 Maestro workspace 的项目中调用 `/maestro*` 时，注入一次性的 `/maestro-init` 或 `/maestro "<intent>"` 初始化引导
  - 普通非 Maestro 任务保持静默，不打扰
- **kg**
  - 缺少 `maestro.db` 时后台执行 `maestro kg init`（5 分钟冷却）
  - 已存在时后台执行 `maestro kg sync --incremental`（30 秒冷却）
  - 直接以 `node maestro.js` 启动，不经过 cmd shell，不弹终端窗口
- **delegate**
  - 同时扫描宿主 tmpdir 和一级 `dsh-*` 会话临时目录中的 `maestro-notify-*.jsonl`
  - 注入未读完成通知并标记已读
- **team**
  - 本地 git 身份匹配已加入成员时，向 `.workflow/collab/activity.jsonl` 追加 60 秒去重心跳
- **coordinator**
  - 在 `step/end` 和 `turn/end` 时写入 `maestro-coord-<dsh_session>.json` 桥接文件

## 环境要求

- DSH `0.1.0-rc.6` profile（`dsh web` 可正常运行）
- Node.js >= 20
- pnpm >= 10
- 已安装 `maestro-flow` CLI，并能在 PATH 中找到 `maestro`（KG 后台同步使用）

## 安装

DSH 插件通过 **pnpm** 安装到 profile，并通过 `cordis.patch.yml` 挂载。本插件可以直接从 GitHub 安装。

### 方式一：直接从 GitHub 安装（推荐）

本包声明了 `dsh.bundle`，因此 `dsh plugin add` 会同时完成依赖安装和组合层激活：

```sh
dsh plugin --profile web add "github:zhao-wuyan/dsh-maestro-runtime#v0.1.2"
```

等价的 pnpm 手动安装命令：

```sh
cd ~/.dsh/profiles/web
pnpm add "github:zhao-wuyan/dsh-maestro-runtime#v0.1.2"
```

无需手动编辑 `cordis.patch.yml`。重启 DSH 后验证组合层已生效：

```sh
dsh --profile web --dump-config | grep maestro-runtime
```

如需覆盖默认值，在 `~/.dsh/profiles/web/cordis.patch.yml` 中加入（用户层优先）：

```yaml
- id: maestro-runtime
  name: 'dsh-maestro-runtime'
  config:
    guardEnabled: true
    contextEnabled: true
    maxContextChars: 8000
    kgEnabled: true
    delegateMonitorEnabled: true
    teamMonitorEnabled: true
    coordinatorEnabled: true
```

### 固定 tag 或 commit

替换 GitHub 简写中的 fragment 即可固定到指定版本：

```sh
# 稳定 tag
pnpm add "github:zhao-wuyan/dsh-maestro-runtime#v0.1.2"

# 精确 commit
pnpm add "github:zhao-wuyan/dsh-maestro-runtime#<commit-sha>"
```

### 方式二：clone 后本地 link（开发）

```sh
git clone https://github.com/zhao-wuyan/dsh-maestro-runtime.git
cd ~/.dsh/profiles/web
dsh plugin --profile web add "<绝对路径>/dsh-maestro-runtime"
```

checkout 同样声明了 `dsh.bundle`，profile 的 bundles 列表会自动更新。完成后重启 DSH。

> Windows 请使用正斜杠绝对路径，例如：
> `pnpm add "link:C:/Users/<you>/projects/dsh-maestro-runtime"`

### 方式三：npm registry

如果已配置的 npm registry 中有该包：

```sh
dsh plugin --profile web add "dsh-maestro-runtime@0.1.2"
```

然后添加相同的挂载项并重启 DSH。

## 配置

| 字段 | 默认值 | 说明 |
| --- | --- | --- |
| `guardEnabled` | `true` | 启用工具守卫 |
| `contextEnabled` | `true` | 启用 workflow 上下文注入 |
| `maxContextChars` | `8000` | 上下文注入大小上限 |
| `kgEnabled` | `true` | 后台执行 `maestro kg init` / `sync` |
| `delegateMonitorEnabled` | `true` | delegate 通知注入 |
| `teamMonitorEnabled` | `true` | team 心跳写入 |
| `coordinatorEnabled` | `true` | coordinator 桥接写入 |

## 遵循的 DSH 插件发布约定

- 包名遵循 `dsh-*` 命名约定
- `type: module`，`main` 和 `exports` 指向构建入口
- 插件入口导出 `name` 和 `apply`（Cordis 插件契约）
- `inject: ['tools']` 声明所需服务
- 运行时消费的 DSH 共享模块（`dsh-agent`、`dsh-llm`、`dsh-tools`）声明为 **peer dependencies**，不随插件打包，避免遮蔽宿主版本
- `@deepseek-ai/cordis@^4.0.1` 与 DSH 宿主 peer 版本对齐 `0.1.0-rc.6`
- 通过 profile 的 `cordis.patch.yml` 挂载，不修改 DSH 源码
- 导出 Schemastery `Config` schema，非法配置会在加载时明确失败
- 声明 `dsh.bundle`，`dsh plugin add` 自动把组合层加入 `dsh.profile.bundles`

## 开发

DSH 运行时直接编辑 `lib/index.js`。profile 的 HMR 插件（`root: ['.']`）会在变更稳定后重载插件入口。

修改 `package.json` 依赖或 `cordis.patch.yml` 后，需要重启 DSH。

## License

MIT
