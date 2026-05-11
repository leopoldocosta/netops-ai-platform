# Platform Stack — Agent Architecture

## Agent Layer Model

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                         │
│  agent/core/communication/frontend  (React + TypeScript)    │
│  Dashboard — 4-level drill-down — real-time WebSocket       │
├─────────────────────────────────────────────────────────────┤
│  API LAYER                                                  │
│  agent/core/communication/backend   (Go + Fiber)            │
│  REST + WebSocket — serves frontend + module outputs        │
├──────────────────┬──────────────────────────────────────────┤
│  MODULES         │  GOVERNANCE                              │
│  agent/modules/  │  agent/core/governance/                  │
│                  │                                          │
│  nsx-collector ──┤  HITL checkpoints                        │
│  nsx-analyzer    │  Audit log (immutable)                   │
│  cve-monitor     │  Permission model                        │
│  rdm-generator   │  Session credential manager              │
│  ...             │                                          │
├──────────────────┴──────────────────────────────────────────┤
│  COGNITION (Phase 1+)                                       │
│  agent/core/cognition/                                      │
│  LangChain + LiteLLM proxy                                  │
│  ┌───────────────┬─────────────────┬──────────────────────┐ │
│  │ Ollama local  │ Gemini (Vertex) │ vLLM (future)        │ │
│  └───────────────┴─────────────────┴──────────────────────┘ │
├──────────────────┬──────────────────────────────────────────┤
│  PostgreSQL      │  Prometheus     │  InfluxDB 3.0          │
│  CMDB, memory,   │  (Phase 2+)     │  (Phase 2+)            │
│  audit log       │  short-term     │  long-term series      │
├──────────────────┴──────────────────────────────────────────┤
│  ACCESS LAYER                                               │
│  agent/core/access/                                         │
│  Token lifecycle │ SSH Key manager │ Docker Secrets (P0-3)  │
│                                   │ HashiCorp Vault (P4+)  │
├─────────────────────────────────────────────────────────────┤
│  IDENTITY                                                   │
│  agent/core/identity/                                       │
│  Profile · Active modules · Capability log · Version        │
├─────────────────────────────────────────────────────────────┤
│  ORCHESTRATION (Phase 3+)                                   │
│  n8n self-hosted — scheduled pipelines — ITSM integration   │
├─────────────────────────────────────────────────────────────┤
│  INFRA                                                      │
│  Docker Compose (Phase 0) → Docker Swarm → Kubernetes (TBD) │
│  Oracle Linux 9 VM                                          │
└─────────────────────────────────────────────────────────────┘
```

## Authentication Flow

```
Level 1 (default)  → API Token (read-only, expiry set, Docker Secret)
Level 2 (alt)      → SSH Key (hosts only)
Level 3 (fallback) → Operator session credential (RAM only, discarded)
Level 4 (lab only) → .env — never in production
```

## Data Flow — Phase 0

```
[NSX-T Manager API] ←── read-only token ──→ [modules/nsx-collector (Go)]
                                                       │
                                               [PostgreSQL]
                                                       │
                                    [core/communication/backend (Go API)]
                                                       │
                                    [core/communication/frontend (React)]
```

## Module Expansion Pattern

```
New capability needed
        │
        ▼
Create agent/modules/<new-module>/ from _template
        │
        ▼
Declare in docs/AGENT.md module registry
        │
        ▼
PR review + authorization note
        │
        ▼
Merge + deploy via scripts/deploy-phase<N>.sh
        │
        ▼
Capability active — logged in AGENT.md expansion log
```
