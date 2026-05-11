# NetOps AI Platform

Multi-vendor network operations AI platform. Extensible, read-only first, human-in-the-loop.

## Supported Vendors (Roadmap)

| Vendor | Status |
|--------|--------|
| VMware NSX-T | 🚧 Phase 0 |
| Cisco ACI | 📋 Planned |
| Palo Alto NGFW | 📋 Planned |
| Fortinet FortiGate | 📋 Planned |
| Juniper | 📋 Planned |

## Architecture

See [docs/architecture/STACK.md](docs/architecture/STACK.md)

## Getting Started

See [docs/runbooks/phase0-quickstart.md](docs/runbooks/phase0-quickstart.md)

## Phases

- **Phase 0** — Read-only: version check, alerts, health check (NSX-T)
- **Phase 1** — AI analysis: release notes, known issues, CVE correlation
- **Phase 2** — Historical metrics: Prometheus + InfluxDB
- **Phase 3** — Scheduling: n8n orchestration
- **Phase 4** — Credential management: HashiCorp Vault + SSH keys
- **Phase 5** — Second vendor: Cisco ACI
- **Phase 6** — LLM routing: LiteLLM + Gemini + vLLM

## Security Principles

- No credentials stored in code, config files, or any committed artifact
- Authentication via API Token (read-only scope) or SSH Key — never passwords
- Tokens injected at runtime via Docker Secrets — never via .env in production
- Read-only access enforced at collector level in Phase 0
- SSH key access with HITL fallback alert on failure
- Human-in-the-loop: platform suggests, human decides

## License

Apache 2.0
