# dsh-mac-vision

[English](./README.en.md)

面向 DeepSeek Harness 的 **macOS 原生视觉插件**。它通过 Apple Vision 为纯文本模型提供本地图片、剪贴板、屏幕和应用窗口的 OCR 与视觉检测能力。

- **完全免费、开源**：插件采用 MIT License，不收取订阅费或按次调用费。
- **完全本地处理**：截图、OCR 与视觉检测均在 Mac 上完成，图片不会发送给第三方 OCR 或视觉服务。
- **无需下载第三方模型**：直接使用 macOS 内置的 Apple Vision，不需要安装或维护额外的视觉模型及其权重。
- **无需第三方 API**：不需要申请 OCR、Vision 或多模态模型 API Key，也不会产生这类 API 调用费用。

> 以上说明针对 `dsh-mac-vision` 的视觉能力。DeepSeek Harness 所使用的语言模型及其服务是否收费，取决于用户自己的 Harness 配置。

## 快速开始

### 1. 安装插件

```sh
dsh plugin --profile default add dsh-mac-vision
```

这一个命令会同时安装视觉工具及其模型使用策略。**不要另外下载、复制或安装 `SKILL.md`。**

### 2. 验证并启动

```sh
dsh --profile default --dump-config
dsh --profile default
```

首次执行视觉任务时，插件会用系统 Swift 编译器构建本地 helper 并缓存。之后可以直接对模型说：

```text
读取这张图片中的标题和主要内容：/absolute/path/to/slide.png
```

或者：

```text
看看当前前台窗口显示了什么，并区分直接看到的内容和你的推断。
```

## 安装前提

- macOS
- Node.js 22 或更高版本
- 已按照 [DeepSeek Harness 入门指南](https://deepseek-harness.github.io/deepseek-harness/guide/quickstart)安装，并可运行 `dsh`
- Xcode Command Line Tools，或包含 Swift 编译器的 Xcode

如果尚无 Swift 编译器，可以运行：

```sh
xcode-select --install
```

读取本地图片不需要屏幕录制权限。读取屏幕或应用窗口时，macOS 可能会要求在“系统设置 → 隐私与安全性 → 屏幕录制”中授权运行 DeepSeek Harness 的终端或宿主应用；授权后可能需要重启该应用。

## 它是一个插件

用户只需安装 `dsh-mac-vision`，不需要在 Plugin 和 Skill 之间做选择。

插件内部包含：

- **视觉工具**：真正执行截图、OCR 和 Apple Vision 检测。
- **内置 Skill**：仅用于指导模型何时调用视觉工具，以及如何表达观察、推断和不确定结果。

Skill 不能独立执行 OCR，它只是随原生插件自动加载的模型使用说明，不是第二个产品或第二个安装步骤。

## 能力

- 免费使用 Apple Vision，无第三方视觉模型下载、API Key 或按次调用费用。
- 读取本地图片、剪贴板图片、全屏、前台窗口或指定窗口。
- 使用 macOS Vision 在本机完成 OCR。
- 返回文本、置信度、坐标、候选结果和复检状态等结构化证据。
- 自动裁剪并放大小字号或公式区域，进行二次 OCR。
- 可选运行图片分类、条码、显著区域、人物和猫狗检测。
- 区分直接观察、语义推断、冲突 OCR 和未运行的检测器。
- 支持 Harness 取消信号、超时和输出大小限制。

插件向模型注册两个工具：

- `mac_vision_inspect`：分析图片、剪贴板、屏幕或窗口。
- `mac_vision_list_windows`：列出可见窗口，以便选择指定窗口。

通常不需要手动调用工具；直接描述任务，模型会按需选择。

## 更多使用示例

```text
读取剪贴板图片中的文字，无法确认的内容请明确标出。
```

```text
列出当前窗口，然后检查浏览器窗口中的错误信息。
```

```text
检查这张截图中是否有二维码，并提取可见文本：/absolute/path/to/image.png
```

模型的结果应区分：

- **Observed / 直接观察**：OCR 或已完成检测器直接返回的证据。
- **Inferred / 推断**：根据布局、文本位置或多个观察作出的解释。
- **Uncertain / 不确定**：冲突 OCR、无法验证的公式或没有运行的检测器。

## 更新与卸载

更新到最新版本：

```sh
dsh plugin --profile default update dsh-mac-vision
```

卸载：

```sh
dsh plugin --profile default remove dsh-mac-vision
```

如果使用了其他 profile，请将 `default` 替换为对应名称。

## 配置

大多数用户不需要修改配置。默认值位于 [`cordis.patch.yml`](./cordis.patch.yml)：

```yaml
config:
  timeoutMs: 45000
  maxOutputBytes: 8388608
  defaultMode: fast
  defaultLanguages: []
  defaultRefineText: true
  defaultRefineLimit: 12
  defaultRefineScale: 3
  allowedSources: [file, clipboard, screen, front-window, window]
```

可以在 profile 的 `cordis.patch.yml` 中覆盖设置。Harness patch 会替换整个 `config`，而不是逐项深度合并，因此覆盖时需要重写完整配置块。

例如，只允许读取本地文件：

```yaml
allowedSources: [file]
```

## 故障排查

- **提示找不到 Swift 编译器**：运行 `xcode-select --install`，安装完成后重试。
- **能读文件但不能读屏幕或窗口**：检查 macOS“屏幕录制”权限，并重启终端或 Harness 宿主。
- **确认插件是否加载**：运行 `dsh --profile default --dump-config`，查找 `dsh-mac-vision`、`mac-vision-tools` 和 `mac-vision-skill`。
- **OCR 小字或公式不准确**：要求模型重新检查具体区域，并明确保留不确定项。

## 本地开发

以下内容仅供贡献者使用，普通安装不需要 clone 仓库、运行 pnpm 或手动打包。

```sh
git clone https://github.com/Kevoyuan/dsh-mac-vision.git
cd dsh-mac-vision
pnpm install
pnpm check
```

从 DeepSeek Harness 源码仓库开发时，可以用绝对路径创建 overlay：

```yaml
- insert:
    - id: mac-vision-tools
      name: '/absolute/path/to/dsh-mac-vision/src/index.ts'
    - id: mac-vision-skill
      name: '/absolute/path/to/dsh-mac-vision/src/skill.ts'
```

然后从 Harness 仓库启动：

```sh
pnpm dsh web --patch /absolute/path/to/overlay.yml
```

这两个 Cordis 入口属于同一个原生插件。通过 npm 正常安装时，它们会自动加载，用户无需手动配置。

## 链接

- [npm 包](https://www.npmjs.com/package/dsh-mac-vision)
- [GitHub 仓库](https://github.com/Kevoyuan/dsh-mac-vision)
- [DeepSeek Harness 插件安装文档](https://deepseek-harness.github.io/deepseek-harness/develop/basic/publish)

## 反馈与贡献

遇到问题或希望增加能力，请提交 [GitHub Issue](https://github.com/Kevoyuan/dsh-mac-vision/issues)。提交代码前请先运行 `pnpm check`。

## License

[MIT](./LICENSE)
