include .env
export

IMAGE ?= cr.makina.rocks/external-hub/node-shell:v0.1
NAMESPACE ?= default
CPU_LIMIT ?= 100m
MEMORY_LIMIT ?= 100Mi

.PHONY: help install build push all clean

help: ## 사용 가능한 명령 목록
	@echo ""
	@echo "k9s nodeShell 설정 도구"
	@echo "======================"
	@echo ""
	@echo "Commands:"
	@LANG=C grep -E '^[a-zA-Z_-]+:.*## .*$$' Makefile | grep -v '^help:' | awk 'BEGIN {FS = "## "}; {split($$1,a,":"); printf "  \033[36mmake %-10s\033[0m %s\n", a[1], $$2}'
	@echo ""
	@echo "Current config (.env):"
	@echo "  IMAGE         = $(IMAGE)"
	@echo "  NAMESPACE     = $(NAMESPACE)"
	@echo "  CPU_LIMIT     = $(CPU_LIMIT)"
	@echo "  MEMORY_LIMIT  = $(MEMORY_LIMIT)"
	@echo ""
	@echo "Override example:"
	@echo "  make install IMAGE=my-registry/node-shell:v2"
	@echo ""

install: ## k9s nodeShell & shellPod 설정 적용
	@bash setup_k9s_shellpod.sh

build: ## Docker 이미지 빌드
	docker build -t $(IMAGE) .

push: ## Docker 이미지 푸시
	docker push $(IMAGE)

all: build push install ## 빌드 + 푸시 + 설치 한번에

clean: ## k9s shellPod 설정 관련 안내
	@echo "k9s 설정을 직접 확인하세요:"
	@echo "  $${XDG_CONFIG_HOME:-$$HOME/.config}/k9s/config.yaml"
	@echo "  $$HOME/.k9s/config.yaml (레거시)"
