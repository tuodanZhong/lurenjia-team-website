# dsh-image-understanding

让 **deepseek-harness (dsh)** 里的纯文本模型（如 DeepSeek）也能"看见"你上传的**图片** —— 自动调用阿里云百炼 `qwen-vl` 把图片转成文字描述再喂给模型，全程对模型透明，无需切换多模态模型。

> 配套说明：本插件是 [deepseek-vision](https://github.com/rison114514/deepseek-vision)（WorkBuddy 钩子版）在 deepseek-harness 上的**原生插件重写版**。两者核心差别见文末「与 deepseek-vision 的差别」。

## 原理（两道闸都堵上）

deepseek-harness 对纯文本模型有**两道**图片拦截：

1. **Gate 1 — 提交校验**：`apiproxy` 在消息含图时查模型 `inputModalities`，DeepSeek 是 `['text']`，直接报错"当前模型不支持图片"。
2. **Gate 2 — 序列化校验**：`serialize.ts` 的 `assertTextOnly` 对 image block 无条件拒绝。

本插件在**插件层**同时解决，不碰 harness 源码：

- 包装 `ctx.llm.resolveModelInfo`，让 deepseek 系纯文本模型"声称"支持 image，骗过 Gate 1；
- 在 `agent/pre-step` seam（serialize 之前）把 `ImageBlock` 经 `attachments.readImage()` 取字节 → 百炼 `qwen-vl` 识别 → 替换为 `【图片识别】…` 文本块，DeepSeek 全程只见纯文本（Gate 2）；
- 仅模拟 deepseek 系纯文本模型；真·视觉模型原样透传，不被二次转换。

另外注册了一个显式 tool `image_understanding`，可手动按图片路径或 data URL 调用。

## 前置条件

- 已本地安装并构建 [deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)（能跑 `pnpm dsh web`）
- 一个阿里云百炼 API Key（OpenAI 兼容模式，申请：https://bailian.console.aliyun.com/ ）

## 安装

```bash
# 一行安装（从 GitHub 以 DSH bundle 形式装入指定 profile）
dsh plugin --profile web add github:rison114514/dsh-image-understanding
```

装好后启动 web：`dsh web`（或 `pnpm dsh web`）。

## 使用

开 **新会话** → 选择 DeepSeek 主模型 → 直接拖入 / 上传图片并输入"描述这张图" → 预期：

- 不再弹出"当前模型不支持图片"
- 图片被 qwen-vl 自动识别为文字描述并回填，DeepSeek 据此作答

也可在对话中显式调用 `image_understanding` 工具，传入图片**本地绝对路径**（或 data URL）做按需识别。

## 配置项（Web UI：设置 → 插件 → 插件配置 → image-understanding）

启动后在网页端「设置」→「插件」→「插件配置」里找到 **image-understanding** 卡片，按需填写并保存（改动即时生效，无需重启）：

| 字段 | 说明 | 默认 |
|---|---|---|
| `api_key` | 阿里云百炼 API Key（`sk-...`），必填；页面以只写输入框呈现，明文不会回传 | — |
| `model` | 视觉模型 ID | `qwen3-vl-flash` |
| `base_url` | OpenAI 兼容接口地址 | `https://dashscope.aliyuncs.com/compatible-mode/v1` |
| `timeout` | 单次调用超时（秒） | `20` |

> 想直接改文件也行：对应 `$DSH_HOME/settings.yaml` 里的 `image-understanding:` 小节，字段同上。

## 与 deepseek-vision 的差别

| 维度 | deepseek-vision（旧） | dsh-image-understanding（本插件） |
|---|---|---|
| 宿主 | WorkBuddy，靠 `UserPromptSubmit` 钩子**外部进程** | deepseek-harness，cordis **原生插件** |
| 图片获取 | 钩子读 stdin 的 `transcript_path` jsonl 取真实路径 | 直接用 harness 内部 `attachments.readImage()` 取字节 |
| 注入方式 | 识别结果写 `additionalContext` 注入 | pre-step 改写消息 + `resolveModelInfo` 包装骗过能力校验 |
| 安装 | `install.sh` 改 `settings.json` 后重启 | `pnpm dsh web --patch cordis.patch.yml` 热加载 |
| 额外能力 | 支持 SVG（Chrome headless 渲染） | 多注册了显式 `image_understanding` tool，支持图片路径 / data URL 按需识别 |

**一句话核心差别**：旧版是"在 WorkBuddy 外部挂一个钩子进程去拦截消息"，新版是"在 deepseek-harness 内部作为原生插件、从消息序列化之前就接管图片"——更内聚、无外部进程依赖、不依赖解析 stdin 的隐式字段。

## 已知限制

- 仅对 deepseek 系纯文本模型自动生效；其他模型需本身支持图片或不会被模拟。
- 单图识别失败会降级为 `【图片识别失败】…` 文本，不阻断对话。
- 拖放 / 上传图片受 harness 附件通道限制，仅支持 jpg/png/webp/gif；SVG、PDF 等非常规格式暂未做预处理。
