# dsh-desktop

DeepSeek Harness 桌面应用,从 harness 仓库拆分而来:一个 Electron 壳,在系统
Node 下启动封闭的 web 宿主负载,并在沙箱窗口中加载其 Web UI。harness
checkout 保持零改动——本项目只在构建负载期间临时使用它。

## 目录结构

| 路径 | 职责 |
|---|---|
| `shell/` | 独立 Electron 应用(自有 npm 树):supervisor、窗口、设置、`--smoke` 验收模式 |
| `payload/` | 负载源码:部署根 manifest(`package.json`)、封闭运行时入口(`bin/web-desktop-bin.mjs`)、空根配置、无密钥冒烟测试(`tests/smoke.mjs`) |
| `payload/dist/staging/` | 壳实际启动的物化闭包(构建输出,已 gitignore) |
| `scripts/build-payload.mjs` | 负载构建器:驱动 harness checkout,用完自清理(见下文) |
| `docs/design.md` | 设计记录与迁移历史 |

负载入口与 `dsh --profile web` 完全一致地组装 Web 面,仅去掉 Harness-home
的 profile 层:它从闭包内部加载官方 `dsh-base` 与 `dsh-web-app` 的
`cordis.patch.yml` 子路径导出,附加随包分发的 agent-presets 根(来自 CLI
包的 `config/agent-presets`),并应用遥测开关。没有任何文件被复制——升级
闭包即升级组装。

## 为什么构建需要 harness checkout

依赖闭包包含 vendored 的 Cordis 框架包(`@deepseek-ai/cordis`、
`cosmokit`、`schemastery`……),它们是 private 且从不发布的包,因此部署根
只能在某个 checkout 的 pnpm workspace 内物化。
`scripts/build-payload.mjs` 把这种耦合保持在临时状态:它把负载源码复制进
`<checkout>/desktop-payload/`,在 checkout 的 `pnpm-workspace.yaml` 里注册
该成员(带标记注释),安装并把闭包部署到本项目的 `payload/dist/staging`,
随后再次移除成员与标记。失败的运行在退出途中清理;`--keep-member` 保留现场
供调试。壳本身从不需要 checkout。

## 构建与运行

完整的本地打包流水线(负载暂存 → 无密钥冒烟 → 打包 → 校验 → Windows 壳
安装包)只需一条命令:

```sh
npm run package            # 或: node scripts/package-all.mjs
npm run package -- --build # 先强制构建 harness
npm run package -- --skip-stage # 复用现有 payload/dist/staging
```

各步骤仍列在下面,便于精细控制。

```sh
# 1. 构建负载(需要已构建的 harness checkout;--build 会跑其完整构建)
node scripts/build-payload.mjs --harness ../deepseek-harness-master
#    若 checkout 还没有 apps/web/dist 或 apps/cli/lib,加 --build
#    构建会把官方 Node 运行时捆进 staging/node/(固定版本,对照
#    SHASUMS256.txt 校验 SHA-256);NODE_DIST_BASE_URL 可覆盖下载镜像
#    (例如 npmmirror 的 base URL)

# 2. 仅负载的无密钥冒烟(无需显示环境)
node payload/tests/smoke.mjs payload/dist/staging

# 3. 打包发布工件(zip + SHA-256 + manifest)
node scripts/package-payload.mjs [--notes <text>] [--data-notes <text>]
#    校验:校验和、解压、以及对解压树跑负载冒烟
node scripts/verify-release.mjs [--target <platform>-<arch> | --all]

# 4. 壳(首次: cd shell && npm install && npm run build)
DSH_DESKTOP_PAYLOAD_DIR=<本项目>/payload/dist/staging npm --prefix shell start
# 无头壳验收
DSH_DESKTOP_PAYLOAD_DIR=<本项目>/payload/dist/staging npm --prefix shell run smoke

# 5. 把壳打成 Windows 安装包(NSIS)+ 更新元数据
npm --prefix shell run dist
#    产物: shell/release/dsh-desktop-setup-<version>-x64.exe + latest.yml + blockmap
```

## 壳安装包与自更新

`electron-builder` 只打包壳本身(绝不打包负载——负载永远来自发布源或
runtime store)。`npm run dist` 产出按用户安装的 NSIS 安装包及
electron-updater 元数据。

