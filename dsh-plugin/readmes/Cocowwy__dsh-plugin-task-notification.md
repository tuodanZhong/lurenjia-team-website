# DSH Native Task Notification

[中文](#中文) | [English](#english)

Native operating-system notifications for DeepSeek Harness tasks. Notifications include the completed task, elapsed time, completion status, sound, and a bundled icon.

## 中文

当 DeepSeek Harness 中的一轮任务结束时，由 DSH Host 直接发送系统级通知。它不依赖浏览器 Notification API，也不需要在网页里授予通知权限。

### 通知内容

每条通知包含：

- 状态：任务已完成、执行异常、已中止或等待处理
- 任务：优先显示本轮用户输入，过长内容会自动压缩
- 用时：从本轮 `turn/start` 到 `turn/end` 的真实耗时
- 声音：使用系统通知声音
- 图标：仅显示一个插件内置的任务完成图标
- 交互：纯信息提示，不添加按钮、下拉菜单或重复确认操作

耗时显示规则：

```text
不足 60 秒：12 秒
不足 1 小时：3 分 18 秒
1 小时以上：2 小时 6 分
```

通知不等待任何自定义交互响应。macOS 的实际显示时长由系统通知策略控制，应用不能可靠指定秒数：

- “横幅”会自动消失
- “提醒”会持续显示，直到用户关闭

如需持续显示，请前往 **系统设置 > 通知**，找到发送通知的通知助手，将样式改为“提醒”。

### 环境要求

- DeepSeek Harness `0.1.0-rc.6` 或更高版本
- Node.js 20 或更高版本
- macOS、Windows 或支持桌面通知服务的 Linux
- `dsh` 和 `pnpm` 可通过 `PATH` 调用

### 从 GitHub 安装

```bash
dsh plugin --profile web add "github:Cocowwy/dsh-plugin-task-notification"
```

然后停止并重新启动 `dsh web`，再刷新现有页面。仅刷新浏览器不会重新加载 Web profile 的 Host 插件。

### 更新

```bash
dsh plugin --profile web update dsh-plugin-task-notification
```

更新后重启 `dsh web`。

### 卸载

```bash
dsh plugin --profile web remove dsh-plugin-task-notification
```

卸载后重启 `dsh web`。如果提示 `ERR_PNPM_CANNOT_REMOVE_MISSING_DEPS`，说明插件当前未安装或已经卸载，不需要重复执行。

### macOS 没有出现通知

1. 确认已经重启 `dsh web`，而不是只刷新页面。
2. 打开 **系统设置 > 通知**，允许通知助手显示通知。
3. 关闭“专注模式”，或允许通知助手在专注模式下通知。
4. 检查启动 `dsh web` 的终端中是否有 `[task-notification]` 错误。

macOS 原生通知由系统通知助手发送，因此系统设置中显示的发送者名称可能是通知助手，而不是浏览器。

### 架构

```text
DSH session/event
  -> turn/start 记录开始时间
  -> user/message 记录本轮任务
  -> turn/end 计算状态和耗时
  -> Node Host 原生通知适配器
  -> macOS / Windows / Linux 通知中心
```

插件完全在 DSH Host 中运行，不上传任务标题、会话标识或其他数据。

## English

This plugin sends native operating-system notifications from the DSH Host when a task turn ends. It does not use the browser Notification API and does not require website notification permission.

Each notification includes:

- Completion, error, interruption, or blocked status
- The current turn's user task, shortened when necessary
- Actual elapsed time from `turn/start` to `turn/end`
- System sound
- One bundled task-completion icon
- Informational presentation only, without custom buttons, dropdown menus, or duplicate confirmation actions

### Install

```bash
dsh plugin --profile web add "github:Cocowwy/dsh-plugin-task-notification"
```

Restart `dsh web` and refresh the existing page.

### Update

```bash
dsh plugin --profile web update dsh-plugin-task-notification
```

Restart `dsh web` after updating.

### Uninstall

```bash
dsh plugin --profile web remove dsh-plugin-task-notification
```

Restart `dsh web` after uninstalling.

### Notification duration

The notification does not wait for a custom interaction response. macOS controls the visible duration through System Settings: banners disappear automatically, while alerts remain until dismissed. Applications cannot reliably override that user-level policy.

### Privacy

The plugin runs locally in the DSH Host and does not upload task titles, session identifiers, or notification data.

## License

MIT
