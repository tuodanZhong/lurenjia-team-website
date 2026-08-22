# dsh-cinematic-workflow

面向 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 的本地优先、人工门禁式作者电影工作流插件。

它把旅行电影导演工作流转成真正可执行的 DSH 插件：素材清单、导演方案、初剪交付物、可导入 FCPXML、Resolve 交接、克制的文案/字幕、质检与交付记录。它不是 Final Cut Pro 或 DaVinci Resolve 的鼠标自动化工具。

最重要的规则由代码强制执行：只有用户运行 `/cinema continue <project-id>`，并且当前阶段的交付物齐全，才会进入下一阶段。模型不能批准、跳过、合并或提前执行后续阶段。

## 安装

```bash
dsh profile install npm:dsh-cinematic-workflow
```

安装后重载 DSH profile。首个兼容目标为 DSH `0.1.0-rc.6`；Harness 仍在开发阶段，升级时请固定兼容版本。

## 快速开始

```text
/cinema doctor
/cinema start "/你的/素材目录" --title "我的电影" --preset travel-authorial
/cinema run <project-id>
```

当前阶段完成后，先审核，再记录创作选择：

```text
/cinema choose <project-id> theme "自由"
/cinema choose <project-id> arc "抵达 → 释放 → 安静余韵"
/cinema continue <project-id>
```

`/cinema choose` 不推进阶段；`/cinema run` 只会排队当前阶段。可使用 `/cinema status`、`/cinema validate`、`/cinema revise` 与 `/cinema attach` 管理流程。

## 阶段与必需交付物

| 阶段 | 人工审核后才能推进的交付物 |
| --- | --- |
| 样片（可选） | 风格数据库 |
| 素材与作者表达 | 素材清单、导演思考、创作语言基准、已选择的情绪曲线 |
| 初剪 | EDL、FCPXML、声音设计、导演审片 |
| 调色 | 调色简报、Resolve 回传文件 |
| 文案字幕 | 文案稿、字幕、回到 FCP 的时间线 |
| 交付 | QC 报告、交付清单 |

## 媒体、隐私与边界

- 基础素材清单仅为自动元数据，不声称已完整观看素材。
- 安装 FFmpeg/FFprobe 后，可在你的流程中扩展联系表和 QC 工具；未安装时插件仍可使用。
- `cinema_build_fcpxml` 从审核后的 EDL 生成 FCPXML 1.14，不会把文件自动导入 FCP。
- Resolve v0.1 只生成交接简报；你在 Resolve 导入/导出后，用 `/cinema attach` 登记回传文件。
- 插件不会移动、重命名、转码、覆盖或上传源素材。
- 项目文件写入 `<workspace>/.dsh/cinematic/`，应保持 gitignore；不要公开含私人绝对路径、GPS、人脸指标或原始媒体的项目目录。

所有观察均标记为 `automatic`、`model-inference`、`human-confirmed` 或 `unresolved`。创作优先级始终是：创作者表达 > 叙事 > 观众情绪 > 镜头语言 > 声音 > 色彩 > 剪辑技巧 > 软件操作。

内置 `travel-authorial` 预设强调第一人称观察、留白、环境声和克制文案，避免导游式介绍、广告感、炫技转场与全程铺满音乐。

## 开发

```bash
npm install
npm run check
npm pack --dry-run
```

MIT 开源。
