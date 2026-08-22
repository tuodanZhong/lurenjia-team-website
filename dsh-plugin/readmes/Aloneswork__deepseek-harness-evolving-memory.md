# DeepSeek Harness 演化式长期记忆

简体中文 | [English](README.en.md)

这是一个非官方社区插件，让 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 获得可跨对话、跨工作区、跨项目复用的本地长期记忆。

它会自动保存成功回合中可复用的结果，并在 DSH 回答前自动召回相关记忆。它使用真正的本地向量，因此用户改写表达后仍能召回。记忆和向量只保存在本机 SQLite，不会发送给 embedding API。

## 安装

需要：

- Node.js `>=22.19.0`
- 已安装并配置 DeepSeek Harness
- 约 91 MB 磁盘空间；首次使用会下载本地 `BGE-small-zh-v1.5` 模型

下载安装包：

```sh
curl -LO https://github.com/Aloneswork/deepseek-harness-evolving-memory/releases/download/v0.2.1/deepseek-harness-evolving-memory-0.2.1.tgz
npm install --global ./deepseek-harness-evolving-memory-0.2.1.tgz
dsh plugin --profile web add ./deepseek-harness-evolving-memory-0.2.1.tgz
plugin_dir="$(npm root --global)/deepseek-harness-evolving-memory"
dsh web --patch "$plugin_dir/evolving-memory.cordis.yml"
```

最后一行只对本次 DSH Web 进程启用插件。如需永久启用，把 `evolving-memory.cordis.yml` 中两个 `insert` 条目合并到 profile 或全局 `cordis.patch.yml`，不要覆盖原有条目。

## 验证

```sh
dsh-evolving-memory --doctor
```

然后在一个对话中告诉 DSH 一条可复用的事实或偏好，成功完成该回合；新开对话后，换一种说法提问，确认它能自动召回。

如需从源码测试：

```sh
git clone https://github.com/Aloneswork/deepseek-harness-evolving-memory.git
cd deepseek-harness-evolving-memory
npm install
npm test
npm pack --dry-run
```

## 给你自带 Agent 的一句话安装提示词

> 请从 https://github.com/Aloneswork/deepseek-harness-evolving-memory 安装并配置 DeepSeek Harness 演化式长期记忆插件；保留现有 DSH profile 和 Cordis patch，安装后运行 doctor 与跨对话语义召回测试，最后报告修改文件、存储路径和测试结果，但不要泄露任何已保存的记忆。

## 它具体做什么

- 在 DSH 首次 `agent/pre-step` 自动召回相关记忆，模型不必记得主动调用搜索工具。
- 成功回合结束后，自动捕获可复用的“请求 + 结果”。
- 混合本地 BGE 向量、词法相关度、可信度和时间衰减排序。
- 使用稳定记忆键更新相同事实，避免重复写入。
- 不确定的新旧差异进入冲突队列；可信度明显更高的信息可替换旧版本。
- 支持可信度、过期、版本历史、项目隔离、归档、安全删除及 Markdown/JSON 导出。
- 在事务中把 v0.1 SQLite 数据迁移到 v0.2。
- MCP 子进程重连与工具重新发现交给官方 `@deepseek-ai/dsh-mcp-client`。

当用户要求 DSH 说出、修改、导出或删除记忆时，可以显式调用这些 MCP 工具：

- `memory_save`、`memory_search`、`memory_get`、`memory_revise`
- `memory_archive`、`memory_delete`
- `memory_conflicts`、`memory_conflict_resolve`
- `memory_export`

## 存储和范围

- 数据库：`~/.dsh-evolving-memory/memories.sqlite`
- 模型缓存：`~/.cache/dsh-evolving-memory/models`
- 默认召回：全局记忆加当前项目记忆
- 跨项目召回：只有显式指定 `includeAllProjects=true` 才会执行

项目标识按工具参数、`EVOLVING_MEMORY_PROJECT`、Git origin、当前目录的顺序确定。

可选环境变量：

```sh
export EVOLVING_MEMORY_FILE=/path/to/memories.sqlite
export EVOLVING_MEMORY_PROJECT=stable-project-key
export EVOLVING_MEMORY_MODEL_CACHE=/path/to/model-cache
```

原生插件配置：

```yaml
- id: memory-evolving-native
  name: deepseek-harness-evolving-memory
  config:
    autoRecall: true
    recallLimit: 6
    autoCapture: true
    captureMinChars: 12
    captureMaxChars: 4000
    captureExpiresDays: 180
```

## 记忆规则

- 用户明确陈述：建议可信度 `0.9–1.0`
- 可靠文档：`0.8–0.9`
- 自动捕获的回合：默认 `0.55`，180 天后过期
- 新信息必须比旧信息高至少 `0.15` 才自动替换，否则生成待处理冲突
- 过期记忆不参与普通召回，但仍可显式查看
- 归档只是隐藏；`memory_delete(confirm=true)` 才会安全删除，并级联清除历史、向量、冲突及截断 WAL

## 隐私边界

- 记忆文本和向量保存在本机。首次下载模型会访问模型分发地址，但不会上传记忆内容。
- 自动捕获会跳过常见密钥模式，但不是完整 DLP。不要输入绝对不能持久化的秘密。
- 召回的记忆会进入当前模型上下文，这是模型使用记忆的必要过程。

MIT 许可证。本项目与 DeepSeek 无隶属或官方认可关系。
