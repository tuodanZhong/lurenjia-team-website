# dsh-plugin-multimodal

[English](README.md) | **中文**

为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 提供**图像识别**与**图像生成**能力的插件（`dsh-plugin`，即 Cordis 插件）（后续会拓展语音）。

**工具**：`image_recognize`、`image_generate`、`vision_providers` 三个模型工具，调用您在配置中声明的**外部 API 模型**（视觉 chat/completions；图像生成支持 OpenAI 兼容 `images/generations` 与阿里云百炼原生异步协议）。**不内置、不默认任何模型** —— 未配置模型时工具调用会直接报错并提示如何配置，绝不猜测、绝不静默失败。

## 图片演示

| 图片识别 | 图片生成 |
|---|---|
| ![图片识别演示](./data/bfd22e009098d2d8d9d1788fb88e62cb.png) | ![图片生成演示](./data/d2d795fc9b2dd76a4f5a419ebb3c44af.png) |

## 功能特性

- **`image_recognize`（识别图片）** —— 传入图片（本地路径 / http(s) URL / data URI），调用配置的视觉模型（多模态 chat/completions）理解并返回文字结果：看图说话、OCR、识别图表截图、审核图片等
  - 本地图片自动转 base64 data URI 内联发送（上限 25 MiB）
  - 支持 `prompt`（问什么）、`max_tokens` / `temperature`、按 `provider` 指定用哪个视觉模型
- **`image_generate`（生成图片）** —— 调用配置的图像生成模型生成或转换图片，保存到磁盘；返回文件路径，启用静态服务时还会返回可在 Web 中渲染的 URL
  - **文生图**：OpenAI 兼容 `images/generations`（优先 b64_json，端点不支持时自动重试下载 URL）；或阿里云百炼原生异步任务协议（`protocol: dashscope-native`，提交 → 轮询 → 下载）
  - **图生图**：传入 `image` 参数（源图）即可在生成时以它为输入（编辑/变体/风格迁移）。OpenAI 兼容端点用 `image` 字段；DashScope 原生用 `base_image_url`
  - **默认去水印**：OpenAI 兼容端点请求体自动带 `watermark: false`（豆包 Seedream 等支持该参数；端点不认会自动去掉重试），provider 设 `watermark: true` 可恢复
  - **Web 对话内直接显示**：内置静态图片服务（默认 127.0.0.1:3081）把生成图以绝对 http(s) URL 暴露，工具返回 Markdown `![](url)` 链接，模型放进回复正文即可在 Web GUI 直接看到图片（GUI 的 Markdown 渲染器只接受绝对 http(s) URL，本地路径/相对链接/Data URI 一律不渲染；DSH 自带 webserver 不服务任意文件，写入前端 dist 目录实测也不生效）
  - **扩展名按真实格式**：base64 结果按文件魔数（PNG/JPEG/WebP/GIF）修正扩展名，Content-Type 与内容一致
  - 支持 `size`（如 1024x1024）、`n`（1~4 张，多张自动加序号）、`output_path`（目录或文件路径）
  - 默认保存到 `<当前工作区>/generated/`，文件名带时间戳
- **`vision_providers`（查看已配置模型）** —— 列出所有已配置的外部 API 模型（id、类型、模型名、端点、是否已填 apiKey），帮助模型选择合适的 provider id
- **多模型切换** —— `providers` 列表可配置任意多个模型；每个工具调用可用 `provider` 参数指定 id，省略时用该类型的第一个
- **未配置仅在调用时报错** —— 没有该类型的 provider、provider id 不存在、apiBase、model 或 apiKey 为空，都会在调用工具时抛出带修复指引的中文错误，不会阻止 DSH Web 启动

## 安装到 DSH profile

DSH 的插件命令会把安装操作转交给 `pnpm`，因此无论 DSH 本身以哪种方式运行，
都必须先确保 `pnpm` 已加入 `PATH`。本地源码包的入口是 `lib/index.js`，安装前先构建：

```sh
cd C:/projects/dsh-harness/dsh-multimodal
pnpm install
pnpm run build
```

然后根据 DSH 的实际运行方式选择命令：

