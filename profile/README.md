<div align="center">

# `erp•ai`

### the substrate for agent-driven SaaS

every business-software category - finance, HR, support, sales, ops, ITSM, billing, project management, analytics - rebuilt as agent-first software on one stack. one storage engine, one memory tier, one runtime, one skill model, one set of interfaces. Rust top to bottom.

</div>

> 🗺 **Org members, start here:** [`erphq/MetaRepo`](https://github.com/erphq/MetaRepo) is the architecture map for every repo - layer-by-layer diagrams, the full edge list, and a current-status snapshot of all 40 repositories. New to the org? Skim that, then dive in.

---

## ✦ The thesis

Business software today is a graveyard of stitched-together SaaS. An ERP. A CRM. A helpdesk. A ticketing system. A BI tool. A billing platform. Three separate identity providers. A Postgres for transactions, a vector DB for retrieval, a graph DB for relationships, a warehouse for analytics, an event bus to keep them in rough sync. Twelve dashboards, one source of truth — usually wrong.

That stack was built for humans clicking forms. **Agent-driven software is built for agents writing thousands of events per second** with full lineage, full typing, and full audit. That's a different shape. Vector-DBs-bolted-on-Postgres do not become agent-native by adding `embedding VECTOR(384)`. Tool-loops over OpenAI Assistants do not become agent-native by adding `if (tool === "send_email")`.

You have to redesign the storage so the writes the agents emit don't drown it. You have to redesign the auth so per-key scopes and audit trails are a default, not a bolt-on. You have to redesign the memory so it's typed, queryable, vector-searchable, **and** graph-walkable in one shot. You have to redesign the runtime so every step is auditable by construction. You have to redesign the embeddings, the replication, the change-capture, the replay, the skills.

The bet is that **once that substrate exists, every vertical of SaaS becomes a thin layer of skills + UI on top of it.** ERP is the highest-leverage first vertical — it sits on the most data, has the most expensive incumbents, and rewards an agent-first rebuild more than anywhere else. But the same stack runs CRM, ITSM, support, billing, project management, recruiting, FP&A. The substrate is horizontal. The brand is the first vertical we're attacking with it.

That's what we're doing. Here.

---

## ✦ The stack

```text
┌────────────────────────────────────────────────────────────────────────┐
│  interface tier            chat · CLI · IDE assistant · mobile         │
│                            clickr · neo · (planned: web app, voice)    │
├────────────────────────────────────────────────────────────────────────┤
│  agent tier                runtime · skills · replay · workflows       │
│                            karta · skills · crucible · (planned: yantra) │
├────────────────────────────────────────────────────────────────────────┤
│  intelligence tier         process mining · forecasting · doc-AI       │
│                            gnn · (planned: drishti, gauge, lekhak)     │
├────────────────────────────────────────────────────────────────────────┤
│  memory tier               agent memory · embeddings · replay store    │
│                            smriti · bija                               │
├────────────────────────────────────────────────────────────────────────┤
│  ingest tier               ERP CDC · WAL replication                   │
│                            flow · vahini                               │
├────────────────────────────────────────────────────────────────────────┤
│  storage tier              graph + vector + columnar engine            │
│                            FFS                                          │
└────────────────────────────────────────────────────────────────────────┘
```

Every tier in Rust. Every tier with a typed contract. Every tier that talks to another over an HTTP-shaped or process-shaped boundary so any single piece can be replaced.

---

## ✦ Storage tier

> The substrate. Where bytes live, where durability is enforced, where queries hit physical I/O.

### `FFS` — the embedded engine

A typed graph + vector + columnar database in a single file. Pager + WAL + transaction manager + HNSW + RelTable + Cypher subset. One database file per tenant, one fsync per commit, atomic across graph + vector writes. Designed for write-heavy workloads — the only ones that matter when an agent fleet is your customer.

### `smriti` — managed agent memory

The HTTP service in front of FFS. Multi-tenant. Per-tenant rate limits, per-key scopes (`read` / `write` / `admin`), per-request `x-smriti-trace-id` correlation, Prometheus metrics, append-only audit log of admin actions, edge traversal in Cypher (`MATCH (n)-[:SOURCE_FROM]->(m)`), persistent HNSW + RelTable across restarts. The boring server in front of the interesting database.

### `vahini` — streaming WAL replication

Sanskrit *vāhinī* — "the flowing channel." Tails the FFS WAL on a primary, ships records to N followers, fsyncs on the replica side, surfaces lag. No consensus, no quorum writes — single primary, async fan-out, failover via DNS / proxy flip. The deployment-side answer to "what happens when the smriti host dies."

### `bija` — local embedding service

Sanskrit *bīja* — "the seed." candle-backed sentence-transformer behind an OpenAI-shape `/v1/embeddings` endpoint. Removes OpenAI as a hard dep on the smriti write path. Persistent KV cache so the same input doesn't re-run the model. The model lives next to the data.

### `flow` — system-of-record change-data-capture

Streams deltas from any operational source — Postgres, MySQL, SaaS APIs (Salesforce, NetSuite, Stripe, Zendesk, Linear, …), SAP / Oracle / Dynamics for ERP, message queues, file watchers — into smriti as typed agent-memory events with `source_event_ids` lineage. The pipe that turns "agent memory" into **a live mirror of the business** — without it, the agent reasons in a vacuum.

---

## ✦ Agent tier

> The runtime that loops memory + tools + LLMs. Where decisions become events.

### `karta` — agent runtime

Sanskrit *kartā* — "the doer." Loads a skill spec, plans with an LLM (any OpenAI-shape endpoint), executes a tool, writes the result back to smriti with `source_event_ids` lineage, plans again with the new memory in context. Single Rust binary. LLM-provider-agnostic. Audit-trail by construction.

Unbundles what every framework today bundles together: memory is smriti's job, capability specs are skills' job, LLM calls are an HTTP-shaped trait. The runtime is the smallest thing that drives the loop correctly.

### `skills` — open enterprise skill stack

50+ skills covering accounting, HR, procurement, support, ops. Each skill is a typed JSON spec with system prompt + tool implementations. Open source. Composable. Versioned. The capability catalogue agents pull from.

### `crucible` — deterministic replay

Walks a smriti audit trail backwards from any event id and reconstructs the karta agent's decision tree. Re-runs the same chain against a counterfactual (different prompt, different model, different memory state) and shows the structural diff. The post-mortem tool for non-deterministic agent fleets.

### Planned: `yantra` — multi-agent orchestrator

For workflows that span more than one agent run (e.g., "monthly close" — 30+ agents, days of wall-clock time, approvals, retries, hand-offs). Sanskrit *yantra* — "the engine / framework." Sketched, not built.

---

## ✦ Intelligence tier

> What turns events into insight: process mining, forecasting, document understanding, anomaly detection.

### `gnn` — process mining with graph attention networks

Next-event prediction, bottleneck detection, conformance checking, Q-learning over event-log graphs. PyTorch + PM4Py + Rust hot paths. Crawls the event graph smriti stores — works equally on procurement workflows, support-ticket flows, sales-order processes, recruiting funnels, anything event-shaped — and finds the actual process, not the one in the SOP doc.

### Planned: `drishti` — document understanding

Sanskrit *dṛṣṭi* — "vision." Invoice / PO / contract extraction with structured output into smriti. The pipe from PDFs to typed events.

### Planned: `gauge` — forecasting + anomaly

Demand forecasting, cash-flow prediction, anomaly detection over the same event substrate everything else uses. No separate warehouse, no separate pipeline.

### Planned: `lekhak` — narrative / report generator

Sanskrit *lekhak* — "writer." Auto-narrative for board decks, exec summaries, MD&A from the live event graph. Read-only against smriti.

---

## ✦ Interface tier

> What humans and agents actually touch.

### `clickr` — natural-language CLI for ClickHouse®

Text-to-SQL with local or cloud LLMs. The terminal-native edge of the analytics stack.

### `neo` — agent console for finance, ops, HR, sales, support

Local-first desktop app for talking to and running AI agents. Tool-loop, typed permissions, file-based memory, model-agnostic (Claude / Gemini / GLM / Ollama). Signed binaries for macOS / Linux / Windows in [`neo-releases`](https://github.com/erphq/neo-releases) (publish in flight).

### Planned: web app, mobile, voice

The conversational and dashboard surface. One identity, one event stream, one set of skills underneath — different rendering targets above. Designed once the agent + memory + intelligence tiers are battle-hardened.

---

## ✦ The verticals

The substrate is vertical-agnostic. The same `smriti` + `karta` + `bija` + `flow` stack delivers radically different products depending on which connectors run, which skills load, and which surfaces ship. Some examples of what fits on it:

| Vertical | Source-of-record `flow` connects to | Skills `karta` runs |
|---|---|---|
| **Finance / ERP** | Postgres-backed ERPs (Odoo, ERPNext), SAP, Oracle EBS / Fusion, NetSuite, Microsoft Dynamics, QuickBooks | journal entry review, AP automation, AR collections, FP&A narrative, month-end close |
| **CRM / Sales** | Salesforce, HubSpot, Pipedrive | lead enrichment, deal-risk triage, account research, quote drafting |
| **Support / Helpdesk** | Zendesk, Intercom, Freshdesk, ServiceNow | ticket triage, response drafting, knowledge-base sync, SLA-breach prediction |
| **ITSM / DevOps** | Linear, Jira, PagerDuty, GitHub | incident triage, post-mortem drafting, runbook execution, change-risk scoring |
| **HR / Recruiting** | Workday, BambooHR, Greenhouse, Lever | candidate screening, scheduling, offer-letter drafting, onboarding |
| **Billing / Revenue** | Stripe, Chargebee, Recurly | dunning, churn-risk scoring, refund triage, revenue recognition |
| **Procurement** | Coupa, Ariba, ERP modules | vendor onboarding, PO matching, contract review, spend analysis |
| **Marketing / Growth** | Marketo, Customer.io, Iterable, Mixpanel | campaign analysis, audience-segment generation, copy drafting |

Every row above is the same stack underneath. The product differences are: which connector `flow` runs (one row's worth), which skill bundle `karta` loads (one library), which interface ships (chat / dashboard / CLI / mobile). Months of integration work for traditional SaaS; days for ours.

---

## ✦ What's open here

The repos linked below are public. The rest of the stack named above is internal until each piece is ready to leave the building.

| Repo | What it does |
|---|---|
| [`GNN`](https://github.com/erphq/GNN) | Process mining with Graph Attention Networks. Next-event prediction, bottleneck detection, conformance, Q-learning. |
| [`clickr`](https://github.com/erphq/clickr) | Natural-language CLI for ClickHouse®. Text-to-SQL with local or cloud LLMs. |
| [`skills`](https://github.com/erphq/skills) | The open enterprise skill stack. 50+ Claude Code skills covering accounting, HR, procurement, support, ops. |
| [`neo-releases`](https://github.com/erphq/neo-releases) | Signed binaries for Neo, our agent console for finance / ops / HR / sales / support. macOS / Linux / Windows. |

---

## ✦ Coverage map

What an AI-native enterprise stack needs, what we have, what's still ⏳.

Symbols: ✅ shipped (one of our repos) · 🟡 partial / in flight · ⏳ planned · ◯ deliberately not building

| Slot | Status | Repo / Note |
|---|:---:|---|
| **Storage tier** | | |
| Embedded graph + vector + columnar engine | ✅ | `FFS` |
| Managed memory service over the engine | ✅ | `smriti` |
| Streaming replication / HA | ✅ | `vahini` |
| Change-data-capture from operational sources | 🟡 | `flow` (Postgres connector first; ERP / SaaS / queue connectors planned) |
| Local embedding service | 🟡 | `bija` (model loader in flight) |
| Schema persistence across restarts | ⏳ | blocked on FFS catalog persistence |
| Property projection in queries | ⏳ | blocked on FFS columnar read API |
| Multi-region / multi-leader replication | ⏳ | v2 — `vahini` is single-primary |
| **Agent tier** | | |
| Agent runtime (loop + audit) | 🟡 | `karta` |
| Skill catalogue (typed capability specs) | ✅ | `skills` |
| Deterministic replay / forensics | 🟡 | `crucible` |
| Multi-agent orchestration / long workflows | ⏳ | planned: `yantra` |
| Sandboxed tool execution (WASM) | ⏳ | v2 — runs in-process today |
| Cost / token governance | ⏳ | planned |
| Approvals / 4-eyes for sensitive actions | ⏳ | planned (likely a `karta` skill type) |
| **Intelligence tier** | | |
| Process mining (graph-attention) | ✅ | `gnn` |
| Document understanding (invoices, POs, contracts) | ⏳ | planned: `drishti` |
| Forecasting + anomaly detection | ⏳ | planned: `gauge` |
| Narrative / report generation | ⏳ | planned: `lekhak` |
| Voice / transcription | ⏳ | planned |
| **Interface tier** | | |
| Natural-language CLI (analytics) | ✅ | `clickr` |
| Local-first agent console | ✅ | `neo-releases` |
| Conversational UI (chat-with-agent) | ⏳ | planned |
| Web dashboard / forms surface | ⏳ | planned |
| Mobile / offline | ⏳ | planned |
| Email / Slack / Teams integration | ⏳ | planned (likely `karta` skills + a thin connector) |
| **Operator tier** | | |
| Identity / SSO / SAML | ⏳ | v1 = API keys with scopes; OIDC is v2 |
| Secrets management | ⏳ | use whatever the operator already runs |
| Per-tenant rate limits + quotas | ✅ | built into `smriti` |
| Audit log | ✅ | built into `smriti` |
| Per-request correlation header | ✅ | built into `smriti` (`x-smriti-trace-id`) |
| Prometheus metrics | ✅ | built into `smriti` |
| Helm chart | ⏳ | when production deploy is on the table |
| **Quality tier** | | |
| Integration test suites per service | ✅ | each Rust service ships tests |
| CI on every push (fmt + clippy + test + docker) | ✅ | each Rust service has it |
| Property-based + fuzz testing | ⏳ | v2 |
| Model evaluation harness | ⏳ | v2 |
| **What we're not building** (for now) | | |
| A general-purpose vector DB | ◯ | `smriti` is agent-memory specific |
| An LLM gateway / proxy | ◯ | use LiteLLM / Ollama / direct |
| A data warehouse | ◯ | use ClickHouse / DuckDB / Snowflake |
| Our own foundation model | ◯ | not the bet |

---

## ✦ What we believe

- **Local-first.** The model goes where the data is. Cloud round-trips are an admission of failure, not a feature.
- **Typed contracts.** Schema enforced at the storage boundary, not in an application layer above. Errors caught at compile, not in production.
- **Composable skills.** Every business process is a skill. Skills compose. Skills ship in less than an hour.
- **Agents that do work.** Tool-loop, typed permissions, real outcomes. Not chat-only demos.
- **Audit trail by construction.** Every step writes events with lineage. Forensics is a query, not a feature request.
- **One language down the stack.** Rust. Top to bottom. Boring is the point.

---

## ✦ CI status — refreshed hourly

A live roll-up of the **public** org surface area so an agent (or human) opening this page each morning can see at a glance what's tested, what's running, and what's red. The window is "since 00:00 UTC today." Refreshed every hour by [`refresh-status.yml`](https://github.com/erphq/.github/blob/main/.github/workflows/refresh-status.yml). Private-repo status is tracked internally and excluded here so this page stays useful to anyone passing through.

<!-- BEGIN: ci-status -->
_Last refreshed: 2026-05-12 03:20 UTC. Window: runs created since 00:00 UTC today (`2026-05-12T00:00:00Z`)._

| Repo | Tests | Runs today | ✅ pass | ❌ fail | ⚠️ other |
|---|---:|---:|---:|---:|---:|
| [`GNN`](https://github.com/erphq/GNN) | 110 | 0 | 0 | 0 | 0 |
| [`clickr`](https://github.com/erphq/clickr) | 46 | 0 | 0 | 0 | 0 |
| [`cypher-rs`](https://github.com/erphq/cypher-rs) | 130 | 0 | 0 | 0 | 0 |
| [`erpai-cli`](https://github.com/erphq/erpai-cli) | — | 0 | 0 | 0 | 0 |
| [`erpai-cli-releases`](https://github.com/erphq/erpai-cli-releases) | — | 0 | 0 | 0 | 0 |
| [`erpai-pages-runtime`](https://github.com/erphq/erpai-pages-runtime) | — | 0 | 0 | 0 | 0 |
| [`mcprec`](https://github.com/erphq/mcprec) | 80 | 0 | 0 | 0 | 0 |
| [`neo-releases`](https://github.com/erphq/neo-releases) | — | 0 | 0 | 0 | 0 |
| [`pm-bench`](https://github.com/erphq/pm-bench) | 232 | 0 | 0 | 0 | 0 |
| [`pm-rag`](https://github.com/erphq/pm-rag) | 77 | 0 | 0 | 0 | 0 |
| [`skillcheck`](https://github.com/erphq/skillcheck) | 77 | 0 | 0 | 0 | 0 |
| [`skills`](https://github.com/erphq/skills) | — | 0 | 0 | 0 | 0 |
| **Total** | **752** *(across 7 badged repos)* | **0** | **0** | **0** | **0** |

> "Other" covers cancelled / skipped / in-progress / neutral runs. "Tests" is read from each repo's README `tests-N passing` badge — repos without a badge show `—`.
<!-- END: ci-status -->

---

## ✦ Why Sanskrit names

You'll see Sanskrit in the project names: `smriti` (memory), `karta` (the doer), `vahini` (the flowing channel), `bija` (the seed). Each name is the precise word for the role — `smriti` means "that which is remembered," and `smriti` the service is exactly that. Words that survived three thousand years of use earn their semantic load.

---

## ✦ Get in touch

- [erp.ai](https://erp.ai)
- security@erp.ai for vulnerabilities (see [SECURITY.md](https://github.com/erphq/.github/blob/main/SECURITY.md))

<div align="center">
<sub>San Francisco</sub>
</div>
