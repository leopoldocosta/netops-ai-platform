# Core — Governance

Defines and enforces what the agent can and cannot do.

## Responsibilities

- HITL checkpoints: mandatory approval gates for WRITE and EXECUTE modules
- Immutable audit log: every agent action logged (PostgreSQL, append-only)
- Permission enforcer: blocks module from exceeding its declared permission level
- Session credential manager: accepts operator input for execution windows

## HITL Checkpoint Flow

```
Module requests WRITE or EXECUTE action
              │
              ▼
   Governance layer intercepts
              │
              ▼
   HITL alert dispatched (dashboard + notification)
              │
              ▼
   Human reviews context + approves or rejects
              │
         ┌────┴────┐
       Approved   Rejected
         │            │
    Action logged  Rejection logged
    Action executed  Module notified
```

## Audit Log Schema

Every entry is **append-only** — no updates, no deletes.

```sql
CREATE TABLE agent_audit_log (
  id          BIGSERIAL PRIMARY KEY,
  ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  module      TEXT NOT NULL,
  action_type TEXT NOT NULL,   -- READ | SUGGEST | WRITE | EXECUTE
  action      TEXT NOT NULL,
  context     JSONB,
  operator    TEXT,            -- null for autonomous READ actions
  approved    BOOLEAN,         -- null for READ/SUGGEST (no approval needed)
  notes       TEXT
);
```

## Files in this directory (to be implemented)

```
governance/
├── hitl.go              ← checkpoint dispatcher, approval tracker
├── audit.go             ← append-only log writer
├── permissions.go       ← permission level enforcer per module
└── session_exec.go      ← execution window: accepts cred, runs, discards
```
