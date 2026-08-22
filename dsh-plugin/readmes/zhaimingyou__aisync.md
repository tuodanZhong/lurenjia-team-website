# aisync 多电脑统一入口

一个入口（选择器页）→ 每台电脑一个子域名 → 服务器上的 SSH 隧道反代到各电脑的 DeepSeek Harness（DSH）Web GUI。

> 本文档以作者自己的部署为例（域名 aisync.club、ECS 阿里云）。**换成你自己的域名/服务器**见下方「部署到自己的域名/服务器」——仓库已参数化，占位符见「部署前替换清单」。

## 架构

```
📱 手机/任意设备
   │  https://aisync.club        ← 电脑选择页 + 控制面接口 (/register /heartbeat)
   │
   ├── https://mac.aisync.club   → ECS 127.0.0.1:10080 → MacBook DSH :3080
   ├── https://dgx.aisync.club   → ECS 127.0.0.1:10081 → dgxspark DSH :3080
   └── https://pc.aisync.club    → ECS 127.0.0.1:10082 → 高性能PC DSH :3080

每台电脑 ──心跳 POST /heartbeat (60s)──▶ ECS aisyncd ──▶ machines.json ──▶ 选择器页
           ──SSH 反向隧道 ──────────────▶ ECS 回环端口 ──▶ nginx map 反代
```

- **DNS**：泛域名 `*.aisync.club` A 记录 → `REPLACE_ECS_PUBLIC_IP`（加新电脑/改名不用再动 DNS）
- **证书**：泛域名证书 `*.aisync.club` + `aisync.club`（certbot + 阿里云 DNS-01）
- **认证**：Authelia，cookie 域 `.aisync.club`，一次登录三台通用
- **隧道**：每台电脑 autossh/ssh 反向隧道，连 ECS 的回环端口；ECS 无需开放任何新公网端口
- **控制面**：ECS 上的 `aisyncd`（Python 标准库守护进程，仅回环监听），负责机器注册、心跳聚合、nginx map 渲染
- **昵称同步**：ECS 上的 `labels-api`（仅回环监听，受 Authelia 保护），✏️ 昵称按账号存储、跨设备生效
- **仪表盘**：首页除选机器卡片外，还显示每台机器的 DSH 活动连接数（机器侧统计 TCP 到 DSH 端口）和 24 小时连接数；下方"近期连接"表展示最近连接（时间/机器/用户/来源 IP/方式），数据来自 nginx 机器子域名 JSON access log → aisyncd 聚合

## 控制面（aisyncd）与机器记录

机器清单的唯一数据源是 **ECS 上的 `/etc/aisync/machines/*.json`**（每台机器一份记录：
`name / label / icon / port / heartbeat_token / last_seen / last_hb`）。以下产物全部由 aisyncd 从记录派生：

| 产物 | 路径 | 说明 |
|------|------|------|
| nginx map 反代 | `/etc/nginx/conf.d/machines.conf` | 按记录渲染（map 版，见 `ecs/nginx-machines.conf`） |
| 选择器数据 | `/var/www/aisync-selector/machines.json` | 分层健康：隧道 → 心跳 → DSH + 活动连接数 |
| 连接日志 | `/var/www/aisync-selector/connections.json` | 仪表盘近期连接聚合（来源：nginx 机器子域名 JSON access log） |
| 兼容数据 | `/var/www/aisync-selector/status.json` | 旧格式（name/port/icon/label/online） |

**接口**（HTTPS，经 nginx 反代到回环，token 鉴权，带限流）：

- `POST /register`：机器用一次性 bootstrap token（`/etc/aisync/register.token`）注册 → 自动分配端口池
  10080-10089 空闲端口 → 生成机器记录与心跳 token → 渲染 nginx map → `nginx -t` + reload（失败自动回滚）
- `POST /heartbeat`：机器用各自心跳 token 上报 load/内存/GPU/DSH 存活/活动连接数，服务器时间戳记为 `last_seen`
- `GET /machines.json` / `GET /connections.json`：首页仪表盘数据（选择器 + 近期连接日志），受 Authelia 保护，由 nginx 以静态文件服务

