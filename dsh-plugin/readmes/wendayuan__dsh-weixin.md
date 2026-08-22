# dsh-weixin

把微信变成 DeepSeek Harness（DSH）的入口：手机微信直接对话 DSH agent，干活、跑命令、读文件、查资料，和网页版同一套认知与规则。

WeChat channel plugin for DeepSeek Harness — chat with your DSH agent from the WeChat app.

## 特性

- 手机微信发消息 → DSH agent 干活 → 回复发回微信
- 上下文连续：每个微信对话一个持久 session
- 复用 DSH 现有模型凭据（`~/.dsh/.credentials.yaml`），无需另配
- 自动加载 `~/.dsh/AGENTS.md` 与 workspace `AGENTS.md`（agent 具备与网页版一致的规则约束）
- 随 DSH 进程常驻，无需独立守护进程

## 链路

```
手机微信 ── iLink 官方通道 ──> weixin-agent-sdk（长轮询）
                                 │ Agent.chat()
                                 ▼
                          dsh-weixin 插件 ──> DSH agent（ctx.agents）
```

## 安装

```bash
dsh plugin --profile web add github:you/dsh-weixin
```

装完按下面「登录」扫码一次，之后随 DSH 自动运行。

## 登录（一次性）

插件复用微信官方 iLink 通道的扫码登录。任选一种：

**方式一（推荐）**：用桥接器 CLI 预登录，凭证存 `~/.openclaw`，插件直接复用：

```bash
npx weixin-acp login
```

终端打印二维码，手机微信扫码并确认，显示「✅ 与微信连接成功」即可。

**方式二**：装完插件后，首次启动 DSH 时日志会提示未登录，按提示登录。

登录凭证存于 `~/.openclaw/openclaw-weixin/accounts/`（token，0600）。换号用 `npx weixin-acp logout` 再 `login`。

## 配置

在 profile 的 `cordis.patch.yml` 里覆盖（均为可选）：

```yaml
- id: weixin
  name: dsh-weixin
  config:
    cwd: /path/to/workspace   # agent 工作目录，默认 DSH 启动目录
    provider: deepseek-official # 覆盖默认 provider 路由
    model: deepseek-v4-pro      # 覆盖默认模型
```

## 验证

微信里依次发：

1. 「你是谁」→ 身份与工作目录正确
2. 「记得刚才说了什么吗」→ 上下文连续
3. 「用 bash 跑 pwd」→ 工具可用
4. 一个只有 AGENTS.md 有答案的问题 → 规则注入生效

第一条消息可能慢 10~30 秒（agent 冷启动），属正常。

## 安全

- 消息走微信服务器，非端到端加密；别在微信里发密码/token。
- 插件无消息白名单，安全边界 = 你的微信账号；建议微信开双重验证/设备锁。
- API key 不落本插件任何文件，由 DSH 凭据服务解析。

## 说明

- 桥接底层用社区包 `weixin-agent-sdk`（走微信官方 iLink 通道，客户端代码非微信官方维护）。
- DSH 重启会清空微信对话记忆（文件改动不受影响）。
