<div align="center">

# `erp•ai`

### the engine behind erp.ai, build.host, and krawler.com

</div>

A 40-repo engineering org behind three live products: [erp.ai](https://erp.ai), [build.host](https://build.host), [krawler.com](https://krawler.com). ~1,850 tests across Rust, Python, and TypeScript. The product platforms are private; the engine that runs underneath them is open here.

> 🗺 **Org members, start here:** [`erphq/MetaRepo`](https://github.com/erphq/MetaRepo) is the architecture map for every repo — layer-by-layer diagrams, the full edge list, and a current-status snapshot of all 40 repositories. New to the org? Skim that, then dive in.

---

## ✦ What's live

**[erp.ai](https://erp.ai)** is the flagship product. AI for the work a business actually runs on — finance, HR, sales, support, operations — sized from small business to large enterprise. The platform that runs it lives in a private monorepo and is not open-sourced.

Two sister brands are also live, in soft-launch:

- **[build.host](https://build.host)** — agent-run deploy infrastructure. The host an agent talks to directly. One prompt in, one URL out. Works with Claude Code, Codex, Neo, or anything that reads a `SKILL.md`.
- **[krawler.com](https://krawler.com)** — the professional network for AI agents. Agents post, comment, follow, and hire. Humans watch.

What ships open under `erphq` is the engine the products run on, plus developer-facing SDKs, the skill catalog, and the agent console.

---

## ✦ What runs underneath

The customer-facing platforms are a set of services not in this org:

- An API gateway in front of all product traffic, with centralized auth, routing, and rate limiting.
- An identity + permissions service with per-tenant scopes and audit.
- An agent runtime that operates the catalog of business apps.
- A UI layer that renders the post-login app surface.
- A tenant-config service that handles custom domains and on-demand TLS.
- An auth SDK that drops into Next.js apps for hosted-app sign-in.
- An app-builder API that turns English specs into running apps.
- Independent services for audit-log, usage metering, attachments, and snapshots.

These services touch customer data and stay closed. The engine they delegate to is open under this org, and is what the rest of this README covers.

---

## ✦ The thesis

Business software today is a stack of separately-bought SaaS: an ERP, a CRM, a helpdesk, a BI tool, three identity providers, a Postgres for transactions, a vector DB for retrieval, a warehouse for analytics, an event bus to keep them in sync. It was built for humans clicking forms.

Agent-driven software is a different workload. An agent fleet writes thousands of typed events per second, every one carrying lineage from the row that produced it to the decision that consumed it. To run that workload, the storage, the memory, the runtime, the replication, the change-capture, and the skill layer all have to be designed for agent traffic rather than bolted on top of stores built for human-paced SQL.

Once an engine like that exists, every category of business software can be rebuilt as a thin layer of skills and UI on top of it. ERP is the first category we're attacking. The same engine runs CRM, support, ITSM, billing, project management, FP&A, recruiting.

---

## ✦ The stack

```text
┌────────────────────────────────────────────────────────────────────────┐
│  interface tier            chat · CLI · IDE assistant · desktop        │
│                            neo · clickr · erpai-cli · shruti           │
├────────────────────────────────────────────────────────────────────────┤
│  agent tier                runtime · replay · skill catalog            │
│                            karta · crucible · agents · skills          │
├────────────────────────────────────────────────────────────────────────┤
│  intelligence tier         process mining · code intel · MDM           │
│                            processmind · GNN · codegraph · voronoi     │
├────────────────────────────────────────────────────────────────────────┤
│  identity tier             auth · risk scoring · sandboxed plugins     │
│                            agentsmith                                  │
├────────────────────────────────────────────────────────────────────────┤
│  memory tier               agent memory · embeddings                   │
│                            smriti · bija                               │
├────────────────────────────────────────────────────────────────────────┤
│  ingest tier               ERP CDC · WAL replication                   │
│                            flow · vahini                               │
├────────────────────────────────────────────────────────────────────────┤
│  storage tier              graph + vector + columnar engine            │
│                            FFS · cypher-rs                             │
└────────────────────────────────────────────────────────────────────────┘
```

Each tier is independently replaceable across an HTTP or process boundary.

---

## ✦ What's open under this org

40 repos total — 13 public, 7 internal (org-only), 18 private active, 2 archived. ~1,850 tests across the active set. The public surface, by layer:

| Layer | Repo | Lang | What it does |
|---|---|---|---|
| Storage | [`cypher-rs`](https://github.com/erphq/cypher-rs) | Rust | openCypher front-end: lex, parse, semantic analysis, logical plan, optimizer, cost model. Storage-agnostic. v0.10.0, 130 tests. |
| Process mining | [`GNN`](https://github.com/erphq/GNN) | Python | Graph-attention networks over event logs. Next-event prediction, bottleneck detection, conformance, Q-learning. v0.4.1, 110 tests. |
| Process mining | [`pm-bench`](https://github.com/erphq/pm-bench) | Python | Open process-mining benchmark — datasets, splits, scoring, leaderboard. 232 tests. |
| Process mining | [`pm-rag`](https://github.com/erphq/pm-rag) | Python | Process-aware retrieval over event traces. Graph diffusion conditioned on process state. v0.6.0, 77 tests. |
| Skills | [`skills`](https://github.com/erphq/skills) | — | 50+ Claude Code skills covering accounting, HR, procurement, support, ops. Vendor-neutral, MCP-native. |
| Skills | [`skillcheck`](https://github.com/erphq/skillcheck) | TS | Static analyzer for Claude Code skills. Lints manifests, verifies refs, catches trigger collisions. SARIF reporter. v0.6.0, 70 tests. |
| Tooling | [`mcprec`](https://github.com/erphq/mcprec) | TS | Record and replay any MCP server. Stdio + HTTP/SSE transports. v0.5.0, 80 tests. |
| Agent UX | [`clickr`](https://github.com/erphq/clickr) | Python | Natural-language CLI for ClickHouse. Text-to-SQL with local or cloud LLMs. v1.0.3, 46 tests. |
| Agent UX | [`neo-releases`](https://github.com/erphq/neo-releases) | — | Signed binaries and auto-update manifests for Neo, the agent console. macOS / Linux / Windows. |
| Agent UX | [`erpai-cli`](https://github.com/erphq/erpai-cli) · [`erpai-cli-releases`](https://github.com/erphq/erpai-cli-releases) | — | Natural-language CLI for ERP data. Source is a placeholder; signed binaries and Next.js download page ship from the `-releases` repo. |
| Browser SDK | [`erpai-pages-runtime`](https://github.com/erphq/erpai-pages-runtime) | JS | Browser runtime for sandboxed ERPAI custom HTML pages. `window.erpai`: SQL/records, formatters, theme, charts. v2.2.0. |
| Org meta | [`.github`](https://github.com/erphq/.github) | Shell | This file plus org community-health files and an hourly CI-status refresh workflow. |

The rest — `FFS`, `smriti`, `karta`, `crucible`, `flow`, `vahini`, `bija`, `agentsmith`, `processmind`, `codegraph`, `neo`, `build-host`, `lab-sites`, `voronoi`, `functor`, and others — is private during active development. `MetaRepo` (internal) carries the full architecture map.

---

## ✦ The engine, by tier

### Storage

`FFS` is a single-file embedded database — property graph, HNSW vector index, columnar reads, MVCC, WAL, typed schema — built for the write workload an agent fleet produces. `cypher-rs` is the openCypher front-end FFS plugs in (and that any other graph store could plug in). `vahini` ships WAL frames from a primary FFS to N replicas, byte-identical, no consensus. `bija` is the local embedding service that turns text into the vectors smriti's HNSW index needs: candle-backed sentence-transformer behind an OpenAI-shape `/v1/embeddings` endpoint.

### Memory

`smriti` is the multi-tenant HTTP service in front of FFS. Scoped tokens (`read` / `write` / `admin`), per-tenant rate limits, append-only audit log, Cypher edge traversal, persistent HNSW across restarts, Prometheus metrics, `x-smriti-trace-id` correlation. Holds the full event history with lineage from operational row to derived fact.

### Ingest

`flow` is change-data-capture from the operational source of record into smriti as typed agent-memory events with `source_event_ids` lineage. Postgres logical replication is in flight; SAP, Oracle, NetSuite, and SaaS APIs follow.

### Agent runtime + audit

`karta` is the runtime that loops memory, tools, and an LLM. Loads a skill spec, plans with any OpenAI-shape endpoint, executes a tool, writes the result back to smriti with lineage, plans again. Single Rust binary, LLM-agnostic, audit trail by construction. `crucible` walks a smriti audit trail from any event id, reconstructs karta's decision tree, and replays it against counterfactual inputs to show structural diffs. `agents` is a GNN-based ensemble (predictor, bottleneck-spotter, allocator) for graph-shaped problems.

### Intelligence

`processmind` is the streaming process-mining product on top of smriti — discovers, monitors, predicts. End-to-end pipeline with GNN ONNX inference and a single-page UI. `GNN`, `pm-bench`, and `pm-rag` are the open companions: the model library, the open benchmark, and the process-aware retrieval research.

### Code intelligence

`codegraph` is multi-signal graph diffusion for code context: 14 graph algorithms, 8 signal sources (AST, calls, types, imports). RAG without embeddings. Recall 0.698 on SWE-bench Verified at 8K tokens (p < 0.0001), ahead of BM25 and ego-graph baselines.

### Identity

`agentsmith` is the auth platform every other service delegates to. Built as a plugin on `better-auth`, so the existing better-auth ecosystem (`twoFactor`, `passkey`, OAuth providers) composes rather than being reimplemented. Ships with a 3-stage anomaly engine (EMA + multivariate Gaussian + LLM judge), a signed WASM plugin sandbox (ed25519 manifest, wasmtime, fuel + memory caps), and AEAD storage. The long-term direction is full Clerk-equivalence for agent-driven SaaS: orgs, RBAC, JWTs, webhooks, magic links.

### Master data + migration

`voronoi` is the master-data resolution studio: vector-similarity entity matching via bija + HNSW, steward review queues, golden-record graph in smriti. `functor` is the legacy-schema mapping copilot: profiles SAP / Oracle / mainframe DDL with codegraph, generates versioned mapping specs, replays via crucible.

### Skills + MCP

`skills` is the open catalog — 50+ Claude Code skills covering accounting, HR, procurement, support, ops. `enterprise-skills` is the production variant. `erpai-builder-skills` are the skills that build apps from English prompts. `skillcheck` is the static analyzer. `mcprec` records and replays any MCP server for deterministic agent-tool tests. `gitlab-mr-mcp` is the MCP server for GitLab merge requests.

### Agent UX

`neo` is the local-first desktop console — Tauri v2 + React 19, 26 built-in tools, typed permissions, file-based memory, MCP, sub-agents. Loads `skills`, `enterprise-skills`, `appskills`, and `lab-opskills` at runtime; calls `karta` for agent loops; calls `mcprec` for record/replay. `clickr` is the natural-language ClickHouse CLI. `shruti` joins Zoom / Meet, records, diarizes, and turns speech into `spec.json` the agent can consume. `erpai-cli` is the NL CLI for ERP data.

### Browser runtime

`erpai-pages-runtime` is the browser SDK for agent-generated HTML pages — the contract between an agent's page output and the iframe it runs in. `window.erpai`: SQL/records, formatters, dropdowns, theme, Tabler icons, charts.

### Marketplace

`krawler` is the codebase behind krawler.com. Identity and lifecycle, per-agent `SKILL.md`, follow graph, log-scaled reputation, hiring, completions, signals, search. Linked installs via `agent_pair_tokens`.

### Distribution + hosting

`build-host` is the deploy host behind build.host: agent-friendly TLS, logs, metrics, rollback, no pipelines to configure. `lab-sites` carries the public web properties. `neo-releases` and `erpai-cli-releases` carry signed binaries and auto-update manifests.

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
| Multi-agent orchestration / long workflows | ⏳ | planned |
| Sandboxed tool execution (WASM) | 🟡 | shipped in `agentsmith` plugin sandbox; karta still runs tools in-process |
| Cost / token governance | ⏳ | planned |
| Approvals / 4-eyes for sensitive actions | ⏳ | planned (likely a `karta` skill type) |
| **Intelligence tier** | | |
| Process mining (graph-attention) | ✅ | `processmind` · `GNN` |
| Process-aware retrieval | ✅ | `pm-rag` |
| Open process-mining benchmark | ✅ | `pm-bench` |
| Code intelligence / graph RAG | ✅ | `codegraph` |
| Document understanding (invoices, POs, contracts) | ⏳ | planned |
| Forecasting + anomaly detection | ⏳ | planned |
| Narrative / report generation | ⏳ | planned |
| Voice / transcription | 🟡 | `shruti` (meeting capture) |
| **Identity tier** | | |
| Auth + sessions + risk scoring | ✅ | `agentsmith` v3 |
| Sandboxed plugin execution | ✅ | `agentsmith` (signed WASM, ed25519, wasmtime) |
| Orgs / RBAC / JWT issuance | 🟡 | `agentsmith` Phase 2 (Clerk-equivalence) |
| Magic links / OAuth / passkeys | 🟡 | via `better-auth` providers, surfaced through `agentsmith` |
| **Master data + migration** | | |
| Entity resolution (vector-similarity) | 🟡 | `voronoi` (scaffold) |
| Legacy schema mapping copilot | 🟡 | `functor` (scaffold) |
| **Interface tier** | | |
| Natural-language CLI (analytics) | ✅ | `clickr` |
| Natural-language CLI (ERP data) | 🟡 | `erpai-cli` (releases; source private) |
| Local-first agent console | ✅ | `neo` · `neo-releases` |
| Browser runtime for agent-generated pages | ✅ | `erpai-pages-runtime` |
| Meeting agent | 🟡 | `shruti` |
| **Operator tier** | | |
| Per-tenant rate limits + quotas | ✅ | built into `smriti` |
| Audit log | ✅ | built into `smriti` |
| Per-request correlation header | ✅ | built into `smriti` (`x-smriti-trace-id`) |
| Prometheus metrics | ✅ | built into `smriti` |
| Identity / SSO / SAML | 🟡 | `agentsmith` (Clerk-equivalence in flight) |
| Helm chart | ⏳ | when production deploy is on the table |
| **Quality tier** | | |
| Integration test suites per service | ✅ | each service ships tests; ~1,850 across the org |
| CI on every push | ✅ | fmt + clippy + test + docker on Rust; ruff + pytest on Python |
| Property-based + fuzz testing | ⏳ | v2 |
| Model evaluation harness | 🟡 | `pm-bench` for process mining; broader harness planned |
| **What we're not building** (for now) | | |
| A general-purpose vector DB | ◯ | `smriti` is agent-memory specific |
| An LLM gateway / proxy | ◯ | use LiteLLM / Ollama / direct |
| A data warehouse | ◯ | use ClickHouse / DuckDB / Snowflake |
| Our own foundation model | ◯ | not the bet |

---

## ✦ CI status — refreshed hourly

A live roll-up of the **public** org surface area so an agent (or human) opening this page each morning can see what's tested, what's running, and what's red. The window is "since 00:00 UTC today." Refreshed every hour by [`refresh-status.yml`](https://github.com/erphq/.github/blob/main/.github/workflows/refresh-status.yml). Private-repo status is tracked internally and excluded here so this page stays useful to anyone passing through.

<!-- BEGIN: ci-status -->
_Last refreshed: 2026-05-12 07:14 UTC. Window: runs created since 00:00 UTC today (`2026-05-12T00:00:00Z`)._

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

## ✦ Get in touch

- [erp.ai](https://erp.ai)
- security@erp.ai for vulnerabilities (see [SECURITY.md](https://github.com/erphq/.github/blob/main/SECURITY.md))

<div align="center">
<sub>San Francisco</sub>
</div>
