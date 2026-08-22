# dsh-ui-background-skin — DeepSeek Harness 自定义背景皮肤插件 （如果手动操作无效，直接clone下来让codex或者TraeWork、QoderWork之类的帮你构建）

为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 网页端设计的 **背景皮肤插件**：上传自定义背景图片、调节透明度与对比度，并管理多套命名皮肤，随时切换。

> 本仓库是 `packages/client/ui-background-skin` 的独立发布副本，源码与构建产物（`lib/`）原样保留，不改动任何源代码；仅将包名与依赖声明调整为可独立发布。发布仓库为 `deepseek-harness-custom-skin`，包名 `dsh-ui-background-skin`。

## 功能特性

- **背景图片上传**：支持 JPG / PNG / WebP，浏览器端自动压缩（最长边 1920px，约 4.5MB），适配任意屏幕比例。
- **透明度调节（1–100%）**：仅作用于背景皮肤图层，不影响其他 UI 元素；滑动后点击「确定」生效并持久化。
- **对比度调节（0–100%）**：控制侧边栏与主内容区域的白色着色浓度，让皮肤在浅色界面上也清晰可读。
- **多套皮肤管理**：可保存、删除、自由切换多套命名皮肤（localStorage 持久化）。
- **自动边框色提取**：从皮肤图片采样平均色调，作为侧边栏边框与毛玻璃卡片描边色。
- **自适应界面**：欢迎页（hero）与会话页均生效，背景在聊天输入区、任务栏下正常透出，输入区有渐变过渡。
- **一键移除**：随时移除背景并恢复系统默认界面。

## 运行环境要求

- 已安装并可运行 **DeepSeek Harness**（`dsh web`），版本 `0.1.0-rc.5` 或兼容版本。
- Node.js `^22.19 || >=24`，pnpm（仅在需要重新构建源码时需要）。

## 安装

本插件是 Harness 的 **client 端插件**。要让它被网页端加载，必须**同时满足两个条件，缺一不可**：

1. **依赖可解析**：插件包能被当前 profile 解析（即出现在 profile 的 `node_modules` 中）。
2. **loader 行声明**：在 profile 的 cordis 配置树中声明一行 loader，网页端才会真正加载它的 `lib/client.js`。

> 只装依赖、不声明 loader 行，或只声明 loader 行、没装依赖，插件都不会生效。安装完成后必须**重启 `dsh web` 并硬刷新浏览器**（Ctrl+Shift+R）。

### 方式一：本地目录安装（推荐，无需发布到 npm）

插件尚未发布到 npm，最稳妥的是把它作为本地目录依赖装入 profile。

```sh
# 1. 克隆本仓库
git clone https://github.com/Lu-Yu-Zhen/deepseek-harness-custom-skin.git
cd deepseek-harness-custom-skin

# 2. 把插件装进当前 profile 的 node_modules（二选一）
#    a) 通过 dsh 命令（推荐，能正确处理依赖）：
dsh plugin --profile web add .
#    b) 或手动用 pnpm 加为本地依赖（在 profile 目录下执行）：
cd ~/.dsh/profiles/web
pnpm add file:/绝对路径/deepseek-harness-custom-skin
```

### 方式二：手动声明 loader 行

确认插件已进入 profile 的 `node_modules` 后（无论用 `dsh plugin add` 还是手动 `pnpm add`），还需声明 loader 行才能被网页端加载：

1. 打开 profile 目录下的 `cordis.patch.yml`（默认在 `$HOME/.dsh/profiles/web/cordis.patch.yml`）。
2. 在顶层数组末尾追加：

   ```yaml
   - id: ui-background-skin
     name: 'dsh-ui-background-skin'
   ```

3. 保存后重启 `dsh web`，硬刷新浏览器。

> loader 行的 `name` 必须与插件 `package.json` 的 `name` 完全一致（此处为 `dsh-ui-background-skin`）。可参考 Harness 内置插件 roster 的写法：`packages/bundle/web-app/cordis.patch.yml`。

