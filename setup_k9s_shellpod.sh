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

# 클러스터/컨텍스트 리스트 자동 탐색 및 nodeShell feature gate 활성화
find "$XDG_DATA_HOME/k9s/clusters" -type f -name config.yaml | while read -r CLUSTER_CONFIG; do
    # featureGates가 없으면 추가, 있으면 nodeShell만 추가/수정
    if grep -q 'featureGates:' "$CLUSTER_CONFIG"; then
        # 이미 nodeShell 설정이 있다면 값만 true로 변경
        if grep -q 'nodeShell:' "$CLUSTER_CONFIG"; then
            sed -i 's/nodeShell: .*/nodeShell: true/' "$CLUSTER_CONFIG"
        else
            # featureGates 블록에 nodeShell 추가
            sed -i '/featureGates:/a\    nodeShell: true' "$CLUSTER_CONFIG"
        fi
    else
        # featureGates 블록 자체가 없으면 k9s: 아래 추가
        sed -i '/k9s:/a\  featureGates:\n    nodeShell: true' "$CLUSTER_CONFIG"
    fi
done

echo "K9s nodeShell & shellPod 설정이 모든 컨텍스트에 적용되었습니다."

echo "K9s shellPod image가 $IMAGE 로 설정되었습니다."

