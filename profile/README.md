<div align="center">

# `erp•ai`

### AI-native enterprise software, top to bottom

</div>

Infrastructure. Agents. Tools. Skills. Every repo in this org is one of those four. Composable. MCP-native. Local-first where it matters.

## ✦ Where to start

| You want to | Repo |
|---|---|
| **Embed a graph + vector DB** | [`FFS`](https://github.com/erphq/FFS) · Cypher · HNSW · MVCC · Rust · one file |
| **Ask English of your ClickHouse warehouse** | [`clickr`](https://github.com/erphq/clickr) · text-to-SQL CLI |
| **Drop AI into a terminal** | [`neo`](https://github.com/erphq/neo) · agentic terminal · TypeScript · local-first |
| **Build an ERP from English** | [`erpai-builder-skills`](https://github.com/erphq/erpai-builder-skills) · schema · tables · workflows |
| **Mine your event logs with GNNs** | [`GNN`](https://github.com/erphq/GNN) · GAT · LSTM · Q-learning · PM4Py |
| **Deploy via Claude Code** | [`build-host`](https://github.com/erphq/build-host) · `*.build.host` · no CI/CD |
| **Browse the open skill stack** | [`skills`](https://github.com/erphq/skills) · SDStack · 50+ skills |

## ✦ The four layers

```text
infrastructure   FFS · build-host · neo
agents           GNN · agents · agentsmith · processmind · codegraph
tools            clickr · erpai-cli · neo · gitlab-mr-mcp
skills           skills · enterprise-skills · erpai-builder-skills · lab-opskills · appskills
```

## ✦ What we believe

- **Local-first.** Models in browsers, on laptops, in CLIs. Not cloud round-trips for things that should be free.
- **Typed contracts.** Schema enforced at the storage boundary, not in an application layer above. Errors caught at compile, not in production.
- **Composable skills.** Every business process is a skill. Skills compose. Skills ship in less than an hour.
- **One engine.** Graph, vector, columnar in one place. Not three systems duct-taped with FK columns.
- **Agents that actually do work.** Not chat-only. Tool-loop, typed permissions, real outcomes.

<div align="center">
<sub>San Francisco · audited from goals.md down · ADR-driven</sub>
</div>