## 部署前替换清单（仓库已参数化）

本项目仓库已把个人化信息参数化为占位符，部署到你的环境前全局替换：

| 占位符 | 含义 | 出现在 |
|--------|------|--------|
| `REPLACE.DOMAIN` | 你的域名（**推荐**用环境变量 `AISYNC_DOMAIN` 注入，`aisyncd-install.sh` 与机器侧 install 脚本会自动替换；也可以全局 sed） | nginx 配置、Authelia 配置、证书/DNS 脚本、`--trusted-host`、各 install 脚本 |
| `REPLACE_ECS_PUBLIC_IP` | 服务器公网 IP（推荐环境变量 `ECS_PUBLIC_IP`） | `ecs/dns-setup.sh`、`ecs/run-remote-diagnose.sh`、各机器的隧道 service/plist |
| `REPLACE_USER` | 各机器的登录用户名（机器侧 install 脚本会自动用 `whoami` 替换） | mac 的 launchd plist（文件名与 Label）、dgx/pc 的 systemd service |
| `REPLACE_AK_ID` / `REPLACE_AK_SECRET` | 阿里云 DNS 权限的 AccessKey（仅 `acme-wildcard.sh`/DNS 脚本需要） | `ecs/acme-wildcard.sh` |
| `ecs/pubkeys/*.pub` | 各机器隧道公钥（换成你自己的公钥后再跑 `harden-authorized-keys.sh`） | pubkeys 目录 |
| `aisync_ecs` / `id_ed25519` | 各机器 SSH 私钥文件名 | 隧道 service/plist 的 `-i` 参数 |

替换方式：`grep -rn 'REPLACE' .` 找到全部位置；推荐把 `export AISYNC_DOMAIN=<你的域名>` 与 `export ECS_PUBLIC_IP=<服务器IP>` 写进你的 shell 配置，各 install 脚本运行时自动替换，无需改文件。

## 开源

- 协议：**MIT**（见 `LICENSE`），可自由使用、修改、商用，保留版权声明即可
- 仓库内容都是部署代码与配置模板，**不含任何真实密钥**：token 一律运行时生成（`/etc/aisync/register.token`、机器记录、Authelia 密钥走 systemd 环境注入），占位符见上表
- 贡献欢迎以 PR 形式提交；涉及 `aisyncd.py` 的 NGINX_TEMPLATE 改动请同步 `ecs/nginx-machines.conf`（两者需保持同构，见下方关键约束）

## 部署到自己的域名/服务器（完整流程）

不需要阿里云也能跑：核心（`aisyncd.py` 纯标准库 Python + nginx + Authelia + 机器侧 agent）任何 Linux 服务器可用。只有三个便利脚本绑定阿里云（均可自行替换）：`dns-setup.sh`（阿里云 DNS）、`acme-wildcard.sh`（阿里云 DNS-01 签证书，acme.sh 支持几十家 DNS 服务商）、`run-remote-diagnose.sh`（云助手，可选）。

```bash
export AISYNC_DOMAIN=你的域名          # 例: example.com
export ECS_PUBLIC_IP=你的服务器公网IP  # 例: 1.2.3.4
```

