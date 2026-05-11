# Phase 0 — Quick Start Guide

## What gets deployed

- **Module active:** `nsx-collector` (READ permission)
- **Core active:** identity, access, communication, governance
- **Containers:** PostgreSQL, nsx-collector, backend API, React frontend

## Prerequisites

- Oracle Linux 9 VM (or compatible RHEL-based)
- NSX-T Manager accessible from the VM (network connectivity)
- NSX-T API token with **Auditor** role (read-only)
- Git installed

## Step 1 — Clone and install Docker

```bash
git clone https://github.com/leopoldocosta/netops-ai-platform
cd netops-ai-platform
bash scripts/install-docker.sh
newgrp docker
```

## Step 2 — Configure non-secret environment variables

```bash
cp .env.example .env
nano .env
# Fill: NSX_MANAGER_URL, POSTGRES_DB, POSTGRES_USER, API_PORT, REACT_APP_API_URL
# DO NOT put tokens or passwords in .env
```

## Step 3 — Deploy

```bash
bash scripts/deploy-phase0.sh
# The script will prompt for secrets (no echo):
#   - NSX-T API token (Auditor role)
#   - PostgreSQL password
#   - API secret key
```

## Step 4 — Access

- Dashboard: `http://<VM-IP>:3000`
- API health: `http://<VM-IP>:8080/health`

## Creating the NSX-T API Token

1. Login to NSX-T Manager
2. Go to: **System → Users and Roles → Generate Token**
3. Role: **Auditor**
4. Set expiration (recommended: 90 days)
5. Copy token — it is shown only once
6. Run `bash scripts/deploy-phase0.sh` and paste when prompted

## Useful commands

```bash
docker stack services netops
docker service logs netops_nsx-collector -f
docker service logs netops_backend-api -f
bash scripts/teardown-phase0.sh
```

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Collector not starting | `docker service logs netops_nsx-collector` |
| Token rejected | Verify Auditor role and token not expired |
| SSL error | Set `NSX_VERIFY_SSL=false` in `.env` (lab only) |
| DB connection error | Check `POSTGRES_USER` and postgres_password secret |