```sh
# 通过 npx 运行 DSH（系统中没有全局 dsh 命令）
npx @deepseek-ai/dsh plugin --profile web add file:C:/projects/dsh-harness/dsh-multimodal

# 从 deepseek-harness 源码运行（需在该仓库根目录执行）
pnpm dsh plugin --profile web add file:C:/projects/dsh-harness/dsh-multimodal

# 已安装可全局调用的 dsh 命令
dsh plugin --profile web add file:C:/projects/dsh-harness/dsh-multimodal
```

包内同时提供了 `prepare` 生命周期脚本，使用 Git 地址安装时会在安装阶段构建。
本地 `file:` 安装仍建议在 `add` 前显式构建，以便直接确认运行入口已经生成。

然后用同一种启动方式重启 Web profile（`npx @deepseek-ai/dsh web`、
`pnpm dsh web` 或 `dsh web`）并开**新会话**（旧会话工具集固定）。包内
`cordis.patch.yml` 是部署配置源（包内覆盖外层；settings.yaml 与用户 profile patch
只补充包内未声明的键）。

> **⚠️ 修改配置后如何生效（重要）**：web profile 使用 `nodeLinker: hoisted`，`file:` 插件以**复制**方式装入 profile（不是符号链接），所以改完 `cordis.patch.yml` 必须重新同步：
> 1. 删除 `<DSH_HOME>\profiles\web\node_modules\dsh-plugin-multimodal`（快照目录）
> 2. 执行 `<你的 DSH 启动命令> plugin --profile web install`
> 3. 用同一种启动方式重启 Web profile
>
> 注意：直接重新执行 `dsh plugin add` **不会**重新复制已存在的内容，删快照后 install 才可靠。

## 使用方法

### 1. 配置外部 API 模型（必需）

编辑插件包内 `cordis.patch.yml` 的 `providers` 列表，填写 `apiBase`、`apiKey` 与 `model`（**这些连接参数均没有可直接使用的默认值**）。参数留空时插件和 DSH Web 仍能启动，只有调用对应工具时才会校验并报错。协议是 OpenAI 兼容的，任意厂商均可：

```yaml
providers:
  # 图像识别：多模态 chat/completions
  - id: my-vision
    kind: vision
    apiBase: https://api.openai.com/v1        # 或硅基流动 https://api.siliconflow.cn/v1 等
    apiKey: sk-xxxx                            # 你的 API Key
    model: gpt-4o                              # 或 Qwen/Qwen2.5-VL-72B-Instruct 等
    # maxTokens: 1024      # 可选
    # temperature: 0.2     # 可选

  # 图像生成：一个 provider 同时覆盖文生图与图生图。
  # （火山引擎方舟豆包 Seedream 也是这套协议）
  - id: my-image
    kind: image
    apiBase: https://api.openai.com/v1        # 或 https://ark.cn-beijing.volces.com/api/v3
    apiKey: sk-xxxx
    model: gpt-image-1                         # 或 doubao-seedream-5-0-pro-260628 等
    # i2iModel: doubao-seedream-3-0-i2i-250528  # 可选：图生图模型（传 image 时自动切换）。
    #                                           #   同一模型支持图生图时（如 Seedream 5.0 Pro）可省略
    # watermark: false      # 默认 false（去水印），无需填写
    # size: 1024x1024      # 可选默认尺寸

  # 图像生成（文生图）：阿里云百炼原生协议（compatible-mode 网关没有
  # images 路由时用这个；实测 wanx2.1-t2i-turbo 出图无水印）。
  # 阿里云 t2i/i2i 是不同模型，所以用 i2iModel 声明图生图模型。
  - id: my-image-wanx
    kind: image
    protocol: dashscope-native
    apiBase: https://dashscope.aliyuncs.com
    apiKey: sk-xxxx
    model: wanx2.1-t2i-turbo
    i2iModel: wanx-v1                          # 图生图模型（输入图须为公网 http(s) URL）
    size: '1024*1024'      # DashScope 尺寸用星号分隔
```

