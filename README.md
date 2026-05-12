# NetOps AI Platform

> ⚠️ **Este repositório não está mais sendo atualizado.**
> O desenvolvimento ocorre no repositório privado interno.
> Uma versão pública sanitizada será publicada aqui quando a plataforma atingir maturidade.
> Veja [ARCHIVE.md](./ARCHIVE.md) para detalhes.

---

An AI agent for network operations. Extensible, read-only first, human-in-the-loop.

## Concept

This platform is built around a single AI agent entity with a persistent identity.
Capabilities expand through modules. Each module has a clear permission boundary:
`READ` → `SUGGEST` → `WRITE` → `EXECUTE`.

Human approval gates are mandatory before any write or execution in production.

## Principles

- Default to read-only
- Expand permissions by phase, never by convenience
- Human-in-the-loop for all impactful actions
- Full audit trail
- Separate environment-specific configuration from generic code
