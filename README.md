# NetOps AI Platform

An AI agent for network operations. Extensible, read-only first, human-in-the-loop.

## Agent Model

This platform is built around a single AI agent entity with a persistent identity,
a fixed core (access, cognition, communication, governance) and modular capabilities
that expand over time.

See [docs/AGENT.md](docs/AGENT.md) for the agent profile.

## Repository Structure

```
agent/
├── core/
│   ├── identity/       ← agent profile, version, declared capabilities
│   ├── access/         ← token lifecycle, SSH key manager, secret injection
│   ├── cognition/      ← LLM pipeline, memory, context (Phase 1+)
│   ├── communication/  ← dashboard API, reports, alerts (Go backend + React)
│   └── governance/     ← HITL logic, audit log, permission model
└── modules/
    ├── _template/      ← module contract (every module implements this)
    ├── nsx-collector/  ← Phase 0: NSX-T read-only data collection
    ├── nsx-analyzer/   ← Phase 1: AI analysis of NSX-T data
    ├── cve-monitor/    ← Phase 1: CVE feed correlation
    └── rdm-generator/  ← Phase 2: Change request document generation

infra/
├── docker/             ← phase-scoped Docker Compose files
└── db/                 ← PostgreSQL schema migrations

docs/
├── AGENT.md            ← agent identity and module registry
├── PREMISSAS.md        ← platform principles (v0.3.0)
├── architecture/       ← stack diagrams
└── runbooks/           ← operational guides

scripts/                ← deploy, install, teardown
```

## Phases

| Phase | Focus | Status |
|-------|-------|--------|
| 0 | Foundation: read-only NSX-T collection | 🚧 Active |
| 1 | Intelligence: AI analysis, CVE, release notes | 📋 Planned |
| 2 | History: Prometheus + InfluxDB metrics | 📋 Planned |
| 3 | Orchestration: n8n scheduling | 📋 Planned |
| 4 | Credential vault: HashiCorp Vault | 📋 Planned |
| 5 | Second vendor: Cisco ACI | 📋 Planned |
| 6 | LLM routing: LiteLLM + Gemini + vLLM | 📋 Planned |

## Security Principles

- No credentials stored anywhere in code or config — tokens via Docker Secrets only
- Read-only access enforced at module level in Phase 0
- Human-in-the-loop: agent suggests, human decides and authorizes
- Every agent action is logged with timestamp, context and operator identity

## License

Apache 2.0
