# dsh-soundscape 🔊

> DeepSeek Harness Web UI 会话声音景观：回合完成庆典（合成号角 + 彩带）、等待审批/回答警示音、错误提示音、发送提示音与可选打字氛围音。零音频资产、零核心改动，并为其他插件提供 `ctx.soundscape` 服务。

[English](./README.md) | 简体中文

**DeepSeek Harness（DSH）** 的 Web GUI 插件：当 agent 完成一个回合、需要你审批、出错或被中断时，用 WebAudio 实时合成的音效给你反馈，成功回合还会撒彩带庆祝。所有声音由振荡器与包络实时生成——**没有音频文件、没有网络请求、不改动任何核心代码**，安装即用，可在设置页逐项开关。

## ✨ 特性

| 事件 | 音效 | 默认 |
|---|---|---|
| 回合开始 | 发送回弹敲击声 `send` | ✅ |
| 回合成功完成 | **庆祝号角 + 彩带** `celebrate`（或简洁铃声 `ding`） | ✅ |
| 回合出错 / 被中断 | 低沉蜂鸣 `buzz` | ✅ |
| 等待你审批 / 回答 / 评审计划 | 双音提醒 `alert`（节流 1.5s） | ✅ |
| 打开会话 | 柔和双音问候 `greet` | ⛔ |
| 流式输出（可选） | 打字氛围音 `click`（节流 + 随机抖动） | ⛔ |

- **零音频资产**：全部 WebAudio 振荡器合成。
- **零核心改动**：只走官方 client 插件扩展缝（`conversation.input.dock` / `conversation.session.header.actions` / `settings.section`）。
- **设置持久化**：`soundscape` 设置命名空间，设置页即时保存。
- **跨插件服务**：`ctx.soundscape.play(name)` / `ctx.soundscape.celebrate()`，其他 client 插件可直接调用。
- **HMR 友好**：所有注册都是 `ctx.effect`，热重载自动清理。

## 📦 安装

前置：已安装 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（`dsh web` 可运行）、Node ≥ 22.19、pnpm。

```bash
# 方式一：从 GitHub 仓库安装（推荐先试本地）
dsh plugin --profile web add "github:Blaczz/dsh-soundscape#main"

# 方式二：本地目录安装（开发用）
cd dsh-soundscape && npm install --legacy-peer-deps && npm run build
dsh plugin --profile web add ./dsh-soundscape

# 方式三：本地 link 安装
dsh plugin --profile web add link:./dsh-soundscape
```

安装后**重启 `dsh web`**（新增插件行需要重启一次；之后源码变更走 HMR）。

> Git 安装需要 `allowBuilds` 授权：首次 `add github:...` 失败时，按 dsh 提示把包 key 写入
> `~/.dsh/profiles/web/pnpm-workspace.yaml` 的 `allowBuilds` 再重跑；或直接发布 npm 包避免构建授权。

## 🎛️ 使用

1. 安装并重启后，打开任意会话，发送一条消息：
   - 回合开始听到回弹敲击声；
   - 回合成功完成——**号角响起 + 彩带撒落**（可在设置关闭庆典，改播简洁铃声）；
   - 出错/中断——低鸣；需要你审批/回答——双音提醒。
2. 会话标题栏有 **🔊/🔇** 快捷静音按钮（记住状态，重启不丢）。
3. **设置 → 音效**：主开关、主音量、每类音效开关与试听、流式氛围节奏旋钮。

## 🔌 开发者：`ctx.soundscape` 服务

其他 client 插件在 `inject` 中加入 `soundscape` 即可调用：

```ts
export const inject = ['slots', 'soundscape']

export function apply(ctx: Context): void {
  // 播放某个音效
  ctx.soundscape.play('celebrate')
  // 完整庆典（音效 + 彩带）
  ctx.soundscape.celebrate()
  // 查询/切换主开关
  if (!ctx.soundscape.isEnabled()) ctx.soundscape.setEnabled(true)
}
```

可播放音效：`click` `send` `ding` `celebrate` `buzz` `alert` `greet`。每个音效受用户设置中对应开关与音量的约束。

## 🛠️ 本地开发

```bash
npm install --legacy-peer-deps          # 安装构建依赖
$env:DSH_NODE_MODULES = "$env:USERPROFILE\.dsh\profiles\node_modules"
npm run setup:dsh-workspace             # 软链运行时的 @deepseek-ai/* 包
npm run verify                          # ★ 一键本地验证（clean + typecheck + test + build）
npm run typecheck                       # 类型检查（src + tests）
npm test                                # vitest 单测（37 项：状态机/synth/引擎/设置/manifest）
npm run build                           # tsc + tsdown → lib/
dsh web --patch ./cordis.patch.yml      # 零安装快速验证（或装进 profile 后重启）
```

`npm run verify` 是上传前的门禁：抽取出的纯状态机（`turn-feedback.ts`）+ mock AudioContext / fetch 单测，能在本地抓出事件映射、门控、节流等逻辑 bug，无需浏览器。

### 目录结构

```
dsh-soundscape/
├── package.json            # dsh.bundle.patch + dsh.client 双契约
├── cordis.patch.yml        # bundle 补丁层（插入本包一行）
├── tsdown.config.ts        # client bundle（__ModuleLoader__.load + 纯度门禁）
├── scripts/                # build / clean / setup-dsh-workspace
├── src/
│   ├── index.ts            # 宿主半：设置命名空间 + loopback HTTP API
│   ├── soundscape-settings.ts  # 共享设置模型（schema + 默认值）
│   ├── settings-api.ts     # GET/PATCH 设置 API（loopback-only）
│   └── client/             # 浏览器半
│       ├── index.ts        # apply：ctx.soundscape 服务 + 槽位注入
│       ├── SessionListener.tsx  # 会话快照 diff → 事件音效
│       ├── SoundEngine.ts  # WebAudio 引擎（懒加载 AudioContext）
│       ├── synth.ts        # 纯合成原语（振荡器 + 包络）
│       ├── confetti.ts     # 零依赖 canvas 彩带粒子
│       ├── HeaderMute.tsx  # 标题栏静音按钮
│       ├── SettingsSection.tsx # 设置页（含试听）
│       └── settings-client.ts  # 设置 API 客户端
└── tests/                  # manifest 契约 + 设置补丁校验
```

## 🧩 生态定位

- 填补空白：DSH 生态此前**没有**回合完成音效/庆典动效、无等待审批警示音（桌面通知无声，`dsh-fun-typewriter` 只覆盖打字氛围）。
- 技术路线：client 插件双面（`dsh.client` + bundle patch），照搬 `dsh-fun-typewriter` 的 WebAudio 零资产与插件自持设置 API 模式，扩展 `ctx.soundscape` 跨插件服务（同 `dsh-client-shortcuts` 的 `ctx.provide` 范式）。
- 零核心改动：所有注册走 `ctx.effect` / `ctx.slots.inject`，HMR 卸载即清理。

## ⚖️ License

MIT © 2026 Blaczz。项目与 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 无关，社区插件。
