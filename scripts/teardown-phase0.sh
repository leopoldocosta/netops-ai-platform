#!/usr/bin/env bash
# ============================================================
# NetOps AI Platform — Teardown Phase 0
# Remove stack, secrets e volumes (USE COM CUIDADO)
# Usage: bash scripts/teardown-phase0.sh
# ============================================================

set -euo pipefail

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

read -p "⚠️  Isso vai remover o stack e os secrets. Confirmar? (yes/no): " confirm
[ "$confirm" = "yes" ] || { log "Cancelado."; exit 0; }

log "Removendo stack netops..."
docker stack rm netops 2>/dev/null || log "Stack não encontrado."

log "Aguardando containers finalizarem..."
sleep 10

log "Removendo secrets..."
for s in nsx_api_token postgres_password api_secret_key; do
  docker secret rm "$s" 2>/dev/null && log "Secret '$s' removido." || log "Secret '$s' não encontrado."
done

log "Teardown concluído."
log "Para remover volumes (dados): docker volume rm netops_pgdata"
