# DSH 考研英语外刊出卷插件（dsh-kaoyan-english）

一个运行在 DeepSeek Harness（DSH）中的**动态 Cordis 插件**：自动抓取《卫报》《今日心理学》《经济学人》等外刊文章，调用大模型命制一套**考研英语（一）模拟卷**完形，阅读和翻译部分，并保存到指定目录。

> 5 道阅读理解选择题 + 5 道句子翻译题 + 20 空完形填空，一次生成，附答案与中文解析。

## ✨ 功能特性

- **一键出卷**：抓文章 → 大模型出题 → 校验 → 保存，全程自动化
- **多刊物支持**：guardian（卫报）、psychologytoday（今日心理学）、economist（经济学人）、bbc、theatlantic、scientificamerican、npr、time、sciencedaily、nature，以及自定义 RSS
- **考研风格命题**：阅读覆盖主旨/推断/细节/态度/词义；翻译题按难度评分**自动挑选长难句**（从句嵌套/非谓语/被动/抽象名词等，≥18 词优先）；完形 20 空由插件确定性挖空，正确选项必含原文词
- **保留原文分段**：阅读正文与完形短文保持原文段落结构（空行分隔），并自动过滤导航/署名等页面噪声行
- **可靠的结构化输出**：最低推理档位 + 工具调用（tools）+ 文本回退 + 多重校验与自动重试
- **确定性流水线**：切句、选句、挖空全部由插件完成，模型只负责「翻译」和「命题」，结果可确定性校验
- **自动跳过短文**：从列表第 `pick` 篇起顺延查找 ≥400 词的文章（最多 6 篇）
- **卫报官方 API 支持**：可选 `guardianApiKey` 获取更干净的全文

## 🛠 注册的工具

| 工具 | 功能 |
|---|---|
| `enexam_list` | 通过 RSS 列出外刊最新文章（标题/链接/日期/摘要） |
| `enexam_fetch` | 抓取单篇文章正文纯文本（标题/作者/日期/词数） |
| `enexam_save` | 把命制好的试卷素材保存到指定目录 |
| `enexam_make` | **一键出卷**：抓取 + 命题（5 阅读 + 5 翻译 + 20 完形）+ 保存 |

## 🚀 在 DSH 中加载

动态插件是**进程内临时**的（DSH 重启后需重新加载），加载方式为在 DSH 会话中让 AI 执行动态插件工具：

1. 用 `cordis_define` 定义插件：`code.host` 的内容即本仓库 [`src/host.js`](src/host.js)（整个文件去掉头部注释即可直接粘贴）；
2. 用 `cordis_run` 激活返回的 `pluginId` / `packageId`；
3. 加载成功后，直接对话即可使用，例如：

```
用今日心理学最新文章出一套卷，保存到 D:\考研英语
抓这篇文章的题：https://www.psychologytoday.com/us/blog/xxx/xxxx
先看看 NPR 最近有什么文章
```

> 希望插件**常驻**：可将同一份代码写入你自己的 Agent Preset（参考 DSH 的 `editing-cordis-compositions` 流程），随会话自动加载。

## 📝 工具参数

### enexam_make（一键出卷）

| 参数 | 说明 |
|---|---|
| `source` | 刊物标识（未提供 `articleUrl` 时必填） |
| `articleUrl` | 文章 URL，优先于 source |
| `rssUrl` | `source=custom` 时的 RSS 地址 |
| `pick` | 从列表第几篇开始选（默认 1，太短自动顺延） |
| `dir` | 保存根目录（默认当前工作区） |
| `guardianApiKey` | 卫报开放平台 API key（可选） |

### 输出结构

每次出卷自动创建子目录 `<来源>_<日期>_<标题>/`：

```
├── 00_原文.md          # 原文全文与来源信息
├── 01_阅读理解.md      # 5 道选择题（Part A 风格）
├── 02_句子翻译.md      # 5 句英译汉
├── 03_完形填空.md      # 20 空完形（含选项）
├── 04_答案与解析.md    # 全部答案 + 中文解析 + 参考译文
└── meta.json           # 结构化试卷数据
```

## 🌐 网络可达性说明

插件优先使用 DSH 的 `web.fetch` 服务，不可用时自动回退到 `curl.exe`/PowerShell 抓取。注意：

- **中国大陆网络**下，guardian / economist / bbc / theatlantic / time 可能无法直连（插件会给出明确报错）；
- **推荐**：npr、sciencedaily、nature、psychologytoday；
- 经济学人等付费墙站点可能只能取得文章开头部分。

## 🏗 工作原理

```
RSS 列表 ──► 抓取正文 ──► 文本清洗（HTML 转纯文本）
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
   阅读理解                句子翻译              完形填空
   大模型 JSON 命题        插件切句/选句          插件截选段/挖 20 空
   （tools 结构化输出）     逐句直译（纯文本）      大模型只出选项/解析
        │                     │              （正确项必含原文词，确定性校验）
        └─────────────┬───────┘                     │
                      ▼                             ▼
                   校验 + 重试 ◄────────────────────┘
                      │
                      ▼
              生成 6 个 Markdown/JSON 文件保存到指定目录
```

- **模型调用**：沿用会话当前模型（`agentDefaultModel`），自动选择最低 reasoning 档位并禁止“先思考”，max-tokens 耗尽时自动加倍重试；
- **沙箱适配**：通过 `sandboxPolicy.resolve({ session })` 透传会话策略，`fs.writeText` 自动创建父目录；
- **每处副作用均可回收**：工具注册全部绑定在插件 Fiber 上，stop/undefine 即自动清理。

## 📚 示例

[`examples/`](examples/) 中是一套完整示例卷（来源 Psychology Today，《How the Brain Chooses What Matters》），含全部 6 个文件，可查看最新版排版与命题风格：阅读 5 题（保留原文分段）、翻译 5 句（自动挑选长难句）、完形 20 空（保留原文分段）。

## 📄 许可证

[MIT](LICENSE) © 2026 Monokuna-Hugo
