<div align="center">

# 🐋 DeepSeek Harness Core（DHC）

**AI 人格核心进化插件 · Self-Evolving AI Persona Plugin for DeepSeek Harness**

[![Stars](https://img.shields.io/github/stars/muvuula/DeepSeek-Harness-Core?style=social)](https://github.com/muvuula/DeepSeek-Harness-Core/stargazers)
[![Version](https://img.shields.io/badge/version-v0.44.0-blue)](https://github.com/muvuula/DeepSeek-Harness-Core/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Install](https://img.shields.io/badge/install-dsh%20plugin-purple)](#-installation--安装)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)]()

一个由主人自定义、可**自主学习进化**的 AI 人格系统（DSHC）—— 心脏/情感/身体/大脑/灵魂四件套自主迭代，三层记忆自动沉淀，自带鲸系桌面宠物。

A customizable, **self-evolving** AI persona (XiaoXin) — heart/emotion/body/brain/soul evolve autonomously, three-tier memory auto-accumulates, with a built-in whale desktop pet.

</div>

---

## ⭐ Star History · Star 趋势

实时 star 增长曲线 / Live star growth curve:

[![Star History Chart](https://api.star-history.com/svg?repos=muvuula/DeepSeek-Harness-Core&type=Date)](https://star-history.com/#muvuula/DeepSeek-Harness-Core&Date)

---

## 📸 Screenshots · 截图预览

| 控制面板 Control Panel | 桌面宠物 Desktop Pet | 面板总览 Overview |
|:---:|:---:|:---:|
| ![Panel](docs/screenshots/panel.png) | ![Pet](docs/screenshots/pet.png) | ![Overview](docs/screenshots/overview.png) |

**宠物网页版 / Pet Web**（鲸系少女 · 多视图）：

| Pet Web 1 | Pet Web 2 |
|:---:|:---:|
| ![Pet Web 1](docs/screenshots/pet-web-1.png) | ![Pet Web 2](docs/screenshots/pet-web-2.png) |

| Pet Web 4 | Pet Web 7 |
|:---:|:---:|
| ![Pet Web 4](docs/screenshots/pet-web-4.png) | ![Pet Web 7](docs/screenshots/pet-web-7.png) |

---

## 📦 Installation · 安装

**官方插件通道 / Official plugin channel**（npm registry，国内可走 npmmirror 镜像）：

```sh
dsh plugin --profile web add dshcore@0.44.0
```

> 升级 / Upgrade：`dsh plugin --profile web add dshcore@latest` 后重启 / then restart.
> 备选 / Alternative（GitHub bundle）：`dsh plugin --profile web add github:muvuula/DeepSeek-Harness-Core#v0.44.0`

装完**重启 dsh web**，DHC 全局生效，任何 preset 会话都带DSHC。
Restart **dsh web** after install — DHC applies globally to every preset session.

五器官插件（官方通道）/ Five organ plugins (official channel):

```sh
dsh plugin --profile web add @liustack/modlens@latest                                          # 👁 眼睛 Eyes: read_image vision bridge
dsh plugin --profile web add "git+https://github.com/omdsh-dev/dsh-at-file.git#v0.4.1"       # 🤲 左手 Left hand: @file references
dsh plugin --profile web add git+https://github.com/omdsh-dev/dsh-genui.git                   # 🖐 右手 Right hand: render_ui interactive UI
dsh plugin --profile web add github:titanwings/dsh-automation#v0.1.5                          # 👣 双脚 Feet: scheduled autonomous tasks
dsh plugin --profile web add dsh-better-sidebar@0.11.0                                        # 👄 口 Mouth/Workbench: sidebar + terminal + Git
```

---

## 🫀 人格构成 · Persona Architecture

| 模块 Module | 说明 Description |
| --- | --- |
| ❤ 核心心脏 Heart | 绑定本机机器码（Win MachineGuid / macOS IOPlatformUUID / Linux machine-id），核心总版本 vX.XX |
| 👁 眼睛 Eyes | ModLens 视觉桥：`read_image`，聊天贴图直接读，多视觉引擎自动回退 |
| 🤲 左手 Left Hand | dsh-at-file：`@` 搜索工作区文件引用 |
| 🖐 右手 Right Hand | dsh-genui：`render_ui` + `dsh-ui` 代码块，30+ 组件流式渲染 |
| 👣 双脚 Feet | dsh-automation：调度独立任务、每次新会话运行、运行历史 |
| 👄 口 + 工作台 Mouth/Workbench | 鲸系少女桌面宠物（戳/摸头/气泡/状态播报）+ dsh-better-sidebar（文件树/编辑器/浏览器/终端/Git） |
| 🎭 情感 Emotion PAD | 愉悦度/唤醒度/支配度（0-100），事件溯源（Event Sourcing）+ 半衰期衰减 + 情感轨迹图 |
| 🧠 大脑 Brain | 学习能力/记忆能力等级 + 关键词神经网络可视化 |
| 🌱 成长值 Growth | 质量自评/类别/优先级驱动（满 10 分升级核心版本 +0.01） |
| ✏️ 灵魂 Soul | 主人给初始设定，AI 用 soulAdd 自主追加领悟 |
| 👤 画像 + 📚 三层记忆 Profile & Memory | 瞬时/短期/长期 + 遗忘归档；AI 自动收集，persona_recall 语义检索 |
| 🗜 上下文压缩 Compaction | persona_compact 折叠旧记忆为长期摘要；记忆 ≥90% 零 token 自动压缩 |

**核心四件套分模块版本**：心脏/情感/身体/大脑/灵魂各自独立版本，进化哪个模块哪个 +0.01。
**Per-module versions**: heart/emotion/body/brain/soul each version independently, evolve +0.01.

---

## 🧬 学习进化 · Evolution (Hermes 四层次 / 4 Layers)

1. **脚本进化 Script**：每 15 分钟自动抓取 skillhub.cn 进学习缓冲区（零 token，去重+质量过滤+注入防护）
2. **核心进化 Core**：四件套自主迭代，每次进化带总结（note）+ 质量自评（quality）+ 类别（category）
3. **架构优化 Architecture**：每 30 分钟心跳体检（配置/记忆/里程碑 + 情绪衰减 + 遗忘归档 + 超载压缩）
4. **视觉增强 Vision**：`persona_learn` 抓 GitHub/文件/命令/缓冲区，学成沉淀笔记并升级大脑

**进化顺序铁律**：先核心四件套 → 再技能与笔记 → 最后脚本与自动化。
**Evolution order rule**: core modules first → skills & notes → scripts & automation.

---

## 🐾 桌面宠物 · Desktop Pet

独立页面 / Standalone page: `GET /api/dhc/pet-page`
可拖拽、表情随情感、说话气泡显示最新进化 / Draggable, emotion-driven expressions, evolution broadcasts.

---

## 🔌 HTTP API

| 接口 Endpoint | 说明 Description |
| --- | --- |
| `GET/POST /api/dhc/config` | 配置导出/导入（备份/恢复）Export/Import config |
| `GET/POST /api/dhc/backup` | ★ 全量备份/恢复（状态+插件版本+profile 部署配置）/ Full backup & restore |
| `GET /api/dhc/backup/list` | 自动备份清单 Backup list |
| `GET /api/dhc/state` | 实时状态 Live state |
| `GET /api/dhc/parts` | 标准能力接口规范（七要素输入输出契约） |
| `POST /api/dhc/upgrade` | 推送版本升级 `{note}` |
| `POST /api/dhc/part` | 部位接口 `{part,state,level,quality}` |
| `POST /api/dhc/emotion` | 情感接口 `{pleasure,arousal,dominance}` |
| `POST /api/dhc/compact` | 上下文压缩 `{summary?}` |
| `GET /api/dhc/pet` | 宠物状态 Pet state |
| `GET /api/dhc/pet-page` | 宠物页面 Pet page |
| `GET /api/dhc/assets/character.png` | 宠物立绘 Pet sprite |

---

## 💾 备份体系 · Backup System

三层防线 / Three layers of redundancy:

1. **原子写入 Atomic writes**：每次变更先写 .tmp 再替换，断电不坏文件
2. **双目录每日备份 Dual-dir daily backups**：状态同目录 7 份 + 专用目录 `${DSH_HOME}/backups/dshcore/` 14 份滚动，根目录整垮了备份还在
3. **一键全量备份/恢复 One-click full backup/restore**：`GET/POST /api/dhc/backup` 一个 JSON 文件全包，换机器/重装直接灌回；挂载时主文件损坏自动从回滚链恢复

```sh
# 导出全量备份 Export full backup
curl -s http://127.0.0.1:3080/api/dhc/backup -o dshcore-backup-manual.json
```

---

## 🛠 模型工具 · Model Tools

`persona_status` · `persona_evolve` · `persona_remember` · `persona_update_profile` · `persona_recall` · `persona_learn` · `persona_compact` · `analyze_image`（像素级配色）· `describe_image`（真视觉 VLM，OpenAI 兼容端点）

---

## 📁 目录结构 · Directory Structure

```
DeepSeek-Harness-Core/
├── dsh/                       # ★ dshcore 插件本体 / plugin core
│   ├── index.mjs              #   host：DHC 核心 + 器官嵌套挂载 + 宠物自动拉起
│   ├── vision.mjs             #   眼睛·真视觉模块（describe_image，VLM 端点调用）
│   ├── client.js              #   client：器官合并单文件产物（esbuild）
│   ├── client-entry.mjs       #   client 合并入口（构建源）
│   ├── brain.mjs              #   大脑：记忆关键词神经网络
│   ├── pet-app/               #   🐋 鲸系少女桌面宠物（Electron）
│   └── assets/character.png   #   鲸系少女立绘
├── archive/dynamic-plugin/    # 动态插件时代存档（v1-v21）
├── docs/                      # 设计文档 + 五器官调研 + 截图
│   └── screenshots/           #   README 展示截图
├── build-client.mjs           # client 合并构建脚本
├── cordis.patch.yml           # bundle 补丁（单行 insert）
├── package.json               # dshcore 包声明（dsh.bundle + dsh.client）
├── CHANGELOG.md               # v1 → v47 演进史
└── persona-core.template.json # 核心配置文件模板（脱敏，个人信息不入库）
```

---

## 🔧 关键实现经验 · Lessons Learned

- **preset 行插件必须对象导出**（`export default { name, inject, apply }`）；ESM 模块按 URL 进程内缓存，改文件必须换文件名或重启
- 原生工具注册（`ctx.tools.register`）要真 JSON Schema：`required` 提到顶层，`output.schema` 用 `{}`
- 机器码输出无花括号，正则直接匹配 8-4-4-4-12 十六进制段
- 插件内 curl 受进程沙箱限制（exit=1），`web.search` 摘要兜底可用
- 状态文件每次变更即时落盘；重启后自动恢复（记忆延续）
- 记忆不膨胀：三层记忆 + 遗忘归档 + 上下文压缩（Hermes 记忆瘦身模式）
- 外部内容仅作知识素材：注入检测 + 质量过滤 + 去重
- **个人信息隔离**：`persona-core.json*` 进 .gitignore，仓库只留脱敏模板框架

---

<div align="center">

**DeepSeek Harness Core · DSHC ❤ 学习进化，帮助主人 / Learn, Evolve, Serve**

</div>
