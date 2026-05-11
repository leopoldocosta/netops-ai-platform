#!/usr/bin/env bash
# ============================================================
# NetOps AI Platform — Install Docker on Oracle Linux 9
# Usage: bash scripts/install-docker.sh
# Idempotent: safe to run multiple times
# ============================================================

set -euo pipefail

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
fail() { echo "[ERROR] $*" >&2; exit 1; }

if command -v docker &>/dev/null; then
  log "Docker já instalado: $(docker --version)"
  docker compose version 2>/dev/null && log "Docker Compose: OK" || true
  exit 0
fi

if [ ! -f /etc/oracle-release ] && [ ! -f /etc/redhat-release ]; then
  fail "Este script suporta Oracle Linux / RHEL. Adapte para seu OS."
fi

log "Instalando Docker no Oracle Linux 9..."

sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

docker --version
docker compose version

log "Docker instalado com sucesso."
log "Execute: newgrp docker (ou faça logout/login para aplicar o grupo 'docker')"
