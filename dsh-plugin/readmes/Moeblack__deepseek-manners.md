# deepseek-manners

在每次发消息之后给可爱的鲸鱼娘说谢谢（默认「谢谢你，鲸鱼大人」），仅当轮生效。

## 安装

本插件是 [DeepSeek Harness（DSH）](https://github.com/deepseek-ai/deepseek-harness) 的插件，需要先有一个可运行的 DSH。

### 本地源码装配

```sh
dsh plugin --profile web add -w link:/path/to/deepseek-manners
```

### 从 GitHub 安装

```sh
dsh plugin --profile web add github:moeblack/deepseek-manners
```

构建产物（`index.mjs` / `client.js`）已随仓库提交，git 安装无需额外构建步骤。

装配完成后，Web 界面输入框右侧会多出一个心形开关，用于随时开关注入。

## 配置

`DSH_HOME/settings.yaml`：

```yaml
deepseek-manners:
  text: 谢谢你，鲸鱼大人
  enabled: true
  hideAboveChars: 2000   # 最近一Turn assistant 回复超过此字符数时跳过遮蔽（保护 prompt cache）；0 = 总是遮蔽
```

## 机制

- 仅在包含用户直接输入的 step（turn 的第一个模型请求）注入，落在 payload 底部
- 只看最近一次 assistant 回复长度——
  - 回复短 → 回收最近一条旧后缀（surface replace 为空，日志保留）
  - 回复超长 → 跳过回收，该后缀**永久保留**（保护长回复的 prompt cache）

## 如何自定义注入文本

`text` 字段的内容会原样注入到每次上行 payload 的底部。你可以把它写成一段**多行指令**（YAML 块标量），用于：

- 追加角色扮演风格的回复引导
- 覆写模型的思考模式（think 标签行为）
- 追加风格、语气、输出格式要求

`text` 不支持模板变量，写入什么就注入什么。

### 多行长文本写法

YAML 中使用 `|`（保留换行）或 `|-`（去掉末尾换行）块标量：

```yaml
deepseek-manners:
  text: |-
    以下是对本次回复的补充要求，请严格遵守：

    1. 回复开头使用角色惯用的口头禅，保持角色语气一致。
    2. 思考过程放在 <think> 标签内，正文直接输出。
    3. 正文不使用列表式结构，用自然段落叙述。
    4. 每次回复控制在 200 字以内。
  enabled: true
  hideAboveChars: 600
```

块标量内的每一行都要**至少缩进 6 个空格**（`text:` 本身缩进 2，正文在它之下再缩进 4）。

### 生效方式

- 修改 `settings.yaml` 后**无需重启**：DSH 的 `dsh-settings-file` 默认开启文件热重载（chokidar，100ms 防抖），改动 1-2 秒内自动生效。
- 若 YAML 语法错误，服务会保留最后一份合法配置并在日志告警，不会崩溃。

### 示例：注入思考模式覆写

```yaml
deepseek-manners:
  text: |-
    <think>
    请在思考过程中遵循以下约定：

    - 先简要分析当前对话的目标与立场。
    - 列出 2-3 个可选回应方向，再选择最符合角色设定的一项。
    - 思考结束后直接输出正文，不重写、不检查。
    </think>
  enabled: true
  hideAboveChars: 600
```

## 额外用法（主要用法）

- 适配 https://github.com/victorchen96/deepseek_v4_rolepaly_instruct/blob/main/README_EN.md 仓库的思维链覆写模式