- **安装**: `dsh-desktop-setup-<version>-x64.exe`;首次启动若无负载且已
  配置发布源,会自动引导安装最新负载。
- **双更新通道、同一 release**: 一个 `desktop-v*` GitHub release 同时承载
  负载 zip + `manifest.json` 以及壳安装包 + `latest.yml`(由 CI 的 `shell`
  job 构建)。壳独立检查"应用更新"(electron-updater,NSIS 通道)与
  "运行时更新"(负载更新器)——负载更新不碰壳、负载自行重启;壳更新则重启
  整个应用。负载 manifest 的 `minShellVersion` 仍会把守负载安装,防止旧壳
  装上新负载。
- **自动检查**: 打包形态下,窗口打开 20 秒后壳检查应用更新;菜单项
  *Check for App Updates…* / *Check for Runtime Updates…* 按需触发任一
  通道。
- **测试钩子**: `DSH_DESKTOP_UPDATE_FEED=<url>` 把壳更新器指向通用 feed
  (一个提供 `latest.yml` + 安装包的目录)。无头 `--shell-update-check`
  标志对该 feed 跑一次检查并打印
  `dsh-desktop-shell-update: <up-to-date|available|unavailable …>`
  (up-to-date/available 退出码 0,失败为 1)——CI 或本地 HTTP 服务器用同一
  标志在无对话框的情况下演练该流程。
- **发布目标**: `electron-builder.yml` 的 `publish` 块(默认
  `wisdomriver/dsh-desktop`);CI 构建并上传工件,release job 负责发布。

剩余运维事项:尚未配置真实 Authenticode 证书(CI 已强制签名,但 PFX/Azure
密钥仍需提供);macOS 壳打包/公证尚未建设。单文件可执行载体已支持
Linux/macOS;Windows 保留 node-carrier zip 作为回退。

## 代码签名(Authenticode)

签名消除 SmartScreen 的"未知发布者"状态,并显示你的组织为发布者。对
SmartScreen 的现实预期:OV 证书仍可能让 Windows 对全新应用显示一次首启
"Windows 已保护你的电脑"提示,直到信誉积累;EV 证书(或具备 EV 等效信任的
Azure Trusted Signing)则立即跳过。签名永远有益——它把"未知发布者"变成
可验证的具名发布者。

**两条支持的路径**(electron-builder,环境变量驱动;见
`shell/electron-builder.yml`):

| 路径 | 要求 | CI secrets |
|---|---|---|
| PFX | 任意商业 Authenticode 证书(OV/EV)导出为 PFX | `CSC_LINK`(base64 `data:application/x-pkcs12;base64,…` 或路径)+ `CSC_KEY_PASSWORD` |
| Azure Trusted Signing | Azure 订阅 + Trusted Signing 账户/配置 | `AZURE_TENANT_ID`、`AZURE_CLIENT_ID`、`AZURE_CLIENT_SECRET`(外加 `electron-builder.yml` 的 `azureSignOptions` 块) |

发布构建(`desktop-v*` 标签)**强制签名**:任一密钥组缺失时 CI `shell` job
直接失败,构建时传 `--config.win.forceCodeSigning=true`,上传前用
`Get-AuthenticodeSignature` 校验每个 `.exe`——未签名版本无法发布。无证书的
本地构建照常工作(跳过签名)。

**本地签名与验证:**

```powershell
# 签名(PFX)
$env:CSC_LINK = 'data:application/x-pkcs12;base64,<base64-of-your.pfx>'
$env:CSC_KEY_PASSWORD = '<password>'
$env:CSC_IDENTITY_AUTO_DISCOVERY = 'false'   # 不让 Windows 证书存储越权选择
npm --prefix shell run dist -- --config.win.forceCodeSigning=true

# 验证
Get-AuthenticodeSignature 'shell/release/dsh-desktop-setup-0.2.0-x64.exe'   # Status: Valid
Get-AuthenticodeSignature 'shell/release/win-unpacked/DeepSeek Harness.exe'
# 或右键 → 属性 → 数字签名
```

首次搭建的网络提示:Electron 二进制可能需要
`ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/`,npm 可能需要
`--registry=https://registry.npmmirror.com` 镜像。若安装后 electron 二进制
缺失,手动运行其安装器:
`cd shell/node_modules/electron && ELECTRON_MIRROR=... node install.js`。

