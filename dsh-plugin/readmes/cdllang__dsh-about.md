# @dsh-local/about

[English](README.md)

DeepSeek Harness Web GUI 的「关于」页插件,按官方 `@deepseek-ai/dsh-client-*`
插件包规格制作。在设置页注册 **关于** 分区:显示运行中的 dsh 版本、官方最新
版本,并提供**一键更新服务端**——全程不修改 dsh 仓库。

## 功能

- **版本卡片** — 当前 dsh 版本(从运行中的安装读取)对比官方最新版(npm
  registry dist-tag;15 分钟缓存、8 秒硬超时、断网降级「无法获取」)。
- **一键更新** — npm 安装环境且存在新版时,关于页出现「一键更新」:确认 →
  `npm install @deepseek-ai/dsh@latest` → 自动重启。源码安装环境显示手动更新
  提示。
- **官方插件形态** — 标准 exports(`.` / `./client` / `./invariant` /
  `./src/*`)、`dsh.client` 清单、tsdown 双面构建(node half + 浏览器闭包)、
  `./invariant` 配套、Model Experience README、vitest 测试(26 项)。
- **双语**(`zh`/`en`),`locale:` 类型化 `t` seat,官方 `settings.section`
  槽位注册。

## 安装

前置条件:dsh 检出目录 + pnpm(或桌面封装版),Node `^22.19 || >=24`。

1. 从 GitHub 添加插件(在 dsh 检出目录执行):

   ```sh
   pnpm dsh plugin --profile web add git+https://github.com/cdllang/dsh-about.git
   ```

2. 若 pnpm 拦截构建脚本(allowBuilds 策略,pnpm >= 10),它会打印需要放行的
   确切键名。把该键复制进 profile 的 workspace 文件后重跑第 1 步:

   ```sh
   # 文件:%USERPROFILE%\.dsh\profiles\web\pnpm-workspace.yaml
   allowBuilds:
     "@dsh-local/about@https://codeload.github.com/cdllang/dsh-about/tar.gz/<commit-sha>: true"
   ```

   键名包含拉取的 commit,插件每次更新后都会变化——再次被拦截时,重跑 add
   命令并复制新打印的键即可。

3. 重启 `dsh web`(或桌面封装版)。打开 **设置 → 关于** 查看。

从本地路径安装迁移:先移除旧条目,再从 GitHub 添加:

```sh
pnpm dsh plugin --profile web remove @dsh-local/about
pnpm dsh plugin --profile web add git+https://github.com/cdllang/dsh-about.git
```

插件安装在 `$HOME/.dsh`(profile),服务端升级不影响它,同一 profile 的所有
实例共享。

### 更新

- 关于页的「一键更新」按钮更新的是 **dsh 服务端包**(`@deepseek-ai/dsh`)并
  重启;插件本身不受影响。
- 插件代码更新:`pnpm dsh plugin --profile web update @dsh-local/about`(或
  重跑 add 命令),然后重启。

## 开发

```sh
npm install
npm run build        # tsc -> lib/types;tsdown -> lib/{index,invariant,client}.js
npm run test         # vitest(host 单测 + jsdom 组件测试)
```

把本地构建装进 profile:

```sh
pnpm dsh plugin --profile web add <本目录的绝对路径>
```

## 工作原理

- **Host 端**在 webserver 上提供 `GET /about/version`、`POST /about/update`、
  `GET /about/update-status`:
  - 当前版本启动时经 config-tree baseUrl 与 `$DSH_HOME/profiles/node_modules`
    镜像解析,各实例报各自的安装版本;
  - 最新版本来自 npm registry(官方 GitHub 仓库没有 tags/releases,
    `releases/latest` 仅作备选);
  - 更新在服务端根目录执行 `npm install @deepseek-ai/dsh@latest`(带
    `x-dsh-about` 防跨站头),成功后打印 `dsh-update: restarting` 标记并退出
    —— 桌面封装监听 stdout 自动重启。
- **浏览器端**经 `slots.inject` 注册 `settings.section`,以组件本地状态驱动
  确认 → 轮询 → 等待重启 → 刷新 流程。

## 配置

插件无自身配置面;组合由 profile 决定。在后续补丁层禁用:

```yaml
- id: about
  disabled: true
```

## 已知限制

- **一键更新只覆盖 dsh 服务端包** — Electron 壳与插件本身仍需手动替换/重建。
- **更新依赖监督进程** — 裸 `dsh web` 启动会在打印重启标记后退出;没有桌面
  封装(或等效 stdout 监视)时需手动重启。
- **npm registry 是版本事实源** — 无法访问 npm 的部署会显示降级状态。
- **不支持系统代理** — host fetch 使用 Node 全局 fetch,不读 `HTTP(S)_PROXY`。
- **host 端改动需重启** — 版本捕获与路由在 host 进程;仅浏览器 bundle 可热刷新。

## Model Experience

无。版本卡片是浏览器界面,不触及模型请求。

#### KV Cache effect

无;本包既不组装也不发送 provider 请求。

## License

MIT
