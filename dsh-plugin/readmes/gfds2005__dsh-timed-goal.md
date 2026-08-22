# dsh-timed-goal

> 在任意 DSH 对话中配置定时任务，到点后自动通过 `/goal` 执行你预设的提示词——支持斜杠命令与完整的 Web 界面。

[![npm version](https://img.shields.io/npm/v/dsh-timed-goal)](https://www.npmjs.com/package/dsh-timed-goal)
[![license](https://img.shields.io/npm/l/dsh-timed-goal)](LICENSE)

[DSH（DeepSeek Harness）](https://github.com/deepseek-ai) Web 插件：在任意对话中配置一次性（或**每日重复**）任务——一个绝对时间加上要执行的提示词。到点时，插件将对话权限固定为 **full access**（`danger-full-access`）并创建一个已武装的 goal，让预设提示词以 `/goal` 语义自动执行。

![dsh-timed-goal Web 界面](https://raw.githubusercontent.com/gfds2005/dsh-timed-goal/main/1.png)

---

## 功能一览

- **按对话配置定时任务** —— 填写绝对时间（年 / 月 / 日 / 时 / 分 / 秒），支持服务器本地时间或 **UTC**。
- **到点自动执行** —— 到点时会话被固定为 full access（`danger-full-access`）并创建 goal，由平台 goal 轮次驱动自动运行你的提示词，无需人工干预。
- **每日重复** —— 每任务可选：触发（或发生冲突）后自动顺延到第二天同一时刻再次执行。
- **轮数上限** —— 可选限制触发后 goal 的自主轮次数（`--rounds <n>` 或界面字段；默认跟随宿主，通常为 256）。
- **任意任务可编辑** —— 编辑已触发/失败的任务会变回「待触发」；添加与编辑都校验**只能填写未来的时间**。
- **Web 界面** —— 浏览器原生管理面板（见下），外加 `/timed-goal` 命令族。
- **不轮询** —— 界面在打开时与每次变更后获取一次；另有手动**刷新**按钮按需重读列表。
- **双语界面** —— 简体中文 / English，跟随 DSH 语言设置。

## Web 界面介绍

入口控件（`⏱ 定时`）位于**每个对话的输入框工具行**——在**所有**会话状态下都可见，包括没有对话记录的全新空白对话（会话头部在有内容前会被整体隐藏，因此入口放在始终可见的输入区）。

点击后，配置面板以**浏览器页内居中模态框**呈现——与「选择工作区」弹窗同款的系统级对话框（官方 `Modal` 组件，portal 渲染到页面根节点，**不随触发按钮定位**；半透明幕布；按 `Esc`、点幕布或「关闭」收起），**左右分栏**：

- **左侧 —— 配置任务**：日历**日期时间选择器**（月份切换、日期网格、时/分/秒下拉、"现在"快捷项）、**UTC** 开关、**每日重复**复选框、可选**轮数**输入、**提示词**文本框。
- **右侧 —— 已配置的任务**：当前对话的任务与实时状态（`待触发` / `已触发` / `失败`、触发时间、每日徽标、轮数、full access 说明），每行带**编辑** / **删除**，另有手动**刷新**与**清空**按钮。

**设置页**同样新增「定时任务」卡片（`settings.section`）：同样的左右分栏，跨**所有会话**管理任务，带会话选择器（"全部会话"视图可看到每个任务所属的会话）。

## 环境要求

- 已安装 [DSH](https://github.com/deepseek-ai/dsh)，并使用 web profile（`dsh web`）。
- Node.js 18+（与你的 DSH 运行时一致）。

## 安装

```bash
dsh plugin --profile web add dsh-timed-goal
```

然后**重启 dsh web 进程**（宿主端插件代码在启动时加载），并验证：

```bash
dsh --profile web --dump-config | grep timed-goal
```

重启后，任意对话输入框工具行会出现 `⏱ 定时` 控件，设置页出现「定时任务」卡片。

本地源码目录安装（例如开发调试）：

```bash
dsh plugin --profile web add file:/绝对/路径/dsh-timed-goal
```

## 卸载

```bash
dsh plugin --profile web remove dsh-timed-goal
# 然后重启 dsh web
```

已配置任务保存在 `$DSH_HOME/plugins/dsh-timed-goal/jobs.json`（默认 `~/.dsh/plugins/dsh-timed-goal/jobs.json`）。若打算重装，请先备份该文件。

## 使用方法

### 斜杠命令

在任意对话内发送（完整帮助见 `/timed-goal help`）：

```
/timed-goal add 2026-09-01 09:30:00 --rounds 32 把当前时间发送到我的邮箱
/timed-goal 2026-09-01 09:30 --daily 每天早上提醒我喝水
/timed-goal list
/timed-goal remove tg-xxxxxxxx
/timed-goal clear
```

- `add` 可省略：`/timed-goal <时间> <提示词...>` 直接可用。
- 时间格式：`YYYY-MM-DD HH:mm[:ss]`（服务器本地时间）或 `YYYY-MM-DD HH:mm[:ss]Z`（UTC）。
- `--daily`：任务每天在此时刻重复执行。
- `--rounds <n>`：限制触发 goal 的自主轮次。
- 时间**必须是未来的**；过去的时间会被拒绝。

### Web 界面

1. 打开一个对话 → 点击输入框工具行的 `⏱ 定时` → 居中模态框打开。
2. **左栏**：在日历中选择日期时间，切换 UTC / 每日重复，可选设置最大轮数，填写提示词，点**添加**。
3. **右栏**：查看任务状态。**编辑**可修改任务（表单自动回填；已触发/失败的任务保存后回到「待触发」，且只能保存未来的时间）；**删除**移除任意任务（已触发也可删）；**刷新**重读列表；**清空**清掉当前对话的任务。
4. **设置 → 定时任务**：跨会话管理所有任务（会话选择器）。

## 工作原理

- 每秒一次的 tick 扫描持久化任务库（`$DSH_HOME/plugins/dsh-timed-goal/jobs.json`），任务在 web 重启后依然生效。
- 到点时插件解析该会话（冷会话会从持久化恢复），把会话权限固定为 **full access**（`danger-full-access`），并以你的提示词创建 goal——由 goal 轮次驱动自动执行。
- 每日任务在触发（或 `GOAL_ALREADY_EXISTS` 冲突）后自动顺延到次日；其他失败以 5 秒退避在 30 分钟宽限窗口内重试，之后标记为「失败」——可编辑后重试。
- 宿主 Web 服务器上的浏览器 API：`/timed-goal/jobs` —— `GET`（列表）、`POST`（创建）、`PATCH /timed-goal/jobs/<id>`（编辑）、`DELETE /timed-goal/jobs/<id>`（删除）、`DELETE /timed-goal/jobs`（清空全部，或带 `?sessionId=…` 仅清空某会话）。

## 安全说明

插件刻意以 **full access**（`danger-full-access`）执行定时任务——其意义就是在你自己的 DSH 实例中无人值守地自主执行。请只安排你信任的提示词。

## 开发

```bash
git clone https://github.com/gfds2005/dsh-timed-goal.git
cd dsh-timed-goal
npm test   # 单元 + 集成测试
```

## License

[MIT](LICENSE)

祝使用愉快！⏱