## 运行时约定

- **配置显式**: 负载要求 `DSH_CORDIS_CONFIG`(或 argv 路径);壳注入
  `payload/config/cordis.yml`。
- **就绪协议**: 负载在其 Loader 树稳定后打印
  `dsh web: http://127.0.0.1:<port>`;supervisor 还要求首页返回 200 才显示
  窗口。
- **关闭协议**: stdin EOF 触发 Cordis 树销毁并以 0 退出——这是常规停止
  通道,也是 Windows 上唯一优雅的通道;壳等待 5 秒后强制杀死进程树
  (Windows 上 `taskkill /T /F`)。
- **Node 解析顺序**: `$DSH_DESKTOP_NODE` > 负载内捆绑的运行时(`node/`,
  node-carrier 起每个版本都有)> PATH `node`,一律对照负载的 engines 下限
  (`^22.19 || >=24`)校验;存在但损坏的候选会响亮失败。
- **数据**: 会话/存储位于默认 Harness home(`~/.dsh`),与 CLI 安装共享;
  `DEEPSEEK_API_KEY` 沿用通常的 env/.env/credentials 阶梯。

## 壳体验(Phase 4)

- **首启向导**: 未配置工作区目录时,一个小型本地页面会询问一个(代理的
  沙箱根跟随它——它防止的隐患正是"静默默认整个用户主目录"),并可选询问
  DeepSeek API key。密钥经 OS 钥匙串加密(Electron `safeStorage`,
  `userData/api-key.bin`),每次启动注入负载环境;环境变量仍然优先。取消
  工作区询问则停留(一次运行会沙箱整个主目录);跳过密钥照常继续。当既无
  负载目录、又无 runtime-store 版本、也无发布源时,向导还会询问如何获得
  负载:指向本地负载/release 目录,或输入 GitHub `owner/repo` 引导最新
  release。
- **更新进度窗口**: 交互式运行时更新显示阶段与字节级进度条
  (`renderer/progress.html` 走极简 IPC 桥);无头模式从不打开它。
- **崩溃重启**: 就绪后的负载崩溃在有限预算内自动重启(五分钟三次,滑动
  窗口;store 管理的负载仍有启动回滚);超出预算则壳报告并退出。
- **孤儿看门狗**: Windows 上 supervisor 把负载绑进 close 即杀的 Job 对象
  (`JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`),壳硬死时整棵进程树立即终止。
  跨平台回退是负载的父 pid 轮询(`DSH_DESKTOP_PARENT_PID`):入口每 2 秒
  轮询,`ESRCH` 即销毁。两条路径都有集成测试(`tests/win32-job.spec.ts`、
  `tests/watchdog.spec.ts`)。
- **托盘**: 带显示/退出的托盘图标;`settings.json` 的 `"closeToTray":
  true` 使关窗后驻留托盘(默认 false——关闭即退出)。
- **窗口打磨**: 深色 paint-then-show(`ready-to-show`)消除启动闪白。

## 单文件可执行载体

Linux 与 macOS 发布把负载打成单个自包含可执行文件,而非 node-carrier
目录树:`scripts/build-exe.mjs` 用 `@yao-pkg/pkg --sea`(内嵌 Node 24)
打包暂存闭包,产出 `dsh-web-desktop-<platform>-<arch>`,macOS 另有
`-spawn-helper`。载体仍以 zip 分发,其 `staging/` 根含可执行文件、
`config/cordis.yml`、以及标记 `"carrier": "exe"` 的 `payload-meta.json`
——更新器的既有 zip 路径与壳的 `payloadDir` 约定不变。Windows 保留
node-carrier zip。

```sh
node scripts/build-exe.mjs --harness ../deepseek-harness-master
node scripts/package-payload.mjs --staging dist/exe/staging
node scripts/verify-release.mjs
```

## 壳设置

`userData/settings.json`: `{ "payloadDir": "...", "workspaceDir": "...",
"closeToTray": false, "release": { … } }`;逐字段环境变量优先
(`DSH_DESKTOP_PAYLOAD_DIR`、`DSH_DESKTOP_CWD`)。`workspaceDir` 是负载的
启动 cwd——代理的沙箱工作区根跟随它;未设置时由首启向导询问。

