# K9s nodeShell을 위한 Ubuntu 22.04 기반 shellPod 자동화

이 프로젝트는 K9s의 nodeShell 기능을 통해 **실제 노드 환경에 직접 진입**할 수 있는 shellPod를 Ubuntu 22.04 기반으로 만들고,
이미지 빌드·푸시·적용까지 모두 자동화할 수 있도록 도와줍니다.

**RHEL / Ubuntu 등 OS 구분 없이** k9s 설정 경로를 자동 탐색하여 적용됩니다.

---

## 📦 구성 파일

| 파일 | 설명 |
|------|------|
| `Dockerfile` | Ubuntu 22.04 + nsenter 기반 shellPod 이미지 |
| `.env` | IMAGE, NAMESPACE, CPU/MEMORY 등 설정 변수 관리 |
| `Makefile` | install/build/push 등 명령 자동화 |
| `setup_k9s_shellpod.sh` | k9s shellPod & nodeShell 설정 스크립트 |
| `build_and_push.sh` | Docker 이미지 빌드/푸시 (레거시) |

---

## 🚀 빠른 시작

```bash
# 1. .env 설정 확인/수정
vi .env

# 2. k9s nodeShell 설정 적용
make install

# 3. (선택) 이미지 빌드 & 푸시 & 설치 한번에
make all
```

---

## ⚙️ 설정 (.env)

`.env` 파일로 모든 변수를 관리합니다:

```bash
IMAGE=cr.makina.rocks/external-hub/node-shell:v0.1
NAMESPACE=default
CPU_LIMIT=100m
MEMORY_LIMIT=100Mi
```

CLI에서 오버라이드도 가능합니다:

```bash
make install IMAGE=my-registry/node-shell:v2
```

**우선순위**: CLI 인자/make 변수 > `.env` 파일 > 스크립트 내 기본값

---

## 🔧 Makefile 명령

```
make help       사용 가능한 명령 및 현재 설정 확인
make install    k9s nodeShell & shellPod 설정 적용
make build      Docker 이미지 빌드
make push       Docker 이미지 푸시
make all        빌드 + 푸시 + 설치 한번에
make clean      k9s 설정 경로 안내
```

---

## 🐳 Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y util-linux procps bash && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["nsenter", "--target", "1", "--mount", "--uts", "--ipc", "--net", "--pid", "--", "bash"]
```

---

## 📂 k9s 설정 경로 자동 탐색

스크립트가 아래 순서로 기존 k9s 설정 디렉토리를 탐색합니다:

1. `$XDG_CONFIG_HOME/k9s`
2. `~/.config/k9s`
3. `~/.k9s`

기존 디렉토리가 없으면 `${XDG_CONFIG_HOME:-$HOME/.config}/k9s`에 새로 생성합니다.

클러스터 설정이 없는 경우 `kubectl`의 현재 컨텍스트를 기반으로 자동 생성합니다.

---

## 🕹️ K9s에서 nodeShell 사용

- K9s를 실행하고, **노드 뷰에서 `s` 키**를 눌러 shellPod로 진입하면
  **즉시 호스트의 bash 네임스페이스로 연결**됩니다 (ubuntu 22.04 환경).
- 네임스페이스 안에서 노드의 프로세스·디렉토리·네트워크·데몬 컨트롤까지 모두 사용 가능

---

## 🧪 Pod 직접 배포 테스트 (옵션)

kubectl로 직접 Pod를 띄워 사용해 볼 수도 있습니다:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nodeshell-direct
spec:
  hostPID: true
  containers:
    - name: nodeshell
      image: cr.makina.rocks/external-hub/node-shell:v0.1
      securityContext:
        privileged: true
      stdin: true
      tty: true
  restartPolicy: Never
```

```bash
kubectl apply -f nodeshell-direct.yaml
kubectl exec -it nodeshell-direct -- bash
```

---

## 🚨 주의사항

- 이 shellPod는 노드의 **모든 권한**을 가지므로 반드시 관리자만 사용해야 하며,
  운영환경에서는 신중하게 사용하세요!
- 반드시 신뢰할 수 있는 프라이빗 레지스트리에 이미지를 올리세요.
- K9s 버전에 따라 shellPod 옵션 지원 범위가 다를 수 있습니다.

---

## 🤝 문의/기여

- Issue, Pull Request로 의견과 개선 사항을 자유롭게 남겨주세요!
