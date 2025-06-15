#!/bin/bash

# 사용법: ./build_and_push.sh <repository> <tag>
# 예시: ./build_and_push.sh ghcr.io/youruser/k9s-nodeshell latest

set -e

if [ $# -ne 2 ]; then
    echo "사용법: $0 <repository> <tag>"
    echo "예시: $0 ghcr.io/youruser/k9s-nodeshell latest"
    exit 1
fi

REPO="$1"
TAG="$2"
IMAGE="$REPO:$TAG"

# Dockerfile 확인 (ubuntu 22.04 기반 여부 검사)
if ! grep -q "FROM ubuntu:22.04" Dockerfile; then
    echo "Dockerfile이 Ubuntu 22.04를 기반으로 하고 있지 않습니다!"
    exit 2
fi

echo "==== Docker 레지스트리에 로그인하세요 (예: docker login ghcr.io) ===="
docker info > /dev/null 2>&1

echo "==== ubuntu:22.04 기반 이미지 빌드 시작 ===="
docker build -t "$IMAGE" .

echo "==== 이미지 푸시 ===="
docker push "$IMAGE"

echo "==== 빌드 및 푸시 완료 ===="
echo "이미지: $IMAGE"