## 发布工件(Phase 1)

`scripts/package-payload.mjs` 把暂存闭包变成 `dist/release/` 下的发布集:

- `dsh-web-desktop-<version>-<platform>-<arch>.zip` —— 载体。压缩包唯一
  根目录是 `staging/`;解压后包含 `bin/web-desktop-bin.mjs` 的目录即负载
  根,与壳的 `payloadDir` 已校验的约定一致。
- `manifest-<platform>-<arch>.json` —— 按平台分片。
- `manifest.json` —— 合并视图,结构如下:

```json
{
  "schema": 1,
  "version": "<harness version, from the checkout's root package.json>",
  "minShellVersion": "<from shell/package.json>",
  "createdAt": "…",
  "harnessCommit": "<sha or null>",
  "notes": "",
  "dataNotes": "",
  "assets": { "windows-x64": { "name": "…zip", "sha256": "…", "bytes": 123 } }
}
```

来源信息来自构建写入的 `payload/dist/staging/payload-meta.json`;一次只
允许打包一个版本(与既有合并 manifest 的版本不匹配会响亮失败)。
`scripts/verify-release.mjs` 是工件验收:对照 manifest 的体积 + SHA-256、
解压、以及对解压树的无密钥负载冒烟——工件只有从打包形态能启动才算合格。

CI 上,`.github/workflows/build-payload.yml` 从 harness checkout(输入
`harness-repository`/`harness-ref`,默认 `deepseek-ai/deepseek-harness` @
`master`——指向你的 fork)构建矩阵(windows-x64、linux-x64/arm64、
macos-arm64),逐腿打包并校验,随后 `desktop-v*` 标签合并分片
(`scripts/merge-manifests.mjs`)并把 zip 与合并 manifest 作为 GitHub
release 发布。

## 更新器(Phase 2)

更新完全在壳内进行:检查 → 下载(支持断点续传)→ SHA-256 校验(一次
重试)→ 升级前备份 → 安装 → 激活 → 重启负载(会话日志让重启保持对话连续,
壳从不退出)。配置位于 `userData/settings.json`:

```json
{
  "release": {
    "source": "github",
    "owner": "<your-fork-owner>",
    "repo": "<your-dsh-desktop-repo>",
    "tagPrefix": "desktop-v",
    "autoCheck": true
  }
}
```

测试环境变量覆盖: `DSH_DESKTOP_RELEASE_DIR=<dir>`(本地 dist/release 风格
目录)或 `DSH_DESKTOP_RELEASE=owner/repo`(GitHub)。配置了发布源后,无负载
的首次启动自动引导最新 release。

值得了解的机制:

- **Runtime store**: 负载安装到 `userData/runtime/<version>/`;
  `state.json` 的指针最后写入(temp+rename),安装中途崩溃时旧版本仍是当前
  版本。保留两个旧版本。
- **备份**: 升级前,`$DSH_HOME ?? ~/.dsh` 的 `sessions/` 与 `settings.yaml`
  快照到 `userData/backup/pre-<from>-to-<to>-<ts>/`(保留两份)——harness
  对磁盘格式不做兼容承诺,manifest 的 `dataNotes` 展示在升级对话框。
- **崩溃回退**: store 管理的负载一分钟内三次启动失败,自动回滚到上一
  版本。
- **壳下限**: manifest 的 `minShellVersion` 高于运行中壳时,更新中止并
  给出指引。
- 菜单: *DeepSeek Harness → Check for Updates…*;`autoCheck` 开启时窗口
  打开 10 秒后自动检查。

测试通道: `npm test`(更新器单元测试,纯 Node),以及 E2E
`npm run update-smoke`——`DSH_DESKTOP_RELEASE_DIR` 指向 fixture
(`node scripts/make-update-fixture.mjs dist/release 99.0.0-test
dist/release-fixture` 可制作一个)——它会真实应用较新版本并打印
`dsh-desktop-updated: <version> <url>`。

## Harness 运行时更新(跟随 deepseek 官方版本)

deepseek-harness 由官方独立发版(`dsh-v*` release,源码形态),dsh-desktop
**不需要发布**,而是运行时自动跟随:每日检测 1 次官方仓库,发现新版本后下载
源码到本地、构建新负载、冒烟验证、原子激活,必要时重启负载(会话延续)。
规则:**后台运行、不打断正常使用**;GitHub 网络不佳时可用浏览器手动下载后
**导入**。

