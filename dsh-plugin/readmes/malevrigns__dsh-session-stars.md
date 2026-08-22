# dsh-session-stars

[English](./README.md)

把完整的 DeepSeek Harness 会话加入收藏，并从一个跨工作区的全局列表中重新打开。
这是一个仅支持 DSH Web 的 bundle，使用公开的增量插槽，不替换内置会话浏览器。

## 功能

- 在当前会话标题栏切换收藏状态。
- 从侧边栏底部打开收藏中心；侧边栏折叠时也保留入口。
- 在 shell 浮层中按最新收藏优先浏览全部收藏，打开仍存在的会话，或移除已失效会话。
- 通过 `storage` 事件同步同源浏览器标签页。
- 会话标题、工作区、运行状态和归档状态都来自当前 DSH 快照，不保存容易过期的副本。

## 兼容性

`0.1.0` 面向 DeepSeek Harness Web `0.1.0-rc.6` 和 React 18。插件没有桌面端或
Host 端组件。只有开发或打包插件时才需要 Node.js `^22.19.0 || >=24.0.0`；正常使用
直接加载预编译 bundle。

## 安装

发布后，把 npm 包安装到 Web profile：

```powershell
dsh plugin --profile web add dsh-session-stars
```

公开仓库可用后，从 GitHub 安装：

```powershell
dsh plugin --profile web add github:malevrigns/dsh-session-stars
```

从已下载或本地生成的 tarball 安装：

```powershell
dsh plugin --profile web add C:\path\to\dsh-session-stars-0.1.0.tgz
```

修改插件列表后重启 Web profile。具体启动命令取决于该 profile 原本的运行方式；只有
Web 应用运行时，本插件才会添加界面。

## 启用、禁用与卸载

插件存在于 profile 中时即为启用状态。添加插件用于启用，移除插件用于禁用或卸载：

```powershell
dsh plugin --profile web add dsh-session-stars
dsh plugin --profile web remove dsh-session-stars
```

从 profile 中移除插件不会清除浏览器中已保存的收藏 ID。

## 存储与隐私

收藏数据写入 Web 应用当前源的 `localStorage`，键名是 `dsh.session-stars.v1`。浏览器源
相互隔离，因此不同浏览器、设备、主机名、协议或端口之间不会共享收藏；同源标签页会自动同步。

插件只保存会话 ID 和收藏时间戳，不发起网络请求，也不读取、保存或传输 API key 与模型提供方
配置。如果已收藏会话不再出现在当前 DSH 列表中，收藏中心会把它标记为不可用并提供显式移除，
不会尝试导航到失效 ID。

## 开发

```powershell
pnpm install
pnpm test
pnpm typecheck
pnpm build
pnpm publint
pnpm pack
```

构建产物提交在 `lib/` 下，npm、GitHub 和 tarball 安装都会加载同一份预编译运行文件。

## 许可证

[MIT](./LICENSE)
