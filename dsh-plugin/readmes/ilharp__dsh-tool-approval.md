# dsh-tool-approval

[English](README.md) | 中文

给任意 Tool Calling 加上前置审批，aka "Manual Mode"/"Ask Mode"。

![](./assets/img1.png)

## 安装

```sh
dsh plugin --profile web add dsh-tool-approval
```

## 配置

### 默认配置

```yml
- id: tool-approval
  name: dsh-tool-approval
```

默认配置下每次 Tool Calling 都会加上前置审批。

### 自定义配置

```yml
- id: tool-approval
  name: dsh-tool-approval
  config:
    include: [fs_*, web_*]
    exclude: [task_output]
    reason: tool execution requires your approval
```

只有 `include` 指定了的工具会前置审批，`exclude` 的工具会放行。支持通配符。

## LICENSE

[BSD 3-Clause](LICENSE)
