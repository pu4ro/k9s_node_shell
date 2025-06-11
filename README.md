# K9s nodeShell & shellPod 설정 자동화 스크립트

이 스크립트는 K9s에서 노드에 직접 셸로 접속할 수 있는 `nodeShell` 기능과 커스텀 shellPod 이미지를 모든 클러스터/컨텍스트에 한 번에 적용합니다.

## 주요 기능

- `~/.config/k9s/config.yaml`에 shellPod 설정 자동 추가
- 모든 클러스터/컨텍스트 config.yaml에 `featureGates.nodeShell: true` 자동 추가
- 오프라인 환경, 다수의 클러스터/컨텍스트 운영 시 편리하게 활용 가능

---

## 기본 경로

- **전역 설정:** `~/.config/k9s/config.yaml`
- **클러스터/컨텍스트별 설정:** `~/.local/share/k9s/clusters/<cluster>/<context>/config.yaml`

> 환경변수 `XDG_CONFIG_HOME`, `XDG_DATA_HOME`을 사용하는 경우 해당 값에 따라 경로가 달라집니다.

---

## 사용 방법

1. 스크립트를 저장합니다. 예시 파일명: `setup_k9s_nodeshell.sh`
2. 기존 설정 파일을 백업하는 것을 권장합니다.
   ```bash
   cp ~/.config/k9s/config.yaml ~/.config/k9s/config.yaml.bak



## 실행 방법
```bash
chmod +x ./setup_k9s_nodeshell.sh
bash ./setup_k9s_nodeshell.sh

