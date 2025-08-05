#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "用法: $0 <trojan_uri_list.txt>"
  exit 1
fi

URI_FILE="$1"
if [[ ! -f "$URI_FILE" ]]; then
  echo "文件不存在: $URI_FILE"
  exit 1
fi

# 基础配置
CONFIG_DIR="$HOME/.config/trojan-go"
mkdir -p "$CONFIG_DIR"
BASE_PORT=1080    # 本地端口起始值
idx=0

while IFS= read -r URI; do
  # 跳过空行和注释
  [[ -z "${URI// /}" || "${URI:0:1}" == "#" ]] && continue

  ((idx++))
  LP=$((BASE_PORT + idx))        # 分配本地端口
  CONF="$CONFIG_DIR/config-$idx.json"

  # 提取 URI 各字段
  UUID=$(echo "$URI" | sed -nE 's/^trojan:\/\/([^@]+)@.*$/\1/')
  HOST=$(echo "$URI" | sed -nE 's/^trojan:\/\/[^@]+@([^:]+):.*$/\1/')
  PORT=$(echo "$URI" | sed -nE 's/^.*:([0-9]+)\?.*$/\1/')
  QSTR=$(echo "$URI" | sed -nE 's/^.*\?([^#]+)#.*$/\1/')
  TAG=$(echo "$URI" | sed -E 's/^.*#(.*)$/\1/')

  ALLOW_INSECURE=$(echo "$QSTR" | tr '&' '\n' | sed -nE 's/allowInsecure=([01])/\1/')
  SNI=$(echo "$QSTR" | tr '&' '\n' | sed -nE 's/sni=([^&]+)/\1/')

  # 生成 config.json
  cat > "$CONF" << EOF
{
  "run_type": "client",
  "local_addr": "127.0.0.1",
  "local_port": $LP,
  "remote_addr": "$HOST",
  "remote_port": $PORT,
  "password": ["$UUID"],
  "ssl": {
    "verify": $( [[ "$ALLOW_INSECURE" == "1" ]] && echo false || echo true ),
    "verify_hostname": $( [[ "$ALLOW_INSECURE" == "1" ]] && echo false || echo true ),
    "sni": "${SNI:-$HOST}"
  },
  "mux": {
    "enabled": false
  }
}
EOF

  echo "[$idx] 已生成配置 $CONF (本地端口: $LP, 标签: $TAG)"

  # 后台启动 trojan-go
  trojan-go -config "$CONF" &
done < "$URI_FILE"

echo "共处理 $idx 条 URI，trojan-go 实例已全部启动。"
echo "请在各个程序中分别将 SOCKS5 代理指向 127.0.0.1:<1080+序号> 使用。"
