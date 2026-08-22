# dsh-ui-spec

[English](README.md) | 简体中文

[![Version](https://img.shields.io/badge/version-v0.1.0-1684d6?style=flat-square)](package.json)
[![License](https://img.shields.io/badge/license-MIT-f2c94c?style=flat-square)](LICENSE)
[![DeepSeek Harness](https://img.shields.io/badge/DeepSeek_Harness-plugin-0f8b8d?style=flat-square)](https://github.com/deepseek-ai/DeepSeek-Harness)
[![Validation](https://img.shields.io/badge/UI_validation-85%2F100-c0392b?style=flat-square)](#deepseek-实测)
[![GitHub stars](https://img.shields.io/github/stars/yumimanji/dsh-ui-spec?style=flat-square&logo=github)](https://github.com/yumimanji/dsh-ui-spec)

将 UI 截图转换为纯文本 DeepSeek 模型真正可用的、面向实现的 Web 规范。

`dsh-ui-spec` 将原生 OCR、确定性图像分析、场景图重建、字体与形状证据、参考资产提取和渲染结果比较合并为一个插件。在支持的 Windows 环境中，默认流程完全在本地运行，不会把原图发送给视觉模型。

## 效果展示

| 原始参考图 | DeepSeek 实现效果 |
|:---:|:---:|
| <img src="https://raw.githubusercontent.com/yumimanji/dsh-ui-spec/main/docs/images/reference-ui.webp" width="420" alt="个人成长 UI 原始参考图"> | <img src="https://raw.githubusercontent.com/yumimanji/dsh-ui-spec/main/docs/images/deepseek-result.webp" width="420" alt="DeepSeek 根据插件规范实现的 UI"> |

上图由 `deepseek-v4-flash` 在 DSH 标准模式、`high` 思考强度下自主实现。插件支持“测量 → 实现 → 渲染 → 比较”的闭环：第一次渲染比较为 `77/100`，第二次提升到 `85/100`，最后三次稳定在 `85/100`。

## 插件输出内容

一次 `analyze_ui_image` 调用会同时返回 JSON 和面向模型的 Markdown，其中包含：

- 精确画布尺寸、布局活动带、间距证据和功能色彩令牌；
- 规范化 OCR 文案以及行级、词级坐标；
- 包含分区、分组、重复项、关系和置信度的层级场景图；
- 固定画布、允许文案、组件数量、导航槽位和禁止项组成的生成契约；
- 局部色板、形状描述、中文字体候选和可复用参考资产；
- 针对渲染结果的全局与分区比较指标；
- OCR 后端、回退状态和坐标精度等运行信息。

## 为什么纯文本模型需要它

纯文本模型无法直接观察像素。普通 OCR 只能提供文字，无法提供重建 UI 所需的视觉规则。本插件补全了这些实现证据：

1. **OCR 后端选择**：优先 Windows.Media.Ocr，原生 OCR 不可用时可在明确授权后回退到视觉模型。
2. **文本遮罩几何分析**：检测非文本组件前，先从图像中移除已识别的文字区域。
3. **多证据融合**：将文字、几何、颜色、重复关系和局部视觉细节组成统一场景图。
4. **生成约束**：给模型精确数量和文案白名单，减少自由发挥。
5. **渲染反馈**：从全局和场景分区两个层面评分，让模型优先修正最大误差。

## 快速使用

发布 npm 版本后安装：

```powershell
dsh plugin --profile web add dsh-ui-spec
```

安装 GitHub 当前版本（pnpm 11 要求显式允许构建脚本）：

```powershell
# 在使用方项目的 pnpm-workspace.yaml 中先加入：
# allowBuilds:
#   "dsh-ui-spec@git+https://github.com/yumimanji/dsh-ui-spec.git": true
dsh plugin --profile web add github:yumimanji/dsh-ui-spec
```

GitHub 源码包安装时会执行 `prepare` 构建。如果 DSH profile 无法提供这个 workspace 白名单，请改用已发布的 npm 包。

然后在 DSH 中告诉 DeepSeek：

```text
使用 ui-spec 分析 C:\path\to\reference.png，并实现对应的 Web UI。
```

模型会自行调用 `analyze_ui_image`。设置 `out_dir` 后还会生成：

```text
<name>.web.ui-spec.json
<name>.web.ui-spec.md
assets/reference-asset-*.png
```

## 核心能力

- 使用 `Windows.Media.Ocr` 在本机提取精确的词级和行级坐标。
- 非 Windows 环境可通过 OpenAI 兼容视觉接口回退，并明确标记坐标为近似值。
- 不会静默上传图片：自动远程回退必须得到明确授权。
- 过滤章节竖线等装饰性 OCR 误识别，避免装饰符变成可见文字。
- 匹配本机中文宋体、黑体、楷体候选。
- 提取复杂视觉区域作为参考资产，避免用通用图标替代。
- 比较像素 MAE、色板、边缘投影、OCR 对齐、画布尺寸和越权文案。
- 保留可选的传统视觉语义层。

## 工具参数

| 参数 | 必填 | 说明 |
|---|---:|---|
| `image_path` | 是 | 参考截图或设计图的绝对路径。 |
| `max_components` | 否 | 最多输出的底层组件候选，默认 `80`。 |
| `ocr_mode` | 否 | `auto`（默认）、`native` 或 `vision`。 |
| `allow_remote_fallback` | 否 | 原生 OCR 不可用时，允许 `auto` 模式上传图片。 |
| `enable_vision` | 否 | 请求额外视觉语义，同时允许远程 OCR 回退。 |
| `rendered_image_path` | 否 | 当前实现截图，用于确定性比较。 |
| `out_dir` | 否 | JSON、Markdown 和参考资产的输出目录。 |

## OCR 模式与隐私

| 模式 | 行为 |
|---|---|
| `auto` | 探测并优先使用 Windows.Media.Ocr；只有明确授权且配置视觉模型后才会远程回退。 |
| `native` | 强制原生 OCR；不可用时返回可操作的错误。 |
| `vision` | 直接使用已配置的视觉模型；选择该模式即明确允许上传图片。 |

能力探测检查实际运行环境，而不只是操作系统名称：系统平台、PowerShell、WinRT 初始化、OCR 引擎创建和识别语言均会验证。失败时返回稳定错误码，例如 `UI_SPEC_OCR_BACKEND_UNAVAILABLE`、`UI_SPEC_REMOTE_FALLBACK_NOT_ALLOWED` 和 `UI_SPEC_VISION_NOT_CONFIGURED`。

## DeepSeek 实测

测试日期：`2026-08-16`。

| 项目 | 结果 |
|---|---|
| Provider | `deepseek-official`，使用官方 API Key，密钥值未记录 |
| 模型 | `deepseek-v4-flash` |
| 思考强度 | `high` |
| DSH 预设 | `standard` |
| 原图 / 渲染尺寸 | `1024×1536` / `1024×1536` |
| 最终确定性得分 | `85/100` |
| 像素 MAE | `0.0481` |
| 色板距离 | `0.0364` |
| 文本对齐误差 | `0.0412` |

结构恢复正确：3 个分区、3 个底部导航项、4 个权益列表项和 7 个日历格。复杂插画使用插件提取的参考资产，没有被替换成通用头像。

完整会话日志确认模型共调用 `analyze_ui_image` 5 次：首次提取规范，随后进行 4 次渲染比较。这证明插件已经能支持可用的自主还原闭环，但不能视为像素级一致保证。

### 当前细节限制

- 权益列表图标仍是语义推断结果，是目前最大的分区误差来源；
- 日历印章、填充和边框仍需要更细的局部形状证据；
- 生成的签到按钮是胶囊形，原图为小圆角矩形；
- 渲染图 OCR 出现两个误报，触发了越权文案警告；
- 垂直投影差值为 `0.0349`，说明细微纵向间距仍有偏差。

当前版本适合作为高质量首版实现和迭代修正基线。下一阶段建议以 `>=93/100`、无越权文案警告、图标和印章使用参考证据为验收目标。

## 视觉回退配置

视觉 OCR 必须明确配置支持图片的模型：

```powershell
$env:DSH_UI_SPEC_VISION_API_KEY = "..."
$env:DSH_UI_SPEC_VISION_BASE_URL = "https://your-provider.example/v1"
$env:DSH_UI_SPEC_VISION_MODEL = "your-vision-capable-model"
$env:DSH_UI_SPEC_ALLOW_VISION_FALLBACK = "true"
```

`DSH_UI_SPEC_VISION_API_KEY` 会依次回退到 `DEEPSEEK_API_KEY` 和 `OPENAI_API_KEY`。当 `coordinate_precision` 为 `approximate` 时，应始终通过渲染比较校正最终位置。

## 环境要求与开发

普通使用默认已经配置好 DeepSeek Harness profile。原生 OCR 额外要求 Windows、PowerShell、WinRT OCR 和可用识别语言。Node.js 版本要求为 `>=22.19.0`。

开发者环境：

```powershell
git clone https://github.com/yumimanji/dsh-ui-spec.git
cd dsh-ui-spec
npm install
npm run typecheck
npm run build
```

`sharp` 提供预构建二进制，不需要 Python。`prepare` 生命周期会为 Git 安装和 npm 发布生成 `lib/`，`prepublishOnly` 会在类型检查失败时阻止发布。

### 修复 pnpm Store 不一致

如果 DSH 报告 `ERR_PNPM_UNEXPECTED_STORE`，说明该 profile 现有的 `node_modules` 是用另一条 pnpm store 路径创建的。这个错误发生在插件下载之前。使用当前 pnpm store 重建 profile 后重新执行 DSH 命令：

```powershell
cd $env:USERPROFILE\.dsh\profiles\web
Rename-Item node_modules node_modules.store-mismatch-backup
pnpm install
dsh plugin --profile web add dsh-ui-spec
```

确认 DSH 正常启动后再删除备份。不要在插件包中设置 `store-dir`；store 路径属于 DSH profile，所有插件必须使用同一个路径。

## 维护者发布

仓库是公开的，但 GitHub 不会自动把包发布到 npm。发布新版本：

```powershell
npm login
npm publish --access public
```

GitHub CLI 的登录状态不能用于 npm 登录。源代码、README 截图和包元数据需要单独提交并推送：

```powershell
git push origin main
```

## 许可证

[MIT](LICENSE)
