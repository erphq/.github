<div align="center">

# `erp•ai`

### AI-native enterprise software, top to bottom

The storage engine, the agents that operate on it, the runtime that drives them, the skills that compose them, and the interfaces that surface them — all designed together, in one stack, in Rust.

</div>

---

## ✦ The thesis

Enterprise software today is a graveyard of stitched-together SaaS. An ERP. A CRM. A ticketing system. A BI tool. A file store. Three separate identity providers. A Postgres for transactions, a vector DB for retrieval, a graph DB for relationships, a warehouse for analytics, an event bus to keep them in rough sync. Twelve dashboards, one source of truth — usually wrong.

That stack was built for humans clicking forms. AI-native enterprise software is built for **agents writing thousands of events per second** with full lineage, full typing, and full audit. That's a different shape. Vector-DBs-bolted-on-Postgres do not become AI-native by adding `embedding VECTOR(384)`. Tool-loops over OpenAI Assistants do not become AI-native by adding `if (tool === "send_email")`.

You have to redesign the storage so the writes the agents emit don't drown it. You have to redesign the auth so per-key scopes and audit trails are a default, not a bolt-on. You have to redesign the memory so it's typed, queryable, vector-searchable, **and** graph-walkable in one shot. You have to redesign the runtime so every step is auditable by construction. You have to redesign the embeddings, the replication, the CDC, the replay, the skills.

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

### `flow` — ERP change-data-capture

Streams Postgres / SAP / Oracle / NetSuite deltas into smriti as typed agent-memory events with `source_event_ids` lineage. The pipe that turns "agent memory" into **ERP-AI memory** — without it, the agent reasons in a vacuum.

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

Next-event prediction, bottleneck detection, conformance checking, Q-learning over event-log graphs. PyTorch + PM4Py + Rust hot paths. Crawls the event graph smriti stores and finds the actual process — not the one in the SOP doc.

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

### `neo` — local-first agentic coding assistant

Signed binaries for macOS / Linux / Windows in [`neo-releases`](https://github.com/erphq/neo-releases). Tool-loop, typed permissions, runs locally.

### Planned: web app, mobile, voice

The conversational and dashboard surface. One identity, one event stream, one set of skills underneath — different rendering targets above. Designed once the agent + memory + intelligence tiers are battle-hardened.

---

## ✦ What's open here

The repos linked below are public. The rest of the stack named above is internal until each piece is ready to leave the building.

| Repo | What it does |
|---|---|
| [`GNN`](https://github.com/erphq/GNN) | Process mining with Graph Attention Networks. Next-event prediction, bottleneck detection, conformance, Q-learning. |
| [`clickr`](https://github.com/erphq/clickr) | Natural-language CLI for ClickHouse®. Text-to-SQL with local or cloud LLMs. |
| [`skills`](https://github.com/erphq/skills) | The open enterprise skill stack. 50+ Claude Code skills covering accounting, HR, procurement, support, ops. |
| [`neo-releases`](https://github.com/erphq/neo-releases) | Signed binaries for Neo, our local-first agentic coding assistant. macOS / Linux / Windows. |

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
| ERP change-data-capture | 🟡 | `flow` (Postgres connector first) |
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
| Local-first coding assistant | ✅ | `neo-releases` |
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

## ✦ Why Sanskrit names

You'll see Sanskrit in the project names: `smriti` (memory), `karta` (the doer), `vahini` (the flowing channel), `bija` (the seed). Each name is the precise word for the role — `smriti` means "that which is remembered," and `smriti` the service is exactly that. Words that survived three thousand years of use earn their semantic load.

---

## ✦ Get in touch

- [erp.ai](https://erp.ai)
- security@erp.ai for vulnerabilities (see [SECURITY.md](https://github.com/erphq/.github/blob/main/SECURITY.md))

<div align="center">
<sub>San Francisco</sub>
</div>
