# Core — Cognition

The agent's reasoning and analysis engine. **Phase 1+**.

## Responsibilities

- Process collected data through LLM pipelines
- Generate plain-language summaries for the dashboard
- Analyze release notes, known issues, CVE feeds
- Maintain analysis memory in PostgreSQL
- Route requests between local (Ollama) and external (Gemini) LLMs via LiteLLM

## Privacy Rule

No real environment data (IPs, hostnames, specific version strings that could
identify the environment) is sent to external LLMs without sanitization.

Local Ollama inference is always preferred. External LLM is opt-in per analysis type.

## LLM Routing (Phase 1)

```
Analysis request
       │
       ▼
   LiteLLM proxy
    ┌──┴──────────────────────┐
    │                         │
Ollama (local)         Gemini via Vertex
Qwen3 14B /            sanitized data only
Llama 4 Scout          opt-in per request
```

## Files in this directory (to be implemented in Phase 1)

```
cognition/
├── pipeline.py          ← LangChain analysis pipeline
├── sanitizer.py         ← removes env-identifying data before external LLM
├── memory.py            ← PostgreSQL read/write for analysis history
├── prompt_templates/    ← structured prompts per analysis type
│   ├── release_notes.md
│   ├── cve_analysis.md
│   ├── health_summary.md
│   └── upgrade_recommendation.md
└── litellm_config.yaml  ← LiteLLM routing config (no secrets here)
```
