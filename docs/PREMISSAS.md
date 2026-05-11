# Premissas da Plataforma — NetOps AI Platform

> **Versão:** 0.2.0  
> **Última revisão:** 2026-05-11  
> **Status:** Ativo

---

## Premissas Globais
*Aplicam-se a toda e qualquer ação, em qualquer fase, por qualquer pessoa.*

---

### PG-01 — Autenticação por Token de API ou SSH Key

O acesso da plataforma a qualquer vendor ou sistema externo ocorre
exclusivamente via **token de API com escopo mínimo (read-only)** ou
**SSH Key**.

Nenhuma senha de usuário é armazenada em qualquer meio:
disco, memória persistente, variável de ambiente, código ou arquivo
de configuração versionado.

Senhas só trafegam em memória RAM de sessão ativa quando digitadas
pelo operador via interface segura, e são descartadas ao término
da sessão sem persistência de nenhum tipo.

**Hierarquia de acesso (do mais ao menos preferido):**

| Nível | Método | Quando usar |
|-------|--------|-------------|
| 1 — Padrão | Token de API read-only | Toda integração com vendor via REST API |
| 2 — Alternativo | SSH Key | Acesso a hosts/VMs, não a APIs REST |
| 3 — Fallback | Credencial digitada na sessão | Token/key inválidos, operador disponível |
| 4 — Emergência | `.env` local | Apenas em lab/dev, jamais em produção |

---

### PG-01-A — Ciclo de Vida dos Tokens

- Tokens criados com escopo mínimo necessário e data de expiração definida
- Registrados no inventário da plataforma: nome, vendor, ambiente, validade, responsável
- A plataforma monitora a proximidade do vencimento
- Alerta HITL disparado com antecedência configurável (padrão: **14 dias**)
- Tokens nunca são compartilhados entre ambientes (prod, DR, lab têm tokens distintos)

---

### PG-01-B — Fallback e Degradação Graciosa

Fluxo obrigatório em caso de falha de token ou SSH key:

```
Falha detectada
      │
      ▼
Análise do target PAUSADA
      │
      ▼
Alerta HITL disparado (dashboard + notificação)
      │
      ▼
Operador digita credencial temporária via interface segura
      │
      ▼
Credencial usada em memória de sessão — NÃO persistida
      │
      ▼
Sessão encerrada → credencial descartada
      │
      ▼
Operador corrige token/key → análise retoma normalmente
```

---

### PG-01-C — `.env` é Exceção Documentada

- **Permitido:** ambiente de desenvolvimento e laboratório isolado
- **Proibido:** qualquer ambiente de produção ou staging
- **Obrigatório:** documentar no PR/commit a justificativa da exceção
- **Prazo:** `.env` com credencial deve ser removido em até 72h após uso em lab

---

### PG-01-D — Secrets em Runtime (Docker)

Para execuções contínuas e agendadas, tokens são gerenciados via
**Docker Secrets** — mecanismo nativo de runtime que não requer `.env`
e não persiste o valor em disco de forma legível:

```bash
# Criar secret (uma vez, pelo operador)
echo "meu-token-nsx" | docker secret create nsx_api_token -

# Consumido pelo container em /run/secrets/nsx_api_token
# Nunca exposto em variável de ambiente ou log
```

Na Fase 4+, Docker Secrets é substituído por HashiCorp Vault com
rotação automática e auditoria completa.

---

### PG-02 — Entrega Exclusiva via Scripts de Deploy

Toda ação no ambiente (instalação, configuração, atualização,
modificação, adição de vendor) é realizada exclusivamente por meio
de **scripts de deploy fornecidos, versionados e revisados**.

- Nenhuma ação manual avulsa é aceita fora de situação de emergência
- Emergências são documentadas em `docs/runbooks/` após o fato
- Scripts são idempotentes: executar duas vezes não causa estado inconsistente
- Cada script valida pré-condições antes de executar qualquer ação

---

### PG-03 — Repositório Duplo

| Repositório | Visibilidade | Conteúdo |
|-------------|-------------|----------|
| `netops-ai-platform` | Público | Código genérico, dados anonimizados, sem referência a ambientes reais |
| `netops-ai-platform-internal` | Privado | Configurações de ambiente, inventory (sem credenciais), adaptações específicas |

- Mudanças estruturais vão para o público primeiro
- O privado nunca recebe código que deveria estar no público
- Credenciais, IPs reais e hostnames de produção **nunca** entram em nenhum dos dois

---

### PG-04 — Read-Only por Padrão

Toda integração com vendor inicia em modo estritamente leitura.

- Tokens criados com permissão **Auditor** ou equivalente read-only do vendor
- Nenhuma chamada de API com método PUT, POST, DELETE ou PATCH na Fase 0 e 1
- Permissões de escrita adicionadas somente em fase posterior,
  por decisão explícita, documentada e aprovada

---

### PG-05 — Human-in-the-Loop (HITL)

A plataforma **prepara, analisa e sugere**. O humano **decide e autoriza**.

- Nenhuma ação de mudança em ambiente ocorre sem aprovação humana explícita
- Análises automáticas geram recomendações, não execuções
- Aprovações são registradas com timestamp, usuário e contexto

---

### PG-06 — Expansibilidade por Design

Cada componente é desenhado para suportar múltiplos vendors sem reescrita.

