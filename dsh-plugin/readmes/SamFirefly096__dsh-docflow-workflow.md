# DSH 文档工作流（docflow）

在 DeepSeek Harness（DSH）中以 **Cordis 动态插件**形式运行的医学研究与文档处理工作流：

- **文档侧**：上传或拖入 docx / pdf / ppt / xlsx / txt 文件，按对话要求**生成 / 修改精美文档**（docx / pptx / pdf / xlsx），浏览器一键下载。
- **文献侧**：真实文献**检索、核查、提炼与审阅**（PubMed / Crossref 官方 API，GB/T 7714-2015 引文格式）。
- **科研侧（medkit，按需唤起）**：医学统计分析、统计作图、生信分析、网络药理学、汤液经法图、技术路线图、中医药配伍查询与安全性核验。

## 功能一览

### 文档处理（docflow 主插件）

| 能力 | 说明 |
| --- | --- |
| 📎 文件上传 | 浏览器面板 + 输入区按钮 + **拖入输入区**（图片拖入放行原生附件） |
| 📄 文档生成 | markdown → 精美 docx / pptx / pdf / **xlsx**（封面、6 套主题配色、表格、引用、代码块、页眉页脚页码；Excel 带主题表头与自动列宽） |
| ✏️ 文档修改 | 查找替换、改标题、追加内容、换主题色（输出为新文件）；**xlsx 支持单元格替换、追加工作表** |
| 🔄 格式转换 | docx / pptx / pdf 互转 |

### 文献检索与引用（docflow 主插件）

| 能力 | 说明 |
| --- | --- |
| 📚 文献检索 | **PubMed/Medline**（NCBI E-utilities 官方 API）真实检索，含 PMID、DOI、摘要 |
| 🔍 Crossref 补充 | DOI 权威注册库检索（中文期刊、会议论文、专著章节） |
| ✅ 文献核查 | 逐条与 PubMed / Crossref 官方数据比对，**防止引用不存在的文献** |
| 📖 引文格式 | **GB/T 7714-2015 顺序编码制**（中华口腔医学会格式），自动生成 `作者. 题名[J]. 刊名, 年, 卷(期): 页码.` |

### 医学研究套件（medkit，按需唤起）

> medkit 为**独立 host-only 插件**，仅在需要时激活、用完可停，**不常驻占用 token**。详见下方「按需唤起」。

| 能力 | 说明 |
| --- | --- |
| 📊 统计分析 | 两组比较（t 检验 / Mann-Whitney / Wilcoxon，含 Cohen d、Shapiro 正态性）、多组（ANOVA / Kruskal-Wallis）、分类（卡方 / Fisher）、相关（Pearson / Spearman）、ROC（AUC） |
| 📈 统计作图 | 箱线图、柱状图、折线图、散点图（含回归）、热图、森林图、火山图、ROC 曲线、生存曲线（PNG） |
| 🧬 生信分析 | 差异表达（t 检验 + log2FC + 火山图）、GO/KEGG 富集（超几何检验 + 条形图） |
| 🌐 网络药理学 | 成分-靶点二分网络、PPI 蛋白互作网络、Hub 基因（degree / betweenness） |
| 🀄 汤液经法图 | 五脏五味补泻规则（《辅行诀脏腑用药法要》）+ 补泻图 |
| 🗺 路线图 | 技术路线图 / 研究机制路径图 / 流程图（节点换行、自定义颜色） |
| 🪴 中医药查询库 | 190 味中药、83 组药对、80 首方剂、十八反十九畏、口腔黏膜病适用方剂速查 |
| 🛡 配伍核验 | 剂量上限（对照《中国药典》2020 参考量）、毒性药警示、十八反十九畏禁忌检查，附 PubMed 佐证 |

## 目录结构

```
.
├── engine/docflow_engine.py   # docflow 引擎：文档生成/编辑/提取 + 文献检索核查 + 中药核验（单文件无依赖）
├── plugin/docflow-host.js     # docflow 插件 Host 半体（RPC、模型工具、下载路由）
├── plugin/docflow-client.js   # docflow 插件 Client 半体（浏览器面板、上传按钮、拖放层）
├── plugin/docflow.json        # docflow 插件定义元数据（自动恢复说明）
├── medkit/
│   ├── medkit_engine.py       # medkit 引擎：统计/作图/生信/网络药理/汤液经法图/流程图/中药查询
│   ├── medkit-host.js         # medkit 插件 Host 半体（8 个模型工具，按需唤起）
│   ├── tcm_data.json          # 中医药数据库（分级标注：A=药典 / B=教材 / C=经典医籍）
│   └── medkit.json            # medkit 插件定义元数据
└── README.md
```

运行时目录（不入库）：`venv/`（Python 虚拟环境）、`uploads/`、`outputs/`、`tmp/`。

## 快速开始

### 1. 准备引擎环境（一次性）

