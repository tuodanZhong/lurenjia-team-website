# DSH-Remote

**用手机远程驱动 PC 上的 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)** —— 局域网内或公网（4G/5G）都可以，公网走安全 Tailscale 网格。所有文件、命令、会话、API key 都留在 PC 上；手机只是屏幕和键盘。

[English](README.md) | 中文

> **它不是什么：** 这是「远程遥控」发行版——agent 跑在你的 **PC** 上，手机从任意位置驱动它。想在**安卓手机上本机**跑 agent（Termux），请看姊妹仓库[手机本机版](https://github.com/ChongYep/-Deepseek-harness-mobile)。

---

## 特性

- **两种可达性，一套安全模型。** 局域网（家庭 WiFi，明文 HTTP）与公网（Tailscale 网格 + `*.ts.net` 真证书 TLS）。两种模式 harness 都**只绑回环**——公网从不开放任何端口。
- **承载令牌门，fail-closed。** 每个 `/api` 请求与事件流都必须出示令牌；无令牌一律 401。网格成员资格是*可达性*，令牌才是*授权*。
- **API key 不出 PC。** web 通道只报告凭据「是否已配置」，从不返回值。
- **共用同一会话。** 桌面浏览器与手机连**同一个** harness 实例，共享同一段对话。

## 截图

| 连接设置 | 令牌登录 |
| --- | --- |
| ![连接设置](screenshots/Main.jpg) | ![令牌登录](screenshots/Token-Request.jpg) |
| 工作区选择 | 与 agent 对话 |
| ![工作区选择](screenshots/WorkSpace.jpg) | ![对话](screenshots/Test-for-chatting.jpg) |

## 工作原理

```
手机（4G/5G 或任意 WiFi）                          家庭 PC
┌──────────────────┐   HTTPS/WSS    ┌──────────────────────────────┐
│ DSH Remote App    │ ─────────────▶ │ tailscale serve（TLS 终止）   │
│ https://pc.x.ts.net│◀───────────── │   *.ts.net 证书自动签发/续期  │
└──────────────────┘                │      │ http://127.0.0.1:3080 │
        ▲                           │ dsh web（回环绑定 + 令牌门）  │
        └──── Tailscale VPN ───────▶│ agent/文件/会话/key 全在 PC    │
        （WireGuard 端到端加密）      └──────────────────────────────┘
```

harness 保持绑定 `127.0.0.1`——可达性来自网格，而不是端口映射。TLS 由 `tailscale serve` 用真证书终结；令牌在网格内再加一道应用层。完整设计与威胁分析见 [docs/plan-and-risk.md](docs/plan-and-risk.md)。

## 快速开始

### 前置条件

- **PC**：Node.js + **deepseek-harness 源码检出目录**（启动脚本用 `pnpm dsh web` 拉起 harness，必须在源码树里跑——需要有 `node_modules/` 和 `packages/`），Tailscale 已装并登录（`winget install tailscale.tailscale`，再 `tailscale up`）。
- **手机**：[DSH Remote 手机壳 APK](apk/DSH-Remote-0.1.0-release.apk)（release 签名）与 Tailscale 安卓版——后者请从[友仓](https://github.com/tailscale/tailscale-android/releases)下载（官方 APK，约 105 MB，不随本仓库发布）。
- **tailnet**：开启 MagicDNS 与 HTTPS 证书（管理控制台 → DNS）。

### 1. 公网远程（Tailscale）

> **部署前提**：这两个脚本用 `pnpm dsh web` 启动 harness，依赖 deepseek-harness 源码树自带的 workspace（`node_modules/` + `packages/`），在 DSH-Remote 仓库里跑不了。先把 `scripts/` 下这两个脚本拷进源码树的 `scripts/` 目录，然后 `cd` 到源码树根再执行：

```powershell
# Windows
.\scripts\dsh-remote-tailscale.ps1 -Port 3090
# macOS / Linux
scripts/dsh-remote-tailscale.sh --port 3090
```

脚本依次：校验 tailscale 登录 → 推导本机 tailnet DNS 名 → 生成**新令牌** → 注册 `tailscale serve`（只指回环后端）→ 以回环绑定启动 harness。终端打印 `public URL` 与令牌：

```text
dsh-remote-tailscale: tailnet name : pc-name.tailxxxx.ts.net
dsh-remote-tailscale: harness bind : 127.0.0.1:3090 (loopback only - no public port)
dsh-remote-tailscale: bearer token : <token>
dsh-remote-tailscale: public URL   : https://pc-name.tailxxxx.ts.net
```

- **桌面**：打开 `http://127.0.0.1:3090`，贴令牌。
- **手机**：打开 Tailscale App（VPN 开），再用浏览器或 DSH Remote 打开 `https://pc-name.tailxxxx.ts.net`，贴**同一个**令牌。

停止：`.\scripts\dsh-remote-tailscale.ps1 -Stop`（移除 serve 配置），再在 harness 终端按 `Ctrl+C`。

### 2. 局域网远程

```sh
dsh remote --token "$(openssl rand -hex 32)"
```

手机浏览器打开 `http://<PC 局域网 IP>:3080`，贴一次打印出的令牌。详见 [docs/cookbook-lan.md](docs/cookbook-lan.md)。

### 3. 故障恢复 —— `corrupt session log`

会话报 `seq gap in committed region` 时，说明曾有第二个 harness 实例写过同一份日志。关闭**所有** harness 实例，然后跑修复工具。

> 本仓库 `scripts/repair-session-log.ts` 的副本是**参考快照**。它 import 的是 harness 源码树里的包（`packages/…`、`@deepseek-ai/dsh-session`），所以要在你的 **`deepseek-harness` 源码检出目录**（有 `node_modules` 和 `packages/`）里运行，而不是本仓库：

```sh
# 在 deepseek-harness 源码检出目录（仓库根）执行
pnpm exec tsx scripts/repair-session-log.ts \
  --path <log> --remove-type <type> --remove-seq <n> \
  --prev-type <t> --prev-seq <n> --next-type <t> --next-seq <n>
```

命令模板见脚本头注释与各文档的排障表。

## 两条红线

1. **一个 DSH_HOME 只跑一个 harness 实例。** 桌面与手机必须连同一个实例；再开一个 `dsh web` 打开同一会话会撞坏会话日志（seq 空洞）。
2. **重启脚本 = 新令牌。** 两端都要更新。

## 仓库结构

```
DSH-Remote/
├── README.md / README.zh.md      ← 本总览（EN / 中文）
├── android/                      ← DSH Remote 手机 App——手机壳 App 完整 Kotlin 源码
│                                    （build/ 与 .kotlin/ 已 gitignore；release 签名 APK 在 apk/）
├── patches/
│   └── harness-all-changes.patch ← 相对上游 deepseek-harness 的全部改动（191 个文件：令牌门、
│                                    回环绑定、安卓 App…；`git apply` 可完整重现）
├── docs/
│   ├── plan-and-risk.md          ← 方案设计与威胁分析（四条路线对比）
│   ├── validation-report.md      ← 2026-08-15 端到端验证记录
│   ├── cookbook-public-remote.md ← Tailscale 公网流程手册（含排障表）
│   ├── cookbook-lan.md           ← 局域网流程手册（含排障表）
│   └── security-review-dsh-remote.md / .zh.md ← 安全审查与整改记录（中英）
├── scripts/
│   ├── dsh-remote-tailscale.ps1  ← 一键公网远程（Windows）
│   ├── dsh-remote-tailscale.sh   ← 一键公网远程（macOS/Linux）
│   └── repair-session-log.ts     ← 会话日志修复工具（seq 撞号时用）
├── screenshots/                  ← 上面四张截图
├── apk/
│   └── DSH-Remote-0.1.0-release.apk ← 手机壳 App（WebView 外壳，release 签名，记住地址/令牌）
└── release-assets/               ← gitignored 本地暂存，不发布
```

## 安全模型

- **无公网端口。** harness 只绑 `127.0.0.1`；可达性来自网格，不是端口映射。
- **双重加密（公网模式）。** WireGuard 承载流量，TLS（真证书，自动签发与续期）再套一层；令牌从不明文传输。
- **令牌，失败即关闭。** 与局域网模式完全一致——没有令牌一切 401，这里从不涉及 `--host 0.0.0.0`。
- **API key 留在 PC。** web 通道只报告「是否已配置」；残余风险是「令牌失窃 → RCE → 读盘」，轮换与限速会进一步收窄（见 [docs/plan-and-risk.md](docs/plan-and-risk.md) Phase 3）。
- **网格不是边界。** tailnet 内任何设备都能触达端口，令牌才是授权；tailnet 里有其他设备时用 ACL 收紧为「手机↔PC」。

## 文档

| 文档 | 内容 |
| --- | --- |
| [plan-and-risk.md](docs/plan-and-risk.md) | 架构决策记录——4 条候选路线对比、风险表、分阶段实施 |
| [validation-report.md](docs/validation-report.md) | 2026-08-15 端到端验证：移动网络、真证书、401 负向测试、会话日志完整性（58 万+ 事件）+ 安全整改附录 |
| [cookbook-public-remote.md](docs/cookbook-public-remote.md) | Tailscale 公网流程手册 + 排障表 + ACL 模板 |
| [security-review-dsh-remote.zh.md](docs/security-review-dsh-remote.zh.md) | 安全审查与整改记录（[English](docs/security-review-dsh-remote.md)） |
| [cookbook-lan.md](docs/cookbook-lan.md) | 局域网流程手册 + 排障表 |

## 相关项目

- [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) —— 上游 agent 框架，"一切皆插件"，由 [Cordis](https://github.com/cordiverse/cordis) 驱动。
- [ChongYep/-Deepseek-harness-mobile](https://github.com/ChongYep/-Deepseek-harness-mobile) —— 手机本机版：harness 直接在安卓手机 Termux 里运行。
- [tailscale/tailscale-android](https://github.com/tailscale/tailscale-android) —— Tailscale 安卓官方 App，公网远程依赖它（在其 Releases 下载 APK）。
- 本仓库的脚本与流程手册与上游源码树保持同步（`scripts/`、`docs/cookbook/`）。

## 许可证

[MIT](LICENSE) —— 与上游相同条款。第三方声明见上游 [THIRD_PARTY_NOTICES.md](https://github.com/deepseek-ai/deepseek-harness/blob/master/THIRD_PARTY_NOTICES.md)。
