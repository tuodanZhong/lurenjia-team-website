# 复刻 Android 功能

[![skills.sh](https://skills.sh/b/addxing/replicate-android-feature)](https://skills.sh/addxing/replicate-android-feature)

面向 AI 编程代理的 Android 功能复刻 Skill。它以 Android 源项目的实际实现为依据，将指定功能完整迁移到其他项目或平台，并保持功能链路、业务行为、UI 和可复用资源一致。

## 安装

```bash
npx skills add addxing/replicate-android-feature
```

### DeepSeek Harness

本仓库遵循 DeepSeek Harness（DSH）的 Skill 格式，克隆到技能目录后即可被自动发现：

```bash
# 用户级安装（所有项目可用）
git clone https://github.com/addxing/replicate-android-feature ~/.dsh/skills/replicate-android-feature

# 项目级安装（仅当前项目可用）
git clone https://github.com/addxing/replicate-android-feature .dsh/skills/replicate-android-feature
```

克隆后 DSH 会自动热更新技能目录，新会话即可使用该 Skill。

也可以作为官方 bundle 插件一行安装（需要 pnpm，安装后重启 Web）：

```bash
dsh plugin --profile web add "github:addxing/replicate-android-feature#main"
```


## 使用方式

让 AI 编程工具应用这个 Skill，并说明需要复刻的功能：

```text
使用 $replicate-android-feature，将 Android 源项目中的收藏功能完整复刻到目标项目。
```

如果工作区中无法判断源项目或目标项目，请同时提供对应路径。

## 功能说明

这个 Skill 会指导代理：

- **功能一致**：实现 Android 端已有的全部功能和业务逻辑
- **UI 一致**：还原 Android 端的布局、颜色、字号、间距等所有视觉元素
- **链路完整**：以 Android 端实际代码为准，追踪并实现所有功能入口及全部关联页面
- **资源复用**：复用 Android 端相关资源，仅在目标平台不支持原格式时进行必要转换
- **结果汇总**：完成后汇总已实现内容、主要改动文件、验证情况，以及剩余缺口或阻塞

## 文件说明

- `SKILL.md` - Skill 指令
- `LICENSE.txt` - Apache 2.0 许可证
