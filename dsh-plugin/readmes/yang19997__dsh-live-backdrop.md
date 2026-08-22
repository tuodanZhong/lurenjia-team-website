# dsh-live-backdrop

DSH Web GUI 动态背景 + **UI 主题接管**插件：**静态图 + GIF + MP4/WebM 视频背景**，以及**不依赖任何皮肤插件的界面外观系统**（三个视觉方向预设 + 六色五形参全部可调）。

架构参考 dsh-skins 皮肤体系（皮肤注册 / 路由 / 插槽 / 持久化机制），**不含任何皮肤资产**，不照搬任何现成皮肤。

## 特性

| 能力 | 说明 |
|---|---|
| 多格式背景 | jpg / png / webp / avif / bmp / **gif** / **mp4** / **m4v** / **webm** |
| 换图方式 | 把素材丢进素材目录（**可自定义到任意盘符**，如 D 盘，默认 `~/.dsh/backgrounds/`），面板点「刷新」即出缩略图，**点选即换、无需重启** |
| 选择持久化 | 当前背景、素材目录、所有开关与主题配置存 `~/.dsh/dsh-live-backdrop.json`，重启自动恢复 |
| 性能保护 | 标签页不可见自动暂停视频；`prefers-reduced-motion` 时不自动播放；低内存设备（<4GB）自动降级为静态帧 |
| 内存保护 | 关闭总开关即**卸载媒体元素**（真正释放解码内存）；任何时刻只存在一个媒体元素 |
| **UI 主题接管** | 覆盖官方 `--dsw-*` token 与形状：主色/应用背景/面板背景/边框/文字色 ×6，应用不透明度/面板不透明度/边框不透明度/毛玻璃/圆角/边框粗细 ×6，**改哪变哪、即时预览** |
| **滑杆 + 数字双通道** | 每个形参都有滑杆粗调与数字输入精确值（不透明度默认 60%） |
| **三个视觉方向** | 玻璃拟态 / 极简扁平 / 沉浸夜色，各含亮暗两套配色，选完仍可逐项微调（自动标记「自定义」） |
| **官方设置页集成** | 面板挂在官方设置页「插件 → 插件配置」（官方 `settings.plugin.item` 插槽）；全部基于官方平台能力，安装/卸载零侵入 |
| 主题适配 | 面板样式走 `--dsw-*` token，自动跟随明暗主题；遮罩浓度 0–100% 可调 |
| 打开素材夹 | 面板一键在文件管理器中打开素材目录 |

### 与第三方皮肤/插件的关系

- 本插件不依赖任何第三方 UI 包，面板入口在官方设置页（**设置 → 插件 → 插件配置 → 动态背景**）；
- 主题模块把配置写入 body 内联样式（优先级高于一切样式表规则），并订阅 `theme/change` 在官方主题写入**之后**重新覆盖——即「完全接管」，其他皮肤的选择器覆盖压不过本插件；
- 可与其他皮肤/插件共存；即使移除了其他皮肤插件，本插件的背景、主题、面板全部照常工作。注意：若启用了第三方皮肤，移除前先切回官方默认外观，否则启动清单会引用不存在的皮肤包。

## 安装

```powershell
# 在项目根目录（本仓库）
pnpm install
pnpm build          # 产出 packages/dsh-live-backdrop/lib/{index.js,client.js}

# 安装进 DSH web profile（link 本地包，改源码后重跑 build 即可）
dsh plugin --profile web add link:$(pwd)/packages/dsh-live-backdrop

# 把插件行写入 profile 用户补丁层（C:\Users\<你>\.dsh\profiles\web\cordis.patch.yml）：
#   - insert:
#       - id: live-backdrop
#         name: 'dsh-live-backdrop'
```

> **为什么插件行要写在用户补丁层而不是包的 cordis.patch.yml**：DSH 宿主的 HMR 只热监听用户补丁层（profile 的 cordis.patch.yml 与 ~/.dsh/cordis.patch.yml），bundle 补丁层是启动时快照。写在用户补丁层可「装完立即生效、无需重启」，且重启后依然持久。若两层同时写同一 id，会因重复插件 id 导致启动失败（本包内的 cordis.patch.yml 因此留空，仅含说明注释）。

安装后刷新 GUI 页面，进入 **设置 → Web UI 插件 → 动态背景**。

## 日常迭代（改代码后如何生效）

| 改动 | 生效方式 |
|---|---|
| 改 **client** 代码（面板/引擎/主题控制器） | `pnpm build` → 刷新页面即生效 |
| 改 **host** 代码（store/routes/入口） | `pnpm build` → **重启 GUI**（DSH 宿主对 host 插件模块无热替换，需要完整重启进程） |
| 换素材 | 丢进素材目录 → 面板点「刷新」 |

