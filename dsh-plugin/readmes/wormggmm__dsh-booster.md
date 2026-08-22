# DSHTray — DeepSeek Harness 托盘助手

一个托盘小工具,用来方便地管理 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness):
启动 / 停止 / 更新 / 重启 / 一键安装,全程无需打开命令行。

**Windows**(任务栏右下角托盘)与 **macOS**(屏幕右上角菜单栏)双平台支持,
同一份 Avalonia 代码构建。运行后**没有任何窗口**,只在系统托盘/菜单栏显示一个图标,点开即可操作。

## ✨ 功能特性

- **一键启动 / 停止**:菜单实时显示状态「已停止 / 启动中... / 运行中...」,通过 HTTP 探测判断网页真正就绪,就绪时弹通知
- **两种运行方式自由切换**:
  - 本地仓库模式(开发者):设置里选 harness 源码目录,内部执行「pnpm dsh web」
  - npx 模式(无需仓库):支持官方 / 阿里 / 腾讯 / 自定义镜像源,执行「npx --registry=[源] @deepseek-ai/dsh web」自动安装并运行,源会被记住
- **智能启动**:点「启动」优先用本地仓库;未配置仓库时自动改用 npx
- **更新**:一键「git pull」,失败(如冲突)弹窗显示原因
- **重启**:「仅重启」/「编译并启动」(自动「pnpm build」)
- **日志查看**:实时查看启动输出、npx 安装进度、构建日志(自动刷新)
- **帮助**:内置安装教程与全部菜单说明
- 双击托盘图标(Windows)→ 用默认浏览器打开「http://localhost:3080」
- 单文件、自包含:目标机器**无需安装 .NET**,只需 PATH 里有「pnpm」(仓库模式)/「git」(更新)/「node」(npx 模式)

## 🚀 快速开始

### Windows(10/11)

1. 从 [Releases](../../releases) 下载最新「DSHTray.exe」
2. 双击运行,右键托盘图标
3. 两种方式任选其一:
   - 「更多 → 设置」选择本地 harness 仓库目录(留空则使用 npx 方式)
   - 「更多 → npx安装」选择镜像源(国内推荐阿里/腾讯),自动安装并运行
4. 菜单显示「运行中...」并弹出就绪通知后,浏览器访问「http://localhost:3080」

### macOS(12+)

1. 下载「DSHTray.app」,拖入「应用程序」文件夹
2. 双击运行(首次打开若被拦截:右键/Control+点击 → 「打开」)
3. 点屏幕**右上角菜单栏**的图标(注意:不在 Dock):
   - 「更多 → 设置」选择本地 harness 仓库目录(留空则使用 npx 方式)
   - 「更多 → npx安装」选择镜像源,自动安装并运行
4. 菜单显示「运行中...」并弹出就绪通知后,浏览器访问「http://localhost:3080」

> macOS 提示:本程序会通过 login shell(bash/zsh)自动解析 PATH,支持 nvm / Homebrew 安装的
> node、pnpm、git;如果提示找不到工具,先执行 `brew install node git`。

## 📋 菜单

| 菜单 | 说明 |
|---|---|
| 「启动」/「停止(...)」 | 括号内为实时状态;无仓库时自动改用 npx |
| 「打开」 | 默认浏览器打开「http://localhost:3080」 |
| 「更多」→「设置」 | harness 目录(可留空)、启动/构建命令、Web 端口、Git 代理(仅对本程序生效) |
| 「更多」→「重启」 | 仅重启 / 编译并启动(编译需要本地仓库) |
| 「更多」→「更新」 | git pull(需要本地仓库) |
| 「更多」→「npx安装」 | 选镜像源后自动安装并运行,源会被记住 |
| 「更多」→「日志」 | 查看启动/安装/更新/构建输出,自动刷新 |
| 「更多」→「帮助」 | 安装教程与菜单说明 |
| 「退出」 | 等待进行中的操作完成后退出 |

## ⚙️ 配置与日志

- 配置:`~/.DSHTray/settings.xml`(harness 目录、命令、端口、npx 镜像源、Git 代理)
- 日志:`~/.DSHTray/logs/`(启动输出、npx 安装进度、更新记录、构建日志)
- 崩溃记录:`~/.DSHTray/error.log`