1. **域名 + DNS**：买域名，加泛域名 A 记录 `*.<域名>` → 服务器公网 IP（阿里云域名可跑 `ecs/dns-setup.sh`，其他注册商在面板加）。
2. **证书**：服务器上装 acme.sh，跑 `ecs/acme-wildcard.sh`（改 `REPLACE_AK_ID/SECRET` 为你的 DNS AccessKey，或换其他 DNS API）；证书落盘到 `/etc/nginx/ssl/<域名>/`。
3. **控制面**：仓库拷到服务器，`cd ecs && ./aisyncd-install.sh` —— 脚本用 `AISYNC_DOMAIN` 自动替换 nginx/Authelia/systemd 里的 `REPLACE.DOMAIN`，生成 bootstrap token，渲染 machines.conf，`nginx -t` 失败自动回滚。
4. **Authelia 用户**：`/etc/authelia/users.yml` 建你的账号（argon2 哈希），跑 `./authelia-secrets.sh` 注入密钥并重启 authelia。
5. **每台电脑接入**：`machines/common/aisync-agent.sh register <名字> <昵称> <图标>`（交互输入 bootstrap token）→ `install` 装心跳；DSH 启动加 `--trusted-host <名字>.<域名>`（systemd 模板 `dsh-web.service` 里的 `REPLACE.DOMAIN` 由机器侧 install 脚本自动替换）。
6. **公钥硬化**：各机器公钥追加进 `/root/.ssh/authorized_keys` 后跑 `./harden-authorized-keys.sh --apply`（每把钥匙只允许开自己的隧道端口）。
7. **验证**：`curl -s http://127.0.0.1:8787/healthz` → ok；浏览器开 `https://<域名>` 登录后卡片显示"在线 · DSH 运行中"。
8. 选择器页**自动从当前域名推断子域名**（`location.hostname` 取后两段），无需任何配置。

## 机器接入（新电脑，全程一条命令）

1. ECS 已部署 aisyncd（见下方"部署与迁移"），管理员读出 bootstrap token：
   `cat /etc/aisync/register.token`
2. 新电脑装 autossh、生成 SSH 密钥（`aisync-agent.sh register` 自动完成），执行：
   ```bash
   machines/common/aisync-agent.sh register <name> <label> <icon>   # 交互输入 bootstrap token
   machines/common/aisync-agent.sh install                          # 装心跳定时器(systemd/launchd)
   ```
3. ECS 上：把公钥追加到 `/root/.ssh/authorized_keys` 后跑
   `./harden-authorized-keys.sh --apply`（自动给每台机器的钥匙加
   `restrict,port-forwarding,permitlisten="127.0.0.1:<端口>"` 前缀，只能开自己的隧道端口）
4. 那台电脑的 DSH 启动参数加 `--trusted-host <名字>.aisync.club`

注册成功后 selector 页自动出现新卡片；心跳上线后显示"在线 · DSH 运行中 + 负载/GPU"。

## 给电脑改名

两种名字，成本不同：

- **显示名**（卡片上的标题）：改 ECS 记录 `/etc/aisync/machines/<name>.json` 的 `label` 后
  `systemctl kill -s HUP aisyncd`，最迟 30 秒全端生效；或直接在选择器页点卡片上的 ✏️ 改昵称
  —— 部署 labels-api 后**按账号同步、所有设备通用**（未部署时退化为保存在当前浏览器
  localStorage），清空回车恢复默认。
  两者都**不用碰** DNS / 证书 / nginx / 隧道 / trusted-host。
- **子域名**（mac/dgx/pc）：泛域名 DNS + 泛域名证书依然不用动，改两处：
  1. ECS：`mv /etc/aisync/machines/<旧名>.json <新名>.json`（改文件内 `name`），
     `systemctl kill -s HUP aisyncd`（nginx map 自动重渲染 + reload 需手动 `systemctl reload nginx`）
  2. 那台电脑：DSH 启动参数 `--trusted-host` 换成新名字并重启 DSH（隧道不用动，只关心端口，与域名无关）

## 部署与迁移（ECS 上，root）

```bash
cd ecs
./aisyncd-install.sh        # 幂等: 安装 aisyncd + labels-api + legacy 记录 + nginx 收口 + 停旧探针
```

安装脚本会：备份现有 nginx 配置到 `/etc/nginx/conf.d/backup-aisyncd-<时间戳>/`；
把现有三台机器转成 legacy 记录（保留原端口，**打印每台的心跳 token**）；
`nginx -t` 失败自动回滚。labels-api 单独部署（可选，昵称跨设备同步依赖它）：

