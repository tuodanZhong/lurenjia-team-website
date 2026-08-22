# DeepSeek Harness Desktop

> 非官方 Electron 桌面壳，包装 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（`dsh`）—— DeepSeek AI 开源的 Agent Harness。

把 `dsh web` 的浏览器界面包装成原生 Windows 桌面应用（EXE）。目标机器**无需安装 Node.js**。

## 截图

![DeepSeek Harness Desktop](assets/screenshot-main.png)

## 特性

- 🖥️ 原生 Windows 应用壳，承载官方 `dsh web` 界面
- 🚀 零运行时依赖：自带 Node 运行时（通过 Electron），目标机器无需安装 Node
- 🔌 自动选择空闲端口（`--port 0`），不会端口冲突
- 📦 两种分发格式：NSIS 安装版 + 免安装 EXE
- 🌐 打包后完全离线可用

## 工作原理

```
┌─────────────────────────────────────────────┐
│  Electron 主进程 (main.js)                  │
│   │                                        │
│   ├─ spawn ──▶ dsh web --port 0 (子进程)     │
│   │              (ELECTRON_RUN_AS_NODE=1    │
│   │               复用 Electron 充当 Node)   │
│   │                                        │
│   └─ BrowserWindow ──▶ http://127.0.0.1:PORT
└─────────────────────────────────────────────┘
```

1. Electron 主进程让操作系统分配一个空闲端口（`--port 0`）
2. spawn `dsh web` 作为子进程（打包版以 `ELECTRON_RUN_AS_NODE=1` 运行，Electron 二进制本身充当 Node 运行时——**目标机器无需安装 Node**）
3. HTTP 服务就绪后，`BrowserWindow` 加载 `http://127.0.0.1:<port>`
4. 应用退出时终止 dsh 子进程

## 项目结构

```
deepseek-harness-desktop/
├── main.js                     # Electron 主进程：spawn dsh web + 窗口
├── preload.js                  # 渲染进程预加载（空，安全隔离）
├── electron-builder.config.js  # 打包配置（afterPack 复制运行时）
├── package.json
└── ../dsh-runtime/             # dsh 运行时（npm 发布版 @deepseek-ai/dsh）；打包时复制进 resources/
```

## 构建

前置条件：Node.js ≥ 22.19（dsh 的 engines 要求）、可访问 npm registry。

```bash
# 1. 准备 dsh 运行时（npm 发布版，含前端 dist 与全部生产依赖）
mkdir -p ../dsh-runtime && cd ../dsh-runtime
npm init -y && npm install @deepseek-ai/dsh@latest

# 2. 安装壳依赖并打包
cd ../deepseek-harness-desktop
npm install
npx electron-builder --config electron-builder.config.js --win nsis portable
# 产物在 release/
#   DeepSeek Harness Setup 0.2.0.exe      NSIS 安装版
#   DeepSeek-Harness-0.2.0-portable.exe  免安装版（首次启动解压约 3 分钟）
```

国内网络打包时设置镜像（下载 Electron 二进制与 NSIS 工具）：

```bash
export ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/"
export ELECTRON_BUILDER_BINARIES_MIRROR="https://npmmirror.com/mirrors/electron-builder-binaries/"
```

## 升级（官方 dsh 发布新版时）

壳项目只是容器，Agent 能力与界面全部来自 `dsh-runtime/` 的 npm 包。官方发布新版后，一条命令完成升级：

```bash
./upgrade.sh           # 检查更新 → 更新 runtime → 验证 → 重新打包
./upgrade.sh --check   # 只检查是否有新版本
./upgrade.sh --no-pack # 更新 + 验证，跳过打包
```

脚本会：
1. 对比 npm 最新版与当前 runtime 版本
2. 有更新则 `npm install @deepseek-ai/dsh@latest`
3. 启动新版 `dsh web` 验证 HTTP 200
4. 同步 `package.json` 的 `dshVersion` 字段（记录配套的 dsh 版本）
5. 重新打包 NSIS + portable
6. 提示发布 GitHub Release 的步骤

**注意**：若官方新版提高了 Node engines 要求或改了 CLI 参数（如 `web --port`），需要同步调整 Electron 版本或 `main.js` 的 spawn 参数——用 `node node_modules/@deepseek-ai/dsh/lib/bin.js web --help` 核对。

## 开发调试

```bash
npm start   # 开发模式：用系统 node 运行 runtime，修改 main.js 即时生效
```

`DSH_PORT` 环境变量可固定端口（默认由系统分配空闲端口）。

## 踩坑记录（供贡献者参考）

1. **electron-builder 的 `extraResources` 不会复制 `node_modules`** —— 它假定 node_modules 必须在 app.asar 内。但 dsh 子进程需要在真实文件系统上读取 node_modules（`ELECTRON_RUN_AS_NODE` 模式无法读取 asar）。→ 在 `electron-builder.config.js` 的 `afterPack` 钩子里用 `fs-extra.copy()` 手动复制。
2. **`pnpm deploy` 不可用**：dsh 把部分运行时依赖放在 devDependencies/peerDependencies，`pnpm deploy --prod` 会缺包（cordis-plugin-group、dsh-timeout、web-frontend 等）。→ 直接用 npm 发布版 `@deepseek-ai/dsh` 作为运行时：依赖树最完整、体积最小（307M vs 678M）。
3. **免安装版首次启动较慢**：144M 单文件每次启动要把整个运行时解压到临时目录（约 3 分钟）。可接受；如需更快，直接分发 `win-unpacked` 目录（无需安装、无需解压）。
4. **npm install-scripts 安全策略**：新版 npm 会阻止 electron 的 postinstall（下载二进制）。需先 `npm install-scripts approve electron`，再 `npm rebuild electron`。
5. **Electron 内置 Node 版本**：dsh 要求 Node ≥ 22.19；Electron 37 内置 Node 22.21 ✅。升级 Electron 时注意核对内置 Node 版本满足项目 engines 要求。

## 免责声明

这是**非官方**社区项目，与 DeepSeek AI 无关联、未经其认可或赞助。"DeepSeek" 与 "DeepSeek Harness" 均为其各自所有者的商标。打包的应用内置官方 `@deepseek-ai/dsh` npm 包并承载其 Web UI；所有 Agent 能力均来自底层官方软件。

## License

MIT — 见 [LICENSE](LICENSE)。
