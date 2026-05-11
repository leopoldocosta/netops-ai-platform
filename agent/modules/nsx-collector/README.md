# Module: nsx-collector

**Permission level:** READ  
**Phase:** 0  
**Vendor:** VMware NSX-T / NSX (VCF)

## What this module does

Collects read-only operational data from NSX-T Manager via REST API.
Pushes data to PostgreSQL. Exposes HTTP endpoints for the backend API.

No write, exec or config-change operations. Ever.

## Token Requirements

- **Role:** Auditor (native NSX-T read-only role)
- **Scope:** Read-only — no write or execute permissions
- **Creation:** NSX-T Manager → System → Users → Generate Token
- **Injection:** Docker Secret `nsx_api_token` → read from `/run/secrets/nsx_api_token`

## Data Collected (Phase 0)

- [x] Product version (`GET /api/v1/node`)
- [x] Active alarms (`GET /api/v1/alarms`)
- [x] Controller cluster status (`GET /api/v1/cluster/status`)
- [x] Transport node status (`GET /api/v1/transport-nodes/status`)
- [x] Fabric health summary (`GET /api/v1/systemhealth/query`)
- [ ] Release notes correlation — Phase 1 (nsx-analyzer module)
- [ ] CVE correlation — Phase 1 (cve-monitor module)
- [ ] Known issues match — Phase 1 (nsx-analyzer module)

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NSX_MANAGER_URL` | yes | — | NSX-T Manager URL (no trailing slash) |
| `NSX_VERIFY_SSL` | no | `true` | Set `false` only in lab with self-signed cert |
| `NSX_COLLECT_INTERVAL_SECONDS` | no | `300` | Collection interval in seconds |
| `POSTGRES_HOST` | yes | — | PostgreSQL host |
| `POSTGRES_PORT` | no | `5432` | PostgreSQL port |
| `POSTGRES_DB` | yes | — | Database name |
| `POSTGRES_USER` | yes | — | Database user |

Password: Docker Secret `/run/secrets/postgres_password` — never via env var.

## NSX-T API References

- REST API docs: https://developer.broadcom.com/xapis/nsx-t-data-center-rest-api/latest/
- Alarms: `GET /api/v1/alarms`
- Node info / version: `GET /api/v1/node`
- Transport nodes: `GET /api/v1/transport-nodes/status`
- Cluster status: `GET /api/v1/cluster/status`
- System health: `GET /api/v1/systemhealth/query`
