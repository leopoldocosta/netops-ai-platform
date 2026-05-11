-- ============================================================
-- V001 — Initial Schema
-- Creates core tables needed for Phase 0
-- ============================================================

-- Agent identity (read by backend API to serve dashboard header)
CREATE TABLE IF NOT EXISTS agent_identity (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  version     TEXT NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO agent_identity (name, version) VALUES ('NetOps AI Platform', '0.3.0')
ON CONFLICT DO NOTHING;

-- Immutable audit log (append-only — no UPDATE or DELETE ever)
CREATE TABLE IF NOT EXISTS agent_audit_log (
  id          BIGSERIAL PRIMARY KEY,
  ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  module      TEXT NOT NULL,
  action_type TEXT NOT NULL CHECK (action_type IN ('READ','SUGGEST','WRITE','EXECUTE')),
  action      TEXT NOT NULL,
  context     JSONB,
  operator    TEXT,
  approved    BOOLEAN,
  notes       TEXT
);

-- Revoke UPDATE and DELETE on audit log (enforce append-only at DB level)
REVOKE UPDATE, DELETE ON agent_audit_log FROM PUBLIC;

-- NSX Collector: versions detected
CREATE TABLE IF NOT EXISTS nsx_collector_versions (
  id            SERIAL PRIMARY KEY,
  collected_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  manager_url   TEXT NOT NULL,
  product_name  TEXT,
  version       TEXT,
  build         TEXT,
  raw           JSONB
);

-- NSX Collector: active alarms
CREATE TABLE IF NOT EXISTS nsx_collector_alarms (
  id            SERIAL PRIMARY KEY,
  collected_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  alarm_id      TEXT,
  severity      TEXT,
  summary       TEXT,
  feature_name  TEXT,
  status        TEXT,
  first_reported TIMESTAMPTZ,
  raw           JSONB
);

-- NSX Collector: transport node status
CREATE TABLE IF NOT EXISTS nsx_collector_transport_nodes (
  id              SERIAL PRIMARY KEY,
  collected_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  node_id         TEXT,
  display_name    TEXT,
  status          TEXT,
  failure_domain  TEXT,
  raw             JSONB
);

-- NSX Collector: controller cluster status
CREATE TABLE IF NOT EXISTS nsx_collector_controllers (
  id            SERIAL PRIMARY KEY,
  collected_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  cluster_id    TEXT,
  status        TEXT,
  nodes         JSONB,
  raw           JSONB
);

-- Token registry (metadata only — never stores token values)
CREATE TABLE IF NOT EXISTS agent_token_registry (
  id                  SERIAL PRIMARY KEY,
  secret_name         TEXT NOT NULL UNIQUE,
  vendor              TEXT NOT NULL,
  environment         TEXT NOT NULL,
  role                TEXT NOT NULL,
  created_by          TEXT NOT NULL,
  created_at          DATE NOT NULL,
  expires_at          DATE NOT NULL,
  alert_dispatched_at TIMESTAMPTZ,
  notes               TEXT
);
