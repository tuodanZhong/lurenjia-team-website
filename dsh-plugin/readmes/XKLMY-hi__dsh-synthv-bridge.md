# dsh-synthv-bridge

Synthesizer V 调音桥接 —— 把开源 [synthv-agent-bridge](https://github.com/SynthVCopilot/synthv-agent-bridge)
（Apache-2.0）的 MCP 运行时接入 DeepSeek Harness，通过 **Synthesizer V Studio 官方公开脚本 API**
检查与编辑当前打开的工程。仅官方接口，无任何破解内容。

## 上游项目与我们的改动

**本插件基于 [synthv-agent-bridge](https://github.com/SynthVCopilot/synthv-agent-bridge)（作者 Pengjie Zhou，Apache-2.0，v0.3.1 / 协议 v3）**，
其架构：Agent（MCP 宿主）→ Node MCP 服务器 → 文件 IPC → SV 内常驻 Lua 脚本 → 官方脚本 API。
六工具语义、Guard/指纹写保护、Undo 边界、紧凑投影等全部来自上游。

我们在其之上做了两层工作：

**① SV1 兼容层（vendor/bridge/synthv/ 内，SV2 行为不变）**

| 改动 | 说明 |
|---|---|
| 版本门禁 | minEditorVersion 131330（SV2.1.2）→ 65537，兼容 SV1.11.x |
| SV1_HOST 兼容层 | hostHas/hostCapabilityError：缺失 API 优雅返回 `UNSUPPORTED_HOST_CAPABILITY`；全部挂载 runtimeState（不占顶层局部变量槽位，避开 Lua 200 局部变量上限） |
| SV:print / Stop 脚本版本头 | SV1 无 print 方法；Stop 脚本门禁同步放宽 |
| detune / AI Retake / Smart Pitch / 轨道混音器 / 计算音素接口 | 调用点条件化 + 相关 action 门禁（SV1 无这些能力） |
| pitch2freq | SV1 缺失，改等律手算 `440×2^((p−69)/12)` |
| addNoteGroup 双参 | SV1 改单参（suggestedIndex 仅 SV2），避免宿主校验错误杀脚本 |
| 自动化参数白名单 | SV1 仅放行 8 个标准参数（大小写不敏感校验后透传原拼写），非法名返回 `PARAMETER_NOT_FOUND`，绝不透传宿主 |
| selection 观察器 | main 内 pcall 保护；SV1 变体缺失回调时不影响启动 |
| 冷启动误报 | TS 侧（v3-facade）：未连接时抛 `BRIDGE_NOT_CONNECTED` 而非 BUILD_MISMATCH，引导用户 Start 而非误装 |

**② DSH 插件封装（本仓库其余部分，BSD-3-Clause）**：vendor 打包、MCP 自动注册、
「SV 调音模式」预设、synthv-bridge 技能、状态面板、一键安装工具，以及两个通用编辑工具：

- **`sv_tune_curve` 音高线通用编辑**：read（读区间点）/ set（设点）/ clear（清区间）/
  shift（整体偏移）/ scale（缩放）/ level（拉平）/ ramp（生成斜坡）/ flatten 系列预设
  （填平缓出/渐入）——一步完成读-算-写-验证，模型无需 describe/contextId 多步流程；
- **`sv_tune_attributes` 音符过渡参数批量编辑**：tF0Left/tF0Right/dF0Left/dF0Right/dF0Vbr
  读-改-写一次完成。

能力清单、支持矩阵与合规声明见 [NOTICE.md](NOTICE.md) 及下文。

## 能力

- **MCP 六工具**：`sv_status` / `sv_describe` / `sv_query` / `sv_command` / `sv_ui` / `sv_review`
  （前缀 `mcp__synthv-agent-bridge__`）—— 检查工程、增删改音符、写歌词、自动化曲线、调音、
  选区/视口/播放控制。
- **`sv_tune_curve`**：音高线（自动化曲线）通用编辑（读/设点/清区间/偏移/缩放/拉平/斜坡/填平预设），
  内部自动处理指纹与验证，一步调用。
- **`sv_tune_attributes`**：音符过渡参数（渐入/缓出时长与偏移、颤音深度）批量编辑。
- **`sv_bridge_status` / `sv_bridge_install`**：一键查桥接状态 / 一键装脚本到官方 SV 脚本目录。
- **「SV 调音模式」agent 预设**（新建会话预设选择器可选）：persona 内建调音工作流、
  责任边界与 SV1 能力限制。
- **synthv-bridge 技能**：详细操作手册（action 速查、错误码、唱法约定、验证流程）。
- **状态面板**：侧边栏「SV 桥接」入口（连接状态灯）+ 浮层状态卡（宿主版本/工程/安装状态/
  一键安装按钮）。

## 支持矩阵

| 版本 | 支持 | 说明 |
|---|---|---|
| Synthesizer V Studio 1.x **Pro** | ✅ | 缺 detune / AI Retake / Smart Pitch / 轨道混音器 / 计算音素接口（优雅降级） |
| Synthesizer V Studio 2 **Pro** | ✅ | 全能力 |
| Basic / 其他无脚本菜单版本 | ❌ | 官方未提供脚本 API |

### 验证环境

- 本插件仅在 **DeepSeek Harness rc.6 + Synthesizer V Studio Pro**（SV1.11.2 引擎）实测验证；
  SV2 Pro 为协议级理论兼容（基于上游 v0.3.1 的 SV2 真机证据），尚未在本插件形态下实测。
- 本项目使用 **vibe coding 辅助开发（DeepSeek-v4 Pro）**。

## 典型应用场景（面向不熟悉歌声合成的用户）

本插件的设计目标是让**不熟悉 SV 的用户也能完成调音**：专业能力由 SV 引擎 + AI 分担，
用户全程只做两件低门槛动作。

### 用户侧（全程仅两次手动操作）

1. **SV 界面里创建自动音高**：新建/打开工程 → 选中音符 → 开启音高自动模式
   （让引擎先生成基础音高曲线；脚本 API 无法代做这一步，必须在界面内完成）；
2. **启动桥接**：`脚本 → SynthV Agent Bridge → Start SynthV Agent Bridge`（每次打开 SV 一次）。

之后的一切交给 AI。

### AI 侧（量化微调：用户说感觉，AI 转参数）

用户在会话里用自然语言描述听感诉求，AI 翻译成量化参数并执行：

| 用户说 | AI 做 |
|---|---|
| 「这句开头软一点」 | PitchDelta 句首滑入 + 起音 Loudness 弱起 |
| 「副歌再用力一点」 | tension/breathiness 声线参数 + Loudness 曲线推高 |
| 「长音要有颤音」 | VibratoEnv 在长音处上弧 |
| 「尾音收得自然点」 | PitchDelta 句尾下沉 + Loudness 收束 |
| 「整体气声多点」 | group voice 的 breathiness 全局上调 |

AI 每次调整后报告改了什么、建议用户试听、按反馈迭代；每次写入可 Ctrl+Z 单独撤销。

### 边界（诚实告知）

- 自动音高本身必须在 SV 界面里开启（SV1.4.3 脚本 API 只读不写，实测验证）；
- 换歌手/唱法受官方 API 限制（读不到当前歌手与默认唱法），需要时用户提供唱法面板截图；
- SV1 无 detune/AI Retake/Smart Pitch/混音器，对应需求用自动化曲线替代。

## 安装

### 前置要求

- DSH 环境（本插件按 DSH 插件生态惯例打包，无 postinstall 脚本）；
- **Node ≥ 20.10**（桥接 MCP 子进程运行时；低于此版本子进程会静默启动失败）；
- 用户自备合法的 **Synthesizer V Studio Pro**（1.x 或 2.x；Basic 无脚本菜单，不支持）。

### 第 1 步：安装插件到 DSH

```bash
# 从 npm（发布后）
dsh plugin --profile web add @xklmy/dsh-synthv-bridge
# 或从本地 tgz / 源码目录
dsh plugin --profile web add ./xklmy-dsh-synthv-bridge-0.1.0.tgz
dsh plugin --profile web add <源码目录路径>
```

- 插件自带 bundle patch，会在装配时注册 host 插件（面板 API / 状态工具 / 预设与技能同步）。
- **重启 DSH 一次**：host 插件把 MCP 条目自动写入 profile patch（预设与技能同步完成）。
- **再重启一次**：MCP 六工具（`sv_status` 等）装配生效。
  > 两段式生效是当前实现方式：MCP 子进程需要插件包的绝对路径，而 bundle patch 的
  > `!!js` 求值环境没有 `require`，所以改为运行时展开路径写入 profile patch。

### 第 2 步：把桥接脚本装进 SV

三种方式任选（同一件事，幂等可重复执行）：

- 面板：侧边栏「SV 桥接」→「装到 SV1 Pro」/「装到 SV2 Pro」；
- 会话：让 agent 调 `sv_bridge_install`（target 为 sv1 或 sv2）；
- 手工：把 `vendor/bridge/synthv/` 下两个 `.lua` 拷到目标目录（见下）。

目标目录（官方数据目录，Pro 才有 scripts 目录）：

| 版本 | 目录 |
|---|---|
| SV Studio 1.x Pro | `%USERPROFILE%\Documents\Dreamtonics\Synthesizer V Studio\scripts\SynthV Agent Bridge\` |
| SV Studio 2 Pro | `%USERPROFILE%\Documents\Dreamtonics\Synthesizer V Studio 2\scripts\SynthV Agent Bridge\` |

### 第 3 步：在 SV 里启动常驻桥接（每次打开 SV 都要点一次，官方机制无法自动化）

```
脚本 → 重新检查脚本 → SynthV Agent Bridge → Start SynthV Agent Bridge
```

启动后无需任何弹窗确认；桥接常驻运行，面板状态灯变绿即就绪。
停止：`脚本 → SynthV Agent Bridge → Stop SynthV Agent Bridge`（或在 SV 中直接关闭工程）。

### 第 4 步：使用

新建会话选「SV 调音模式」预设，直接提调音需求；或先 `sv_status` 确认连接再操作。

## AI 安装指南

> 本插件**没有** postinstall 脚本：装包阶段 pnpm 只做标准安装，其余全部由 DSH 重启后的
> 装配逻辑自动完成。请按下面的时序执行并逐步验证，不要跳步。

### 安装时序与逐步验证

1. **装包**
   ```bash
   dsh plugin --profile web add @xklmy/dsh-synthv-bridge
   ```
   （本地 tgz / 源码目录同样适用：`dsh plugin --profile web add <tgz 或目录路径>`）
2. **第一次重启 DSH**，然后验证 host 插件已装配：
   ```bash
   curl -s http://127.0.0.1:<WEB_PORT>/@xklmy/dsh-synthv-bridge/api
   ```
   （`<WEB_PORT>` 为 DSH Web 端口，默认 3080）
   - 返回含 `"bridge":{...}` 的 JSON → host 插件正常（面板 API、状态工具、预设与技能同步完成）；
   - 404 / 无响应 → 检查 profile 的 `package.json` 的 `bundles` 是否含
     `@xklmy/dsh-synthv-bridge`；若在，看 DSH 启动日志里该 entry 的报错。
   同时确认 MCP 条目已被 host 插件写入 profile patch：
   ```bash
   grep -n "mcp-synthv-agent-bridge" ~/.dsh/profiles/web/cordis.patch.yml
   ```
   有输出 → 正常（这就是"要重启两次"的原因：MCP 条目是重启时由 host 插件展开路径写入的）。
3. **第二次重启 DSH**，验证 MCP 六工具已装配：
   ```bash
   dsh --profile web --dump-config 2>&1 | grep -c "mcp-synthv-agent-bridge"
   ```
   返回 ≥1 → 装配就绪。新会话里让模型自检：工具列表应含 `sv_status`/`sv_describe`/
   `sv_query`/`sv_command`/`sv_ui`/`sv_review`（前缀 `mcp__synthv-agent-bridge__`）。
4. **装桥接脚本到 SV**（幂等，可重复）：
   - 会话里调 `sv_bridge_install`（target: sv1 或 sv2）；或
   - 面板「装到 SV1 Pro / SV2 Pro」按钮；或
   - 手工拷贝 `vendor/bridge/synthv/` 下两个 `.lua` 到
     `%USERPROFILE%\Documents\Dreamtonics\Synthesizer V Studio\scripts\SynthV Agent Bridge\`
     （SV1）或 `...\Synthesizer V Studio 2\scripts\SynthV Agent Bridge\`（SV2）。
5. **用户在 SV 里手动启动常驻桥接**（官方机制无法自动化，请明确告知用户这一步）：
   ```
   脚本 → 重新检查脚本 → SynthV Agent Bridge → Start SynthV Agent Bridge
   ```
6. **连通验证**：`sv_status` 返回 `connected: true` 即可开始调音。

### 常见失败与应对（遇到时先对照这里，不要乱试）

| 现象 | 原因 | 应对 |
|---|---|---|
| MCP 工具没出现 | 只重启了一次，MCP 条目还没装配 | 确认第 2 步 grep 有输出后再重启一次 |
| 面板 API 404 | host 插件没装配 | 查 bundles 列表与启动日志中 `synthv-bridge` entry |
| `sv_status` 返回 connected:false | SV 没开 / 没点 Start / 桥接脚本未安装 | 依次确认：脚本目录有 `SynthV Agent Bridge\SynthVAgentBridge.lua` → SV 已打开工程 → 已点 Start；再调 `sv_bridge_install` 重装一次并让用户重启桥接 |
| 写入报 `BRIDGE_NOT_CONNECTED` | 桥接从未启动或已停止 | 让用户在 SV 里 Start SynthV Agent Bridge，**不要**重装脚本 |
| 写入报 `BRIDGE_TIMEOUT`（约 30 秒后） | Lua 已停止但状态文件未及时更新 | 先调 `sv_status` 确认连接，勿连续重试；断连则让用户重新 Start |
| `SYNTHV_SESSION_CHANGED` | SV 重启或桥接重载过 | 所有旧 contextId 已失效，重新读目标再写 |
| `SynthV executor build does not match the MCP server build` | 插件升级后 SV 里跑的还是旧 Lua | `sv_bridge_install` 重装脚本，用户重新「重新检查脚本 + Start」 |
| 返回 `UNSUPPORTED_HOST_CAPABILITY` | SV1 正常能力降级（detune/Retake/Smart Pitch/混音器/计算音素） | 换可用能力实现（如 PitchDelta 自动化），见技能文档 |
| 安装按钮/工具报「未检测到」 | 用户是 Basic（无脚本目录）或数据目录非默认 | 告知 Pro 要求；数据目录被自定义时手工拷贝 |
| 写入报 `STALE_*` / 提示重读 | 用户在 SV 里改了同一目标 | 重读目标再写 |
| 桥接写入后 SV 没变化但返回 verified | SV 里脚本状态过期 | 用户重新 Start 桥接 |

### 卸载

```bash
dsh plugin --profile web remove @xklmy/dsh-synthv-bridge
```
卸载后需手动清理：从 `~/.dsh/profiles/web/cordis.patch.yml` 删除
`id: mcp-synthv-agent-bridge` 条目（插件自身无法在卸载后清理），
`~/.dsh/.agent-presets/sv-tuning` 与 `~/.dsh/skills/synthv-bridge` 可留可删。
SV 端：删除官方脚本目录下的 `SynthV Agent Bridge` 文件夹即可。

## 主要事项

1. **Pro 专属**：脚本 API 是 SV Studio **Pro** 特性；Basic 免费版无脚本菜单，不支持。
2. **启动是手动的一步**：官方无脚本自动运行入口，每次打开 SV 需手动 Start 一次（上游在 SV2 上同样如此）。
3. **SV1 能力降级**：detune / AI Retake / Smart Pitch / 轨道混音器 / 计算音素接口不可用，
   对应操作返回 `UNSUPPORTED_HOST_CAPABILITY`，请用自动化曲线等替代（详见技能文档）。
4. **唱法（Vocal Mode）约定**：官方 API 读不到歌手身份与默认唱法；涉及唱法的操作前
   需提供唱法面板截图或完整唱法名称。
5. **索引 1 基**；每次写入对应一个 SV 撤销记录（Ctrl+Z 可回退）。
6. **卸载注意**：插件卸载后，它自动写入 profile patch 的 MCP 条目不会自动移除；
   若不再使用，请手动从 `~/.dsh/profiles/<name>/cordis.patch.yml` 删除
   `id: mcp-synthv-agent-bridge` 条目，避免残留条目导致装配报错。
7. 合规：仅使用官方公开脚本 API，不解析工程文件，无破解内容（见 NOTICE.md）。
8. **安全模型（上游继承设计）**：桥接通过**本机临时目录下的文件 IPC**与 SV 内 Lua 通信，
   无网络端口、无鉴权——信任边界是"同一台机器的同一用户"。同机其他进程理论上可伪造
   请求文件驱动 SV 编辑。请勿在多人共享主机 / 不受信任的同机软件环境下使用；
   可用 `SYNTHV_AGENT_BRIDGE_DIR` 把 IPC 目录改到用户私有位置（两侧自动一致）。
9. **可选环境变量**：
   - `SYNTHV_AGENT_BRIDGE_DIR`：自定义 IPC 目录（插件、MCP、Lua 三侧一致读取）；
   - `SYNTHV_SCRIPTS_DIR_SV1` / `SYNTHV_SCRIPTS_DIR_SV2`：覆盖 SV 脚本目录检测
     （Documents 被 OneDrive 重定向 / 非默认数据目录时使用）；
   - `SYNTHV_DOCUMENTS_DIR`：覆盖「我的文档」根目录检测。

## 开发

```bash
npm run sync:vendor   # 从上游仓库同步 vendor 运行时（需上游先 npm run build）
npm run build         # 构建 host + client（build.sh 内含 vendor 同步）
```

上游仓库：synthv-agent-bridge 的本地 clone（含 SV1 兼容修改与补丁脚本，
改动清单见其 `docs/SV1-adaptation-changes.md`）。仓库位置任意，
用 `SYNTHV_BRIDGE_UPSTREAM` 环境变量指定，构建时由 `scripts/sync-vendor.mjs` 读取。

## 致谢

架构灵感来自 Haruki Okada 的概念验证项目
[ocadaruma/mcp-svstudio](https://github.com/ocadaruma/mcp-svstudio)——
它首次演示了「本地 MCP 服务器 + SV 内常驻 Lua 脚本」经文件通信的可行路线；
上游 synthv-agent-bridge 在此之上重实现了请求关联、校验、过期上下文保护、
撤销记录、跨平台路径与更完整的工具面，本插件进一步完成 SV1 兼容与 DSH 生态封装。

Synthesizer V 与 Synthesizer V Studio 是 Dreamtonics 的产品与商标。
本独立项目与 Dreamtonics 无关联，亦未获得其背书。

## 许可

- 本插件：BSD-3-Clause
- vendor/bridge：Apache-2.0（synthv-agent-bridge 上游 + SV1 兼容性修改）
