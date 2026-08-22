# DSH K12 English Lesson Builder

这是一个面向初中英语教师的 DeepSeek Harness 插件。它读取教师自己提供的教材、课程标准、PowerPoint 模板和 Word 教案模板，先形成一份统一教学蓝图，再从同一份蓝图生成同步对应的可编辑 PPTX 与 DOCX。

插件不内置教材、课程标准或模板，也不会把文件上传到独立服务。所有输入、中间文件和输出都必须位于当前 DSH 任务工作区内。

## 环境要求

- Windows 10/11；
- 已安装桌面版 Microsoft Word 和 Microsoft PowerPoint；
- DeepSeek Harness `0.1.0-rc.6`；
- PowerShell 7。

当前版本使用 Office COM 自动化，因此不支持 macOS、Linux、WPS 或纯网页版 Office。

## 安装

在本仓库执行：

```powershell
npm install
npm test
npm pack
dsh plugin --profile web add .\dsh-k12-lesson-builder-0.1.1.tgz
dsh --profile web --dump-config
```

卸载：

```powershell
dsh plugin --profile web remove dsh-k12-lesson-builder
```

## 教师需要准备的文件

把下列四个文件放入当前 DSH 工作区：

1. 教材：`.pdf` 或 `.docx`；
2. 课程标准：`.pdf` 或 `.docx`；
3. PPT 模板：`.pptx`，至少有一个“标题 + 正文/内容”版式；
4. Word 教案模板：`.docx`，包含以下 11 个内容控件 Tag，每个 Tag 必须唯一：

```text
lesson_title
grade_unit
lesson_type
duration
objectives
key_points
difficulties
procedure
assessment
homework
ppt_map
```

在 Word 中可通过“开发工具 → 控件 → 属性 → 标记”设置 Tag。

## 使用方式

在 DSH 中直接描述任务，例如：

> 请用 `inputs/textbook.pdf`、`inputs/standards.docx`、`inputs/template.pptx` 和 `inputs/template.docx`，为七年级 Unit 1 Reading 第 4—5 页生成 1 课时、45 分钟的 PPT 和 Word 教案，输出到 `outputs/unit-1`。

Agent 的标准流程是：

1. 调用 `prepare_k12_lesson_sources` 提取教师来源并检查模板；
2. 依据来源包中的 `blueprintContract` 创建 `lesson-blueprint.json`；
3. 调用 `render_k12_lesson_materials`；
4. 先生成 PPT，取得最终页码，再把页码映射写入 Word 教案；
5. 重新打开两个文件并生成审计 JSON。

典型输出：

```text
outputs/unit-1/lesson-日期-时间-短ID/
├── source-package.json
├── template-report.json
├── lesson-blueprint.json
├── Unit-1-Reading.pptx
├── Unit-1-Reading.docx
└── Unit-1-Reading-audit.json
```

已有同名文件不会被覆盖，新文件会自动使用 `(2)`、`(3)` 等后缀。生成失败的半成品会移动到 `failed/`。

## 边界与隐私

- 插件只接受当前工作区内的普通文件，拒绝工作区外路径和符号链接；
- 单个输入文件默认上限为 50 MB，提取文本默认上限为 20 万字符；
- 教材与课程标准只读打开，集成测试会核对输入哈希不变；
- 插件本身不调用第二个模型，蓝图由当前 DSH Agent 在可见会话中生成；
- 审计确认文件可重新打开、PPT 页 ID 完整、Word 11 个内容控件已填充，但不能替代教师对教学内容的专业终审。

## 常见问题

- `invalid-template`：检查 Word Tag 是否缺失/重复，以及 PPT 是否含标题和正文占位符。
- `outside workspace`：把输入文件移入当前任务工作区，再使用工作区相对路径。
- Office 被占用或弹窗：先保存并关闭正在编辑的同名文件，再重试。
- 教材 PDF 为扫描图片：当前版本不含 OCR，请先转换为可复制文本的 PDF 或 DOCX。

本项目目前对齐 DeepSeek Harness `0.1.0-rc.6` 开发者预览版；DSH 插件接口升级后需要重新验证兼容性。