```bash
install -m 755 labels-api.py /usr/local/bin/aisync-labels-api.py
install -m 644 labels-api.service /etc/systemd/system/aisync-labels-api.service
systemctl daemon-reload && systemctl enable --now aisync-labels-api
# apex 配置已含 /api/ 反代块; 若已部署过需重装该 conf:
# install -m 644 aisync-club-final.conf /etc/nginx/conf.d/aisync.conf && nginx -t && systemctl reload nginx
# 校验(未带用户头应 401):  curl -s http://127.0.0.1:8645/api/mylabels
```

### 安全加固（部署后建议立即执行）

```bash
./harden-authorized-keys.sh          # 预览将写入的硬化行
./harden-authorized-keys.sh --apply  # 自动备份并改写 authorized_keys
./authelia-secrets.sh                # 生成密钥 → systemd 注入 → 重启 authelia(重新登录一次)
```

每台老电脑认领一次心跳（token 见安装输出或 `./aisync-token-show.sh <name>`）：

```bash
# 各机器上 (dgx: <dgx用户> / mac: <mac用户> / pc: WSL2 内)
sudo cp machines/common/aisync-agent.sh /usr/local/bin/ && sudo chmod 755 /usr/local/bin/aisync-agent.sh
aisync-agent.sh adopt <name> <心跳token>
aisync-agent.sh install         # 装心跳定时器; pc 见 machines/pc-windows/README.md
```

回滚：恢复备份目录里的 nginx 文件 + `systemctl disable --now aisyncd aisync-labels-api`。
旧探针(status-check)已随 art 域名一并移除。

## 目录结构

```
ecs/                         ECS 侧部署文件（放到 ECS 上执行）
  aisyncd.py                 控制面守护进程（注册/心跳/状态聚合/nginx map 渲染, 标准库 only）
  aisyncd.service            systemd 单元
  aisyncd-install.sh         一键部署（备份 + legacy 迁移 + 校验 + 回滚, 含 labels-api）
  labels-api.py              每用户昵称同步 API（受 Authelia 保护, 仅回环监听）
  labels-api.service         systemd 单元
  aisync-register-legacy.sh  老机器记录迁移（读 /etc/aisync-machines.conf 或传参）
  aisync-token-show.sh       查看/轮换机器心跳 token
  aisync-club-final.conf     aisync.club apex 配置（备案主域; 选择器 + /register /heartbeat /api/ 反代 + 限流 + HSTS）
  nginx-machines.conf        nginx map 版反代模板（aisyncd 按记录渲染同构文件, 含 TLS 加固）
  harden-authorized-keys.sh  隧道公钥加固（restrict,port-forwarding,permitlisten, 可 dry-run）
  authelia-secrets.sh        Authelia 密钥生成/轮换（EnvironmentFile 注入, 不落明文）
  diagnose.sh                云助手/SSH 诊断脚本（排查 sshd 卡死）
  run-remote-diagnose.sh     本机定位实例 → 云助手执行 diagnose.sh → 取回结果
  fix-image-upload-body-size.sh  DSH 贴图发送 413 修复（nginx 请求体上限 150m, 幂等+自动回滚）
  acme-wildcard.sh           用 acme.sh 签发泛域名证书 (DNS-01)
  selector/                  选择器页（数据驱动 + 分层健康 + ✏️ 改昵称）
machines/
  common/                    机器侧通用 agent（register/adopt/heartbeat/install）+ timer 模板
  mac/                       Mac 本机 launchd 隧道（含 ControlMaster 加固）+ DSH 目录选择器 browse 补丁
  dgxspark/                  dgxspark: 隧道 + DSH 安装 + systemd
  pc-windows/                Windows 高性能 PC 的 WSL2/原生方案 + 心跳计划任务
tests/
  smoke.sh                   本地全链路冒烟（不碰 ECS/nginx）
```

## 关键约束（踩过的坑）

- DSH 前端资源是绝对路径，**必须用子域名不能用子路径**
- 每台电脑的 DSH 必须带 `--trusted-host <自己的子域名>`，否则 Host 校验拒绝访问
- ECS 的 sshd 保持默认 `GatewayPorts no`：隧道绑 ECS 回环，nginx 再反代，公网不暴露
- nginx 反代必须支持 WebSocket upgrade（DSH 事件流依赖），超时调大
- `nginx-machines.conf`（及 aisyncd 渲染版）依赖 apex 顶部的
  `map $http_upgrade $connection_upgrade`（现由 `aisync-club-final.conf` 自带，部署为 `aisync.conf`）
