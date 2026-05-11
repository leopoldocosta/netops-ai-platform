# Module: nsx-analyzer

**Permission level:** SUGGEST  
**Phase:** 1  
**Status:** Planned

## What this module does

Analyzes NSX-T collected data using the cognition pipeline.
Correlates current version against release notes, known issues and CVE feeds.
Generates upgrade recommendations with risk assessment.
Outputs are suggestions only — no infrastructure changes.

## Inputs

- Data from `nsx-collector` (PostgreSQL)
- Broadcom TechDocs release notes (web fetch)
- CVE feeds from `cve-monitor` module

## Outputs (SUGGEST level — no side effects)

- Upgrade recommendation document
- Risk assessment (conflicts, known issues affecting current environment)
- Executive summary text (displayed on dashboard Level 1)
- Playbook draft (displayed on dashboard Level 4)

## Activation requirement

nsx-collector must be stable in production for at least 30 days before
this module is activated (PP-MD-03).
