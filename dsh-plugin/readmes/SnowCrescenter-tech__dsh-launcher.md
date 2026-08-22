# DeepSeek Harness 一键启动器(dsh-launcher)

> 双击就能用上 DeepSeek Harness,免安装 Node.js、免 pnpm、免命令行。

## 这是什么

DeepSeek Harness 是 DeepSeek 官方的 agent 框架,能帮你把复杂任务交给 AI 一步步完成。不过官方目前还是开发者预览版,想自己装起来,得先准备 Node 22.19+ 或 Node 24、装好 pnpm,再对着命令行敲一堆命令去构建。对大多数非技术用户来说,这一步的门槛实在太高了。

本项目的目标只有一个:把这些准备工作全部打包好,做成一个免安装的绿色便携版。下载、解压、双击启动,浏览器里就会出现 DeepSeek Harness 的 Web UI。

## 三步上手

1. 到本项目 Releases 页面下载 `DeepSeek-Harness-免安装版-v0.1.0.zip`
2. 解压到任意目录(建议不要放在中文路径里)
3. 双击 `启动.bat`,按提示粘贴你的 DeepSeek API Key,浏览器会自动打开 Web UI

程序会自动检查运行环境、把 API Key 写入本地配置、启动服务并打开浏览器,这些都不需要你手动操作。

## 准备一个 API Key

DeepSeek 的 API 是官方按量计费的,需要你先有一个 Key:

1. 打开 https://platform.deepseek.com,注册并登录
2. 在 API Keys 页面点击"创建",会得到一个形如 `sk-xxxxxxxx` 的 Key
3. 启动时把它粘贴进窗口即可,程序会自动帮你保存

你的 Key 只会写在自己电脑上,不会上传到任何地方。

## 常见问题

**杀毒软件报毒怎么办?**

本程序是绿色便携版,没有安装器,目录里只有 `启动.bat` 脚本、官方签名 `node.exe` 和依赖库,不修改系统设置。首次启动会自动解除下载文件的 SmartScreen 标记,一般不会再提示。

如果仍被拦截,可以在杀毒软件里把解压目录加入信任区:

- 360 安全卫士:木马查杀 → 信任区 → 添加信任目录
- 火绒安全:防护中心 → 病毒防护 → 信任区 → 添加文件/目录
- 腾讯电脑管家:病毒查杀 → 信任区
- Windows Defender:病毒和威胁防护 → 排除项

每个版本还附带 SHA256SUMS.txt 校验文件,可以核对下载的压缩包是否完整、未被改动。

**提示端口 3080 被占用怎么办?**

端口 3080 被占用时会自动切换到空闲端口,无需手动处理。

**和官方版本有什么不同?**

没有任何不同。启动脚本直接运行官方原版程序,只是帮你自动检查环境、写入 API Key、打开浏览器,不改一行代码。

**需要付费吗?**

需要。软件本身是免费开源项目,但调用 DeepSeek 的 API 由官方按量计费。当前参考价(每百万 tokens):deepseek-v4-flash 输入 $0.14、输出 $0.28;deepseek-v4-pro 输入 $0.435、输出 $0.87;命中缓存时输入价格要低得多。具体价格以 https://api-docs.deepseek.com/quick_start/pricing 为准,2026-08-16 起官方改为峰谷计价。

## 技术说明

- 内置 Node v24.19.0 便携版,不依赖系统安装的 Node
- 使用 `@deepseek-ai/dsh@0.1.0-rc.6` 启动 Web UI
- 数据保存在 `%USERPROFILE%\.dsh`
- 组成:`启动.bat`(入口)、`launcher/`(启动逻辑)、`node.exe` 与 `node_modules/`(内置运行环境)

## 免责声明

本项目是社区作品,非 DeepSeek 官方出品。DeepSeek Harness 目前处于 developer preview 阶段,后续可能有破坏性变更。本项目基于 MIT 协议开源,使用中遇到的问题请优先查阅官方文档。

## 相关链接

- DeepSeek Harness 官方仓库:https://github.com/deepseek-ai/deepseek-harness
- API 控制台:https://platform.deepseek.com
- 项目 Topics:dsh-plugin、dsh、deepseek-harness、windows、portable、launcher
