#!/usr/bin/env bash
# 路人甲官网部署脚本（高位端口 HTTP 版，绕过未备案的 80/443 拦截）
# 用法：本机终端，与 luren-site.tar.gz 同目录执行  bash deploy-port.sh
# 作用：
#   1) 上传站点到 /var/www/luren-website
#   2) 从 Caddyfile 移除之前 ip.glmai.com.cn 的 80/443 配置块（停止无效的证书重试）
#   3) 自动挑一个空闲高位端口，用 Caddy 起一个纯 HTTP 静态站
#   4) 其他站点(hr/xhs/默认:80)一律不动；校验通过才重载
set -e

SERVER="ubuntu@43.143.122.43"
PKG="luren-site.tar.gz"
WEBROOT="/var/www/luren-website"

if [ ! -f "$PKG" ]; then
  echo "找不到 $PKG，请把本脚本和 luren-site.tar.gz 放在同一目录。"; exit 1
fi

echo "[1/4] 上传站点包 ..."
scp "$PKG" "$SERVER:/tmp/luren-site.tar.gz"

echo "[2/4] 远程部署 + 改 Caddy 配置 + 重载 ..."
ssh -t "$SERVER" "WEBROOT='$WEBROOT' bash -s" <<'REMOTE'
set -e

# 1) 更新静态文件
sudo mkdir -p "$WEBROOT"
sudo tar -xzf /tmp/luren-site.tar.gz -C "$WEBROOT"
rm -f /tmp/luren-site.tar.gz
sudo chown -R root:root "$WEBROOT"
sudo chmod -R a+rX "$WEBROOT"
echo ">> 文件已更新到 $WEBROOT"

# 2) 挑空闲高位端口
CANDIDATES="8088 8090 8188 8288 8388 8688 8788 8888 9080 9090"
PORT=""
for p in $CANDIDATES; do
  if ! ss -tlnH | awk '{print $4}' | sed 's/.*://' | grep -qx "$p"; then PORT="$p"; break; fi
done
if [ -z "$PORT" ]; then echo "候选端口都被占用，请手动改脚本 CANDIDATES。"; exit 1; fi
echo ">> 选用空闲端口: $PORT"

CADDYFILE=/etc/caddy/Caddyfile
TS=$(date +%Y%m%d-%H%M%S)
sudo cp "$CADDYFILE" "${CADDYFILE}.bak.${TS}"
echo ">> 已备份: ${CADDYFILE}.bak.${TS}"

# 3) 用 python 安全地：移除旧的 ip/luren 相关顶层块，追加新的 :PORT 块
sudo PORT="$PORT" WEBROOT="$WEBROOT" python3 - "$CADDYFILE" <<'PY'
import os, sys
path = sys.argv[1]
port = os.environ['PORT']
webroot = os.environ['WEBROOT']
lines = open(path, encoding='utf-8').read().split('\n')
out, i, n = [], 0, len(lines)
while i < n:
    line = lines[i]
    stripped = line.strip()
    top_level = (line[:1] not in (' ', '\t')) and stripped.endswith('{')
    if top_level:
        blk = [line]
        depth = line.count('{') - line.count('}')
        j = i + 1
        while j < n and depth > 0:
            blk.append(lines[j]); depth += lines[j].count('{') - lines[j].count('}'); j += 1
        btext = '\n'.join(blk)
        header = stripped[:-1].strip()
        # 丢弃：ip.glmai.com.cn 块，或任何指向 luren-website 的块（含旧的端口块，保证幂等）
        if header == 'ip.glmai.com.cn' or webroot in btext:
            i = j; continue
        out.extend(blk); i = j; continue
    out.append(line); i += 1
body = '\n'.join(out).rstrip() + '\n'
body += "\n:%s {\n\troot * %s\n\tencode gzip\n\tfile_server\n}\n" % (port, webroot)
open(path, 'w', encoding='utf-8').write(body)
print(">> 已移除旧 ip/luren 配置块，追加 :%s 纯HTTP站" % port)
PY

# 4) 校验 + 重载
if sudo caddy validate --config "$CADDYFILE" --adapter caddyfile >/dev/null 2>&1; then
  sudo systemctl reload caddy
  echo ">> Caddy 已重载"
else
  echo "!! 校验失败，未重载。已备份 ${CADDYFILE}.bak.${TS}，请把下面报错发我："
  sudo caddy validate --config "$CADDYFILE" --adapter caddyfile || true
  exit 1
fi

# 若开了 ufw，放行端口
if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
  sudo ufw allow "$PORT"/tcp || true
  echo ">> 已在 ufw 放行 $PORT"
fi

echo "PORT=$PORT" | sudo tee /tmp/luren_port >/dev/null
echo "----------------------------------------"
echo ">> 完成。访问地址（二选一）："
echo "   http://ip.glmai.com.cn:$PORT"
echo "   http://43.143.122.43:$PORT"
echo ">> 还需去【腾讯云控制台 → 安全组】放行入站 TCP 端口 $PORT，外网才能访问。"
echo "----------------------------------------"
REMOTE

echo "[3/4] 远程流程结束。"
echo "[4/4] 记得到腾讯云安全组放行上面显示的端口；备案通过后我再帮你切回裸域名 80/443 + HTTPS。"
