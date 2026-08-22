# dsh-session-share

[English](README.md) | 中文

> 在不同的 DeepSeek Harness 之间，以本地离线会话包的形式分享完整 Session 树。

## 安装

```sh
dsh plugin --profile web add dsh-session-share
```

发送方和接收方都需要在自己的 Harness 中安装这个插件。

## 分享会话

这个插件用于把自己的 Session 分享给其他人。它会将当前 Session、完整的子会话树以及引用的图片导出为一个本地离线会话包（`.dsh-session-share.zip`），你可以通过聊天工具、文件传输或其他可信方式把这个文件发送给对方。

1. 打开要分享的 Session。
2. 点击 Session Header 中的 **Share**，或执行 `/share-session`。
3. 在弹窗中点击 **下载会话包**，保存生成的 ZIP 文件。
4. 将 ZIP 文件发送给接收方。

## 导入会话

接收方拿到会话包后：

1. 执行 `/import-session` 打开导入弹窗。当前 Harness 没有侧边栏中的 **Import Session** 入口。
2. 选择要导入的本地目标工作区。
3. 将会话包 ZIP 拖入弹窗，或点击选择文件。
4. 导入成功后浏览器会刷新并打开导入的根会话。

导入的会话默认处于等待状态。接收方发送新消息后，它才会使用接收方 Harness 的模型、Agent 配置、凭证、工具和工作区继续运行；发送方的执行环境不会被直接复用。

## 导入行为

- 每次导入都会创建全新的本地 Session 树，并生成新的本地 ID。
- 重复导入同一个会话包会产生第二份独立副本，而不是复用原会话。
- 会话包是离线文件，不是在线分享链接；插件不会自动上传会话内容。

## 隐私与安全

会话包可能包含提示词、模型回复、工具输入输出、Workspace 路径和图片。请只发送给可信的接收方，并在分享前确认内容中没有敏感信息。

Session Capsule v1 不提供加密、内容脱敏、权限控制或在线撤回能力。
