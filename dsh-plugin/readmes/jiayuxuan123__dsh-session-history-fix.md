# DSH Session History Fix

修复 **DSH Desktop**（[myYangyunfan/dsh_desktop](https://github.com/myYangyunfan/dsh_desktop)
个人打包版）的历史会话加载失败问题。

Fix for "history unavailable for session ... SessionFormatUnsupportedError"
in DSH Desktop (the [myYangyunfan/dsh_desktop](https://github.com/myYangyunfan/dsh_desktop)
packaged build of DeepSeek Harness).

## 问题 / Problem

打开历史会话时报错：

```
history unavailable for session "...":
SessionFormatUnsupportedError: session "..." contains event type
"agent-teams/team-created" (seq 3211) unknown to this harness and not
marked ignorable; refusing to interpret the log — it was likely written
by a newer harness (raw log: .../session.jsonl.zstd)
```

### 根因 / Root cause

1. 会话读取器（`dsh-session-persistence` → `@deepseek-ai/dsh-session`）
   只接受生成词汇表 `KNOWN_SESSION_EVENT_TYPES` 中的事件类型，
   其余类型必须带 `ignorable: true` 标记，否则拒绝解释整个日志
   （防止因不认识的事件而错误重建会话）。
2. 仓库外插件写入的持久化会话事件不在该词汇表中：
   - `dsh-agent-teams` → `agent-teams/team-created | member-added | member-removed | task-created | task-updated | message-sent | team-deleted`
   - `dsh-message-edit` → `message-edit/version`
   - `dsh-web-search-exa` → `web/exa-search-request`
3. 核心的 `Session.append(type, data, opts)` 没有 `ignorable` 选项，
   核心也没有给仓库外插件提供事件类型注册面，插件无法自行标记
   （上游讨论：[deepseek-ai/deepseek-harness#802](https://github.com/deepseek-ai/deepseek-harness/discussions/802)）。

### 影响范围 / Scope

本修复**仅针对** [myYangyunfan/dsh_desktop](https://github.com/myYangyunfan/dsh_desktop)
打包版 DSH Desktop（0.3.x，内置官方核心 `@deepseek-ai/dsh-session@0.1.0-rc.6`）：

- 只要会话里出现过上述插件事件，历史就无法加载。
- 官方 npm 当前发布的核心（`@deepseek-ai/dsh-session@0.0.1-rc.1`）**尚未包含**
  词汇表检查机制，因此官方原版（`dsh` CLI）暂不会遇到此问题；这是官方
  npm 发布滞后于仓库最新代码所致，与打包作者无关（打包版使用的是官方
  发布的核心包，版本号与 `repository` 均可验证）。
- 不装这些插件的安装不受影响。

## 修复原理 / Fix

向 `@deepseek-ai/dsh-session` 的两份 `KNOWN_SESSION_EVENT_TYPES` 副本
（`lib/index.js` 与 `lib/types/known-event-types.js`）加入上述 9 个事件
类型（44 → 53 项）。事件数据本身不被改动、不会被丢弃，Web 端插件
卡片渲染不受影响。脚本按内容定位词汇表（绝不误改
`SURFACE_EVENT_TYPES`），且**幂等**，可重复执行。

## 使用方法 / Usage

### 一条命令（npm，无需克隆仓库）

```bash
npx dsh-session-history-fix
```

自动定位 DSH Desktop 安装目录 → 打补丁（幂等）→ 校验全部会话日志。
详见 [`cli/`](cli/)（npm 包 `dsh-session-history-fix` 源码）。

### 一键（Windows）

双击 `fix-dsh-history.bat`（自动请求管理员权限）：

1. 重打补丁（幂等）
2. 校验全部会话日志
3. 提示重启 DSH Desktop

### 手动

```bash
# 默认安装路径 C:\Program Files\DSH Desktop
node apply-patch.mjs

# 其它安装路径
DSH_APP_DIR="D:/MyDSH" node apply-patch.mjs
```

### 校验

```bash
# 校验某个工作区全部会话日志能否被读取器接受
node verify-all-sessions.mjs
# 或指定会话目录
node verify-all-sessions.mjs "C:/Users/xxx/.dsh/sessions/--my-workspace--"
```

**改完后必须重启 DSH Desktop**（运行中进程内存里仍是旧词汇表）。

## 重要提醒 / Caveats

- DSH Desktop 有自动更新器，**更新会覆盖打包文件**，更新后需重新运行
  本修复（脚本幂等，直接重跑即可）。
- 这是对已安装程序的本地补丁，治本方案在上游：为核心提供仓库外插件
  的事件注册面，或让插件事件带 `ignorable` 标记。

## 关联项目 / Related

- [myYangyunfan/dsh_desktop](https://github.com/myYangyunfan/dsh_desktop) —— 本修复所针对的 DSH Desktop 打包版（DeepSeek Harness Windows 桌面客户端）
- [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) —— 官方上游（词汇表检查机制的来源）
- [deepseek-ai/deepseek-harness#802](https://github.com/deepseek-ai/deepseek-harness/discussions/802) —— 上游关于"仓库外插件无法安全持久化自己的 Session 事件"的讨论

## License

MIT
