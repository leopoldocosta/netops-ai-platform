# Collector Template

Use this template to add a new vendor collector.

## Required Interface

Every collector MUST implement:

1. `GET /health` — returns collector status
2. `GET /version` — returns detected product version
3. `GET /alerts` — returns active alerts list
4. Pushes data to PostgreSQL via shared DB client
5. Reads API token from `/run/secrets/<vendor>_api_token` (Docker Secret)
6. Never logs token values — mask in all output

## File Structure

```
collectors/<vendor>/
├── main.go          # entrypoint
├── client.go        # vendor API client (read-only)
├── collector.go     # collection logic
├── models.go        # data models
├── config.go        # config from env vars + Docker Secrets ONLY
├── Dockerfile
└── README.md        # vendor-specific notes
```

## Environment Variables Pattern

- All config via env vars. No hardcoded values. No config files committed.
- Prefix: `<VENDOR>_` (e.g., `NSX_`, `ACI_`, `PALOALTO_`)
- Token: read from `/run/secrets/<vendor>_api_token` — NEVER from env var

## Security Rules

- Only HTTP GET methods allowed in Phase 0/1
- SSL verification enabled by default
- Token value never appears in logs (use `[REDACTED]` if needed)
- Collector stops and alerts HITL if token is invalid/expired
