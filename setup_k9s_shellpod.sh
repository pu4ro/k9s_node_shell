#!/bin/bash

# 사용법: ./setup_k9s_shellpod.sh [image]
# .env 파일로 변수 관리 가능 (IMAGE, NAMESPACE, CPU_LIMIT, MEMORY_LIMIT)
# 인자로 image를 전달하면 .env보다 우선 적용

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"

# .env 파일 로드
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
    echo ".env 로드: $ENV_FILE"
fi

# 인자가 있으면 .env보다 우선
if [ $# -ge 1 ]; then
    IMAGE=$1
fi

# 기본값 설정
IMAGE="${IMAGE:-cr.makina.rocks/external-hub/node-shell:v0.1}"
NAMESPACE="${NAMESPACE:-default}"
CPU_LIMIT="${CPU_LIMIT:-100m}"
MEMORY_LIMIT="${MEMORY_LIMIT:-100Mi}"

# k9s 설정 디렉토리 자동 탐색 (OS 무관)
# 우선순위: XDG_CONFIG_HOME > ~/.config/k9s > ~/.k9s
detect_k9s_dir() {
    local candidates=()

    if [ -n "$XDG_CONFIG_HOME" ]; then
        candidates+=("$XDG_CONFIG_HOME/k9s")
    fi
    candidates+=("$HOME/.config/k9s" "$HOME/.k9s")

    for dir in "${candidates[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return
        fi
    done

    # 기존 디렉토리가 없으면 XDG 표준 경로 사용
    local default_dir="${XDG_CONFIG_HOME:-$HOME/.config}/k9s"
    mkdir -p "$default_dir"
    echo "$default_dir"
}

K9S_DIR=$(detect_k9s_dir)
K9S_CONFIG_FILE="$K9S_DIR/config.yaml"

echo "k9s 설정 디렉토리: $K9S_DIR"

mkdir -p "$K9S_DIR"

# shellPod 설정 적용
if [ -f "$K9S_CONFIG_FILE" ] && grep -q 'shellPod:' "$K9S_CONFIG_FILE" 2>/dev/null; then
    sed -i "/shellPod:/,/limits:/{s#image:.*#image: $IMAGE#}" "$K9S_CONFIG_FILE"
else
    if [ ! -f "$K9S_CONFIG_FILE" ] || ! grep -q 'k9s:' "$K9S_CONFIG_FILE" 2>/dev/null; then
cat <<EOF >> "$K9S_CONFIG_FILE"
k9s:
  shellPod:
    image: $IMAGE
    namespace: $NAMESPACE
    limits:
      cpu: $CPU_LIMIT
      memory: $MEMORY_LIMIT
EOF
    else
        # k9s: 블록은 있지만 shellPod가 없는 경우
        sed -i "/k9s:/a\\
  shellPod:\\
    image: $IMAGE\\
    namespace: $NAMESPACE\\
    limits:\\
      cpu: $CPU_LIMIT\\
      memory: $MEMORY_LIMIT" "$K9S_CONFIG_FILE"
    fi
fi

echo "shellPod image: $IMAGE"

# 클러스터/컨텍스트별 nodeShell feature gate 활성화
# k9s 버전에 따라 clusters 디렉토리 위치가 다를 수 있음
CLUSTER_CONFIGS=()
for clusters_dir in "$K9S_DIR/clusters" "$K9S_DIR"/clusters/*/; do
    if [ -d "$clusters_dir" ]; then
        while IFS= read -r -d '' cfg; do
            CLUSTER_CONFIGS+=("$cfg")
        done < <(find "$clusters_dir" -type f -name config.yaml -print0 2>/dev/null)
        break
    fi
done

if [ ${#CLUSTER_CONFIGS[@]} -eq 0 ]; then
    echo "[경고] 클러스터 설정 파일을 찾을 수 없습니다."
    echo "  k9s를 한 번 실행하여 클러스터에 접속한 뒤 이 스크립트를 다시 실행하거나,"
    echo "  아래 명령으로 현재 컨텍스트의 설정을 직접 생성합니다."

    # 현재 kubectl 컨텍스트 기반으로 클러스터 설정 자동 생성
    if command -v kubectl &>/dev/null; then
        CONTEXT=$(kubectl config current-context 2>/dev/null)
        CLUSTER=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$CONTEXT\")].context.cluster}" 2>/dev/null)
        if [ -n "$CONTEXT" ] && [ -n "$CLUSTER" ]; then
            CLUSTER_DIR="$K9S_DIR/clusters/$CLUSTER/$CONTEXT"
            mkdir -p "$CLUSTER_DIR"
            CLUSTER_CFG="$CLUSTER_DIR/config.yaml"
            if [ ! -f "$CLUSTER_CFG" ]; then
cat <<EOF > "$CLUSTER_CFG"
k9s:
  featureGates:
    nodeShell: true
EOF
                echo "  생성됨: $CLUSTER_CFG"
                CLUSTER_CONFIGS+=("$CLUSTER_CFG")
            fi
        fi
    fi
fi

for CLUSTER_CONFIG in "${CLUSTER_CONFIGS[@]}"; do
    if grep -q 'featureGates:' "$CLUSTER_CONFIG"; then
        if grep -q 'nodeShell:' "$CLUSTER_CONFIG"; then
            sed -i 's/nodeShell: .*/nodeShell: true/' "$CLUSTER_CONFIG"
        else
            sed -i '/featureGates:/a\    nodeShell: true' "$CLUSTER_CONFIG"
        fi
    else
        if grep -q 'k9s:' "$CLUSTER_CONFIG"; then
            sed -i "/k9s:/a\\
  featureGates:\\
    nodeShell: true" "$CLUSTER_CONFIG"
        else
cat <<EOF >> "$CLUSTER_CONFIG"
k9s:
  featureGates:
    nodeShell: true
EOF
        fi
    fi
    echo "  nodeShell 활성화: $CLUSTER_CONFIG"
done

echo ""
echo "K9s nodeShell & shellPod 설정 완료."

