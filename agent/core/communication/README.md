# Core — Communication

How the agent presents itself to operators, analysts and managers.

## Responsibilities

- Go backend API (Fiber): serves all dashboard data, receives module outputs
- React frontend: dashboard with 4-level drill-down
- Real-time WebSocket: live counter updates without page refresh
- Alert system: structured alerts by severity (info / warning / critical)
- Report generator: exports analysis as PDF/Markdown (Phase 1+)

## Dashboard Levels

```
Level 1 — Global counters + executive summary (AI text — Phase 1)
  └─ Level 2 — Item list per counter
       └─ Level 3 — Item detail + AI analysis
            └─ Level 4 — Suggested playbook + reference links
```

Level 1-2: available in Phase 0 (without AI summary text).
Level 3-4: available in Phase 1 (with AI analysis).

## Files in this directory (to be implemented)

```
communication/
├── backend/             ← Go + Fiber API
│   ├── main.go
│   ├── handlers/
│   ├── models/
│   └── Dockerfile
└── frontend/            ← React + TypeScript
    ├── src/
    ├── public/
    ├── package.json
    └── Dockerfile
```
