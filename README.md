# K9s nodeShell을 위한 Ubuntu 22.04 기반 shellPod 자동화

이 프로젝트는 K9s의 nodeShell 기능을 통해 **실제 노드 환경에 직접 진입**할 수 있는 shellPod를 Ubuntu 22.04 기반으로 만들고,  
이미지 빌드·푸시·적용까지 모두 자동화할 수 있도록 도와줍니다.

---

## 📦 구성 파일

- `Dockerfile`  
  Ubuntu 22.04 + nsenter(bash)로 바로 호스트 네임스페이스 진입하는 shellPod 이미지용  
- `build_and_push.sh`  
  원하는 레지스트리로 이미지를 빌드/푸시 (ubuntu:22.04 기반만 지원)
- `setup_k9s_shellpod.sh`  
  빌드/푸시한 이미지 주소를 K9s shellPod에 자동 적용

---

## 🐳 1. Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y util-linux procps bash && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["nsenter", "--target", "1", "--mount", "--uts", "--ipc", "--net", "--pid", "--", "bash"]
```

---

## ⚡ 2. 이미지 빌드 및 푸시

`build_and_push.sh` 사용법:

```bash
./build_and_push.sh <repository> <tag>
```

예시:
```bash
./build_and_push.sh ghcr.io/youruser/k9s-nodeshell latest
```

- `<repository>`: Docker 이미지 리포지토리 (예: ghcr.io/youruser/k9s-nodeshell)
- `<tag>`: 이미지 태그 (예: latest)
- Dockerfile은 반드시 `ubuntu:22.04`로 시작해야 함  
- 사전에 해당 레지스트리 로그인 필요  
  (예: `docker login ghcr.io`)

빌드와 푸시가 완료되면 이미지 경로(예: ghcr.io/youruser/k9s-nodeshell:latest)를 기억해두세요.

---

## ⚙️ 3. K9s shellPod 이미지 적용

`setup_k9s_shellpod.sh` 사용법:

```bash
./setup_k9s_shellpod.sh <image>
```

예시:
```bash
./setup_k9s_shellpod.sh ghcr.io/youruser/k9s-nodeshell:latest
```

- 입력한 이미지 주소로 `$HOME/.config/k9s/config.yaml` 파일 내 shellPod image 항목을 자동 설정합니다.

---

## 🕹️ 4. K9s에서 nodeShell 바로 사용

- K9s를 실행하고, **노드 뷰에서 `s` 키**를 눌러 shellPod로 진입하면  
  **즉시 호스트의 bash 네임스페이스로 연결**됩니다 (ubuntu 22.04 환경).
- 네임스페이스 안에서 노드의 프로세스·디렉토리·네트워크·데몬 컨트롤까지 모두 사용 가능

---

## 🧪 5. Pod 직접 배포 테스트 (옵션)

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
      image: ghcr.io/youruser/k9s-nodeshell:latest
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