- `/register` 与 `/heartbeat` 是 exact location，不受 Authelia 拦截，安全性靠 token + nginx 限流；
  bootstrap token 泄露可增删机器，用后建议轮换（`openssl rand -hex 16 > /etc/aisync/register.token` + 重启 aisyncd）
- `/api/`（labels-api）是用户侧接口，走 Authelia 认证；nginx 经 `auth_request_set` 把
  `Remote-User` 透传后端，labels-api 无用户头一律 401，数据存 `/var/lib/aisync-labels/labels.json`
- 机器记录目录 `/etc/aisync/` 权限保持 root-only（含心跳 token）；心跳 token 泄露只会被冒报状态，可 `aisync-token-show.sh <name> rotate` 轮换
- TLS 加固：apex 配置均带 HSTS（`includeSubDomains`）+ `ssl_session_cache`；aisyncd 渲染的
  machines.conf 与 `ecs/nginx-machines.conf` 同构，加固项需同步进 `aisyncd.py` 的 NGINX_TEMPLATE
- authorized_keys 硬化依赖 OpenSSH 8.5+（`permitlisten`），版本不足时脚本自动降级为
  `command="",port-forwarding`；⚠️ 实测阿里云 Linux 3 的 OpenSSH 8.0p1-29.al8 构建会
  **静默丢弃 `restrict`**（调试日志 key options 只剩 port-forwarding），所以脚本一律用
  `command=""` 拦 exec（`-N` 隧道不触发命令，不受影响）；
  执行前确保保留至少一把无限制的管理员钥匙，脚本会先备份
- Authelia 的 `session.secret` / `storage.encryption_key` 不再写配置文件，由 `authelia-secrets.sh`
- **nginx 机器子域名配置与 aisyncd NGINX_TEMPLATE 必须同构**：任何改动（含本次新增的 `log_format aisync_conn`、`access_log`、`auth_request_set $auth_user`）必须同时修改 `ecs/nginx-machines.conf` 和 `aisyncd.py` 的 `NGINX_TEMPLATE`，否则注册新机器时渲染的配置会丢失这些字段。连接日志文件 `/var/log/nginx/aisync-machines.log` 被 nginx 默认 logrotate 自动覆盖。
  生成到 `/etc/authelia/authelia.env`（600）经 systemd EnvironmentFile 注入；`--rotate` 会使所有会话失效
- **DSH 目录选择器与远端访问**：mac 的 DSH 以 `--host 127.0.0.1` 本地启动、由远端经隧道访问，
  darwin 平台会被自适应选择器（directory-picker-auto）误判为"操作者在本机屏幕前"而挂载 native
  后端——远端浏览器点"添加工作区"时 osascript 弹窗开在 Mac 屏幕上（远端看不到），目录浏览/
  新建文件夹 API 也返回不可用。修复：把 `machines/mac/dsh-web.cordis.patch.yml` 复制为
  `~/.dsh/cordis.patch.yml`（固定 browse 交互；用户层 patch 热加载，无需重启 DSH）。
  dgx/pc 走 headless Linux 自动解析为 browse，不受影响；若 pc 改在原生 Windows 跑 DSH，同样需要此 patch。
- **DSH 贴图发送被 nginx 413 拒绝**：机器子域名反代块没有 `client_max_body_size`（默认 1m），
  而 DSH 图片以 base64 进 `session.prompt` 请求体（单条消息上限 100MB），超过 ~750KB 的截图
  一发送就被 413。修复：ECS 上跑 `ecs/fix-image-upload-body-size.sh`（在 location / 加
  `client_max_body_size 150m`，并同步进 `aisyncd.py` 的 NGINX_TEMPLATE，幂等、失败自动回滚）。
  /register /heartbeat 的 256k 限制是有意保留的。