## 🔨 从源码构建

需要 .NET 10 SDK。

### Windows

    cd DSHTray
    .\build.ps1                        # 自包含单文件 exe → publish\DSHTray.exe
    .\build.ps1 -FrameworkDependent    # 依赖 .NET 10 桌面运行时的精简版

托盘图标由「tools\png-to-ico.ps1」从「Icon.png」生成「icon.ico」。

> 也可以在 **macOS/Linux 上交叉发布 Windows 版**(无需 Windows 机器):
>
>     cd DSHTray
>     ./build-win.sh                    # win-x64 单文件 exe(含图标)
>     ./build-win.sh win-arm64          # ARM 版
>     ./build-win.sh win-x64 fd         # 框架依赖版

### macOS

    cd DSHTray
    ./build.sh                         # 按当前架构(osx-arm64 / osx-x64)
    ./build.sh osx-arm64               # 指定 Apple Silicon
    ./build.sh osx-x64 fd              # 框架依赖版(目标机器需装 .NET 10 运行时)

产物:`publish/DSHTray`(单文件自包含二进制)与 `DSHTray.app`(已 ad-hoc 签名,含 icns 图标)。
应用图标由「tools/make-icns.sh」从「Icon.png」生成。分发他人使用需额外做
[notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)。

## 📦 发布到 GitHub Release

**方式 A:GitHub Actions 自动构建(推荐)** —— 仓库已带 `.github/workflows/release.yml`,
推送 `v*` 标签后自动构建 win-x64 / win-arm64 exe 与 macOS 两种架构的 `.app`(构建前先跑自检/冒烟测试),
并附到对应 Release:

    git tag v1.1.0
    git push origin v1.1.0

也可以在 GitHub 仓库 Actions 页面手动触发(workflow_dispatch),产物从该次运行的 Artifacts 下载。

**方式 B:本机构建后手动上传** —— 在 GitHub 仓库页面「Releases → Draft a new release」,
用下方命令产出的文件上传:

    cd DSHTray
    ./build-win.sh            # → publish-win-x64\DSHTray.exe(Windows)
    ./build.sh osx-x64        # → DSHTray.app(Intel Mac)
    ./build.sh osx-arm64      # → DSHTray.app(Apple Silicon)
    zip -r -y DSHTray-macos-arm64.zip DSHTray.app   # macOS 的 .app 需打包成 zip 再上传

注意:`.app` 是目录,Release 附件必须用 zip;本地产物为 ad-hoc 签名,他人首次打开需
右键(Control+点击)→「打开」;正式分发建议 Apple notarization。

## 🗂️ 项目结构

| 文件 | 职责 |
|---|---|
| DSHTray\Program.cs + App.axaml | Avalonia 应用入口、单实例、平台选项(菜单栏应用) |
| DSHTray\TrayApplication.cs | 托盘图标、菜单、操作编排与退出等待 |
| DSHTray\HarnessController.cs | 启动/停止/检测/git pull/build/npx(跨平台) |
| DSHTray\Platform.cs | 平台差异层:cmd/zsh、taskkill/pkill、powershell/ps+lsof、login shell PATH 解析 |
| DSHTray\AppConfig.cs | 配置读写(「~\.DSHTray\settings.xml」) |
| DSHTray\SettingsWindow / NpxInstallWindow / LogViewerWindow / HelpWindow / WaitingWindow | 五个对话框 |
| DSHTray\MessageWindow / ToastWindow / DialogService | 消息框、确认框与浮动通知 |
| DSHTray\IconFactory.cs | 托盘图标(Windows 彩色 / macOS 44px 菜单栏尺寸,程序绘制回退) |
| DSHTray\SelfTest.cs | 自检与端到端冒烟测试(--selftest / --smoketest) |
| DSHTray\tools\ | 图标生成脚本(ico / icns) |

详见 [DSHTray\README.md](DSHTray/README.md)。

## 🧪 自检与冒烟测试(两个平台通用)

    DSHTray --selftest result.txt    # 配置读写 / 端口检测 / 进程枚举 / PATH 解析
    DSHTray --smoketest result.txt   # 端到端:启动测试服务 → 就绪探测 → 停止并确认清理

## 📄 License

MIT
