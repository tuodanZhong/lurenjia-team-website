# kongmu-im-bridge

让 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 通过飞书可指挥、可通知、可审批的 IM 桥插件家族（**衍生自 [dsh-im-bridge](https://github.com/shaobeichen/dsh-im-bridge)，MIT 许可**，溯源见 [UPSTREAM.md](UPSTREAM.md)）。

```
packages/im/          核心插件（ctx.im 服务、会话映射、命令、通知、审批、MockChannel）
packages/im-feishu/   飞书适配器（官方 SDK 长连接、审批卡片、群聊 @ 过滤、流式卡片）
demo/                 终端演示与联调运行器（跨平台 shell）
docs/                 安装、飞书配置、适配器开发指南
```

## 特性（相对上游 v1.0.5 的增强）

- **流式打字机回显**：飞书 interactive 卡片 + `im.message.patch` 原地更新（`notifications.streamEdit`）
- **群聊仅回复 @ 机器人**：`groupMentionOnly`（默认开），@ 占位符自动清洗
- **`/stop` 命令**：IM 内随时中断运行中的任务
- **首次接触不吞首条任务**：自动信任后立即派发
- **Windows 全兼容**：跨平台 shell 执行器、CI 双平台矩阵、凭据/路径测试平台无关
- 完整命令集：`/start /new /status /log /help /mute /unmute /approve /stop /trust /revoke`
- 审批流：风险规则门 + 按钮/文本审批 + 超时可恢复拒绝 + `approvals.log` 审计
- 扫码接入：`npx -y kongmu-im-feishu-qr` 一键创建应用，凭据落本机文件（App Secret 不进浏览器）

## 快速开始

```sh
# 1) 装进 DSH web profile（需 pnpm；Windows 无 pnpm 先 npm install -g pnpm）
dsh plugin --profile web add kongmu-im kongmu-im-feishu -w

# 2) 配凭据（二选一）
#    a. 扫码接入（推荐）：npx -y kongmu-im-feishu-qr
#    b. 环境变量：FEISHU_APP_ID / FEISHU_APP_SECRET（飞书开放平台自建应用）

# 3) 重启 dsh web，飞书里私聊机器人：
#    /new → 派活 → /status → /log；危险操作弹审批卡片
```

配置与命令详解见 [docs/install.md](docs/install.md)；
飞书应用四件事（凭证/权限/订阅/发布）见 [docs/feishu-setup.md](docs/feishu-setup.md)。

## 开发

```sh
npm install
npm test          # 全套离线测试（无真实凭据/网络）
node demo/mock-demo.mjs --auto   # 终端 E2E（MockChannel + 模拟 LLM）
```

## 许可

MIT。本仓库为 dsh-im-bridge 的衍生作品，保留其版权声明；改动与增强遵循同许可。
