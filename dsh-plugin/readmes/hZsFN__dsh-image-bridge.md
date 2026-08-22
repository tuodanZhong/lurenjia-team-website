# dsh-image-bridge

[![CI](https://github.com/hZsFN/dsh-image-bridge/actions/workflows/ci.yml/badge.svg)](https://github.com/hZsFN/dsh-image-bridge/actions/workflows/ci.yml)

让**不支持图片输入**的模型（如 DeepSeek）也能接收图片消息的 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (dsh) 插件。

原理：图片消息到达模型前，`agent/pre-step` 钩子把消息里的 image 块替换为**文本占位**（含附件本地路径 + 识图脚本调用指令）。agent 收到后调用自带识图脚本（默认 qwen 视觉模型）描述图片，再基于描述回答。**模型请求里永远只有文本**，不会触发适配器的图片拒绝逻辑。

## 为什么需要它

- dsh 的模型适配器（如 DeepSeek 的 `assertTextOnly`）对历史消息里的 image 块会直接抛 `UNSUPPORTED_CONTENT`——一张图进过会话后，之后**每一轮**都失败。
- apiproxy 在 prompt 入口也会按 `modelInfo.inputModalities` 拒绝无图模型的图片消息。
- 本插件 + 两个小 patch（见下）解决整条链路。

## 安装

1. 把本仓库的 `index.js` 和 `vision-qwen.mjs` 放进 profile 目录（两个文件必须同目录，或自行配置脚本路径）：
   ```
   ~/.dsh/profiles/web/image-bridge-plugin/{index.js, vision-qwen.mjs}
   ```
2. 在 `~/.dsh/profiles/web/cordis.patch.yml` 注册：
   ```yaml
   - insert:
       - id: image-bridge
         name: ./image-bridge-plugin/index.js
         config:
           enabled: true
           # visionScript: 自定义识图脚本路径（可选；默认同目录 vision-qwen.mjs，
           #               也可用环境变量 DSH_VISION_SCRIPT）
   ```
3. 配置识图 API Key：环境变量 `DASHSCOPE_API_KEY`（阿里云百炼 DashScope，千问视觉模型）。
   脚本也会回退读取 `$DSH_HOME/.credentials.yaml` 里的 `DASHSCOPE_API_KEY`。
4. 重启 dsh web。

### 配套 patch（dsh 升级后需要重打）

发布版的插件本身只做"图片 → 文本占位"的替换；要让图片**能进到这一步**，还需要两处官方包补丁（升级 dsh 后丢失需重打）：

1. **apiproxy 放行**：`@deepseek-ai/dsh-host-apiproxy` 两处图片模态检查改为绕过
   - `lib/index.js` 与 `lib/types/api-proxy.js`：`if (modelInfo.inputModalities ...)` → `if (false && ...)`
2. **DeepSeek 适配器图片中和**（关键配套，缺了"消息都发不进来"）：
   - `@deepseek-ai/dsh-llm-deepseek/lib/index.js`：`assertTextOnly` 从"抛错"改为"把 image 块中和成文本占位"，`serializeMessages` 使用中和后的 content。
   - 该补丁同时自动治愈已中毒的会话（历史里的图片序列化为占位文本）。

> ⚠️ 改动 dsh 官方包属于高危修改：改前备份、改后 `node --check` 验证、重启后测试。

## 工作原理

```
用户发图 ──▶ GUI 附件落盘 $DSH_HOME/attachments/v1/objects/<ab>/<sha256>
                │ (apiproxy patch 放行无图模型)
                ▼
        agent/pre-step 钩子（本插件）
         ├─ await next() 拿完整 decision（保留 persona/工具上下文）
         └─ image 块 → 文本占位：[图片…本地文件 <path>。先用识图脚本…node vision-qwen.mjs "<path>"…]
                │
                ▼
        模型（纯文本请求）→ agent 调用 vision-qwen.mjs（qwen3.7-plus）→ 描述图片 → 回答
```

- 图片占位包含附件 sha256 本地路径，agent 可直接用文件工具读取或调用识图脚本。
- 脚本按文件**魔数**识别格式（png/jpeg/gif/webp），附件路径无扩展名也能读。

## 识图脚本

`vision-qwen.mjs <图片路径> [自定义提示词]`

- 模型：`qwen3.7-plus`（DashScope OpenAI 兼容端点，实测支持图像输入）
- 密钥：`DASHSCOPE_API_KEY`（环境变量或 `$DSH_HOME/.credentials.yaml`）
- 可单独使用：`node vision-qwen.mjs photo.png "描述这张照片"`

## License

MIT
