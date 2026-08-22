# dsh-markdown-table · Markdown 表格生成

把 JSON 数组 / 二维数组转换为 Markdown 表格。纯 Node 实现。

## 提供的工具

| 工具 | 作用 |
|---|---|
| `make_table` | JSON → Markdown 表格 |

## 安装

```bash
dsh plugin add dsh-markdown-table
```
安装后在 profile 的 `package.json` 的 `dsh.profile.bundles` 中加入 `"dsh-markdown-table"`。

## 用法示例

```
把这组数据整理成 Markdown 表格
→ 调用 make_table(data=[{name:"a",value:1},{name:"b",value:2}])
```
