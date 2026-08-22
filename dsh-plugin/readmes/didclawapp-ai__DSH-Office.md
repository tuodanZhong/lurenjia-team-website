# DSH-Office

[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 插件：用本机 [zagens-office](https://zagens.com/download/install.md) 生成和编辑 PPTX / DOCX / XLSX / PDF。

| 工具 | 作用 |
| --- | --- |
| `office_schema` | 取 JSON 契约，写/改之前先调 |
| `office_write` | 新建文档 |
| `office_edit` | 按 op 改已有文档 |
| `office_read` | 读回文档核对 |

没有引擎时，模型会自行下载到 `~/.zagens-pro/bin`。

## 安装

已安装发布版 `dsh`：

```sh
dsh plugin --profile web add github:didclawapp-ai/DSH-Office
dsh web
```

从 Harness 源码跑（没有 PATH 上的 `dsh`）把上面的 `dsh` 换成 `pnpm dsh`。也可以 `npx @deepseek-ai/dsh`。

启动日志出现 `[zagens-office] plugin loaded` 即成功。钉死版本：`github:didclawapp-ai/DSH-Office#<commit-sha>`。卸载：`dsh plugin --profile web remove dsh-zagens-office`。
