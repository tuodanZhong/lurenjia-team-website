# DeepSeek Harness 桌面客户端（Tauri 2）

一个基于 **Tauri 2** 的桌面应用源码工程，把本机的 DeepSeek Harness Web UI
（`http://127.0.0.1:3080`）装进一个独立的桌面窗口（1280×800，可缩放）。

## 自动启动 harness 服务

应用启动时会先探测 `127.0.0.1:3080` 是否已通：

- **服务已运行**：直接加载 Web UI，不干预，退出时也不影响它。
- **服务未运行**：自动在后台拉起服务，等它就绪后加载 Web UI；**退出时自动停掉由它启动的服务**（不误伤你手动已开的服务）。

启动服务用哪个命令、工作目录、网址、超时等，**全部由 exe 同目录的 `harness.json` 决定**，
程序本身不再写死源码路径：

```json
{
  "url": "http://127.0.0.1:3080",
  "probeAddr": "127.0.0.1:3080",
  "workingDir": "D:/deepseek_harness/deepseek-harness-master/deepseek-harness-master",
  "command": "node",
  "args": ["--import", "tsx/esm", "apps/cli/src/bin.ts", "web"],
  "startupTimeoutSecs": 60
}
```

- **找不到 `harness.json` 时**，程序用内置默认值（与上面一致），保证开箱可用。
- **打包时** `harness.json` 会随安装包一起放到 exe 旁边（`bundle.resources`）；
  装好后直接改安装目录里的这份文件即可生效，**无需重新编译**。
- 项目根目录这份 `harness.json` 是「源文件」，改了它要重新 `tauri build` 才会进安装包。
- 路径用 `/` 或 `\\`（JSON 里反斜杠需转义）都可以。

## 目录结构

```
deepseek-harness-desktop/
├── package.json                 # Node 侧（@tauri-apps/cli）
├── harness.json                 # 启动配置（随安装包分发）
├── dist/index.html              # 前端占位（实际加载外部 URL）
└── src-tauri/
    ├── Cargo.toml               # Rust 依赖
    ├── build.rs
    ├── tauri.conf.json          # 应用/打包配置（含 resources 打包 harness.json）
    ├── capabilities/default.json
    ├── icons/                   # 图标集（png + ico）
    └── src/
        ├── main.rs
        └── lib.rs               # 读配置 → 自动拉起服务 → 创建窗口加载 Web UI
```

## 环境要求

- Rust stable（MSVC 工具链）+ VS Build Tools 2022
- Node.js（用于 `@tauri-apps/cli` 与拉起服务）
- cargo 已配 USTC 镜像、npm 已配 npmmirror 镜像（依赖下载快）

## 构建

```powershell
cd D:\deepseek-harness-desktop
npm install          # 安装 @tauri-apps/cli（走 npmmirror）
npm run tauri build  # 编译并打包（走 USTC 镜像）
```

产物在 `src-tauri\target\release\bundle\` 下：

- `nsis\DeepSeek Harness_0.1.0_x64-setup.exe` —— 安装版（推荐）
- `msi\*.msi`

首次构建需下载 Rust 依赖并编译，约 5–15 分钟。

## 自定义

| 想改什么 | 改哪里 |
|---|---|
| 启动命令 / 工作目录 / 网址 / 超时 | 安装目录里的 `harness.json`（源文件在项目根 `harness.json`） |
| 窗口尺寸 | `src-tauri/src/lib.rs` 里的 `inner_size` / `min_inner_size` |
| 应用名 / 版本 / 包名 | `src-tauri/tauri.conf.json` 的 `productName` / `version` / `identifier` |
| 图标 | 替换 `src-tauri/icons/`，或用 `npm run tauri icon 图标.png` 重新生成全套 |
| 打包目标（只要 exe） | `tauri.conf.json` 的 `bundle.targets` 改为 `["nsis"]` |

## 说明

- `npm run tauri dev` 会以调试模式运行（开发期默认用内置配置，可在调试 exe 旁放 `harness.json` 覆盖）。
- 若服务始终拉不起来（窗口显示无法连接），先在终端手动跑 `pnpm dsh web` 看报错。
- 打包 macOS（.dmg）需在 macOS 上执行，并补 `src-tauri/icons/icon.icns`。
- 想用 git 管理：仓库已含 `.gitignore`（忽略 `node_modules/` 与 `target/`）。
