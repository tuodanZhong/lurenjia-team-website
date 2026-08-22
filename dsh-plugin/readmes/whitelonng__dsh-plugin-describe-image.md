# dsh-plugin-describe-image

[English](README.md) | 中文

**DeepSeek Harness 图片理解插件** —— 面向模型的 `describe_image` 识图工具，让**纯文本模型**（DeepSeek V4 等）也能看懂图片。

一个 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 插件：面向模型的 `describe_image` 工具。它加载一张图片——本地文件路径、http(s) URL 或持久附件引用——并请求 **OpenAI 兼容端点**上的**视觉语言模型（VLM）**（Qwen-VL、GLM-4V、GPT-4o 或本地 Ollama 端点）描述它。只有返回的**文本**跨入对话，图片本身从不进入会话日志。关键词：DeepSeek Harness 插件、describe_image 工具、图片理解、图像描述、多模态、视觉语言模型、VLM、纯文本模型、Qwen-VL、GLM-4V、GPT-4o、Ollama。

## 安装

```sh
dsh plugin --profile web add github:whitelonng/dsh-plugin-describe-image
```

桌面应用的插件列表安装框可直接粘贴同一条 spec（`github:whitelonng/dsh-plugin-describe-image`），插件在应用重启后加载。

## 特性

- **三种输入形式**：本地路径、http(s) URL，或 `[image attachment …]` 注记里的 JSON（经 harness 附件服务解析——把注记原样复制进 `image` 即可）。
- **实时配置卡片**：Web GUI「设置 → 插件 → 图像理解」卡片可直接改 `baseURL`、`model` 与 API Key（走凭据缝），保存立即生效、无需重启。
- **逐调用 API Key 解析**：内联 `apiKey` → 凭据缝（`apiKeyEnv`，默认 `VISION_API_KEY`）→ 启动环境。
- **安全与边界**：每次请求拒绝重定向，`maxBytes` / `maxOutputTokens` / `timeoutMs` 上界，魔数媒体类型闸门，错误摘要有界，密钥绝不入日志。
- **配套 harness 改动**（随 harness 仓库发布，不在本子树内）：DeepSeek 纯文本路由把图片块压平为可复制的 `[image attachment …]` 注记，宿主在纯文本路由上接受图片提示——两者一起闭环「把图片发给纯文本模型」。

## 快速开始（在 DeepSeek Harness 检出内）

```yaml
# cordis.yml
- id: describe-image
  name: '@deepseek-ai/dsh-tool-describe-image'
  config:
    baseURL: https://dashscope.aliyuncs.com/compatible-mode/v1
    model: qwen-vl-max
    apiKey: !!js process.env.VISION_API_KEY
```

## 常见问题

**这个插件是干什么的？**
给 DeepSeek Harness 增加 `describe_image` 工具：Agent（或用户）把一张图交给工具，工具让配置好的视觉语言模型描述它，只有描述文本回到对话里。

**支持哪些视觉模型？**
任何 OpenAI 兼容的视觉端点：Qwen-VL（`https://dashscope.aliyuncs.com/compatible-mode/v1`）、GLM-4V、GPT-4o，或本地 Ollama 端点。在「设置 → 插件 → 图像理解」里配好 `baseURL` 与 `model` 即可。

**图片本身会进入对话或会话日志吗？**
不会。图片被加载、校验后只发给视觉端点；会话日志与模型只看到返回的描述文本。

**怎么安装？**
执行 `dsh plugin --profile web add github:whitelonng/dsh-plugin-describe-image`，或把同一条 spec 粘贴进桌面应用的插件安装框，随后重启应用。

**API Key 怎么配置？**
三层解析，按序：配置里的内联 `apiKey`、凭据缝（`apiKeyEnv`，默认 `VISION_API_KEY`）、启动环境。密钥从不写入日志。

**对恶意输入安全吗？**
拒绝重定向、按魔数校验媒体类型、限制体积与输出 token、错误摘要截断——恶意图片或端点无法窃取密钥。

## 仓库布局

```
packages/vision/
├── README.md                  # vision 能力家族
└── tool-describe-image/       # 插件包（源码 + 测试 + 文档）
```

本仓库保存插件子树**在 `deepseek-harness` 内的原样**：包依赖保持 `workspace:^`，构建、类型检查与测试都在 harness 检出中完成（见 [INTEGRATION.md](INTEGRATION.md)）。harness 树才是构建环境，而不是本仓库。两边保持同步：

```sh
git subtree push --prefix packages/vision dsh-describe-image main   # 在 harness 检出中执行
```

## 致谢

- [LINUX DO](https://linux.do) — 本项目在 LINUX DO 社区持续分享与讨论。

## License

[MIT](LICENSE)
