# dsh-drop-preview

**DeepSeek Harness Web UI 拖拽文件预览插件：把文件拖进页面即可预览，一键附带给 AI。**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![DSH](https://img.shields.io/badge/DSH-Web-5B4CF0?style=flat-square)](https://github.com/deepseek-ai/deepseek-harness)
[![Node](https://img.shields.io/badge/Node.js-%3E%3D20-339933?style=flat-square&logo=nodedotjs&logoColor=white)](package.json)

[English](README.md) | 简体中文

## 简介

把文件 / 文件夹**拖入 DeepSeek Harness Web 页面任意位置**，立即弹出**全屏预览**，
确认后一键**附带给 AI**——不用手打路径、不用复制粘贴。

## 功能特性

- **拖入即预览**
  - 图片：大图内联预览（data URL 为主，blob 兜底）
  - Markdown：完整渲染（标题 / 列表 / 代码块 / 表格 / 链接），`![]()` 图片引用自动解析显示
  - 文本 / 代码：内联预览（上限 50 万字符 / 1MB）
  - 其他文件：显示名称、大小、类型
- **图片查看器**：点击任意预览图片 → 放大 / 缩小（按钮 + 滚轮）/ 旋转 / 拖拽平移 / 复位
- **Markdown 图片自动查找**：拖入集合中没有的图片，自动在当前会话工作区（最多 3 层子目录）
  按文件名搜索并显示；确实找不到才标注“图片未找到”
- **文件盒**：一键「存入文件盒」持久化到浏览器 IndexedDB（刷新 / 重启仍在），
  在输入框上方以卡片网格管理：缩略图、点击预览、删除、清空
- **发送给 AI**：文件复制进会话工作区附件目录（`.dsh/tmp/attachments/`），
  路径随消息前置给模型；气泡里附件块折叠为 📎 chip
- 保留：Ctrl+V 粘贴、回形针选择文件 / 文件夹、设置页附件用量统计与清理

## 安装

需要 Node.js ≥ 20 与 DeepSeek Harness（dsh）。

```sh
git clone https://github.com/Cheyeah/dsh-drop-preview.git
dsh plugin --profile web add <本仓库路径>
# 或：dsh plugin --profile web add github:Cheyeah/dsh-drop-preview
```

重启 `dsh web`，浏览器硬刷新（Ctrl+F5）。

## 使用

1. 打开会话并选择工作区
2. 把文件 / 文件夹拖到页面任意位置 → 全屏预览
3. 点 **发送给 AI**：文件进入附件队列，发送时复制到工作区附件目录，路径随消息给模型
4. 或点 **存入文件盒**：保存到输入框上方的文件盒，随时点开预览 / 发送

> Markdown 相对路径图片（`images/x.png`）：优先从拖入集合匹配；找不到会自动在
> 工作区搜索（≤3 层）；都没有则显示“图片未找到”。

## 兼容性

- 实测 DeepSeek Harness `0.1.0-rc.6`（npm 发版）
- 纯 JavaScript，无构建步骤，无第三方运行时依赖

## 工作原理

- 宿主端（`lib/index.js`）：通过 `webServer` 注册附件上传 API（分批上传 / 提交 / 清理）
  与图片解析接口 `/dsh-drop-preview/v1/image`
- 客户端（`lib/client.js`）：通过 `__ModuleLoader__` 注册，使用
  `slots` / `conversation` / `sessions` / `inputTriggers` 服务；
  附件协议块（`==== DSH_PASTE_INPUT_V1 ====`）在气泡中折叠为 chip

## 开发

```sh
node --check lib/index.js
node --check lib/client.js
```

## 卸载

```sh
dsh plugin --profile web remove dsh-drop-preview
```

## 致谢

- 派生自 [lhh010/dsh-paste-input](https://github.com/lhh010/dsh-paste-input)（MIT）
- 及其上游 [dsh-external/dsh-multimedia-webui-input](https://github.com/dsh-external/dsh-multimedia-webui-input)（MIT）

## License

MIT
