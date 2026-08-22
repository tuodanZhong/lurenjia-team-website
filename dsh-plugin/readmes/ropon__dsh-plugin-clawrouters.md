# dsh-plugin-clawrouters

[English](README.md) | 简体中文

把 [ClawRouters](https://www.clawrouters.com/) 接入 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)：安装一个 DSH 组合包，在 Web UI 配置一份 API Key，即可使用对话、生图、生视频和联网搜索。

## 为什么做这个插件

ClawRouters 用一个 OpenAI 兼容 API 和一份凭证提供多种 AI 能力。本插件把这些能力映射到 DSH 原生插件接口，不需要再运行一套独立应用：

- `clawrouters / auto` — OpenAI 兼容对话路由，支持图片输入。
- `clawrouters_image_generate` — 生图并保存为 DSH 持久图片附件。
- `clawrouters_video_generate` — 提交并轮询视频任务，完成后返回签名结果 URL。
- `clawrouters_web_search` — 返回结构化标题、摘要和来源 URL，不会替换 DSH 已有的通用 `web_search` provider。

## 安装

要求：DeepSeek Harness `0.1.0-rc.6` 或更新版本，且 `PATH` 中存在 pnpm。

把带版本标签的 GitHub 仓库安装进 Web profile：

```sh
dsh plugin --profile web add github:ropon/dsh-plugin-clawrouters#v0.1.1
dsh web
```

仓库已经提交构建后的 `lib/`，因此从 GitHub 安装时不需要配置 pnpm `allowBuilds`，也不会执行安装期构建脚本。

开发时可直接安装本地 checkout：

```sh
dsh plugin --profile web add .
dsh web
```

## 只配置一份 Key

1. 打开 DSH Web 或 Desktop。
2. 进入 **设置 → 模型 → ClawRouters**。
3. 粘贴 ClawRouters API Key 并保存。
4. 在对话模型选择器中选择 **clawrouters / auto**。

Web UI 会通过 DSH 凭证服务把密钥保存到 `CLAWROUTERS_API_KEY`，不会写进 `settings.yaml`。对话路由和三个工具每次调用都会解析同一份凭证，因此轮换 Key 不需要重新构建插件。

也可以通过启动环境提供 Key：

```sh
export CLAWROUTERS_API_KEY='...'
dsh web
```

## 工作原理

本仓库是一个 DSH bundle。[`cordis.patch.yml`](cordis.patch.yml) 完成两件事：

1. 向 DSH 内置的通用 `llm-pi-ai` 适配器增加 `clawrouters` provider profile。复用已有的 `llm-pi-ai` 设置 namespace，原生模型设置页会直接显示 ClawRouters 凭证卡，不需要浏览器补丁或 fork。
2. 插入 `dsh-plugin-clawrouters` 函数插件，把生图、生视频和搜索工具注册进 `ctx.tools`；可选的 `ctx.attachments` 存在时，用它持久化图片。

默认 API 地址为 `https://www.clawrouters.com/api/v1`。如需调整工具侧部署默认值，可以在更后的 profile patch 中定位 `id: clawrouters-tools` 覆盖：

```yaml
- id: clawrouters-tools
  config:
    apiKeyEnv: CLAWROUTERS_API_KEY
    baseURL: https://www.clawrouters.com/api/v1
    imageModel: auto
    videoModel: auto
    imageTimeoutMs: 600000
    videoTimeoutMs: 1800000
    searchTimeoutMs: 30000
    videoPollIntervalMs: 5000
```

## 端点映射

| 能力 | ClawRouters API |
|---|---|
| 对话 | 通过 DSH pi-ai 适配器调用 `POST /chat/completions` |
| 生图 | `POST /images/generations` |
| 生视频 | `POST /videos`，兼容回退到 `POST /videos/generations`，随后 `GET /videos/{id}` |
| 联网搜索 | `POST /search` |

每个直连 provider 请求都会携带 DSH 归因 `User-Agent` 和 bearer 凭证。图片 URL 只接受 HTTP(S)，下载后会解码、检查格式、通过 DSH 附件策略校验，并在工具结果写入日志前持久化。视频结果 URL 同样只允许 HTTP(S)。

## 延后能力

- **嵌入 / 向量搜索：** ClawRouters 可以生成 embedding，但可用的向量搜索还需要存储、索引、元数据过滤和相似度检索。本插件会在 DSH 出现向量库接口后接入；目前刻意不把大段浮点数组当作聊天工具返回。
- **文本转语音 / 语音转文本：** 延后到 DSH 具备持久音频附件、上传处理及播放器/录音 UI 后实现。把 base64 音频作为文本返回既昂贵也不可用。
- **持久视频：** DSH 当前没有视频附件块，因此插件返回 provider 签名 URL，不会把视频字节复制进会话存储。

## 开发

```sh
pnpm install
pnpm check
```

测试覆盖图片持久化、视频轮询、结构化搜索结果、鉴权 Header 和 bundle 形态。仓库提交构建产物，是为了支持从 GitHub 直接安装 DSH bundle。

## 许可证

[MIT](LICENSE)
