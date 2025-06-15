#!/bin/bash

# 사용법: ./setup_k9s_shellpod.sh <image>
# 예시: ./setup_k9s_shellpod.sh ghcr.io/youruser/k9s-nodeshell:latest

if [ $# -ne 1 ]; then
    echo "사용법: $0 <image>"
    echo "예시: $0 ghcr.io/youruser/k9s-nodeshell:latest"
    exit 1
fi

IMAGE=$1
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
K9S_CONFIG_FILE="$XDG_CONFIG_HOME/k9s/config.yaml"

mkdir -p "$(dirname "$K9S_CONFIG_FILE")"

if grep -q 'shellPod:' "$K9S_CONFIG_FILE" 2>/dev/null; then
    # shellPod 섹션이 이미 있으면 image 값만 변경
    sed -i "/shellPod:/,/limits:/{s#image:.*#image: $IMAGE#}" "$K9S_CONFIG_FILE"
else
cat <<EOF >> "$K9S_CONFIG_FILE"
k9s:
  shellPod:
    image: $IMAGE
    namespace: default
    limits:
      cpu: 100m
      memory: 100Mi
EOF
fi

echo "K9s shellPod image가 $IMAGE 로 설정되었습니다."

