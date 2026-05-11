# Module: rdm-generator

**Permission level:** SUGGEST  
**Phase:** 2  
**Status:** Planned

## What this module does

Generates Change Request (RDM) documents using the cognition pipeline.
Does not submit to ITSM — output is a structured document for human review.

ITSM submission (ServiceNow / Jira) is a separate module (itsm-integration, Phase 3)
activated only after explicit authorization.

## Document Output

Generated RDM includes:
- Change title and justification
- Current state vs. target state
- Risk assessment (from nsx-analyzer)
- Known conflicts (from nsx-analyzer + cve-monitor)
- Rollback plan
- Maintenance window suggestion
- Pre/post validation checklist

## Format

- Markdown (primary)
- PDF export (via Pandoc)
- Pre-filled ITSM template (JSON/YAML — for manual import or itsm-integration module)