`id` 必须唯一；同一端点可配置多个模型（不同 id）；视觉与生图可指向不同厂商。`image_generate` **不区分文生图/图生图**：传了 `image` 参数就是图生图（自动用 `i2iModel`，未配置则用同一 `model`），不传就是文生图。

### 2. 验证插件已生效

开**新会话**，问模型：*"你有 image_recognize / image_generate 工具吗？"* —— 或让它执行 `vision_providers` 查看已配置的模型。

### 3. 模型能做什么

- **识别** —— *"识别这张图 C:\path\to\photo.png 里有什么"* → `image_recognize`
- **文生图** —— *"画一只戴帽子的橘猫，保存到 output 目录"* → `image_generate`，返回生成图片的文件路径
- **图生图** —— *"把这张图 https://.../a.png 里的猫变成蓝色（用 my-image-wanx）"* → `image_generate` 传 `image` + `provider`
- **查模型** —— *"你现在能用哪些图像模型？"* → `vision_providers`

### 未配置时会发生什么

DSH Web 和插件仍可正常使用，只有实际调用的工具会报错，例如：

```
multimodal: provider "my-vision" 未配置 apiBase。请在插件包内 cordis.patch.yml 的 providers 中填写 OpenAI 兼容端点，然后重启 Web profile。
```

## 配置

| 键 | 默认值 | 含义 |
|---|---|---|
| `providers` | schema 默认为 `[]`；包内补丁提供两个留空、可编辑的示例 | 外部 API 模型列表。每项包含 `id`（唯一）、`kind`（`vision` / `image`）、`apiBase`、`apiKey`、`model`（调用该 provider 时必填）、`protocol`（生图协议：`openai` 或 `dashscope-native`），以及可选的 `i2iModel` / `watermark`（默认 `false`）/ `size` / `maxTokens` / `temperature` |
| `outputDir` | 空（= `<调用方工作区>/generated`） | 生成图片默认保存目录；相对路径基于调用方工作区，绝对路径按原样使用 |
| `staticPort` | `3081` | 内置静态图片服务端口（127.0.0.1），生成图通过 `http://127.0.0.1:<port>/<文件名>` 供 Web GUI 渲染 Markdown 图片；`0` 关闭（只返回本地路径）；端口被占用自动降级 |

`image_recognize` 工具参数：`image`（必填：本地路径 / URL / data URI）、`prompt`、`provider`、`max_tokens`、`temperature`。
`image_generate` 工具参数：`prompt`（必填）、`image`（可选：图生图源图，本地路径 / URL / data URI）、`provider`、`size`、`n`（1~4）、`output_path`（目录以 `/` 或 `\` 结尾）。

## 开发

```sh
npm install --cache ./.npm-cache   # 安装构建与测试依赖
npm run build                      # tsc 编译到 lib/
npm test                           # 单元测试（stub API，无需网络）
node scripts/verify.mjs            # 挂载验证：插件可加载、工具注册、未配置报错契约
```

peer 依赖（`@deepseek-ai/cordis`、`@deepseek-ai/dsh-tools`、`@deepseek-ai/schemastery`）也作为开发依赖供本地构建和测试使用；插件安装后使用 DSH profile/runtime 提供的兼容 peer 版本。

## 已知限制

- **本地图片内联上限 25 MiB** —— 更大的图片请压缩或改用 URL
- **生成图片格式识别** —— PNG/JPEG/WebP/GIF 的 base64 结果按实际格式保存，未知格式回退为 PNG；URL 下载结果按响应 Content-Type 决定扩展名
- **DashScope 图生图需要公网图片 URL** —— 阿里云 `base_image_url` 不接受本地路径与 data URI（实测拒绝）。本地图片请先上传到公网（阿里云 OSS / 任意图床）再传 URL；`wanx2.1-imageedit` 等部分模型对 URL 校验更严（实测拒绝 wanx 结果 URL），用 `wanx-v1` 做图生图最稳
- **旧会话看不到新工具** —— 插件安装/升级后请开新会话
- **部分非标准兼容端点** —— 若端点不支持 `response_format`，插件会自动重试一次；仍失败会返回远端的原始错误信息

## License

MIT
