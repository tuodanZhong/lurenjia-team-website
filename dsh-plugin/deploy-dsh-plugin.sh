#!/usr/bin/env bash
# DSH 插件小卖部 · 一键部署脚本
# 作用：上传 dsh-plugin 目录到服务器，静态文件进 webroot，后端建 venv + systemd 常驻，Caddy 加 API 反代。
# 用法：在本机项目根目录执行  bash dsh-plugin/deploy-dsh-plugin.sh
# 可选：DSH_ADMIN_PASSWORD=你的密码 bash dsh-plugin/deploy-dsh-plugin.sh （仅首次建管理员时生效）
set -e

SERVER="ubuntu@43.143.122.43"
DOMAIN="ip.midonghub.com"
API_PORT="8787"
REMOTE_APP="/home/ubuntu/dsh-plugin-api"
WEBROOT="/var/www/luren-website"
CADDYFILE=/etc/caddy/Caddyfile
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[1/3] 打包并上传 ..."
# 排除本地测试数据(data.db)、虚拟环境(venv)、缓存，保证服务器从零初始化
tar --exclude='dsh-plugin/api/data.db' --exclude='dsh-plugin/api/venv' --exclude='__pycache__' \
  -czf /tmp/dsh-plugin-pkg.tar.gz -C "$SCRIPT_DIR/.." dsh-plugin
scp /tmp/dsh-plugin-pkg.tar.gz "$SERVER:/tmp/dsh-plugin-pkg.tar.gz"
rm -f /tmp/dsh-plugin-pkg.tar.gz

echo "[2/3] 远程部署 ..."
ssh -t "$SERVER" "DOMAIN='$DOMAIN' API_PORT='$API_PORT' REMOTE_APP='$REMOTE_APP' WEBROOT='$WEBROOT' CADDYFILE='$CADDYFILE' DSH_ADMIN_PASSWORD='${DSH_ADMIN_PASSWORD:-}' bash -s" <<'REMOTE'
set -e

# 1) 解包
sudo mkdir -p "$WEBROOT"
sudo tar -xzf /tmp/dsh-plugin-pkg.tar.gz -C "$WEBROOT"
mkdir -p "$REMOTE_APP"
tar -xzf /tmp/dsh-plugin-pkg.tar.gz -C "$REMOTE_APP"
rm -f /tmp/dsh-plugin-pkg.tar.gz
sudo chown -R root:root "$WEBROOT/dsh-plugin"
sudo chmod -R a+rX "$WEBROOT/dsh-plugin"
echo ">> 静态文件已到 $WEBROOT/dsh-plugin，后端代码已到 $REMOTE_APP/dsh-plugin"

# 2) venv + 依赖
cd "$REMOTE_APP/dsh-plugin/api"
if [ ! -x venv/bin/python ] || [ ! -x venv/bin/pip ]; then
  if ! python3 -m venv venv; then
    echo ">> 缺少 Python venv 依赖，安装 python3.12-venv ..."
    sudo apt-get update
    sudo apt-get install -y python3.12-venv
    python3 -m venv venv
  fi
fi
./venv/bin/pip install -q --upgrade pip
./venv/bin/pip install -q -r requirements.txt
echo ">> Python 依赖就绪"

# 3) systemd 常驻
sudo tee /etc/systemd/system/dsh-plugin-api.service >/dev/null <<UNIT
[Unit]
Description=DSH plugin market API
After=network.target

[Service]
User=ubuntu
WorkingDirectory=$REMOTE_APP/dsh-plugin/api
Environment=DSH_COOKIE_SECURE=1
Environment=DSH_ADMIN_USER=admin
Environment=DSH_ADMIN_PASSWORD=$DSH_ADMIN_PASSWORD
ExecStart=$REMOTE_APP/dsh-plugin/api/venv/bin/uvicorn main:app --host 127.0.0.1 --port $API_PORT
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable dsh-plugin-api.service
sudo systemctl restart dsh-plugin-api.service
sleep 2
sudo systemctl --no-pager --lines=0 status dsh-plugin-api.service | head -4 || true

# 4) Caddy 路由（幂等）
TS=$(date +%Y%m%d-%H%M%S)
sudo cp "$CADDYFILE" "${CADDYFILE}.bak.${TS}"
sudo python3 - "$CADDYFILE" "$DOMAIN" "$API_PORT" "$WEBROOT" <<'PY'
import re
import sys

path, domain, port, webroot = sys.argv[1:]
text = open(path, encoding="utf-8").read()
lines = text.splitlines(keepends=True)
start = None
depth = 0
end = None
header = re.compile(r"^\s*" + re.escape(domain) + r"\s*\{\s*$")

for index, line in enumerate(lines):
    if header.match(line):
        start = index
        break

if start is None:
    print("!! 没找到 %s 配置块" % domain)
    sys.exit(1)

for index in range(start, len(lines)):
    depth += lines[index].count("{") - lines[index].count("}")
    if depth == 0:
        end = index
        break

if end is None:
    print("!! %s 配置块括号不完整" % domain)
    sys.exit(1)

replacement = f"""{domain} {{
\thandle /dsh-plugin/api/* {{
\t\treverse_proxy 127.0.0.1:{port}
\t}}

\thandle /dsh-plugin/* {{
\t\troot * {webroot}
\t\tfile_server
\t}}

\thandle {{
\t\treverse_proxy 127.0.0.1:8088
\t}}
}}
"""
updated = "".join(lines[:start]) + replacement + "".join(lines[end + 1:])
open(path, "w", encoding="utf-8").write(updated)
print(">> 已配置 %s：插件静态文件 + API 反代 + 主站回退" % domain)
PY

if sudo caddy validate --config "$CADDYFILE" --adapter caddyfile; then
  sudo systemctl reload caddy
  echo ">> Caddy 已重载"
else
  echo "!! Caddyfile 校验失败，未重载。备份在 ${CADDYFILE}.bak.${TS}"
  exit 1
fi

# 5) 自检
sleep 1
echo ">> 自检:"
curl -s -o /dev/null -w "   服务器本地 API: %{http_code}\n" "http://127.0.0.1:$API_PORT/dsh-plugin/api/plugins"
curl -s -o /dev/null -w "   公网 API: %{http_code}\n" "https://$DOMAIN/dsh-plugin/api/plugins" || true
curl -s -o /dev/null -w "   公网市场页: %{http_code}\n" "https://$DOMAIN/dsh-plugin/"

echo "----------------------------------------"
echo ">> 完成。访问 https://$DOMAIN/dsh-plugin/"
echo ">> 管理员 admin 的初始密码: sudo journalctl -u dsh-plugin-api | grep 初始密码"
echo "----------------------------------------"
REMOTE

echo "[3/3] 部署结束。"
