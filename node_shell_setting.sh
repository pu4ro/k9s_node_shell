#!/bin/bash

# K9s 환경변수 기본값 세팅 (수정 가능)
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# shellPod 세팅 추가 (존재하지 않으면 생성)
CONFIG_FILE="$XDG_CONFIG_HOME/k9s/config.yaml"
if ! grep -q 'shellPod:' "$CONFIG_FILE" 2>/dev/null; then
cat <<EOF >> "$CONFIG_FILE"
k9s:
  shellPod:
    image: cool_kid_admin:42
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
