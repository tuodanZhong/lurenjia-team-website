# 安洁莉娜 DSH 插件

[English](README.md) | 中文

这是一个用于 DeepSeek Harness Web UI 的非官方安洁莉娜桌面伙伴与罗德岛风格主题插件。它提供予愿安洁莉娜动态背景、由本地时间驱动的罗德岛班次环境、终端界面、自主活动的动画伙伴、主题预设、任务状态响应、拖动停靠、鼠标接近和连续点击回应、本地对话与重力场特效，并且不会读取会话内容或输入框文字。

## 兼容性

`0.1.0` 版本面向 npm `next` 渠道的 DeepSeek Harness `0.1.0-rc.6`。Harness 仍处于开发者预览阶段，后续版本可能需要同步更新插件。

如果开发版 Harness 已经内嵌 `@deepseek-ai/dsh-client-ui-rhodes-theme`，启用这份独立插件前需要禁用 `ui-rhodes-theme` 和 `ui-rhodes-theme-settings` 两行。标准 Harness 安装不需要迁移；这一步只用于避免同一主题的两份实现同时渲染。

## 从 GitHub 安装

把组合包安装到 Web profile：

```sh
dsh plugin --profile web add github:FlowerWater1019/Angelina-dsh-plugin#main
```

Git 依赖通过包内 `prepare` 脚本完成构建。pnpm 10 第一次可能拒绝执行该脚本；此时把 pnpm 显示的准确包键加入 Web profile 的 `pnpm-workspace.yaml`：

```yaml
allowBuilds:
  "@flowerwater1019/angelina-dsh-plugin": true
```

随后重新执行安装命令。验证配置层并启动 Web UI：

```sh
dsh --profile web --dump-config
dsh web
```

打开 `http://127.0.0.1:3080`，进入“设置 → 安洁莉娜主题”。偏好保存在当前浏览器 profile 和站点来源的 `localStorage` 中，因此公开插件不需要修改 Harness 的设置 API。

卸载命令：

```sh
dsh plugin --profile web remove @flowerwater1019/angelina-dsh-plugin
```

## 功能

- 静谧、陪伴、活跃三个预设，以及单项细节调节。
- 只根据浏览器本地时间自动切换晨曦、日间、黄昏与夜间，也可手动固定为日间或夜间。
- 可调节平滑环境过渡、环境光带和夜间背景亮度。
- 动态背景与减少动态效果时使用的静态后备图。
- 覆盖侧边栏、当前会话、输入框、消息、状态感知工具卡、弹窗、菜单、小型面板、键盘焦点与响应式布局的罗德岛终端样式。
- 使用予愿安洁莉娜精英 1 半身像、罗德岛标志和“重力自定义”技能图标的干员档案设置页。
- 可拖动的安洁莉娜伙伴、释放缓冲和多个安全停靠点。
- 看书、探索、送件与纸飞机动画。
- 空闲时乘纸飞机前往根据侧栏、输入框与视口边缘计算出的安全停靠点，并可显示标明起点与终点的弧形航路。
- 可选的停靠共鸣会让目标侧栏、输入框或视口指示短暂显示航路辉光和抵达信号，但不会改变原控件行为。
- 可选的任务状态联动会让输入框、当前会话与本地状态指示分别显示运行、完成和重连信号。
- 偶尔从视口右边缘以头部为主、保留少量外套地探出，鼠标靠近时进一步现身，点击后返回安全停靠点。
- 任务进行、任务完成、输入框聚焦与断线重连响应。
- 鼠标接近关注、连续点击对话和空闲时双击触发的重力场特效。
- 在浏览器本地保存环境、显示、大小、动画、亮度、纸飞机航路、停靠共鸣、任务状态联动、互动和特效强度。
- 卸载插件时完整清理样式、背景、路由与 UI 注册。

## 开发

```sh
pnpm install
pnpm run typecheck
pnpm test
pnpm run build
pnpm pack
```

本包是一份 DSH 组合包：`cordis.patch.yml` 插入 Host／客户端插件项，Node 侧通过 `/angelina-rhodes-assets/` 提供随包素材，`lib/client.js` 则把浏览器 factory 注册到 Harness 模块表。终端样式只使用 Harness 管理的语义角色和稳定 `data-*` 标记，不检查已渲染的消息或输入框文字。

## 素材与许可证

源代码使用 MIT 许可证。角色素材不包含在该授权内，仍受相应权利人的条款约束。重新分发或使用前请阅读 [NOTICE.md](NOTICE.md)。本项目是非官方同人项目，不表示鹰角网络、明日方舟或 DeepSeek 对其提供认可或背书。
