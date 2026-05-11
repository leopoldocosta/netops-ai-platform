# Platform Stack

## Layers

```
┌─────────────────────────────────────────────────────────────┐
│  FRONTEND: React + TypeScript                               │
│  Dashboard N3/N4/Manager — drill-down 4 levels              │
├─────────────────────────────────────────────────────────────┤
│  BACKEND API: Go (Fiber framework)                          │
│  REST + WebSocket — real-time counters                      │
├─────────────────────────────────────────────────────────────┤
│  COLLECTORS: Go (one binary per vendor)                     │
│  Read-only API calls — no write/exec permissions            │
│  ┌──────────────┬──────────────┬───────────────────────┐   │
│  │ nsx-collector│ aci-collector│ paloalto-collector ... │   │
│  └──────────────┴──────────────┴───────────────────────┘   │
├──────────────┬──────────────────────────────────────────────┤
│  Prometheus  │  InfluxDB 3.0  │  PostgreSQL               │
│  (short-term │  (long-term    │  (CMDB, inventory,        │
│   metrics)   │   time-series) │   AI logs, HITL)          │
├──────────────┴──────────────────────────────────────────────┤
│  AI PIPELINE: Python + LangChain + LiteLLM proxy            │
│  ┌──────────────┬─────────────────┬──────────────────────┐ │
│  │ Ollama local │  Gemini via API  │  vLLM (future)       │ │
│  └──────────────┴─────────────────┴──────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  ORCHESTRATION: n8n self-hosted (Phase 3+)                  │
├─────────────────────────────────────────────────────────────┤
│  SECRETS: Docker Secrets (Phase 0-3) → HashiCorp Vault (4+) │
│  SSH Key Manager with HITL alert on failure                 │
├─────────────────────────────────────────────────────────────┤
│  INFRA: Docker Compose → Kubernetes (future)                │
│  Oracle Linux 9 VM                                          │
└─────────────────────────────────────────────────────────────┘
```

## Authentication Model

```
Level 1 (default)  → API Token (read-only scope, expiry set)
Level 2 (alt)      → SSH Key (hosts only, not REST APIs)
Level 3 (fallback) → Operator types credential in secure input
                     — discarded after session, never persisted
Level 4 (lab only) → .env file — never in production
```

## Data Flow (Phase 0)

```
[NSX-T Manager API] ←── read-only token ──→ [nsx-collector (Go)]
                                                     │
                                               [PostgreSQL]
                                                     │
                                            [Go Backend API]
                                                     │
                                           [React Dashboard]
```

## Secret Injection (Phase 0)

```
Operator runs deploy script
        │
        ▼
Script prompts for NSX API token (no echo)
        │
        ▼
Token piped to: docker secret create nsx_api_token -
        │
        ▼
Collector container reads /run/secrets/nsx_api_token
        │
        ▼
Token used in-memory only — never logged, never stored
```