- **每日检测**:窗口打开后 15 秒触发一次(当天已检测过则跳过,成功/失败都
  记入 `userData/harness-update-state.json` 的 `lastCheck`),跨午夜自动
  补检;`autoUpdate: false` 可关闭自动路径(手动路径仍在)。
- **自动路径**:发现新版 → 后台下载 `https://github.com/<repo>/archive/
  refs/tags/<tag>.zip`(断点续传 + 3 次重试)→ 解压并校验
  (`package.json` 的 name 与 version)→ `pnpm install` + `pnpm run build`
  → 用 `scripts/build-payload.mjs` 组装闭包到
  `userData/runtime/<version>/` → 无密钥冒烟 → 原子激活(保留 2 个旧版)。
  全程无对话框;完成后一次性询问"现在重启 / 稍后"(稍后则下次启动生效)。
- **手动路径**(菜单):*检查 Harness 更新…* 发现新版后三选一——后台自动
  更新 / 在浏览器中打开下载页 / 导入本地文件…;*导入 Harness 更新…* 直接
  选择本地下载的 zip(或已解压目录)走同一管线。
- **配置**(`userData/settings.json`,env 覆盖:
  `DSH_HARNESS_REPO` / `DSH_HARNESS_TAG_PREFIX` / `DSH_HARNESS_ROOT`):
  ```json
  { "harness": { "repo": "deepseek-ai/deepseek-harness", "tagPrefix": "dsh-v", "autoUpdate": true } }
  ```
- **网络不佳的兜底**:
  - 版本检查:GitHub API 失败自动回退 `releases.atom`(无速率限制);
  - TLS 被公司代理拦截时,壳自动用 `--use-system-ca` 启动子进程,手动运行
    脚本时加同参数或设 `NODE_EXTRA_CA_CERTS`;
  - `DSH_HARNESS_MIRROR_PREFIX` 可为源码下载加镜像前缀(ghproxy 类服务)。
- **前置条件(dev 工具模式)**:需要 dsh-desktop 源码树(scripts/ + payload/)
  与本机构建环境(`pnpm`,可用 corepack 回退);缺脚本时功能自动禁用并记
  日志。构建期间负载不受影响,重启前不切换。
- **验收**: `--harness-update-check` 无头跑一次检查并打印
  `dsh-desktop-harness-update: harness-update: check current=… latest=…
  newer=…`(exit 0/1)。

## 安全姿态

沙箱窗口(`contextIsolation`、无 `nodeIntegration`、外链交给系统浏览器);
仅绑定回环地址、端口由 OS 分配。已知缺口继承自 webserver v1(回环服务器无
鉴权):任何本地进程都能触达代理——与 `dsh --profile web` 相同的暴露面。
负载输出归档到 `userData/logs/payload.log`。

## 路线图

1. ~~staging 布局之上的 zip 载体 + `manifest.json`(每资产 SHA-256);CI
   workflow 发布 GitHub release。~~ **已完成**(见"发布工件")。
2. ~~GitHub 更新器: 发布源把负载装入 `userData/runtime/<version>/`
   (`resolveSettings` 扩展;supervisor 不变);Harness home 升级前备份;
   崩溃循环回退上一版本。~~ **已完成**(见"更新器")。
3. ~~Windows NSIS 壳安装包 + electron-updater 壳自更新,发布进同一
   `desktop-v*` release。~~ **已完成**(见"壳安装包与自更新")。
4. ~~捆绑 Node 运行时(node-carrier): 每个负载发布都在 `node/` 携带官方
   Node,校验且固定版本,无系统 Node 的机器直接运行。~~ **已完成**(见
   "运行时约定")。
5. ~~参数化上游 exe 流水线的 pkg 单文件载体;node-carrier 留作 Windows
   回退。~~ **Linux/macOS 已完成**(见"单文件可执行载体")。
6. 壳 UX(工作区选择器、API-key 设置、托盘)与签名安装包
   (electron-builder,Authenticode)。**UX 与 Windows 签名已完成;macOS
   壳打包/公证与真实签名证书仍待办。**

设计细节与迁移记录: [docs/design.md](docs/design.md)。
