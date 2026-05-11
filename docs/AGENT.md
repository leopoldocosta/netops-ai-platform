# Agent Identity — NetOps AI Platform

> **Version:** 0.3.0  
> **Last updated:** 2026-05-11  
> **Status:** Active

---

## What this agent is

This is an AI operations agent specialized in network infrastructure.
It has a persistent identity, a fixed core, and modular capabilities that
expand incrementally under human authorization.

The agent **observes, analyzes, and recommends**. It does not act without
explicit human approval on consequential operations.

---

## Core Components

### Identity (`agent/core/identity/`)
The agent's persistent profile:
- Name, version, declared capabilities
- List of active modules with their permission levels
- Changelog of capability expansions (who authorized, when, what)

### Access (`agent/core/access/`)
How the agent connects to external systems:
- API token lifecycle manager (expiry tracking, HITL alerts at T-14 days)
- SSH Key manager with graceful degradation (HITL alert on failure)
- Docker Secrets integration (Phase 0–3) → HashiCorp Vault (Phase 4+)
- Authentication hierarchy: Token → SSH Key → Session credential → .env (lab only)

### Cognition (`agent/core/cognition/`)
How the agent thinks and processes — Phase 1+:
- LLM pipeline (LangChain + LiteLLM proxy)
- Local inference via Ollama (Qwen3 14B / Llama 4 Scout)
- Memory: PostgreSQL stores analysis history, decisions, context
- No real environment data sent to external LLMs without sanitization

### Communication (`agent/core/communication/`)
How the agent presents itself and reports:
- React dashboard with 4-level drill-down
- Go backend API (Fiber) with WebSocket for real-time counters
- Structured alert system (info / warning / critical)
- Plaintext executive summaries (Phase 1: AI-generated)

### Governance (`agent/core/governance/`)
What the agent can and cannot do:
- HITL checkpoints: every consequential action requires explicit approval
- Immutable audit log: every action logged with timestamp, operator, context
- Permission model per module (see Module Registry below)
- Session-scoped credentials: operator provides at execution time, discarded after

---

## Module Registry

Every module must be registered here before activation.

| Module | Path | Permission Level | Phase | Status |
|--------|------|-----------------|-------|--------|
| nsx-collector | `agent/modules/nsx-collector/` | READ | 0 | 🚧 Building |
| nsx-analyzer | `agent/modules/nsx-analyzer/` | READ + SUGGEST | 1 | 📋 Planned |
| cve-monitor | `agent/modules/cve-monitor/` | READ (external feeds) | 1 | 📋 Planned |
| rdm-generator | `agent/modules/rdm-generator/` | SUGGEST (doc output) | 2 | 📋 Planned |
| itsm-integration | `agent/modules/itsm-integration/` | WRITE (ITSM only, HITL) | 3 | 📋 Planned |
| upgrade-executor | `agent/modules/upgrade-executor/` | EXECUTE (HITL + session cred) | 5 | 📋 Planned |
| aci-collector | `agent/modules/aci-collector/` | READ | 5 | 📋 Planned |

### Permission Levels

| Level | Description | Human approval required |
|-------|-------------|------------------------|
| READ | API calls with read-only token — no side effects | No |
| SUGGEST | Generates recommendations, documents, alerts | No (output only) |
| WRITE | Creates records in external systems (ITSM, tickets) | Yes — HITL checkpoint |
| EXECUTE | Makes changes in infrastructure environment | Yes — HITL + session credential |

---

## Adding a New Module

1. Copy `agent/modules/_template/` to `agent/modules/<new-module>/`
2. Implement the module contract (see `_template/MODULE_CONTRACT.md`)
3. Declare the module in this registry (above table)
4. Submit PR with:
   - Module code
   - Updated registry entry
   - Authorization note (who approved the capability expansion)
5. Merge only after review
6. Deploy via `scripts/deploy-phase<N>.sh`

---

## Capability Expansion Log

| Date | Module | Authorized by | Notes |
|------|--------|---------------|-------|
| 2026-05-11 | nsx-collector | Initial setup | Phase 0 foundation |
