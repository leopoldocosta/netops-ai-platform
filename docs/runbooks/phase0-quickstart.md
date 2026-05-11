# Phase 0 — Quick Start Guide

## Prerequisites

- Oracle Linux 9 VM (or compatible RHEL-based)
- NSX-T Manager accessible from the VM (network connectivity)
- NSX-T API token with **Auditor** role (read-only)
- Git installed

## Step 1 — Install Docker

```bash
bash scripts/install-docker.sh
newgrp docker  # apply group without logout
```

## Step 2 — Configure environment (non-secret vars only)

```bash
cp .env.example .env
# Edit .env — fill NSX_MANAGER_URL, POSTGRES_DB, POSTGRES_USER, etc.
# DO NOT put tokens or passwords in .env
nano .env
```

## Step 3 — Deploy

```bash
bash scripts/deploy-phase0.sh
# Script will prompt for secrets (no echo):
# - NSX-T API token
# - PostgreSQL password
# - API secret key
```

## Step 4 — Access

- Dashboard: http://<VM-IP>:3000
- API: http://<VM-IP>:8080
- API Health: http://<VM-IP>:8080/health

## Useful commands

```bash
# Check services
docker stack services netops

# Check NSX collector logs
docker service logs netops_nsx-collector -f

# Check API logs
docker service logs netops_backend-api -f

# Teardown
bash scripts/teardown-phase0.sh
```

## Token Creation on NSX-T

1. Login to NSX-T Manager
2. Navigate to: **System → Users and Roles → Generate Token**
3. Role: **Auditor**
4. Set expiration (recommended: 90 days)
5. Copy token — it will not be shown again
6. Run deploy script and paste when prompted

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Collector not starting | `docker service logs netops_nsx-collector` |
| API token rejected | Verify Auditor role and token not expired |
| SSL error | Set `NSX_VERIFY_SSL=false` in `.env` (lab only) |
| DB connection failed | Check `POSTGRES_USER` and password secret |
