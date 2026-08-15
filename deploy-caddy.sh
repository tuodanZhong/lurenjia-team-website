#!/usr/bin/env bash
# 路人甲官网部署脚本（Caddy 版）
# 用法：本机终端，与 luren-site.tar.gz 同目录执行  bash deploy-caddy.sh
# 作用：把站点放到 /var/www/luren-website，并在现有 Caddyfile 里"追加"一段
#      ip.glmai.com.cn 的配置（其他站点不动），Caddy 自动签发 HTTPS。
set -e

SERVER="ubuntu@43.143.122.43"
DOMAIN="ip.glmai.com.cn"
PKG="luren-site.tar.gz"
WEBROOT="/var/www/luren-website"

if [ ! -f "$PKG" ]; then
  echo "找不到 $PKG，请把本脚本和 luren-site.tar.gz 放在同一目录。"; exit 1
fi

echo "[1/4] 上传站点包 ..."
scp "$PKG" "$SERVER:/tmp/luren-site.tar.gz"

echo "[2/4] 远程部署文件 + 追加 Caddy 配置 + 重载 ..."
ssh -t "$SERVER" "DOMAIN='$DOMAIN' WEBROOT='$WEBROOT' bash -s" <<'REMOTE'
set -e

# 1) 部署静态文件
sudo mkdir -p "$WEBROOT"
sudo tar -xzf /tmp/luren-site.tar.gz -C "$WEBROOT"
rm -f /tmp/luren-site.tar.gz
sudo chown -R root:root "$WEBROOT"
sudo chmod -R a+rX "$WEBROOT"          # 保证 caddy 用户可读
echo ">> 文件已部署到 $WEBROOT"

CADDYFILE=/etc/caddy/Caddyfile

# 2) 备份现有 Caddyfile
TS=$(date +%Y%m%d-%H%M%S)
sudo cp "$CADDYFILE" "${CADDYFILE}.bak.${TS}"
echo ">> 已备份: ${CADDYFILE}.bak.${TS}"

# 3) 若还没配过该域名，则追加一段（幂等）
if sudo grep -q "$DOMAIN" "$CADDYFILE"; then
  echo ">> Caddyfile 里已存在 $DOMAIN，跳过追加（如需更新请手动检查）。"
else
  sudo tee -a "$CADDYFILE" >/dev/null <<BLOCK

$DOMAIN {
	root * $WEBROOT
	encode gzip
	file_server
}
BLOCK
  echo ">> 已追加 $DOMAIN 配置块"
fi

# 4) 校验 + 平滑重载
if sudo caddy validate --config "$CADDYFILE" --adapter caddyfile; then
  sudo systemctl reload caddy
  echo ">> Caddy 已重载"
else
  echo "!! Caddyfile 校验失败，未重载。已保留备份 ${CADDYFILE}.bak.${TS}，请把上面报错发我。"
  exit 1
fi

echo "----------------------------------------"
echo ">> 完成。访问: https://$DOMAIN"
echo ">> 首次访问若证书还没签好，等 10~30 秒再刷新（Caddy 正在自动申请 HTTPS）。"
echo "----------------------------------------"
REMOTE

echo "[3/4] 部署流程结束。"
echo "[4/4] 打开 https://ip.glmai.com.cn 验证；以后更新内容重新打包后再次运行本脚本即可。"
