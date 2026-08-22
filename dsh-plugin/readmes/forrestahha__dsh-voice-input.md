# dsh-voice-input

[English](README.md) | 简体中文

适用于 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) Web UI 的语音转文字输入插件。

插件会在消息发送按钮前添加一个麦克风按钮。它使用浏览器的 Web Speech API，将识别结果实时写入当前输入框草稿，并且不会自动发送消息。

## 功能

- 使用官方 `conversation.input.right` 扩展插槽。
- 同时支持标准版和带 WebKit 前缀的 SpeechRecognition 实现。
- 默认使用浏览器语言；无法获取时回退到 `zh-CN`。
- 为中文、日文、韩文和拉丁文字保留自然的拼接间距。
- 再次点击按钮即可停止录音；组件卸载时会自动中止识别。
- 无需额外 API Key 或主机端服务。

## 安装

直接从 GitHub 安装到 Web profile：

```sh
dsh plugin --profile web add github:forrestahha/dsh-voice-input
dsh web
```

如需固定版本：

```sh
dsh plugin --profile web add github:forrestahha/dsh-voice-input#v0.1.1
```

打开 Web UI，选择工作目录，然后点击麦克风按钮。首次使用时，浏览器会请求麦克风权限。

识别出的文字只会进入输入框草稿。确认内容无误后，需要手动点击发送按钮。

## 浏览器支持

插件要求浏览器支持 `SpeechRecognition` 或 `webkitSpeechRecognition`。Chromium 系浏览器的支持最完善。不支持语音识别的浏览器会显示一个禁用的麦克风按钮，而不会导致页面启动失败。

现代浏览器会将 `localhost` 视为安全上下文。如果 Harness 运行在另一台机器上，请使用 HTTPS，否则浏览器可能拒绝麦克风访问。

## 隐私说明

插件不会存储音频，也不会自行添加网络请求。Web Speech API 的具体实现由浏览器控制，浏览器可能会把音频发送给其供应商的语音服务。在录制敏感内容前，请先查看浏览器的隐私政策。

## 开发

环境要求：Node.js `^22.19.0 || >=24.0.0` 和 pnpm 11。

```sh
pnpm install
pnpm check
```

安装本地代码进行集成测试：

```sh
dsh plugin --profile web add /absolute/path/to/dsh-voice-input
dsh web
```

## 设计

该 npm 包同时是 Harness bundle 和客户端插件：

- `cordis.patch.yml` 将该包插入所选 profile。
- Node 入口有意保持为空；`dsh.client` 会发现 `./client`。
- 浏览器入口会把 `VoiceInputButton` 注册到 `conversation.input.right`。
- Harness 通过插槽属性提供当前输入状态和 `inputActions.setDraft()`。

插件不会修改 agent loop、模型、会话日志或 Host API 行为。

## 许可证

MIT