### 方式三：集成进 web-app bundle（进阶）

如果你维护自己的 Harness 构建，可把本插件直接作为内置包集成（与官方仓库将 `ui-background-skin` 内置进 web-app 的做法一致）：

1. 把 `src/` + `lib/` 放入 `packages/client/ui-background-skin`，并在 `pnpm-workspace.yaml` 注册。
2. 在 `packages/bundle/web-app/package.json` 的依赖中加入 `"@deepseek-ai/dsh-client-ui-background-skin": "workspace:^"`。
3. 在 `packages/bundle/web-app/cordis.patch.yml` 的 loader 区域追加 `- id: ui-background-skin` / `name: '@deepseek-ai/dsh-client-ui-background-skin'`。
4. 重新构建并启动。

## 使用

1. 启动 `dsh web` 并打开网页端。
2. 页面 **右下角** 有一个「背景皮肤」按钮（白色圆角小按钮，带个性化图标）。
3. 点击后弹出「背景皮肤设置」面板：
   - **点击上传图片** 选择背景图（立即生效）。
   - 拖动 **透明度** / **对比度** 滑块调节，点击 **确定** 保存并关闭。
   - 输入皮肤名称后点 **保存皮肤**，可把当前设置存为一套命名皮肤；用下拉框 **切换**、**删除** 已保存皮肤。
   - 点 **移除背景** 一键恢复默认界面。

设置保存在浏览器 `localStorage`（键 `dsh.background-skin`），刷新页面后自动恢复。

## 从源码构建

`lib/` 已包含可直接使用的构建产物，以下仅供需要自行重新构建时使用。

```sh
pnpm install
pnpm run bundle    # 生成 lib/client.js（client 端 bundle）
```

> 构建依赖 `packages/client/tsdown.client.ts` 预设（`../tsdown.client.ts`），该文件属于 DeepSeek Harness 仓库。若在 Harness 仓库外独立构建，需自行提供等价的 tsdown 配置（或直接在 Harness 仓库内以 workspace 方式构建）。

## 发布到 npm（可选）

本仓库已可直接作为安装源使用，如需发布到 npm 供 `dsh plugin add dsh-ui-background-skin` 直接拉取：

```sh
npm login
npm publish
```

> 发布前请确认 `package.json` 中 `version` 与 `repository.url`，并按需调整为实际仓库地址。

## 常见问题

- **按钮不显示**：通常是 loader 行未声明或未重启。确认 `cordis.patch.yml` 已追加 loader 行，重启 `dsh web` 后硬刷新浏览器。
- **加载报 `MissingClientBundleError`**：`lib/client.js` 缺失或未构建，先执行 `pnpm run bundle`。
- **上传图片过大**：图片会被自动压缩到最长边 1920px；若仍超限，请更换更小的图片。
- **安装后仍无效果**：用 `dsh --profile web --dump-config` 检查组合配置里是否出现 `ui-background-skin` 行；若没有，说明 loader 行未正确解析。

## 目录结构

```
deepseek-harness-custom-skin/
├── src/                  # 插件源码（原样保留）
│   ├── index.ts          # node 半（占位 apply）
│   └── client/           # 浏览器半
│       ├── index.ts      # 插件入口：注入 shell.overlay 槽位
│       ├── background.ts # 背景层与透明化逻辑
│       ├── storage.ts    # localStorage 持久化 + 图片压缩
│       ├── locales.ts    # 中英文案
│       └── BackgroundSkinAction.tsx / BackgroundSkinPanel.tsx / *.module.css
├── lib/                  # 构建产物（原样保留）
│   ├── index.js          # node 半
│   ├── client.js         # client 端 bundle（浏览器加载）
│   └── types/            # 类型声明
├── tsconfig.json         # 构建配置
├── tsdown.config.ts      # tsdown 配置
└── package.json          # 独立包声明（已调整依赖版本）
```

## 许可

MIT License。本插件基于 DeepSeek Harness（MIT）开发，源码从其 `packages/client/ui-background-skin` 目录独立而来。
