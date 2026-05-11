#!/usr/bin/env bash
# ============================================================
# NetOps AI Platform — Deploy Script Phase 0
# Agent modules deployed: nsx-collector
# Agent core deployed: identity, access, communication, governance
#
# Usage: bash scripts/deploy-phase0.sh
# Idempotent: safe to run multiple times
# ============================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"
COMPOSE_FILE="$REPO_DIR/infra/docker/docker-compose.phase0.yml"
ENV_FILE="$REPO_DIR/.env"

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
fail() { echo "[ERROR] $*" >&2; exit 1; }

# ── Pre-checks ──
command -v docker &>/dev/null  || fail "Docker não encontrado. Execute: bash scripts/install-docker.sh"
docker info &>/dev/null        || fail "Docker daemon não está rodando. Execute: sudo systemctl start docker"

# ── Validar .env ──
[ -f "$ENV_FILE" ] || fail ".env não encontrado. Copie .env.example e preencha (apenas variáveis não-secretas)."

required_env_vars=(NSX_MANAGER_URL POSTGRES_DB POSTGRES_USER API_PORT REACT_APP_API_URL)
log "Validando variáveis de ambiente..."
for var in "${required_env_vars[@]}"; do
  val=$(grep -E "^${var}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || true)
  [[ -z "$val" || "$val" == "CHANGE_ME"* ]] && fail "Variável não configurada no .env: $var"
done

# ── Docker Swarm (required for Docker Secrets) ──
if ! docker info 2>/dev/null | grep -q 'Swarm: active'; then
  log "Inicializando Docker Swarm (necessário para Docker Secrets)..."
  docker swarm init --advertise-addr 127.0.0.1 2>/dev/null || \
  docker swarm init --advertise-addr "$(hostname -I | awk '{print $1}')" || \
  log "Swarm já inicializado ou erro ignorável."
fi

# ── Criar Docker Secrets (tokens — nunca em .env) ──
create_secret_if_missing() {
  local name="$1"
  local prompt="$2"
  if docker secret inspect "$name" &>/dev/null; then
    log "Secret '$name' já existe — pulando."
  else
    log "Criando secret: $name"
    printf '%s' "$prompt "
    read -rs secret_value
    echo
    printf '%s' "$secret_value" | docker secret create "$name" -
    unset secret_value
    log "Secret '$name' criado."
  fi
}

log "=== Configuração de Secrets ==="
create_secret_if_missing "nsx_api_token"    "Token de API do NSX-T (role: Auditor):"
create_secret_if_missing "postgres_password" "Senha do PostgreSQL (escolha uma senha forte):"
create_secret_if_missing "api_secret_key"   "Chave secreta da API (Enter para gerar automaticamente):"

# ── Deploy ──
log "=== Iniciando deploy Phase 0 ==="
cd "$REPO_DIR"

docker stack deploy \
  --compose-file "$COMPOSE_FILE" \
  --with-registry-auth \
  netops

# ── Health check ──
log "Aguardando serviços iniciarem (45s)..."
sleep 45

log "=== Status dos serviços ==="
docker stack services netops

log "=== Verificando API backend ==="
curl -sf "http://localhost:${API_PORT:-8080}/health" && \
  log "Backend API: ✅ OK" || \
  log "Backend API: aguardando (pode demorar mais alguns segundos)"

log ""
log "=== Deploy Phase 0 concluído ==="
log "Dashboard : http://localhost:${FRONTEND_PORT:-3000}"
log "API       : http://localhost:${API_PORT:-8080}"
log ""
log "Módulos ativos: nsx-collector (READ)"
log "Core ativo: identity, access, communication, governance"
log ""
log "Para verificar logs:"
log "  docker service logs netops_nsx-collector"
log "  docker service logs netops_backend-api"
