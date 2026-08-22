# dsh-start

> [**English**](README.md) | **中文**

DeepSeek Harness（DSH）Web 的 macOS 一键启动器。不用再手动敲 `dsh web`——一条命令即可启动/停止/查看状态，还能构建一个程序坞里的 **DSH.app**，像普通 macOS 应用一样开关。

## 功能

- **一条命令，四种模式** — `dsh-start`（前台启动，日志可见，Ctrl+C 停止）、`dsh-start -d`（后台守护，日志写入 `~/.dsh/web.log`）、`dsh-start stop`（停止）、`dsh-start status`（状态）。
- **防重复启动** — 服务已在运行（默认端口 3080）时只打开浏览器，不会启动第二个实例。
- **自动打开浏览器** — 启动后轮询端口，就绪即打开 `http://127.0.0.1:3080`（前台/后台模式均支持）。
- **正常应用体验（DSH.app）** — `scripts/build-dsh-app.sh` 在 `~/Applications/DSH.app` 编译出常驻启动器：双击启动服务，Cmd+Q（带确认弹窗）停止；再点程序坞图标会确保服务在跑并打开浏览器。
- **权限安全设计** — App 把服务器进程交给「终端」启动（终端有完整文件访问权限），避开 macOS 沙箱/TCC 直接拉起 dsh 时的 `EPERM` 启动崩溃。

## 安装

### 从 npm 安装（推荐）

```sh
npm install -g dsh-start
dsh-start            # 前台启动
dsh-start status     # 查看是否在运行
```

### 从源码使用

```sh
git clone https://github.com/zhengjy01/dsh-start.git
cd dsh-start
./bin/dsh-start      # 同样的 CLI
```

### 构建程序坞应用（可选）

```sh
dsh-start --build-app        # 等价于 scripts/build-dsh-app.sh
# 或
./scripts/build-dsh-app.sh   # 图标需要 python3 + Pillow
```

## 用法

| 命令 | 作用 |
| --- | --- |
| `dsh-start` | 前台启动；Ctrl+C 停止服务 |
| `dsh-start -d` | 后台启动（窗口可关）；日志在 `~/.dsh/web.log` |
| `dsh-start stop` | 停止正在运行的服务（按端口定位） |
| `dsh-start status` | 显示服务是否在运行及地址 |
| `dsh-start --build-app` | 构建/刷新 `~/Applications/DSH.app` |

端口默认 `3080`（`dsh web` 默认值），可用环境变量 `DSH_PORT` 覆盖。

## 工作原理

- `scripts/start-dsh.sh` 先探测端口：已在运行 → 打开浏览器；未运行 → 前台（或 `nohup` 后台）拉起 `dsh web` 并等待就绪。
- `scripts/DSH.applescript` 是常驻 AppleScript 应用（`osacompile -s`）：`run`/`reopen` 确保服务在跑并打开浏览器；`quit` 弹确认框后执行 `start-dsh.sh stop` 再退出。
- 构建脚本用 Pillow 生成图标、编译应用、补丁 `Info.plist`、注册 LaunchServices。

## 故障排查

- **App 启动报 `EPERM: operation not permitted`** — macOS 权限上下文问题：重新 `dsh-start --build-app`（v2 版 App 已改为委托终端启动），或直接用终端 `dsh-start` 启动。
- **重启后"会话丢失"** — 会话数据不会被删除，都在 `~/.dsh/sessions`。若 App 拉起的服务启动即崩溃（看 `~/.dsh/web.log`），改用终端启动，侧边栏会重新载入旧会话。
- **DSH.app 首次启动** — macOS 可能弹「DSH 想要控制"终端"」授权，点允许（一次性）。

## 许可证

[MIT](LICENSE) © zhengjy01
