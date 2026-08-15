#!/usr/bin/env bash
# 把路人甲站从 8080 迁到 8088，并腾出 8080。
# 安全点：8088 上的旧实例可能是 Caddy 提供的（deploy-port.sh 那套），
#         Caddy 往往还在给别的站点服务，所以只“移除 :8088 配置块 + reload”，绝不杀 Caddy 进程。
#         若 8088 是零散 python http.server，则精准停掉该进程（不动其它）。
# 用法：本机终端执行  bash switch-port-8088.sh
set -e

SERVER="ubuntu@43.143.122.43"
NEWPORT=8088
OLDPORT=8080

echo ">> 连接服务器执行迁移 ..."
ssh -t "$SERVER" "NEWPORT=$NEWPORT OLDPORT=$OLDPORT bash -s" <<'REMOTE'
set -e

echo "========== 迁移前状态 =========="
echo -n ">> :$NEWPORT 现状: "; sudo ss -tlnp | grep ":$NEWPORT " || echo "(空闲)"
echo -n ">> :$OLDPORT 现状: "; sudo ss -tlnp | grep ":$OLDPORT " || echo "(空闲)"
echo "================================"

# ---- 1) 腾出 $NEWPORT ----
FREED=""
# 情况 a：Caddy 提供 :$NEWPORT —— 只移除该块并 reload，不碰 Caddy 其它站点
if command -v caddy >/dev/null 2>&1 && [ -f /etc/caddy/Caddyfile ] && grep -qE "^:$NEWPORT[[:space:]]*\{" /etc/caddy/Caddyfile; then
  echo ">> 检测到 Caddy 提供 :$NEWPORT，安全移除该配置块（不影响其它站点）..."
  sudo cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%Y%m%d-%H%M%S)"
  sudo NEWPORT="$NEWPORT" python3 - /etc/caddy/Caddyfile <<'PY'
import os, sys
path = sys.argv[1]; port = os.environ['NEWPORT']
lines = open(path, encoding='utf-8').read().split('\n')
out, i, n = [], 0, len(lines)
while i < n:
    l = lines[i]; s = l.strip()
    if s.startswith(':'+port) and s.endswith('{'):
        depth = l.count('{') - l.count('}'); i += 1
        while i < n and depth > 0:
            depth += lines[i].count('{') - lines[i].count('}'); i += 1
        continue
    out.append(l); i += 1
open(path, 'w', encoding='utf-8').write('\n'.join(out))
print("   已移除 :%s 块" % port)
PY
  if sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null 2>&1; then
    sudo systemctl reload caddy && echo "   Caddy 已重载" && FREED="caddy"
  else
    echo "!! Caddy 校验失败，未重载（已备份），请把报错发我。"; exit 1
  fi
fi
# 情况 b：零散 python http.server 占用 :$NEWPORT —— 精准停掉（只停 http.server，不误伤 Caddy 等）
if [ -z "$FREED" ]; then
  PIDS=$(sudo ss -tlnpH "sport = :$NEWPORT" 2>/dev/null | grep -o 'pid=[0-9]*' | cut -d= -f2 | sort -u || true)
  for pid in $PIDS; do
    if ps -p "$pid" -o cmd= 2>/dev/null | grep -q 'http.server'; then
      echo ">> 停掉占用 :$NEWPORT 的旧 http.server 进程 pid=$pid"
      sudo kill "$pid" 2>/dev/null || true; FREED="python"
    fi
  done
fi
sleep 1

# ---- 2) 把 luren-web.service 指到 $NEWPORT 并重启（会自动放开 $OLDPORT）----
if [ -f /etc/systemd/system/luren-web.service ]; then
  echo ">> 将 luren-web.service 切到 :$NEWPORT ..."
  sudo sed -i "s|http.server [0-9]*|http.server $NEWPORT|" /etc/systemd/system/luren-web.service
  sudo systemctl daemon-reload
  sudo systemctl restart luren-web.service
else
  echo "!! 没找到 luren-web.service（可能当前 8080 也是 Caddy 提供的）。请把上面『迁移前状态』发我，我再给你对应方案。"; exit 1
fi

# ---- 3) 防火墙放行 $NEWPORT ----
if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
  sudo ufw allow "$NEWPORT"/tcp || true
fi

sleep 1
echo "========== 迁移后结果 =========="
echo -n ">> :$NEWPORT : "; sudo ss -tlnp | grep ":$NEWPORT " && echo "   ✓ 路人甲站已在 $NEWPORT" || echo "   ✗ 未监听（异常，请把输出发我）"
echo -n ">> :$OLDPORT : "; sudo ss -tlnp | grep ":$OLDPORT " || echo "   ✓ 已空出"
sudo systemctl --no-pager --lines=0 status luren-web.service | head -4
echo ">> 访问地址: http://43.143.122.43:$NEWPORT"
echo ">> 注意：到腾讯云控制台【安全组】放行入站 TCP $NEWPORT；如不再需要 $OLDPORT，可在安全组关闭它。"
echo "================================"
REMOTE

echo ">> 迁移流程结束。"
