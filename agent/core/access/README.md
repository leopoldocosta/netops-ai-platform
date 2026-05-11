# Core — Access

Manages how the agent authenticates to external systems.

## Responsibilities

- API token lifecycle: creation, registration, expiry tracking, HITL alert at T-14d
- SSH Key management: key distribution, failure detection, HITL alert
- Docker Secrets integration (Phase 0–3)
- HashiCorp Vault integration (Phase 4+)
- Session credential handler: accepts operator input, holds in RAM, discards on session end

## Authentication Hierarchy

```
1. API Token (read-only scope, expiry set)    ← default for all vendor API integrations
2. SSH Key (no passphrase, managed rotation)  ← for host-level access
3. Session credential (operator input, RAM)   ← fallback when token/key fails
4. .env file                                  ← lab/dev only, never production
```

## Token Registry

All tokens are registered in `inventory/token-registry.yaml` (internal repo).
The registry stores **metadata only** — never token values.

Fields tracked per token:
- `name`: Docker Secret name
- `vendor`: which product it accesses
- `environment`: prod / dr / lab
- `role`: the access role granted (e.g., Auditor)
- `expires_at`: expiry date — agent alerts at T-14 days
- `created_by` / `created_at`: accountability

## Files in this directory (to be implemented)

```
access/
├── token_manager.go     ← expiry check, HITL alert trigger
├── ssh_manager.go       ← key validation, failure handler
├── secret_reader.go     ← reads from /run/secrets/* (Docker) or Vault
└── session_cred.go      ← in-RAM session credential, auto-discard
```