```bash
cd .docflow
python3 -m venv venv
venv/bin/pip install python-docx python-pptx pdfplumber reportlab openpyxl \
                   matplotlib scipy statsmodels networkx pandas scikit-learn
```

### 2. 在 DSH 会话中定义并运行插件

**docflow**：`cordis_define`（`code.host` ← `plugin/docflow-host.js`，`code.client` ← `plugin/docflow-client.js`）→ `cordis_run` 激活（Client 半体需用户批准一次）。

**medkit**（按需）：仅当需要统计/作图/生信/网络药理/汤液经法图/路线图/中药查询核验时，`cordis_define`（`code.host` ← `medkit/medkit-host.js`，无 client）→ `cordis_run` 激活；用完 `cordis_stop` 释放。

> 动态插件在 DSH 进程重启后丢失。已提供持久化定义与「文档工作流」agent preset（会话启动自动恢复 + medkit 按需唤起指令）。

### 3. 引擎命令行（也可独立使用）

```bash
# docflow 引擎
venv/bin/python engine/docflow_engine.py decode-file <b64文件> <out>       # base64 → 二进制
venv/bin/python engine/docflow_engine.py extract <file>                     # 提取全文 → JSON
venv/bin/python engine/docflow_engine.py create <fmt> <out> [spec.json]    # 生成 docx/pptx/pdf/md/txt/xlsx
venv/bin/python engine/docflow_engine.py edit <fmt> <in> <out> [spec.json] # 修改文档
venv/bin/python engine/docflow_engine.py lit-search <term> [n]             # PubMed 检索
venv/bin/python engine/docflow_engine.py lit-crossref <query> [n]          # Crossref 检索
venv/bin/python engine/docflow_engine.py lit-verify <refs.json>            # 引文真实性核查
venv/bin/python engine/docflow_engine.py tcm-verify <items.json> [0]       # 中药配伍核验（0=跳过PubMed佐证）

# medkit 引擎
venv/bin/python medkit/medkit_engine.py stats   <spec.json>   # 统计分析
venv/bin/python medkit/medkit_engine.py plot    <spec.json>   # 作图（spec.out 为 PNG 路径）
venv/bin/python medkit/medkit_engine.py bio     <spec.json>   # 生信（diff/enrich）
venv/bin/python medkit/medkit_engine.py network <spec.json>   # 网络药理（herb_target/ppi）
venv/bin/python medkit/medkit_engine.py tangye  <spec.json>   # 汤液经法图
venv/bin/python medkit/medkit_engine.py flow    <spec.json>   # 技术路线图/机制路径图
venv/bin/python medkit/medkit_engine.py tcm     <spec.json>   # 中药/药对/方剂/禁忌查询
```

### 4. 模型工具

**docflow**：`docflow_create_document` · `docflow_edit_document` · `docflow_parse_document` · `docflow_list_documents` · `docflow_export_document` · `docflow_literature_search` · `docflow_literature_crossref` · `docflow_literature_verify`

**medkit**：`medkit_stats` · `medkit_plot` · `medkit_bio` · `medkit_network` · `medkit_tangye` · `medkit_flow` · `medkit_tcm_query` · `medkit_tcm_verify`

## 中医药数据真实性

`medkit/tcm_data.json` 内置数据库（190 味中药 / 83 药对 / 80 方剂 / 十八反十九畏）按以下机制保障可靠性：

- **来源分级**：每条数据标注 `grade`（A=《中国药典》2020 原文 / B=规划教材《中药学》共识 / C=经典医籍）与 `source`（具体出处）
- **在线核验**：`medkit_tcm_verify` 对照药典参考剂量上限表核验剂量、标记毒性药（附子、半夏、细辛等）、自动检出十八反（如"甘草反甘遂"）与十九畏（如"人参畏五灵脂"）禁忌组合，并可检索 PubMed 佐证文献
- **免责声明**：查询输出统一标注"AI 整理分级、供科研参考、临床处方须经执业中药师审核"

## 主题配色

`blue / green / red / purple / gold / slate`——自动应用到封面、标题、表格表头、引用块、图表与页脚。

## 技术说明

- **下载**：插件通过 `webServer` 注册 `/dsh-docflow/download/<id>` 前缀路由；地址为相对路径，浏览器按当前页面 origin 解析，任意访问方式（IP/域名/端口转发）均可下载。
- **文件传参**：上传 base64 与生成 spec 均先落盘再交给 Python 处理，规避沙箱 stdin 传递的不确定性；所有 fs/shell 写操作显式声明 `workspace-write` 沙箱策略。
- **文献来源**：PubMed/Medline（NCBI E-utilities：esearch → esummary → efetch）与 Crossref REST API，均为官方公开接口；检索带速率控制（NCBI 3 req/s）。
- **按需唤起**：medkit 为独立 host-only 插件，不常驻注册工具；需要时激活、用完可停，避免浪费 token。