> 卸载：
> ```powershell
> dsh plugin --profile web remove dsh-live-backdrop
> # 并删除 profiles/web/cordis.patch.yml 中 live-backdrop 的 insert 行
> ```

## 素材目录与规格建议（性能关键）

目录：`~/.dsh/backgrounds/`（可用环境变量 `DSH_LIVE_BACKDROP_DIR` 覆盖）。

**插件的优化只能"少干活、干完就停"，真正决定 CPU/内存的是素材本身。** 建议规格：

| 素材 | 建议 | 原因 |
|---|---|---|
| 视频（mp4/webm） | **≤720p**、H.264/VP9、码率 1–3 Mbps、10–30 秒短循环 | 浏览器对视频做 GPU 解码，分辨率是 CPU/显存成本的主项 |
| GIF | **尽量转 mp4**（如 `ffmpeg -i bg.gif -c:v libx264 -pix_fmt yuv420p -crf 28 bg.mp4`） | GIF 解码后**每一帧都驻留内存**（宽×高×4 字节×帧数），10 秒 720p 24fps 的 GIF 可占 ~1.7GB |
| 静态图 | ≤2K 分辨率，webp/jpg 优先 | 单张静态图成本极低，但 8K 原图没必要 |

运行时兜底策略（插件内置，无需配置）：

- `visibilitychange`：标签页切走 → 视频暂停，切回 → 恢复播放；
- `prefers-reduced-motion: reduce` → 视频不自动播放（尊重系统无障碍设置）；
- `navigator.deviceMemory < 4GB` 且开启「低内存降级」→ 视频只显示静态帧（面板可关）；
- 素材加载失败 → 显示纯色底，不会报错刷屏。

## 素材服务与安全

- 素材经 `/api/live-backdrop/media/<文件名>` 提供，支持 **HTTP Range**（视频边下边播、可 seek）；
- 仅白名单扩展名 + 双重的目录穿越校验（文件名单段化 + 解析后必须位于素材目录内）；
- 全部 API 带同源围栏（Sec-Fetch-Site / Origin），拒绝跨站浏览器请求。

## API 摘要

| 路由 | 方法 | 作用 |
|---|---|---|
| `/api/live-backdrop/state` | GET | 目录、当前选择、选项、素材列表 |
| `/api/live-backdrop/list` | GET | 仅素材列表（刷新用） |
| `/api/live-backdrop/select` | POST | `{id: 文件名 \| null}` 切换/清除背景 |
| `/api/live-backdrop/options` | POST | `{enabled?, paused?, opacity?, lowMemoryFallback?}` |
| `/api/live-backdrop/open-folder` | POST | 在文件管理器中打开素材目录 |
| `/api/live-backdrop/media/<name>` | GET | 素材静态服务（Range 支持） |

## 项目结构

```
packages/dsh-live-backdrop/
├─ package.json          # dsh.bundle.patch + dsh.client 声明（DSH 插件标准声明）
├─ cordis.patch.yml      # 留空（插件行见安装步骤，写入 profile 用户补丁层）
├─ build.mjs             # esbuild：host ESM + client __ModuleLoader__ 外壳
└─ src/
   ├─ index.ts           # 宿主：路由挂载 + system prompt 公告
   ├─ store.ts           # 素材扫描 + JSON 持久化 + 三预设主题（原子写入）
   ├─ routes.ts          # /api/live-backdrop/*（含 Range、同源围栏、/theme）
   ├─ theme-shared.ts    # 主题配置共享类型
   └─ client/
      ├─ index.ts        # 浏览器：字典 / body 作用域 / 引擎 / 主题控制器 / 面板插槽
      ├─ engine.ts       # 背景引擎（全部性能与内存策略的落点）
      ├─ theme.ts        # 主题控制器（token 覆盖 + theme/change 重放 + 颜色数学）
      ├─ theme-defaults.ts # 客户端兜底主题（玻璃拟态）
      ├─ api.ts          # 宿主 API 客户端
      ├─ panel.ts        # 设置页面板（React.createElement，无 JSX）
      ├─ styles.ts       # CSS（--dsw-* token + 毛玻璃/圆角/边框注入层）
      └─ locales.ts      # 中英双语文案
```

## 与其他皮肤共存

背景层是一个 `position:fixed; z-index:-1` 的独立图层，位于 body 背景与页面内容之间：

- 覆盖当前皮肤的 body 背景图（含 miku 等会写 `background-image` 的皮肤），皮肤自带的标题栏 / 状态栏等 chrome 不受影响；
- 面板与皮肤中心同在「Web UI 插件」分组，两套开关互不干扰。
