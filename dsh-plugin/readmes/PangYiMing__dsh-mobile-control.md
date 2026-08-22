# dsh-mobile-control

> DeepSeek Harness 插件 · 操控手机 / DSH plugin for controlling mobile devices

通过 **WebDriverAgent（WDA）** 驱动 iOS 模拟器：截图、点击、找元素、打开 URL、抓可访问性树。
WDA 是跑在模拟器**内部**的 XCUITest 运行器，暴露 `localhost:8100` HTTP 服务——**零 macOS 辅助功能授权、不依赖 idb、能点任意 app（含系统弹窗）**。

Drives the iOS simulator through **WebDriverAgent (WDA)**: screenshots, taps, element lookup, URL opening, accessibility-tree dumps. WDA is an in-simulator XCUITest runner exposing an HTTP API on `localhost:8100` — no macOS accessibility permission, no idb, and it can tap any app, including system dialogs.

## 为什么用 WDA（而不是别的）

| 方案 | 问题 |
|---|---|
| idb (Meta) | homebrew-core 的 `idb-companion` formula 已下架，装不上 |
| cliclick / AppleScript | 走 macOS CGEvent，需要给终端授「辅助功能」权限，否则点了没反应 |
| **WDA ✅** | 模拟器内部 XCTest 自动化特权点击，不走 CGEvent，任何 app 都能点 |

## 快速开始 Quick start

前置：**完整版 Xcode**（XCUITest 靠 `testmanagerd` 拉起，纯 `simctl launch` 起不来 HTTP 服务）。

```bash
bash scripts/wda-up.sh [UDID]            # 不传 UDID 用当前 Booted 的模拟器
curl -s localhost:8100/status | head -c 200   # 返回 build/os/device 即 OK
```

幂等设计：已在跑 → 秒返回；有缓存 → 免编译 ~30s；没缓存 → 首次 clone+编译一次（之后一直免编译）。**端口自适应**：WDA 构建产物的监听端口是编译时写死的（可能是 8100 或 8101 等），脚本从运行日志发现真实端口并写入 `~/.cache/webdriveragent/wda.port`，插件和脚本都读它。模拟器包未签名、arch=arm64+x86_64，**可跨 Mac 复用**：把 `Build/Products` + `.xctestrun` 拷给别人，直接 `test-without-building`，谁都不用再编。真机不能这么白嫖（真机 WDA 必须用含设备 UDID 的描述文件重新签名）。

## 操控 API

见 [docs/wda-drive.md](docs/wda-drive.md)：建会话、找元素、点击、坐标点击、可访问性树、截图、隐私预授权、scheme 打开 URL——全部 curl 可调。

## DSH 工具 Tools

安装插件后，以下 `mobile_*` 工具自动注册进 agent 的工具集：

| 工具 | 说明 |
|---|---|
| `mobile_status` | 检查 WDA 是否在服务（端口自适应，默认 8100） |
| `mobile_wda_up` | 幂等启动 WDA（首次 clone+编译，之后免编译 ~30s） |
| `mobile_screenshot` | `simctl` 截图到 PNG |
| `mobile_find_element` | 按 accessibility label / class 找 UI 元素（返回元素 id） |
| `mobile_tap` | 点元素（`elementId`）或按逻辑点坐标（`x`/`y`）点击 |
| `mobile_accessibility_tree` | 导出当前前台 app 的可访问性树 XML |
| `mobile_open_url` | `simctl openurl` 打开 URL 或自定义 scheme 深链 |
| `mobile_grant_privacy` | `simctl privacy grant` 预授权，避免系统弹窗挡自动化 |

```sh
# 安装后直接在 agent 会话里用自然语言触发：
#   "用 mobile_wda_up 启动 WDA，然后 mobile_tap 点 (268, 492)"
dsh plugin --profile demo add dsh-mobile-control
```

## 路线图 Roadmap

- [x] WDA 幂等启动（`scripts/wda-up.sh`）
- [x] 建会话 / 找元素 / 点击 / 坐标点击 / 可访问性树
- [x] `simctl` 截图 + privacy 预授权
- [x] 自定义 scheme 打开 URL（deeplink）
- [x] 封装为 DSH 工具（8 个 `mobile_*` tools）
- [ ] Android（ADB）支持
- [ ] 元素级滑动 / 长按 / 输入文本

## 安装 Install

```sh
# 发布到 npm 后
dsh plugin --profile demo add dsh-mobile-control

# 或从 GitHub 安装（源码安装需要 prepare 构建）
dsh plugin --profile demo add github:PangYiMing/dsh-mobile-control
```

## 许可证 License

[MIT](./LICENSE)
