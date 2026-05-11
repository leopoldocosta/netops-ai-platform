# NSX-T Collector

Read-only collector for VMware NSX-T / VMware NSX (VCF).

## Permissions Required

- Role: **Auditor** (native NSX-T read-only role)
- No write, exec or config-change permissions
- Token created in NSX-T Manager: System → Users → Generate Token

## Authentication

Token injected via Docker Secret at runtime:
```bash
# During deploy (prompted by script — no echo)
read -rs NSX_TOKEN
echo "$NSX_TOKEN" | docker secret create nsx_api_token -
unset NSX_TOKEN
```

Container reads from `/run/secrets/nsx_api_token`.
Token never stored in env var, file, or log.

## Data Collected (Phase 0)

- [x] Product version
- [x] Active alarms/alerts
- [x] Controller cluster status
- [x] Transport node status
- [x] Fabric health summary
- [ ] Release notes correlation (Phase 1)
- [ ] CVE correlation (Phase 1)
- [ ] Known issues match (Phase 1)

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NSX_MANAGER_URL` | yes | — | NSX-T Manager URL (no trailing slash) |
| `NSX_VERIFY_SSL` | no | `true` | Disable only in lab with self-signed certs |
| `NSX_COLLECT_INTERVAL_SECONDS` | no | `300` | Collection interval |
| `POSTGRES_HOST` | yes | — | PostgreSQL host |
| `POSTGRES_PORT` | no | `5432` | PostgreSQL port |
| `POSTGRES_DB` | yes | — | Database name |
| `POSTGRES_USER` | yes | — | Database user |
| `POSTGRES_PASSWORD` | yes | — | Via Docker Secret: `/run/secrets/postgres_password` |

## NSX-T API References

- Manager REST API: https://developer.broadcom.com/xapis/nsx-t-data-center-rest-api/latest/
- Alarms: `GET /api/v1/alarms`
- Version: `GET /api/v1/node`
- Transport Nodes: `GET /api/v1/transport-nodes/status`
- Controllers: `GET /api/v1/cluster/status`
