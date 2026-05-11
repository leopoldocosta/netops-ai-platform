# Module Contract

Every module in `agent/modules/` MUST satisfy this contract before activation.

---

## 1. Declaration in `docs/AGENT.md`

The module must appear in the Module Registry table with:
- `id`, `path`, `permission level`, `phase`, `status`

Modules not declared in the registry are not considered active, even if deployed.

---

## 2. Required HTTP Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Module health status |
| `/version` | GET | Module version + last collection timestamp |
| `/data` | GET | Module's primary output |

All endpoints return JSON. No authentication required (internal network only).

---

## 3. Permission Level Declaration

The module's `config.go` (or equivalent) must declare its permission level as a constant:

```go
const ModulePermission = "READ" // READ | SUGGEST | WRITE | EXECUTE
```

The governance layer will enforce this. A READ module that attempts a POST/PUT/DELETE
API call will be blocked and an alert will be raised.

---

## 4. Secret Handling

- Tokens read exclusively from `/run/secrets/<vendor>_api_token`
- Token value **never** appears in any log output (use `[REDACTED]`)
- Module stops and emits HITL alert if token is missing, expired, or rejected

---

## 5. Database Output

Every module pushes its collected/generated data to PostgreSQL.
Tables must be prefixed with the module id: `nsx_collector_*`, `nsx_analyzer_*`, etc.

---

## 6. File Structure

```
agent/modules/<module-id>/
├── main.go (or main.py)    ← entrypoint
├── client.go               ← external API client (read-only for collectors)
├── collector.go            ← collection/analysis logic
├── models.go               ← data models
├── config.go               ← config + permission level declaration
├── Dockerfile
└── README.md               ← vendor-specific notes + token requirements
```

---

## 7. Activation Checklist

- [ ] Module declared in `docs/AGENT.md` registry
- [ ] Module registered in `agent/core/identity/profile.yaml`
- [ ] Permission level declared in code
- [ ] Secret handling implemented (no passwords in logs)
- [ ] `/health` endpoint responds
- [ ] Data pushes to PostgreSQL
- [ ] README documents token requirements and API references
- [ ] PR includes authorization note (who approved the capability expansion)
