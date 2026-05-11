#!/usr/bin/env bash
# ============================================================
# NetOps AI Platform — Server Assessment Script
# Version: 1.0.0
#
# PURPOSE:
#   Pre-install inventory and compatibility check.
#   Identifies what is already installed, what versions,
#   what ports are in use, and potential conflicts.
#
# USAGE:
#   bash scripts/check-server.sh
#   bash scripts/check-server.sh 2>&1 | tee server-assessment-$(date +%Y%m%d-%H%M).txt
#
# OUTPUT:
#   Structured report with status per item:
#     [OK]   Requirement met
#     [WARN] Present but needs attention (version, config, conflict risk)
#     [FAIL] Requirement NOT met
#     [INFO] Informational — no action required
#
# SAFE: Read-only. Makes no changes to the system.
# ============================================================

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ─────────────────────────────────────────────────────────────
# Status counters
# ─────────────────────────────────────────────────────────────
CNT_OK=0; CNT_WARN=0; CNT_FAIL=0

ok()   { echo -e "${GREEN}[OK]${RESET}   $*";  ((CNT_OK++)); }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; ((CNT_WARN++)); }
fail() { echo -e "${RED}[FAIL]${RESET} $*";   ((CNT_FAIL++)); }
info() { echo -e "${CYAN}[INFO]${RESET} $*"; }
section() { echo -e "\n${BOLD}┌───────────────────────────────────────────────────────────
│ $* 
└───────────────────────────────────────────────────────────${RESET}"; }

# ─────────────────────────────────────────────────────────────
# HEADER
# ─────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}"
echo "  ██████╗ █████╗ "
echo "  ██╔════╝██╔══██╗  NetOps AI Platform"
echo "  ██║     ██║  ██║  Server Assessment Script v1.0.0"
echo "  ██║     ██║  ██║  "
echo "  ╚██████╗╚█████╔╝  $(date '+%Y-%m-%d %H:%M:%S')"
echo "   ╚═════╝ ╚════╝   Host: $(hostname)"
echo -e "${RESET}"

# =============================================================
# 1. OPERATING SYSTEM
# =============================================================
section "1. OPERATING SYSTEM"

if [ -f /etc/oracle-release ]; then
  OS_NAME=$(cat /etc/oracle-release)
  OS_VER=$(grep -oP '[0-9]+\.[0-9]+' /etc/oracle-release | head -1)
  MAJOR=$(echo "$OS_VER" | cut -d. -f1)
  if [ "$MAJOR" -ge 9 ]; then
    ok "OS: $OS_NAME — Oracle Linux 9+ (supported)"
  elif [ "$MAJOR" -ge 8 ]; then
    warn "OS: $OS_NAME — Oracle Linux 8.x (supported but OL9 recommended)"
  else
    fail "OS: $OS_NAME — Oracle Linux < 8 (not supported)"
  fi
elif [ -f /etc/redhat-release ]; then
  OS_NAME=$(cat /etc/redhat-release)
  warn "OS: $OS_NAME — RHEL-based (should work, not primary target)"
elif [ -f /etc/os-release ]; then
  OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
  fail "OS: $OS_NAME — Not Oracle Linux/RHEL. Scripts may need adaptation."
else
  fail "OS: unknown — cannot detect OS"
fi

info "Kernel: $(uname -r)"
info "Architecture: $(uname -m)"
info "Hostname: $(hostname -f 2>/dev/null || hostname)"
info "Uptime: $(uptime -p 2>/dev/null || uptime)"

# =============================================================
# 2. HARDWARE RESOURCES
# =============================================================
section "2. HARDWARE RESOURCES"

# CPU
CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
CPU_MODEL=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
if [ "$CPU_CORES" -ge 4 ]; then
  ok "CPU: $CPU_CORES cores — $CPU_MODEL"
elif [ "$CPU_CORES" -ge 2 ]; then
  warn "CPU: $CPU_CORES cores — minimum met, 4+ recommended for Phase 1 (LLM)"
else
  fail "CPU: $CPU_CORES core — insufficient (minimum 2, recommend 4+)"
fi

# RAM
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(( TOTAL_RAM_KB / 1024 / 1024 ))
AVAIL_RAM_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
AVAIL_RAM_GB=$(( AVAIL_RAM_KB / 1024 / 1024 ))
if [ "$TOTAL_RAM_GB" -ge 16 ]; then
  ok "RAM: ${TOTAL_RAM_GB}GB total / ${AVAIL_RAM_GB}GB available — good for Phase 1+ (LLM)"
elif [ "$TOTAL_RAM_GB" -ge 8 ]; then
  warn "RAM: ${TOTAL_RAM_GB}GB total / ${AVAIL_RAM_GB}GB available — OK for Phase 0, limited for LLM (Phase 1 needs 16GB+)"
elif [ "$TOTAL_RAM_GB" -ge 4 ]; then
  warn "RAM: ${TOTAL_RAM_GB}GB total / ${AVAIL_RAM_GB}GB available — Phase 0 only. Phase 1 LLM requires 16GB+"
else
  fail "RAM: ${TOTAL_RAM_GB}GB total — insufficient even for Phase 0 (minimum 4GB)"
fi

# DISK
DISK_ROOT_AVAIL=$(df -BG / | awk 'NR==2{gsub(/G/,"",$4); print $4}')
DISK_ROOT_TOTAL=$(df -BG / | awk 'NR==2{gsub(/G/,"",$2); print $2}')
DISK_ROOT_USE=$(df / | awk 'NR==2{print $5}')
if [ "$DISK_ROOT_AVAIL" -ge 50 ]; then
  ok "Disk /: ${DISK_ROOT_AVAIL}GB free of ${DISK_ROOT_TOTAL}GB (${DISK_ROOT_USE} used) — comfortable for all phases"
elif [ "$DISK_ROOT_AVAIL" -ge 20 ]; then
  warn "Disk /: ${DISK_ROOT_AVAIL}GB free — OK for Phase 0-1. LLM models need 10-30GB. Monitor disk."
elif [ "$DISK_ROOT_AVAIL" -ge 10 ]; then
  warn "Disk /: ${DISK_ROOT_AVAIL}GB free — tight. Phase 0 OK, will be a problem from Phase 1 (LLM models)"
else
  fail "Disk /: ${DISK_ROOT_AVAIL}GB free — insufficient. Minimum 10GB free required."
fi

# Check /var/lib/docker separately if it exists
if mountpoint -q /var/lib/docker 2>/dev/null; then
  DOCKER_DISK=$(df -BG /var/lib/docker | awk 'NR==2{gsub(/G/,"",$4); print $4}')
  info "Disk /var/lib/docker: ${DOCKER_DISK}GB free (separate mount)"
fi

# SWAP
SWAP_TOTAL_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
SWAP_GB=$(( SWAP_TOTAL_KB / 1024 / 1024 ))
if [ "$SWAP_GB" -ge 2 ]; then
  ok "Swap: ${SWAP_GB}GB configured"
elif [ "$SWAP_GB" -ge 1 ]; then
  warn "Swap: ${SWAP_GB}GB — minimal, consider 4GB+ for LLM workloads"
else
  warn "Swap: none configured — OK for Phase 0, recommended for Phase 1+ (LLM OOM protection)"
fi

# =============================================================
# 3. NETWORK
# =============================================================
section "3. NETWORK"

# Interfaces
info "Network interfaces:"
ip -br addr show 2>/dev/null | grep -v '^lo' | while read -r line; do
  info "  $line"
done

# DNS
if host google.com &>/dev/null 2>&1 || nslookup google.com &>/dev/null 2>&1; then
  ok "DNS resolution: working"
else
  warn "DNS resolution: failed — internet access may be restricted (check if that's intentional)"
fi

# Internet connectivity (GitHub for git clone)
if curl -sf --max-time 5 https://github.com -o /dev/null 2>/dev/null; then
  ok "Internet: GitHub reachable (git clone will work)"
else
  warn "Internet: GitHub not reachable — will not be able to git clone; may need to transfer files manually"
fi

# Docker Hub
if curl -sf --max-time 5 https://registry-1.docker.io/v2/ -o /dev/null 2>/dev/null; then
  ok "Internet: Docker Hub reachable (docker pull will work)"
else
  warn "Internet: Docker Hub not reachable — will need local registry or pre-pulled images"
fi

# Default gateway
GW=$(ip route show default 2>/dev/null | awk '/default/{print $3}' | head -1)
[ -n "$GW" ] && info "Default gateway: $GW" || warn "No default gateway configured"

# =============================================================
# 4. PORTS IN USE (conflict check)
# =============================================================
section "4. PORTS IN USE (Conflict Check for NetOps Platform)"

PLATFORM_PORTS=(3000 8080 5432 11434 4000 9090 8086 5678)
PLATFORM_NAMES=("Frontend (React)" "Backend API (Go)" "PostgreSQL" "Ollama (Phase 1)" "LiteLLM proxy (Phase 1)" "Prometheus (Phase 2)" "InfluxDB (Phase 2)" "n8n (Phase 3)")

for i in "${!PLATFORM_PORTS[@]}"; do
  PORT=${PLATFORM_PORTS[$i]}
  NAME=${PLATFORM_NAMES[$i]}
  if ss -tlnp 2>/dev/null | grep -q ":${PORT} " || \
     netstat -tlnp 2>/dev/null | grep -q ":${PORT} "; then
    PROC=$(ss -tlnp 2>/dev/null | grep ":${PORT} " | grep -oP 'users:\(\("[^"]+"' | head -1 | tr -d 'users:("' || echo 'unknown')
    warn "Port ${PORT} ($NAME): IN USE by '$PROC' — CONFLICT if platform deploys on this port"
  else
    ok "Port ${PORT} ($NAME): free"
  fi
done

info "\nOther listening ports (non-loopback):"
ss -tlnp 2>/dev/null | grep -v '127.0.0.1' | grep LISTEN | awk '{print "  "$4" "$6}' | head -20 || \
  netstat -tlnp 2>/dev/null | grep LISTEN | grep -v '127.0.0.1' | awk '{print "  "$4" "$7}' | head -20 || \
  info "  (ss/netstat not available)"

# =============================================================
# 5. DOCKER
# =============================================================
section "5. DOCKER"

if command -v docker &>/dev/null; then
  DOCKER_VER=$(docker --version | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
  DOCKER_MAJOR=$(echo "$DOCKER_VER" | cut -d. -f1)
  if [ "$DOCKER_MAJOR" -ge 24 ]; then
    ok "Docker: $DOCKER_VER (current — good)"
  elif [ "$DOCKER_MAJOR" -ge 20 ]; then
    warn "Docker: $DOCKER_VER — works but upgrade to 24+ recommended"
  else
    fail "Docker: $DOCKER_VER — too old, upgrade required"
  fi

  if docker info &>/dev/null; then
    ok "Docker daemon: running"
  else
    fail "Docker daemon: not running (service docker status)"
  fi

  # Docker Compose
  if docker compose version &>/dev/null 2>&1; then
    DC_VER=$(docker compose version --short 2>/dev/null || docker compose version | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
    ok "Docker Compose plugin: $DC_VER"
  elif command -v docker-compose &>/dev/null; then
    DC_VER=$(docker-compose --version | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
    warn "Docker Compose: $DC_VER (standalone v1 detected — use 'docker compose' v2 plugin instead)"
  else
    fail "Docker Compose: not found — install docker-compose-plugin"
  fi

  # Swarm (needed for Docker Secrets)
  if docker info 2>/dev/null | grep -q 'Swarm: active'; then
    ok "Docker Swarm: active (Docker Secrets will work)"
  else
    info "Docker Swarm: not initialized (will be initialized by deploy script)"
  fi

  # Existing containers / stacks
  RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)
  if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
    warn "Docker: $RUNNING_CONTAINERS container(s) already running:"
    docker ps --format '  {{.Names}} — {{.Image}} — {{.Status}}' 2>/dev/null | while read -r line; do
      warn "  $line"
    done
  else
    ok "Docker: no containers currently running (clean slate)"
  fi

  # Existing volumes
  VOL_COUNT=$(docker volume ls -q 2>/dev/null | wc -l)
  [ "$VOL_COUNT" -gt 0 ] && info "Docker volumes: $VOL_COUNT existing" || info "Docker volumes: none"

  # Existing secrets
  SECRET_COUNT=$(docker secret ls -q 2>/dev/null | wc -l || echo 0)
  if [ "$SECRET_COUNT" -gt 0 ]; then
    info "Docker secrets already present:"
    docker secret ls --format '  {{.Name}}' 2>/dev/null
  else
    info "Docker secrets: none (will be created by deploy script)"
  fi

  # Existing networks
  info "Docker networks:"
  docker network ls --format '  {{.Name}} ({{.Driver}})' 2>/dev/null | grep -v 'bridge\|host\|none' | head -10 || true

else
  fail "Docker: not installed — run: bash scripts/install-docker.sh"
fi

# =============================================================
# 6. RUNTIME VERSIONS
# =============================================================
section "6. RUNTIME / LANGUAGE VERSIONS"

# Go
if command -v go &>/dev/null; then
  GO_VER=$(go version | grep -oP 'go[0-9]+\.[0-9]+' | head -1 | tr -d 'go')
  GO_MAJOR=$(echo "$GO_VER" | cut -d. -f1)
  GO_MINOR=$(echo "$GO_VER" | cut -d. -f2)
  if [ "$GO_MAJOR" -ge 1 ] && [ "$GO_MINOR" -ge 21 ]; then
    ok "Go: $GO_VER (sufficient — 1.21+ required)"
  else
    warn "Go: $GO_VER — outdated, 1.21+ required for platform modules"
  fi
  info "Go path: $(which go) | GOPATH: ${GOPATH:-$(go env GOPATH)}"
else
  info "Go: not installed — only needed if building modules outside Docker"
fi

# Python
for py in python3 python; do
  if command -v $py &>/dev/null; then
    PY_VER=$($py --version 2>&1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
    PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
    if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 11 ]; then
      ok "Python ($py): $PY_VER (sufficient — 3.11+ required for cognition pipeline)"
    elif [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 9 ]; then
      warn "Python ($py): $PY_VER — works for basic scripts, 3.11+ needed for Phase 1 LangChain"
    else
      warn "Python ($py): $PY_VER — too old for Phase 1. Upgrade to 3.11+"
    fi
    break
  fi
done
command -v python3 &>/dev/null || command -v python &>/dev/null || \
  info "Python: not installed — needed for Phase 1 (cognition pipeline)"

# Node.js
if command -v node &>/dev/null; then
  NODE_VER=$(node --version | tr -d 'v')
  NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
  if [ "$NODE_MAJOR" -ge 20 ]; then
    ok "Node.js: v$NODE_VER (sufficient — needed only if building frontend outside Docker)"
  elif [ "$NODE_MAJOR" -ge 18 ]; then
    warn "Node.js: v$NODE_VER — works, v20 LTS recommended"
  else
    warn "Node.js: v$NODE_VER — outdated, v20 LTS recommended"
  fi
else
  info "Node.js: not installed — only needed if building frontend outside Docker"
fi

# Git
if command -v git &>/dev/null; then
  GIT_VER=$(git --version | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
  ok "Git: $GIT_VER"
else
  fail "Git: not installed — required (dnf install -y git)"
fi

# curl
command -v curl &>/dev/null && ok "curl: $(curl --version | head -1 | awk '{print $2}')"\
  || fail "curl: not installed — required (dnf install -y curl)"

# jq (optional but useful)
command -v jq &>/dev/null && ok "jq: $(jq --version)" \
  || info "jq: not installed — optional but useful for JSON inspection (dnf install -y jq)"

# =============================================================
# 7. EXISTING SERVICES (conflict detection)
# =============================================================
section "7. EXISTING SERVICES (Conflict Detection)"

CONFLICT_SERVICES=("postgresql" "postgresql-15" "postgresql-16" "prometheus" "influxdb" "nginx" "httpd" "apache2" "grafana-server")
CONFLICT_NAMES=("PostgreSQL (system)" "PostgreSQL 15" "PostgreSQL 16" "Prometheus" "InfluxDB" "Nginx" "Apache HTTPD" "Apache2" "Grafana")

for i in "${!CONFLICT_SERVICES[@]}"; do
  SVC=${CONFLICT_SERVICES[$i]}
  NAME=${CONFLICT_NAMES[$i]}
  if systemctl is-active --quiet "$SVC" 2>/dev/null; then
    warn "Service '$SVC' ($NAME): RUNNING — potential conflict with Docker-based platform components. Consider stopping or using different ports."
  elif systemctl list-unit-files 2>/dev/null | grep -q "^${SVC}.service"; then
    info "Service '$SVC' ($NAME): installed but not running"
  fi
done

# Check for any existing n8n, ollama
for SVC in n8n ollama vault; do
  if systemctl is-active --quiet "$SVC" 2>/dev/null; then
    warn "Service '$SVC': RUNNING — platform will deploy its own Docker-based instance. Check port conflicts."
  elif command -v "$SVC" &>/dev/null; then
    warn "$SVC: installed as system binary — platform uses Docker-based version. May conflict."
  fi
done

# =============================================================
# 8. FIREWALL
# =============================================================
section "8. FIREWALL"

if command -v firewall-cmd &>/dev/null; then
  if systemctl is-active --quiet firewalld; then
    FWZONE=$(firewall-cmd --get-default-zone 2>/dev/null || echo 'unknown')
    ok "firewalld: active (zone: $FWZONE)"
    info "Open ports/services in default zone:"
    firewall-cmd --list-all 2>/dev/null | grep -E 'services:|ports:' | while read -r line; do
      info "  $line"
    done
    warn "firewalld: platform ports 3000, 8080 must be open. Run after deploy:"
    warn "  sudo firewall-cmd --add-port=3000/tcp --add-port=8080/tcp --permanent && sudo firewall-cmd --reload"
  else
    info "firewalld: installed but not running"
  fi
elif command -v ufw &>/dev/null; then
  UFW_STATUS=$(ufw status | head -1)
  info "ufw: $UFW_STATUS"
else
  info "No firewall manager detected (firewalld/ufw)"
fi

# iptables check
if command -v iptables &>/dev/null; then
  IPTR_COUNT=$(iptables -L INPUT -n 2>/dev/null | wc -l || echo 0)
  [ "$IPTR_COUNT" -gt 3 ] && \
    warn "iptables: custom rules detected ($IPTR_COUNT INPUT rules) — verify Docker traffic is allowed" || \
    info "iptables: no custom INPUT rules detected"
fi

# =============================================================
# 9. SELinux
# =============================================================
section "9. SELinux"

if command -v getenforce &>/dev/null; then
  SELINUX=$(getenforce)
  if [ "$SELINUX" = "Enforcing" ]; then
    warn "SELinux: Enforcing — Docker works with SELinux, but volume mounts may need :z/:Z labels."
    warn "  If containers cannot read mounted volumes, add :z to volume definitions."
    warn "  Example: - ./data:/data:z"
  elif [ "$SELINUX" = "Permissive" ]; then
    ok "SELinux: Permissive — no blocking, will log violations"
  else
    ok "SELinux: Disabled"
  fi
else
  info "SELinux: getenforce not available (likely not SELinux system)"
fi

# =============================================================
# 10. SYSTEMD RESOURCES
# =============================================================
section "10. SYSTEMD & SYSTEM LIMITS"

# max file descriptors
ULIMIT_N=$(ulimit -n 2>/dev/null || echo 0)
if [ "$ULIMIT_N" -ge 65536 ]; then
  ok "File descriptors (ulimit -n): $ULIMIT_N"
elif [ "$ULIMIT_N" -ge 1024 ]; then
  warn "File descriptors (ulimit -n): $ULIMIT_N — increase to 65536 for production workloads"
else
  warn "File descriptors (ulimit -n): $ULIMIT_N — very low, may cause issues under load"
fi

# Time sync
if timedatectl status 2>/dev/null | grep -q 'synchronized: yes'; then
  ok "Time sync (NTP): synchronized"
else
  warn "Time sync: not synchronized — important for audit log timestamps (timedatectl set-ntp true)"
fi
info "System time: $(date '+%Y-%m-%d %H:%M:%S %Z')"

# =============================================================
# 11. DISK I/O BASELINE
# =============================================================
section "11. DISK I/O BASELINE"

if command -v dd &>/dev/null; then
  TMPFILE=$(mktemp)
  WRITE_SPEED=$(dd if=/dev/zero of="$TMPFILE" bs=1M count=64 conv=fdatasync 2>&1 | grep -oP '[0-9.]+ [MG]B/s' | tail -1 || echo 'n/a')
  rm -f "$TMPFILE"
  info "Sequential write speed (64MB): $WRITE_SPEED — (PostgreSQL needs >50MB/s for good performance)"
fi

# =============================================================
# 12. EXISTING DATA DIRECTORIES
# =============================================================
section "12. EXISTING DATA / CONFLICT DIRECTORIES"

DIRS_TO_CHECK=(
  "/var/lib/docker"
  "/opt/netops"
  "/opt/prometheus"
  "/opt/influxdb"
  "/opt/n8n"
  "/opt/vault"
  "/opt/ollama"
)

for DIR in "${DIRS_TO_CHECK[@]}"; do
  if [ -d "$DIR" ]; then
    SIZE=$(du -sh "$DIR" 2>/dev/null | cut -f1 || echo 'unknown')
    warn "Directory '$DIR' already exists (size: $SIZE) — check if it belongs to an existing service"
  else
    ok "Directory '$DIR': does not exist (clean)"
  fi
done

# =============================================================
# 13. CURRENT USER
# =============================================================
section "13. USER & PERMISSIONS"

info "Current user: $(whoami) (UID=$(id -u))"
info "Groups: $(groups)"

if [ "$(id -u)" -eq 0 ]; then
  warn "Running as root — not recommended. Create a dedicated user and add to 'docker' group."
else
  if groups | grep -q '\bdocker\b'; then
    ok "User '$(whoami)' is in 'docker' group — can run docker without sudo"
  else
    warn "User '$(whoami)' is NOT in 'docker' group — run: sudo usermod -aG docker $(whoami)"
  fi

  if sudo -n true 2>/dev/null; then
    ok "sudo: available without password (needed for install-docker.sh)"
  else
    info "sudo: requires password (OK — install scripts use sudo interactively)"
  fi
fi

# =============================================================
# 14. NSX-T CONNECTIVITY (optional — only if URL provided)
# =============================================================
section "14. NSX-T MANAGER CONNECTIVITY (optional)"

if [ -f ".env" ] && grep -q 'NSX_MANAGER_URL' .env 2>/dev/null; then
  NSX_URL=$(grep '^NSX_MANAGER_URL=' .env | cut -d= -f2- | tr -d '"')
  if [ -n "$NSX_URL" ] && [[ "$NSX_URL" != *"example.com"* ]]; then
    info "Testing connectivity to NSX-T Manager: $NSX_URL"
    if curl -sf --max-time 5 --insecure "${NSX_URL}/api/v1/node" -o /dev/null 2>/dev/null; then
      ok "NSX-T Manager: reachable at $NSX_URL (HTTP 200)"
    else
      HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" --max-time 5 --insecure "${NSX_URL}/api/v1/node" 2>/dev/null || echo '000')
      if [ "$HTTP_CODE" = "403" ] || [ "$HTTP_CODE" = "401" ]; then
        ok "NSX-T Manager: reachable at $NSX_URL (HTTP $HTTP_CODE — auth required, connectivity OK)"
      elif [ "$HTTP_CODE" = "000" ]; then
        fail "NSX-T Manager: NOT reachable at $NSX_URL — timeout or connection refused"
      else
        warn "NSX-T Manager: $NSX_URL returned HTTP $HTTP_CODE — verify URL and network path"
      fi
    fi
  else
    info "NSX_MANAGER_URL not set to a real value — skipping connectivity test"
    info "To test: set NSX_MANAGER_URL in .env and re-run this script"
  fi
else
  info ".env not found or NSX_MANAGER_URL not set — skipping NSX-T connectivity test"
  info "To test: cp .env.example .env, set NSX_MANAGER_URL, re-run"
fi

# =============================================================
# SUMMARY
# =============================================================
echo
echo -e "${BOLD}┌───────────────────────────────────────────────────────────
│ ASSESSMENT SUMMARY
├───────────────────────────────────────────────────────────${RESET}"
echo -e "${GREEN}  OK  : $CNT_OK${RESET}"
echo -e "${YELLOW}  WARN: $CNT_WARN${RESET}"
echo -e "${RED}  FAIL: $CNT_FAIL${RESET}"
echo

if [ "$CNT_FAIL" -eq 0 ] && [ "$CNT_WARN" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}  ✅  Server is ready. Proceed with: bash scripts/deploy-phase0.sh${RESET}"
elif [ "$CNT_FAIL" -eq 0 ]; then
  echo -e "${YELLOW}${BOLD}  ⚠️  Server has warnings. Review WARNs above before deploying.${RESET}"
  echo -e "${YELLOW}     Most WARNs are non-blocking for Phase 0.${RESET}"
else
  echo -e "${RED}${BOLD}  ❌  Server has FAILs. Address them before deploying.${RESET}"
fi

echo
echo -e "${CYAN}  Save full output: bash scripts/check-server.sh 2>&1 | tee server-assessment-$(date +%Y%m%d).txt${RESET}"
echo
