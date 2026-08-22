<h1 align="center">dsh-serial</h1>

<p align="center">嵌入式串口调试工具插件 —— 扫描端口、发送数据、实时监控、抓取日志；由 pyserial Python 脚本驱动，零原生依赖。</p>

## 能力

| 工具 | 说明 |
|------|------|
| `serial_scan` | 枚举串口（描述 / VID / PID / 芯片名 / 序列号 / 位置），支持关键词过滤 |
| `serial_send` | 发送文本或 Hex 数据（支持行尾、重复发送、等待响应），适合 AT 命令与刷机命令 |
| `serial_monitor` | 实时监控串口输出（正则过滤 / 排除，超时自动结束，可随时中止） |
| `serial_log` | 抓取串口输出存为 text / csv / jsonl 日志文件 |

安全规则内置在工具契约里：绝不猜波特率、绝不替你选串口、没有明确意图不发数据。

## 要求

- Python 3 + pyserial：`pip install pyserial`
- 串口驱动（Windows：CH340 / CP2102 / FT232 等按芯片装驱动）

## 安装

```sh
# git 源（主通道）
dsh plugin --profile web add "github:hgy043/dsh-serial#main"

# npm
dsh plugin --profile web add dsh-serial

# 本地开发
dsh plugin --profile web add E:/dsh-plugins/plugins/dsh-serial
```

**安装后必须重启 web**（bundle 层栈在 boot 时合成）。验证：

```sh
dsh --profile web --dump-config | grep -i serial
```

## 配置

`~/.dsh/settings.yaml` 中以插件 id `serial` 为键覆盖默认值（全部可选）：

```yaml
serial:
  python: py            # python 解释器名（默认 python，找不到自动试 py）
  baudrate: 115200
  workspace_dir: D:/my-embedded-project   # 子进程工作目录与状态落盘处
```

## 使用示例

以下为 GEC6818 嵌入式 Linux 开发板（COM7，PL2303GT）上的实测输出：

```
用户：扫描一下串口
→ serial_scan
→ { "status": "ok", "summary": "发现 5 个串口", "details": { "ports": [
    { "port": "COM7", "description": "Prolific USB-to-Serial Comm Port",
      "vid": "067B", "pid": "23A3", "chip": "PL2303GT", ... }, ... ] } }

用户：向 COM7 发送 AT 并等待响应
→ serial_send(data="AT", line_ending="crlf", wait_response=true)
→ { "status": "ok", "summary": "已发送 1 次到 COM7@115200",
    "details": { "tx": "AT", "tx_bytes": 4,
      "rx": "-/bin/sh: AT: not found\r\n~ # ", "rx_bytes": 79 } }
// 板子是 Linux 控制台而非 AT 猫——回复即真实 shell 输出

用户：监控 COM7 10 秒
→ serial_monitor(timeout_sec=10)
→ { "status": "ok", "summary": "监控结束，共 12 行，耗时 10.1s",
    "details": { "lines": [ { "timestamp": "...", "text": "~ # " }, ... ] } }

用户：把 COM7 的日志抓 5 秒
→ serial_log(duration=5)
→ { "status": "ok", "summary": "日志已保存: .../serial_20260817_195845_391755.log",
    "details": { "log_summary": { "lines": 8, "bytes": 142, "format": "text", ... } } }
```

## 插件管理

插件管理推荐使用 plugin-registry 的轻量控制台：

```sh
dsh plugin --profile web add github:vlln/plugin-registry#main&path:/packages/plugin/console
```

## 开发

- 串口 I/O 由 `serial-scripts/` 下的 Python 脚本完成，**脚本上游归 serial skill**（`~/.agents/skills/serial`），插件内副本按版本冻结，同步 = 重跑复制命令，不要手改副本。
- 改 `index.mjs` / `lib/*.mjs` 后必须重启 web（ESM 缓存）。
- 本地 link: 开发时官方包（@deepseek-ai/*）靠 `node_modules` junction 注入，发布安装无需。
