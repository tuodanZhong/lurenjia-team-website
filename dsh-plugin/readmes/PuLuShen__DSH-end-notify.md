# dsh-client-ui-session-end-notify

DeepSeek Harness Web 客户端的纯浏览器端 UI 插件：每当某个会话的一轮回复结束
（主机 `host/session-status` 的 running 位由 true 翻转为 false），就在窗口
右下角弹出一条消息卡片，并播放一声短促的双音提示音。

## 行为

- 监听会话列表 store（`ctx.sessions.list`）——无 RPC，除上次观察到的
  running 位外不持有任何按会话状态。
- 每个结束的会话弹一条 toast：会话显示标题 + 结束时间；6 秒后自动消失
  （标签页隐藏期间会等待，回到页面后再消失），点击可关闭。
- 提示音用 Web Audio API 合成（无需音频资源文件）；500ms 内合并，多个会话
  同时结束时只响一声。`AudioContext` 会在首次用户交互时解锁，以符合浏览器
  的自动播放策略。

## 挂载

节点端是一个空 `apply`，便于该行出现在 cordis.yml / Loader 中；浏览器端通过
`exports["./client"]` 发布，由 package.json 中的 `dsh.client` 声明被发现。
在 profile 的 `cordis.patch.yml`（或某个 bundle 补丁）中挂载：

```yaml
- insert:
    - id: ui-session-end-notify
      name: '@deepseek-ai/dsh-client-ui-session-end-notify'
```
