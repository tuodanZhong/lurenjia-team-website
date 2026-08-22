# DSH 会话导入插件

需要把 DeepSeek Harness 导出的对话恢复到另一台电脑、另一个部署或新的工作区？
本插件可以读取 DSH `/export` 生成的 `.zip` 压缩包或裸 `.jsonl` 日志，在导入前
完成结构校验和 SHA-256 指纹检查，然后把内容恢复为一个新的 DSH 会话。整个流程
可以在新建会话页面的「导入对话」窗口中完成。

[English](./README.md)

## 其他项目

- [DSH Image2 生图插件](https://github.com/JuneLearn/dsh-image2-draw)：为 DSH
  增加 `gpt-image-2` 文生图和图生图能力。
- [DSH 推理强度设置插件](https://github.com/JuneLearn/dsh-reasoning-settings)：为
  第三方 Provider 和模型配置独立的推理档位及参数值。

## 功能

- 支持 DSH `/export` 导出的 `.zip` 和裸 `.jsonl` 会话日志。
- 在新建会话页面提供「导入对话」按钮，支持点击选择和拖放文件。
- 导入前预览标题、消息数、工具调用、轮次、原工作区、模型和会话状态。
- 始终生成新的会话 ID，不覆盖本机已有会话。
- 支持选择目标工作区、自定义标题、保留原时间或把会话时间平移到当前。
- 可以分别同步模型与思考深度、Agent 预设、权限、沙箱、审批策略和计划模式。
- 支持 SHA-256 指纹展示和 `expectedHash` 强匹配。
- 支持 `dryRun=1` 无副作用预演和 `open=1` 导入后立即恢复。
- 写入、工作区挂载或装载校验失败时自动回滚，避免留下半成品会话。
- 删除接口只接受当前插件进程成功导入并登记的会话，不会按任意会话 ID 删除普通
  冷会话。
- 校验 ZIP CRC-32、中央目录、条目范围和名称一致性，并拒绝加密、分卷及 ZIP64。
- 浏览器端包含请求取消、文件选择竞态保护、Escape 关闭、焦点恢复和移动端布局。

## 安装

### 安装前准备

- 安装 [Node.js](https://nodejs.org/)。DSH 当前支持 Node.js 22.19.x 或 24 及以上
  版本；建议使用 Node.js 24 LTS。Node.js 自带 `npm` 和 `npx`。
- 安装 [Git](https://git-scm.com/)，用于从 GitHub 仓库获取插件。
- 安装 pnpm。两种方法都需要 pnpm，因为 `dsh plugin` 会在 profile 目录中调用
  pnpm 安装或移除插件。
- 网络需要能够访问 `registry.npmjs.org` 和 `github.com`。如果当前网络无法稳定访问
  npm 或 GitHub，需要先配置可用的网络代理。
- 方法一不需要 DeepSeek Harness 源码；方法二还需要准备好该源码仓库。

可先检查环境：

```powershell
node --version
npx --version
git --version
corepack enable
pnpm --version
```

如果 `corepack enable` 因权限不足失败，请用管理员身份打开 PowerShell 后再执行一次。
也可以根据 [pnpm 官方安装说明](https://pnpm.io/installation)选择其他安装方式。

如果下载出现 `ECONNRESET`、`ETIMEDOUT` 或 GitHub 连接失败，可以在当前
PowerShell 窗口临时设置代理。下面的 `7890` 只是示例，请改成自己的代理端口：

```powershell
$proxy = "http://127.0.0.1:7890"
$env:HTTP_PROXY = $proxy
$env:HTTPS_PROXY = $proxy
$env:npm_config_proxy = $proxy
$env:npm_config_https_proxy = $proxy
```

这些环境变量只对当前 PowerShell 窗口有效，关闭窗口后不会继续生效。

### 方法一：使用 npx（普通用户推荐）

这种方法不需要克隆 DeepSeek Harness 源码，也不需要全局安装 `dsh`，但仍需准备好
Git 和 pnpm：

```powershell
npx --yes -p @deepseek-ai/dsh dsh plugin --profile web add github:JuneLearn/dsh-session-import
```

安装完成后，用同一种方式启动 Web：

```powershell
npx --yes -p @deepseek-ai/dsh dsh web
```

### 方法二：使用 pnpm 和 Harness 源码（开发者推荐）

进入 DeepSeek Harness 源码根目录。第一次使用源码时先安装依赖，然后安装插件：

```powershell
cd D:\deepseek-harness
pnpm install
pnpm dsh plugin --profile web add github:JuneLearn/dsh-session-import
```

以后从该源码目录启动 Web：

```powershell
cd D:\deepseek-harness
pnpm dsh web
```

包内的 `dsh.bundle` 声明会自动把插件加入 Web profile；两种安装方式都不需要手动
编辑 `cordis.patch.yml`。Web 默认地址为 `http://127.0.0.1:3080`。

### 本地开发安装

如果正在修改本地源码，可以直接把插件目录链接到 Web profile：

```powershell
cd D:\deepseek-harness
pnpm dsh plugin --profile web add "D:\CodexFile\临时文件夹\dsh-session-import"
pnpm dsh web
```

本地链接安装后，修改源码通常只需重启 `dsh web` 并刷新浏览器，不需要重复安装。

### 升级

再次执行对应的安装命令即可升级，无需先卸载，也无需手动维护 profile patch。

npx 方式：

```powershell
npx --yes -p @deepseek-ai/dsh dsh plugin --profile web add github:JuneLearn/dsh-session-import
```

pnpm 源码方式：

```powershell
cd D:\deepseek-harness
pnpm dsh plugin --profile web add github:JuneLearn/dsh-session-import
```

### 卸载

npx 方式：

```powershell
npx --yes -p @deepseek-ai/dsh dsh plugin --profile web remove dsh-session-import
```

pnpm 源码方式：

```powershell
cd D:\deepseek-harness
pnpm dsh plugin --profile web remove dsh-session-import
```

卸载插件不会删除已经导入的会话。重启 `dsh web` 后，导入按钮和接口会被移除。

## 使用

1. 打开 DSH Web，点击左侧边栏顶部的「新建会话」。
2. 在中央输入框上方找到工作区和模式选择区域。
3. 点击「标准模式」右侧的「导入对话」按钮。
4. 选择或拖入 DSH `/export` 导出的 `.zip` / `.jsonl` 文件。
5. 查看结构校验、SHA-256、消息统计、原工作区和可同步状态。
6. 选择目标工作区，并按需设置标题、时间置顶和状态同步项。
7. 点击「开始导入」。导入成功后，新会话会出现在侧栏并自动打开。

按钮位置大致如下：

```text
[选择工作区]  [标准模式]  [导入对话]
```

插件也提供本地 HTTP API。完整参数和响应格式见
[API 文档](./docs/api.md)。

## 校验与资源限制

- 上传文件和根会话日志解压后均不得超过 256 MB。
- 单个 ZIP 最多包含 10,000 个条目，展开后的根日志最多包含 1,000,000 个事件。
- ZIP 中的 `subagents/` 子代理日志和 `media/` 媒体文件目前只统计数量，不会随根
  会话一起导入。
- 结构校验覆盖事件 `seq`、时间、类型、引用、turn/step、工具调用配对、消息
  envelope、`surfaceOp` 和 `sourceEventSeqs`。
- SHA-256 可以确认文件与指定指纹一致，但 DSH 导出不含数字签名，因此不能证明
  文件作者身份。
- 删除所有权登记只保存在当前 DSH 进程内。重启后会话仍可正常使用，但不能再通过
  插件撤销接口删除。

## 权限与数据

- 文件只在本机内存中解析，不会上传到外部服务。
- 插件没有任何出站网络请求，也不读取 API Key 或其他 DSH 凭据。
- 导入只写入 DSH 自身的会话持久化目录和工作区注册表。
- 撤销接口只处理当前进程由本插件成功导入并登记的会话。

## 常见问题

| 现象 | 原因与处理 |
| --- | --- |
| 页面没有「导入对话」按钮 | 确认位于新建会话页面，重启 `dsh web` 后按 `Ctrl+F5` 刷新 |
| `loaded without registering` | 客户端模块仍是旧缓存；更新插件、重启 DSH 并强制刷新 |
| `400 bad-file` | 文件不是合法 ZIP/JSONL，或文件损坏、加密、超限、版本不受支持 |
| `409 hash-mismatch` | 文件 SHA-256 与填写的预期指纹不同 |
| `422 structure` | 日志事件断裂、引用非法或导入后装载校验失败；失败产物会自动回滚 |
| `403 not-imported` | 删除目标不是当前进程由插件登记的导入会话，或 DSH 已重启 |
| `503 persistence / workspace` | 当前 profile 缺少会话持久化或工作区服务，检查插件依赖和 bundle |

## 开发

```powershell
npm test
npm run check
npm pack --dry-run
```

`tests/plugin.test.mjs` 覆盖日志和 ZIP 解析、结构校验、seq 重排、事务回滚、删除
保护、客户端工具函数、模块 ID 与包清单。

## 兼容性

当前版本以 DeepSeek Harness `0.1.0-rc.6` 的公开会话格式、双端插件、WebServer、
工作区和会话持久化接口为兼容目标。Harness 仍处于 Developer Preview；升级后如果
插件不再加载，请先检查事件白名单、消息 envelope、Host 服务名和
`dsh.client.inject` 声明是否变化。

## 致谢

本项目基于采用 MIT 许可证的
[kinyokun/dsh-session-import](https://github.com/kinyokun/dsh-session-import)，感谢
原作者 [kinyokun](https://github.com/kinyokun) 的工作。原项目版权和许可证声明保留
在 [LICENSE](./LICENSE) 中；详细归属与改动说明见 [NOTICE](./NOTICE.md) 和
[上游对比文档](./docs/upstream-comparison.md)。

## License

[MIT](./LICENSE)
