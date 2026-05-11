# Database — Schema Migrations

All schema changes are applied via versioned migration files.
Never alter the database manually — always via migration script.

## Naming convention

```
V<version>__<description>.sql

V001__initial_schema.sql
V002__add_nsx_collector_tables.sql
V003__add_audit_log.sql
```

## Migration tool

Flyway (or golang-migrate) — to be configured in Phase 0 backend.

## Tables by component

| Prefix | Owner | Phase |
|--------|-------|-------|
| `nsx_collector_*` | module: nsx-collector | 0 |
| `agent_audit_log` | core: governance | 0 |
| `agent_identity_*` | core: identity | 0 |
| `nsx_analyzer_*` | module: nsx-analyzer | 1 |
| `cve_*` | module: cve-monitor | 1 |
| `rdm_*` | module: rdm-generator | 2 |