- Novos vendors entram como **coletores Go independentes**
- Interface de coletor é padronizada (ver `collectors/_template/`)
- O core da plataforma (API, frontend, banco) não muda para adicionar vendor
- Ordem de implementação: NSX-T → Cisco ACI → Palo Alto → Fortinet → Juniper

---

### PG-07 — Acesso SSH com Fallback Alertado

- Acesso padrão a hosts: SSH Key (sem senha)
- Falha de SSH Key → target pausado + alerta HITL imediato
- Operador pode fornecer credencial temporária via interface segura
- Credencial temporária não é persistida (ver PG-01-B)

---

### PG-08 — Scripts Idempotentes

Todo script de deploy deve:
- Funcionar em ambiente limpo e em ambiente já parcialmente configurado
- Verificar estado atual antes de aplicar mudança
- Não deixar estado inconsistente se interrompido
- Logar cada etapa com timestamp

---

### PG-09 — Versionamento Semântico

| Tipo de mudança | Incremento |
|-----------------|------------|
| Mudança de arquitetura, breaking change | MAJOR (X.0.0) |
| Nova fase, novo vendor, nova feature | MINOR (0.X.0) |
| Correção, ajuste, melhoria pontual | PATCH (0.0.X) |

---

### PG-10 — Linguagem por Camada

| Camada | Linguagem | Justificativa |
|--------|-----------|---------------|
| Coletores de API (vendors) | **Go** | Binários leves, concorrência nativa, sem runtime |
| Backend API central | **Go (Fiber)** | Alta performance, baixo consumo |
| Pipeline de IA / análise | **Python** | Ecossistema LLM exclusivo (LangChain, LlamaIndex) |
| Scripts de deploy / infra | **Bash** | Universal, sem dependências |
| Frontend | **React + TypeScript** | Interface N3/N4/gestores |
| Orquestração (Fase 3+) | **n8n** | Workflows visuais, integração ITSM |

---

## Premissas Pontuais por Fase

---

### Fase 0 — Fundação Read-Only

**PP-F0-01** — Apenas 4 containers: PostgreSQL, Go API, NSX Collector, React Frontend.  
Sem Prometheus, sem InfluxDB, sem n8n, sem LLM. Foco em funcionar.

**PP-F0-02** — O coletor NSX-T usa token de API com role **Auditor** (read-only nativo do NSX-T).  
Nenhuma permissão além de leitura é concedida.

**PP-F0-03** — Dados coletados na Fase 0:
- Versão do produto NSX-T
- Alertas/alarmes ativos
- Status dos controllers
- Status dos transport nodes
- Health summary geral

**PP-F0-04** — Dashboard Fase 0 entrega:
- Contadores globais (alertas, versão atual vs. recomendada, health)
- Listagem dos itens por contador
- Detalhe básico de cada item
- Sumário executivo IA e Playbooks são Fase 1

**PP-F0-05** — Token NSX-T é fornecido pelo operador no momento do deploy,
via input seguro no terminal (sem eco). Injetado como Docker Secret.  
Nunca armazenado em `.env`, arquivo ou variável de ambiente persistente.

---

### Fase 1 — Inteligência IA

**PP-F1-01** — LLM local via Ollama. Modelo padrão inicial: Qwen3 14B ou Llama 4 Scout.

**PP-F1-02** — Nenhum dado real de ambiente (IPs, hostnames, versões específicas)
é enviado para APIs externas sem sanitização/anonimização prévia.

**PP-F1-03** — Se Gemini via Vertex AI for disponibilizado, entra via LiteLLM proxy
como backend premium. Dados enviados são anonimizados antes do envio.

**PP-F1-04** — O dashboard evolui para os 4 níveis de drill-down:
1. Contadores globais + sumário executivo (parágrafo IA)
2. Listagem dos itens por contador
3. Detalhe do item + análise IA
4. Playbook sugerido + links de referência

---

### Fase 2 — Histórico e Métricas

**PP-F2-01** — Prometheus para métricas de curto prazo e alertas.

**PP-F2-02** — InfluxDB 3.0 OSS para séries temporais de longo prazo (30/90/365 dias).

**PP-F2-03** — PostgreSQL permanece como CMDB e armazenamento de análises da IA.

---

### Fase 3 — Orquestração

**PP-F3-01** — n8n self-hosted para agendamento de coletas e pipelines de análise.

**PP-F3-02** — Workflows n8n são versionados como JSON exportado no repositório público.

---

### Fase 4 — Gestão de Credenciais Avançada

**PP-F4-01** — HashiCorp Vault OSS substitui Docker Secrets para todos os tokens.

**PP-F4-02** — Rotação automática de tokens com notificação HITL 14 dias antes da expiração.

**PP-F4-03** — Auditoria completa: todo acesso a secret é logado com timestamp e contexto.

---

### Vendors

**PP-VD-01** — Cada novo vendor entra com seu próprio coletor Go independente.

**PP-VD-02** — Interface obrigatória de todo coletor (ver `collectors/_template/`):  
`GET /health`, `GET /version`, `GET /alerts`, push para PostgreSQL.

**PP-VD-03** — Antes de adicionar vendor novo, o coletor anterior deve estar  
estável em produção por no mínimo **30 dias**.

**PP-VD-04** — Token do novo vendor: escopo mínimo read-only, expiração definida,  
registrado no inventário antes do primeiro deploy.
