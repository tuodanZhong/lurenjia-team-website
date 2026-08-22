<p align="center">
  <a href="./README.md">English</a> · <strong>简体中文</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-22c55e?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/DeepSeek%20Harness-Plugin-7C3AED?style=flat-square" alt="DeepSeek Harness 插件"/>
  <img src="https://img.shields.io/badge/version-0.1.1-0891b2?style=flat-square" alt="版本 0.1.1"/>
</p>

# easy-vision

**让仅支持文本的智能体获得"看图"能力 —— 通过任意 OpenAI 兼容视觉模型。**

easy-vision 是一个 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 工具插件，注册了一个面向模型（model-facing）的 `describe_image` 工具。当模型需要查看截图、照片、图表、UI 设计稿或任何本地图片时，它会以文件路径调用该工具。插件会：

- **自动识别真实格式** —— 通过魔数（magic bytes）识别 PNG / JPEG / GIF / WebP，即使文件扩展名错误也能正确处理
- **发送图片** —— 以 base64 data URI 通过 chat completions 发送给你配置的 **OpenAI 兼容视觉模型**
- **返回文字描述** —— 或可选择直接写入 Markdown 文件，用于 UI 说明文档、设计稿笔记等

这让运行在纯文本路由上的模型（例如某个拒绝图片输入的网关上跑的 `deepseek`）也能通过文字"看到"图片。

## 使用效果

用自然语言让智能体"看一下"某张图片，`describe_image` 工具就会把它转换成可用的文字描述——并可选择直接写入 Markdown 文件。

![调用工具描述图片](img/usage-describe.png)

![返回的文字描述结果](img/usage-result.png)

![结果预览 / 文档输出](img/usage-preview.png)

## 快速开始

该包是零依赖的纯 ESM Cordis 插件，只注入 `tools`。需要先把包装进你的 DSH profile，再在 patch 层进行挂载。

### 第一步：安装到 DSH profile

**从 npm 安装：**
```powershell
dsh plugin --profile web add easy-vision
```

或者直接在 profile 目录下运行 pnpm：
```powershell
cd "$env:DSH_HOME\profiles\web"
pnpm add easy-vision
```

> `@deepseek-ai/cordis` 声明为 peer 依赖 —— DSH 已在运行时提供，无需额外安装。

### 第二步：在 patch 层挂载

将其添加到 DSH patch 文件 —— 例如 home 级 `$DSH_HOME\cordis.patch.yml`（作用于所有 profile）或某个 profile 的 `cordis.patch.yml`：

```yaml
- insert:
    - id: easy-vision
      name: easy-vision
      config:
        baseUrl: https://example.com/v1
        model: your-vision-model
        apiKeyEnv: YOUR_API_KEY
        timeoutMs: 120000
```

保存即可 —— DSH 会热重载 `cordis.patch.yml` 的改动。新会话即可把 `describe_image` 工具暴露给模型。

### 第三步：配置视觉模型 API key

工具会按 `apiKeyEnv` 解析密钥：先查环境变量，再回退到从 `$DSH_HOME\.credentials.yaml` 读取同名 key。如果该 key 还不是环境变量，请在这里添加：

```yaml
# C:\Users\Z\.dsh\.credentials.yaml
YOUR_API_KEY: sk-...
```

> 如果 profile 在这几步之前就已经启动，请重启该 profile（或打开新会话），以便工具 schema 能被模型使用。

## 配置

| 字段         | 默认值                     | 说明                                                                  |
| ------------ | -------------------------- | --------------------------------------------------------------------- |
| `baseUrl`    | `https://example.com/v1`  | OpenAI 兼容的 chat completions 基础 URL。                             |
| `model`      | `your-vision-model`       | 视觉模型的 ID。                                                       |
| `apiKeyEnv`  | `YOUR_API_KEY`            | API key 的环境变量名；同时会回退到从 `$DSH_HOME/.credentials.yaml` 读取同名 key。 |
| `timeoutMs`  | `120000`                   | 请求超时时间（毫秒）。                                                 |

## 模型体验

`describe_image` 的工具描述会告诉模型：当用户要求查看 / 浏览 / 描述 / 分析 / 识读一张图片时自动调用它，并能识别自然语言意图（例如「描述一下 / 看一下 / 分析这张图」）—— 用户**无需**指定工具名。

| 参数       | 必填 | 说明                                                              |
| ---------- | :--: | ----------------------------------------------------------------- |
| `path`     | ✅   | 图片的本地绝对路径。                                              |
| `prompt`   | —    | 指定要提取的重点（例如提取 UI 布局/配色、描述人物、OCR 文字）。   |
| `outFile`  | —    | 用于写入描述的 `.md` 文件绝对路径；必要时会自动创建父目录。       |

## 已知限制

- 需要一个 **OpenAI 兼容** 且接受 base64 `image_url` data URI 的端点。
- API key 从环境变量或 `$DSH_HOME/.credentials.yaml` 读取；并未接入 DSH 自身的 provider 路由。
- 视觉结果是纯文字 —— 描述并非真实图片，因此精细的空间精确度受限于视觉模型本身所报告的内容。

## 构建与打包

```bash
npm run prepack   # 将 src 复制到 lib
npm pack          # 生成 easy-vision-0.1.1.tgz
```

## License

[MIT](LICENSE) —— 可自由使用、修改与分发。
