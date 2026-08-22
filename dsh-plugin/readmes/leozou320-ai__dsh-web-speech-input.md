# dsh-web-speech-input

[English](README.md) | 简体中文

这是一个用于 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) Web 输入框的麦克风按钮。它使用浏览器 Web Speech API 把实时语音转换成可编辑的提示词，并在说话过程中显示临时识别结果。

## 功能

- 在对话输入框中一键开始或停止语音输入。
- 把临时和最终识别结果写入已有草稿，绝不会自动提交提示词。
- 优先使用页面语言，其次使用浏览器语言，最后回退到 `zh-CN`。
- 清晰显示监听中、浏览器不支持、权限拒绝、麦克风不可用和网络错误状态。
- 支持键盘焦点、ARIA 标签和减少动态效果偏好。
- 插件卸载时会停止语音识别并移除注入样式。

## 运行要求

- DeepSeek Harness Web profile `0.1.0-rc.5` 或兼容的开发者预览版。
- 浏览器提供 `SpeechRecognition` 或 `webkitSpeechRecognition`。
- 为 Harness Web 地址授予麦克风权限。

不同浏览器的支持范围和识别行为存在差异。Chromium 系浏览器目前通常兼容性最好，但本插件无法保证浏览器服务可用。

## 安装

```sh
dsh plugin --profile web add github:leozou320-ai/dsh-web-speech-input
```

安装后重启 `dsh web`，即可在提示词输入框左侧看到麦克风按钮。卸载命令：

```sh
dsh plugin --profile web remove dsh-web-speech-input
```

## 使用方式

1. 点击麦克风按钮。
2. 如果浏览器询问权限，请允许使用麦克风。
3. 开始说话，临时识别文字会实时写入当前草稿。
4. 点击停止，检查或修改草稿，再由你手动提交。

插件不会自动点击发送，也不会直接调用 DeepSeek API。

## 权限与隐私

- 只有点击麦克风按钮后，插件才会请求使用麦克风。
- 音频由浏览器的语音识别实现处理。具体浏览器或操作系统可能会调用厂商的远程识别服务，因此未必能离线使用。
- 插件没有服务端，不保存音频，也不会自行发起网络请求。
- 识别结果只会先写入草稿；只有你提交提示词后，文字才会发送给当前模型提供方。
- 处理机密语音前，请先确认浏览器厂商的语音识别隐私条款。

## 已知局限

- Firefox 正常发行版目前不提供兼容 API。
- 企业策略、不安全来源、浏览器设置或被拒绝的权限都可能禁用语音识别。
- 某些浏览器会在停顿后终止连续识别，需要再次点击按钮继续。
- 识别质量、标点、支持语言和本地/云端处理方式由浏览器与操作系统服务决定。
- 插件依赖当前 Web UI slot API；Harness 仍在开发者预览期，该接口可能变化。

## 故障排查

- **按钮不可点击：** 换用支持 Web Speech API 的浏览器。
- **麦克风权限被拒绝：** 在浏览器网站设置中允许 Harness 地址使用麦克风，然后刷新页面。
- **网络错误：** 即使插件没有后端，浏览器厂商的语音识别服务仍可能需要联网。
- **没有文字：** 检查当前草稿是否可编辑，并确认浏览器选择了正确的麦克风。

## 开发与验证

```sh
node --check host.mjs
node --check client.js
node --test
npm pack --dry-run
```

本地安装测试：

```sh
dsh plugin --profile web add ./path/to/dsh-web-speech-input
```

## 许可证

[MIT](LICENSE)
