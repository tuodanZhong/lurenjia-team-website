# dsh-multimodal — DeepSeek Harness 多模态插件

[English](README.md) | 简体中文

给 DeepSeek 安装一双眼睛和一支画笔:会话里直接贴截图/图片,你配置的视觉提供商先精确转写图片内容(报错信息、代码、界面逐字保留),然后 **DeepSeek 继续处理你的问题**——同一轮完成,全程无感;需要配图时,DeepSeek 自动调用你配置的生图后端出图并显示在会话中。

> **设计上就是空白插件**:本插件**不预置任何模型、提供商或后端**。视觉端点、生图后端、模型全部由*你*声明——接入任何你已有的 API(DeepSeek / 智谱 / 阿里云 / 硅基流动 / 魔搭 / 讯飞 / 千帆 / 本地 Ollama…)。代码里没有任何写死的模型或服务商。

> **兼容性**:适配 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) `0.1.0-rc.6`(Web 与 headless 双端)。更新记录见 [CHANGELOG](CHANGELOG.md)。

## 功能

| 场景 | 行为 |
|---|---|
| 纯文本对话 | 全部走 DeepSeek API(不变) |
| 发图 + 提问(如报错截图) | 你配置的视觉提供商先"看"→ 转写为文本注入 → **DeepSeek 基于转写继续处理**(修代码、解释、给方案);点"停止"立即中止视觉调用 |
| 附图时 UI | **不再弹"当前模型不支持图片"** |
| 用户要求画图 | DeepSeek 自动调用 `generate_image` → 你配置的生图后端出图;主后端失败自动 **failover** 到备用后端(AUTH/已取消不浪费配额) |
| 任意生图 API | `custom` 后端通过一个小的适配器文件接入任何非 OpenAI/DashScope 协议的 API——无需改插件代码 |
| 生图卡片 | 专属图片卡片:缩略图网格、点击放大(Lightbox)、一键保存、提示词与模型信息,外加**圈选提问**(拖拽区域+提问)、**复制参数**(可复现 JSON)、失败时**重试**按钮(支持 refine) |
| 要求提取图中文字 | DeepSeek 可调用 `extract_text`(OCR)→ Markdown / 纯文本 / JSON;与观看路由解耦,任何会话可用 |
| **粘贴 Key 自动接入**(0.7+) | 设置页快速接入框粘贴任意 API Key → 自动识别平台(Key 指纹 → `/models` 探测)→ 一步完成接入 + 启用功能 + 预填模型列表 |
| 接入视觉平台 | `extraProviders` 支持任意 OpenAI 兼容视觉端点 + **一键预设卡片**(智谱 / 阿里百炼 / 讯飞星辰 / 魔搭 / 硅基流动 / 千帆 / 本地 Ollama) |
| 转写缓存 | 相同图片+相同上下文直接复用上次转写结果,不重复消耗视觉额度(LRU,按会话隔离) |
| 视觉降级链 | 主视觉提供商限流/失败 → 自动切换 `fallbackProviders` 备用提供商 |
| 并行转写 | `parallelImages` 每张图独立并发转写,多图轮次大幅提速 |
| 场景模式 | 内置 `transcribeMode` 预设:`error-fix`(报错截图诊疗)、`chart-sql`(图表→SQL+Pandas)、`design-code`(设计稿→HTML+CSS) |
| 成本路由 | 小图(≤ `costMaxPixels`)自动走廉价提供商 |
| 本地视觉 | 一键 Ollama 预设,敏感图不出内网(见[本地视觉模型](#本地视觉模型敏感图不出内网)) |
| 配置迁移 | 设置页把全部配置导出/导入为 JSON(仅允许白名单字段) |

## 安全加固

自 `0.2.1` 起,插件针对恶意或手工篡改的配置做了以下加固:

- **API Key 白名单**(`allowedApiKeyEnvs`):只有白名单内的环境变量/凭据名可被当作 API Key 读取——恶意配置无法再用 `apiKeyEnv: "GITHUB_TOKEN"` 之类的手段窃取任意环境变量密钥
- **信任域名列表**(`trustedBaseUrls`):自定义视觉平台必须指向官方主机或你显式信任的域名——凭据不会被静默重定向到攻击者端点;显式列出的**本地端点**(如 `http://localhost:11434`)允许 http 且无需 Key
- **SSRF 防护**:生图结果下载与 `reference_image` URL 均拒绝回环 / 内网(RFC1918)/ 链路本地地址
- **不转发 sessionId**:内部会话 ID 不会发送给第三方视觉 API
- **Prompt injection 标记**:视觉与 OCR 输出均以显式"不可信上下文"标记包裹后再交给文本模型
- **敏感信息脱敏**(`redactSensitive`):转写文本(含缓存命中)自动打码手机号 / 18 位身份证 / 邮箱
- **审计日志**(`auditLog`):每次转写记录 时间 / 图片数 / 字节数 / 耗时 / 提供商
- **内存有界**:转写缓存、会话图片记忆、图片类型统计全部 LRU 有上限——不会无限增长

## 安装

前置:官方 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)(`0.1.0-rc.6+`)已安装并可运行、Node.js 18+。

```sh
# 方式一:直接引用 GitHub 仓库(需要 git)
dsh plugin --profile web add https://github.com/MC5lan/dsh-multimodal

# 方式二:克隆到本地后,用本地路径安装
git clone https://github.com/MC5lan/dsh-multimodal.git
dsh plugin --profile web add /path/to/dsh-multimodal

# headless 模式同样需要时:
dsh plugin --profile headless add /path/to/dsh-multimodal
```

仓库已包含构建产物(`lib/`),克隆后即可安装;如需从源码重新构建,见[开发](#开发)一节。

重启 `dsh web` 后,Settings(设置)侧栏出现 **「多模态」** 页面,所有配置在一个界面完成:

- **状态总览**:四张指标卡(识图 / 生图 / 平台接入 / 密钥)一眼看清已配置与缺失项
- **快速开始**(仅未配置时显示):两步引导卡——"想让 DeepSeek 看图?"→ 选平台 → 粘贴 Key;"想让它画图?"→ 添加后端。配置完自动消失
- **密钥管理**:**视觉转写 Key**(负责"看"图的视觉端点)与**图像生成 Key**(生图后端密钥)——粘贴保存即生效
- **视觉转写**:观看路由、转写提供商、转写模式,以及四个开关(并行转写 / 截图场景提示 / 敏感脱敏 / 审计日志)
- **生图后端管理**:协议下拉(dashscope 异步 / dashscope-v2 同步 / OpenAI 兼容 / 自定义适配器)添加、移除、切换后端,各自独立配置 base URL、Key 引用、模型与默认尺寸
- **平台接入**:**粘贴 Key 自动识别**——在快速接入框粘贴任意 API Key,插件自动判断平台(先 Key 指纹匹配,再逐个 `/models` 探测已知端点;Key 一次性传输、不落盘),注册端点、白名单 Key 环境变量、写入凭据,并自动预填发现的模型列表。**任何 OpenAI 兼容 API 都能用**。卡片点选(讯飞星辰 / 魔搭 / 硅基流动 / 千帆 / 智谱 / 阿里百炼 / 本地 Ollama)与自定义端点表单仍作为手动路径保留

## 使用

1. **最快路径(推荐,0.7+)**:设置 → 多模态 → 快速接入 → **粘贴你的 API Key** → 自动识别平台并接入(端点 + 白名单 + Key + 模型列表一步完成,识图/画图自动启用)。识别不了的 Key 会提示原因,再手动点平台卡片或自定义端点
2. **手动路径**:点平台预设卡片(智谱 / 阿里百炼 / 讯飞星辰 / 魔搭 / 硅基流动 / 千帆 / 本地 Ollama)粘贴 Key,或自定义端点;也可以在 `providers.deepseek.models` 里给内建 DeepSeek 路由槽位声明模型
3. **状态栏**:识图 ✓/✗ · 画图 ✓/✗ —— 按真实可用功能计算(转写提供商已设且已注册 / 后端已激活),不会"注册过就显示已配置"
4. Web UI 模型选择器里选择 `deepseek-vision` 路由下的模型(如 DeepSeek-V4-Flash (Vision))——该路由的会话才带"眼睛"
5. 正常对话;需要看图时直接粘贴/拖入图片 + 提问;需要画图时直接说"帮我画一张……"

## Key 配置(也可直接写凭据文件)

设置 → 多模态 → 密钥管理 页面可直接写入两把 Key。想直接改凭据文件(路径为 `$DSH_HOME/.credentials.yaml`,默认 `~/.dsh/.credentials.yaml`),保存即生效:

```yaml
VISION_API_KEY: <你的视觉端点key>   # 视觉转写(对应 UI 里的"视觉转写 Key")
IMAGE_API_KEY:  <你的生图后端key>   # 图像生成(对应 UI 里的"图像生成 Key")
```

> 这些是你的*自有*平台 Key——任何你在平台接入里注册的 OpenAI 兼容端点,都按你给它的环境变量名(`apiKeyEnv`)读 Key。

## 工作原理(架构)

```
用户附图 ──▶ host 准入(模型目录声明 image 模态 → 放行,不弹窗)
         ──▶ agent/pre-step(插件):检测图片 → 调你配置的视觉引擎转写
             └─▶ 图片块替换为"【图片内容转写】…"文本
         ──▶ DeepSeek API 处理转写 + 你的问题(图片本身绝不上传 DeepSeek)
```

- `deepseek-vision` 路由 = DeepSeek API + 一份声明支持图片的模型目录,让 UI 允许附图;图片实际由你配置的视觉提供商转写替换,**不会发给 DeepSeek**
- 图片字节经 dsh 附件服务读取,转写指令默认"逐字转写 + 提取报错关键信息",可在 `~/.dsh/settings.yaml` 的 `dsh-multimodal:` 段自定义
- 转写失败时降级为"【图片转写失败: 原因】"占位文本,DeepSeek 继续处理,不会卡死
- 设置界面:Settings → 多模态(settings.section 槽位,与 Models 页同款原生 UI)

## 配置项(可选,`~/.dsh/settings.yaml`)

```yaml
dsh-multimodal:
  # 0.2.1+ 安全:只有白名单内的环境变量名可被当作 API Key 使用
  allowedApiKeyEnvs:
    - DEEPSEEK_API_KEY
    # - MY_PROVIDER_API_KEY     # 自定义平台的 Key 环境变量名加在这里
  # 0.2.1+ 安全:允许接收凭据的自定义视觉平台域名
  trustedBaseUrls:
    # - https://my-vision.example.com   # 自定义平台的域名加在这里
  providers:
    deepseek:
      models: []                 # 可选:在 DeepSeek 路由槽位上声明模型
  vision:
    watchProvider: deepseek-vision  # 该路由的会话带"眼睛"
    transcribeProvider: ''          # 负责"看"的提供商(留空 = 关闭识图)
    fallbackProviders: []           # 0.2.2+: 主提供商限流/失败时依次尝试的备用提供商
    transcribeMode: auto            # auto | verbatim | structured | ocr | describe | error-fix | chart-sql | design-code
    parallelImages: false           # 0.2.5+: 每张图独立并发转写
    costProvider: ''                # 0.2.5+: 小图专用廉价提供商(成本路由)
    costModel: ''
    costMaxPixels: 1000000          # 像素数 ≤ 此值的图片走 costProvider
    sceneHints: true                # 0.2.5+: 截图转写附加诊断提示
    customModes: {}                 # 0.2.4+: 自定义模式名 → 提示词(插件化 transcriber)
    redactSensitive: false          # 0.2.4+: 转写文本打码手机号/身份证/邮箱
    auditLog: false                 # 0.2.4+: 每次转写记审计日志(时间/图片数/字节数/耗时/提供商)
  ocr:
    provider: ''                    # OCR 工具引擎(留空 = 禁用;任意已注册视觉提供商都可用)
    model: ''
  image:
    backends: {}                    # 后端在 UI 里添加,不预置任何项
    activeBackend: ''               # 生图后端 key(留空 = 不启用生图)
    failoverOrder: []               # 0.2.5+: 主后端失败时依次尝试的后端 key
    verifyChineseText: true         # 0.2.3+: 用视觉模型检查生图中文字是否乱码
    verifyProvider: ''              # 乱码检查用的视觉提供商(留空 = 不检查)
  transcribePrompt: ...             # 自定义转写指令
  transcribeTimeoutMs: 90000        # 转写超时

  # 任意 OpenAI 兼容视觉平台(填 key 即可用,自动出现在模型选择器与 Models 页)
  extraProviders:
    xfyun-vision:                   # 讯飞星辰 MaaS
      displayName: 讯飞星辰视觉
      baseURL: https://maas-api.cn-huabei-1.xf-yun.com/v2
      apiKeyEnv: XFYUN_API_KEY
      models:
        - id: xoppaddleocrv16       # 免费 OCR(PaddleOCR-VL-1.6)
          name: PaddleOCR-VL-1.6
    siliconflow-ocr:                # 硅基流动(DeepSeek-OCR 免费托管)
      displayName: 硅基流动 OCR
      baseURL: https://api.siliconflow.cn/v1
      apiKeyEnv: SILICONFLOW_API_KEY
      models:
        - id: deepseek-ai/DeepSeek-OCR
          name: DeepSeek-OCR
    modelscope-vision:              # 魔搭(ModelScope,每天 2000 次免费)
      displayName: 魔搭视觉
      baseURL: https://api-inference.modelscope.cn/v1
      apiKeyEnv: MODELSCOPE_API_TOKEN
      models:
        - id: Qwen/Qwen3-VL-8B-Instruct
          name: Qwen3-VL-8B
```

生图后端(OpenAI 兼容 `/images/generations` 与 DashScope 协议)示例 —— 在 UI 里添加或直接写在这里:

```yaml
dsh-multimodal:
  image:
    backends:
      z-image:                      # 阿里云 Z-Image 系列(新协议 multimodal-generation 同步)
        kind: dashscope-v2
        baseURL: https://dashscope.aliyuncs.com
        apiKeyEnv: DASHSCOPE_API_KEY
        model: z-image-turbo
        defaultSize: 1024*1024      # 支持 512*512 ~ 2048*2048
      modelscope-t2i:
        kind: openai-images
        baseURL: https://api-inference.modelscope.cn/v1
        apiKeyEnv: MODELSCOPE_API_TOKEN
        model: <模型广场有闪电标记的生图模型>
    activeBackend: z-image
```

### 自定义生图后端(0.2.6+)

任何既不是 OpenAI 兼容也不是 DashScope 协议的 API,都可以通过一个**小型适配器文件**接入,无需改插件代码。写一个 ES 模块,默认导出带 `generate()` 函数的对象:

```yaml
dsh-multimodal:
  image:
    backends:
      my-api:
        kind: custom
        adapterFile: D:/my-adapters/my-api.mjs   # 绝对或相对路径
        baseURL: https://api.example.com/v1       # 传给适配器
        apiKeyEnv: MY_API_KEY
        model: my-image-model
        defaultSize: 1024*1024
    activeBackend: my-api
    failoverOrder: [z-image]                      # 失败时可回退到另一个已配置后端
```

适配器收到 `{ prompt, size, n, negative_prompt, reference_image, apiKey, baseURL, model, signal, fetch, log }`,返回 `{ urls: string[], b64s: string[] }`。模板见 [`scripts/adapters/example-custom.mjs`](scripts/adapters/example-custom.mjs)。**`adapterFile` 只指向你信任的文件** —— 适配器拥有完整进程权限。异步轮询类后端可逐后端调整 `pollIntervalMs` / `pollTimeoutMs`。

## 本地视觉模型(敏感图不出内网)

插件转写走任意 OpenAI 兼容端点,因此本地 [Ollama](https://ollama.com) 视觉模型可让图片数据完全留在本机。一键预设:设置 → 多模态 → 平台接入 → **+ 本地 Ollama**(自动把 `http://localhost:11434/v1` 加入 `trustedBaseUrls`;本地端点无需 API key)。

模型矩阵(按显存选择):

| 模型 | `ollama pull` | 显存 | 说明 |
|---|---|---|---|
| `llava` | `ollama pull llava` | ~4 GB | 经典 7B,基础 OCR |
| `llava-llama3` | `ollama pull llava-llama3` | ~6 GB | 基线更强 |
| `qwen2.5vl:7b` | `ollama pull qwen2.5vl:7b` | ~6 GB | 中文文字更好 |
| `minicpm-v` | `ollama pull minicpm-v` | ~6 GB | 文档/OCR 专精 |
| `qwen2.5vl:32b` | `ollama pull qwen2.5vl:32b` | ~20 GB | 高质量,大显存 |

接入前可先对比各提供商表现:

```sh
node scripts/benchmark-vision.mjs shot.png \
  my-endpoint=https://your-vision-api.example.com/v1,your-model,YOUR_API_KEY_ENV \
  ollama=http://localhost:11434/v1,llava,SKIP
```

## 故障排查

| 现象 | 原因与解决 |
|---|---|
| 发图后回复"【图片转写失败: MISSING_CREDENTIAL…】" | 视觉 Key 未配置:设置 → 多模态 → 密钥管理 里填 Key,或写凭据文件 |
| 发图后回复"【图片转写失败: RATE_LIMIT…】" | 免费档限流,稍后重试或换付费档 |
| 识图不生效(图片被忽略) | `vision.transcribeProvider` 为空:设置 → 多模态 → 视觉转写 里填一个已注册的提供商 |
| 设置里没有"多模态"入口 | 确认插件已挂载(`dsh --profile web --dump-config` 应包含 dsh-multimodal),并强制刷新浏览器(Ctrl+F5) |
| 自定义视觉平台被跳过并提示"not trusted" | 该平台域名未在白名单:`trustedBaseUrls` 加入它的域名(或改用官方主机);同时确保它的 Key 环境变量名在 `allowedApiKeyEnvs` 里 |

## 开发

```sh
npm install
npm run build      # host: tsc;client: tsc 检查 + tsdown 打出 lib/client.js
```

## 许可

[MIT](LICENSE)
