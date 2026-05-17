# Supply-chain policy and remediation plan

Living document. Tracks the org-wide program to reduce dependency-supply-chain risk across `erphq` repos.

- **Long-term goal:** every critical open-source dependency the closed services rely on is forked under `erphq` and pinned by git URL + commit SHA, so a compromised upstream maintainer can't inject code into our running services through a routine version bump.
- **Scope today:** **closed services only** (the 18 private active repos + the 7 internal-visibility repos). The 13 public repos remain on public registries during Phase 1 and Phase 2; revisit after Phase 2 ships.
- **Status:** Phase 0 — baseline hygiene — pending kick-off. No forks exist yet.

> Tracking issue with phase checklists: [`erphq/MetaRepo` #TBD](https://github.com/erphq/MetaRepo/issues) (link added when issue is filed).

---

## 1 · Why this exists

Today every repo in `erphq` pulls dependencies directly from `crates.io`, `npm`, and `PyPI` with no centralized supply-chain controls. A single compromised maintainer of `serde` / `next` / `better-auth` / `wasmtime` / `torch` can land code in our agent runtime, our auth platform, our customer-facing surfaces — anywhere — through any routine version bump.

The forks-under-erphq model breaks that chain: consumers pin by SHA to our fork, and upstream releases land only after a sync PR has been reviewed by a human.

This isn't a one-time exercise. It's a sustained operational commitment that replaces some of what Dependabot does for free with human-reviewed sync PRs. The remediation plan below sequences that work so the most-critical surfaces are covered first.

---

## 2 · Baseline (audited 2026-05-17)

| Control | Coverage today |
|---|---|
| Forks of any OSS dep under `erphq` | **0** — every dep comes from public registries |
| Private registry / `.npmrc` override | **0 repos** |
| `cargo-deny` / `cargo-audit` / `cargo-vet` | **0 of 9** Rust repos |
| `pip-audit` / `safety` / `bandit` | **0 of 7** Python repos |
| `npm/pnpm audit` in CI | **0 of 13** TS/JS repos |
| `socket.dev` / `snyk` / `osv-scanner` / `lockfile-lint` | **0 anywhere** |
| Dependabot | 2/7 Python · 5/13 TS · 0/9 Rust |
| CodeQL | 1 of 40 (only `neo`) |
| `Cargo.lock` committed in binary crates | **2 of 9** (`FFS`, `agentsmith`) — 7 binaries ship with no lockfile |
| `pnpm-lock.yaml` committed | absent in `agentsmith` workspaces |
| Existing fork-as-git-URL pattern | **1 working example**: `neo` → `github:erphq/erpai-pages-runtime#v2.2.0` |
| `pnpm.onlyBuiltDependencies` allowlist | **1 of 13** (`krawler`) |

The lockfile gap is more urgent than the forking question — seven Rust binaries currently build non-reproducibly, so even before forks land we can't pin a known-good transitive tree.

---

## 3 · Highest-risk surfaces (where compromise hurts most)

| Repo | Why it's load-bearing | Worst-case dep on the trust path |
|---|---|---|
| `agentsmith` | Auth platform every service delegates to. Crypto stack + WASM sandbox + DB. | `wasmtime` (runs untrusted plugin code), `ed25519-dalek` (manifest signature verify), `chacha20poly1305` (AEAD), `rusqlite` |
| `krawler/api` | Public API behind krawler.com; full auth + DB + payments-adjacent. | `better-auth 1.6.10`, `fastify 5.x`, `pg`, `drizzle-orm`, `ioredis`, `resend` |
| `build-host` | Deploy-infra dashboard with auth + DOMPurify on user input. | `next 16.x`, `better-auth ^1.6.10`, `marked`, `isomorphic-dompurify` |
| `neo` | Tauri desktop binary shipped to users; heavy postinstall surface. | `@tauri-apps/cli`, `tauri-plugin-mcp 0.1.0` (pre-1.0 native!), `better-sqlite3` |
| `smriti` | Multi-tenant memory service in front of FFS. | `axum`, `reqwest`, `rusqlite`, `sha2` — **no `Cargo.lock` committed** |
| `gitlab-mr-mcp` | MCP server with stale `@modelcontextprotocol/sdk ^0.5.0` (vs 1.27 in neo). | drifted MCP SDK + `axios ^1.6.0` (known CVEs since) |
| `processmind` | Streaming product, model loader + DB driver. | `torch`, `onnxruntime`, `fastapi`, `neo4j`, `mcp` |
| `codegraph` | LLM + MCP path. | `anthropic`, `mcp`, several scientific wheels with C ext |
| `cypher-rs` (public) | Public crate consuming untrusted Cypher input. | `pest` / `pest_derive` |

---

## 4 · Fork prioritization

### Wave 1 — crypto + auth + agent SDKs (12 deps)

| # | Dep | Ecosystem | Consumed by | Why first |
|---:|---|---|---|---|
| 1 | `wasmtime` | rust | agentsmith | Runs untrusted plugin code; the sandbox itself |
| 2 | `ed25519-dalek` | rust | agentsmith | Verifies signed plugin manifests; compromise = signature bypass |
| 3 | `chacha20poly1305` + `hmac` + `sha2` + `subtle` + `zeroize` | rust | agentsmith, smriti | AEAD + MAC stack for secrets-at-rest |
| 4 | `better-auth` + `@better-auth/passkey` | ts | krawler, build-host, agentsmith | Auth trust-boundary across 3 repos |
| 5 | `@modelcontextprotocol/sdk` | ts | neo, gitlab-mr-mcp | Currently drifted (`^0.5.0` vs `^1.27.0`); fork forces reconciliation |
| 6 | `mcp[cli]` | python | codegraph, processmind | Same SDK, Python side, young package, fast-moving |
| 7 | `@anthropic-ai/sdk` | ts | shruti | LLM credential-bearing client, pre-1.0 (`^0.92.0`) |
| 8 | `anthropic` | python | codegraph | Same, Python side |
| 9 | `pyyaml` | python | pm-bench | Classic `yaml.load` RCE path on registry file |
| 10 | `pest` + `pest_derive` | rust | cypher-rs | Parses user-supplied Cypher (deferred — public repo) |
| 11 | `tauri-plugin-mcp 0.1.0` | ts | neo | Pre-1.0 native plugin with install-time build |
| 12 | `better-sqlite3` | ts | neo | Native compilation in user-facing desktop binary |

### Wave 2 — HTTP frameworks + DB drivers + parsers at edge (15 deps)

| # | Dep | Ecosystem | Consumed by |
|---:|---|---|---|
| 13 | `serde` + `serde_json` | rust | 6/9 Rust repos |
| 14 | `axum` + `tower` + `tower-http` | rust | smriti, bija, agentsmith |
| 15 | `reqwest` + `rustls` | rust | 7/9 Rust repos |
| 16 | `rusqlite` | rust | smriti, agentsmith |
| 17 | `fastify` + `@fastify/cors` + `@fastify/sensible` | ts | krawler |
| 18 | `next` | ts | build-host, erpai-cli-releases |
| 19 | `hono` | ts | neo-proxy, neo (overrides) |
| 20 | `fastapi` + `uvicorn` + `pydantic` | python | processmind, agents, GNN serve |
| 21 | `httpx` | python | processmind, agents |
| 22 | `drizzle-orm` + `drizzle-kit` + `pg` | ts | krawler |
| 23 | `neo4j` | python | processmind |
| 24 | `axios` | ts | gitlab-mr-mcp |
| 25 | `onnxruntime` | python | processmind |
| 26 | `marked` + `isomorphic-dompurify` | ts | build-host |
| 27 | `@tauri-apps/cli` + `@tauri-apps/api` + 9 `@tauri-apps/plugin-*` | ts | neo |

### Wave 3 — long tail (rolling)

`torch`, `react`/`react-dom`, `tokio`, `tracing`+`tracing-subscriber`, `clap`, `parking_lot`, `uuid`, `vite`, `tailwindcss`, `zod`, `numpy`, `pandas`, `scikit-learn`, `sentence-transformers`, `dgl`, `tree-sitter`, `pino`, `commander`, `typescript`, etc. Schedule by quarterly budget, not deadline.

---

## 5 · Phased execution plan

### Phase 0 — Baseline hygiene (2 weeks, no forks yet)

Do this **before** any forking. It's cheap, removes immediate risk, and gives Phase 1 a stable foundation.

| Action | Repos | Notes |
|---|---|---|
| Commit `Cargo.lock` to all binary crates | smriti, karta, crucible, flow, vahini, bija | 6 PRs; mechanical |
| Commit `pnpm-lock.yaml` to workspace root | agentsmith | 1 PR |
| Roll out `cargo-deny` + `cargo-audit` CI workflow | all 9 Rust repos | Shared reusable workflow in `erphq/.github/workflow-templates/` |
| Roll out `pip-audit` CI step | all 7 Python repos | Shared reusable workflow |
| Roll out `pnpm audit --prod` / `npm audit --production` CI step | all 13 TS repos | Shared reusable workflow |
| Roll out Dependabot config to remaining repos | 5 Python + 8 TS + 9 Rust | Reusable template per ecosystem |
| Roll out CodeQL to high-value repos | agentsmith, smriti, krawler, build-host, neo, processmind | 6 repos |
| Enforce `pnpm.onlyBuiltDependencies` allowlist | all pnpm repos (krawler, agentsmith, others) | Pattern already exists in krawler |
| Standardize `secret-scan` workflow org-wide | all 40 | Already in some |

Deliverable: PR per repo, plus 3 reusable workflow files in `erphq/.github/workflow-templates/`.

### Phase 1 — Wave 1 forks + fork-sync automation (4 weeks, closed services only)

This is where the forking program starts. Build the automation before the forks so the operational model is in place from day one.

**Infrastructure (week 1, before any fork):**

1. **Naming convention** — `erphq/<name>-fork` for forks of external repos. Avoid name collisions with our own packages.
2. **Fork-sync bot** — reusable workflow at `.github/workflow-templates/fork-sync.yml` that runs daily on every fork repo:
   - Pulls upstream main / latest tag.
   - Opens a PR titled `sync: upstream <tag>` against our fork's `main`.
   - Adds reviewers (the relevant repo's CODEOWNER).
   - Fails CI loudly on merge conflicts so a human is forced to look.
3. **CVE alerting** — `osv-scanner` workflow on every fork repo to catch upstream advisories independent of GitHub's Dependabot.
4. **CODEOWNERS** for fork repos — explicit two-reviewer policy on any merge from upstream.
5. **Pin policy** — consumers always pin by SHA (`rev = "<40-char-sha>"`), never branch (`branch = "main"`) or tag (mutable in our forks). Codify in `cargo-deny` and `lockfile-lint` configs.

**Forks (weeks 2-4):**

Execute the 12 entries from Wave 1 (item 10, `pest` / `pest_derive`, is in a public repo and is **deferred** under the current scope). Per-fork checklist:

- [ ] Fork to `erphq/<name>-fork`
- [ ] Set up fork-sync workflow + CODEOWNERS
- [ ] Pin upstream version (note SHA in the fork's README)
- [ ] Update all consumer repos (closed services only) in one PR per consumer
- [ ] Add `[bans]` entry to consumer's `deny.toml` (Rust) or block in `.npmrc` / `.lockfile-lintrc.json` (TS) to prevent accidental registry use
- [ ] Verify CI passes on consumers

**Special handling for Wave 1:**

- `@modelcontextprotocol/sdk` — reconcile `^0.5.0` (gitlab-mr-mcp) vs `^1.27.0` (neo) drift first. The gitlab-mr-mcp pin is ~2 years stale.
- `better-auth` — currently exact-pinned in `krawler`, range-pinned in `build-host`, peer-dep in `agentsmith`. Standardize on one version before forking.
- `wasmtime` — coordinate with `agentsmith` release cadence; this is a giant crate with frequent upstream churn.

### Phase 2 — Wave 2 forks (6-8 weeks, closed services only)

Execute the 15 deps in Wave 2. By this point the fork-sync automation is proven and we know how much human time each upstream-sync PR actually takes. Adjust velocity accordingly.

Risks to plan for:
- `serde` is foundational across the Rust slice; forking it means *every* CI run depends on the fork being healthy. Stage carefully.
- `next` ships fast and breaks fast; CVE response time gets worse with a fork unless we're tracking upstream daily.
- `fastapi` + `pydantic` are still ecosystem-churn-heavy; expect frequent sync PRs.

### Decision point — public-repo posture (after Phase 2 ships)

Reopen the question of how the 13 public repos handle their own deps. Three options to revisit:
1. Keep them on public registries with stronger hygiene (lockfile + SBOM publication + audit). Recommended starting position.
2. Uniform forking across all 40 repos. Outside consumers would need to accept git-URL deps.
3. Public repos consume our forks but re-export as `@erphq/<name>` to the public registry.

Defer until Phase 2 data shows the real operational cost.

### Phase 3 — Wave 3 + long tail (rolling, 3-12 months, scope TBD)

Tier-2 deps as time permits. Quarterly "fork debt" budget rather than a deadline.

### Phase 4 — Block registries entirely on Tier-1 (continuous)

Once Waves 1 + 2 are forked and consumers updated:

- `cargo-deny` `[sources]` block to deny crates.io for the forked deps.
- `.npmrc` per repo with registry override for the forked packages.
- Python: `--index-url` to a private index or move to git-pinned forks via `pip install <pkg> @ git+https://github.com/erphq/<fork>.git@<sha>` and ban PyPI sources for those packages in CI.

---

## 6 · Operational tradeoffs

| Tradeoff | Reality |
|---|---|
| **Dependabot doesn't update git pins** | Once we switch to `git = "https://github.com/erphq/..."`, Dependabot stops. The fork-sync bot replaces it. Without that bot, security patches stop landing automatically. |
| **CVE response time gets worse** | Upstream patches a CVE → our fork-sync bot opens a PR → human reviews → consumers re-pin. Hours-to-days instead of automatic. Budget on-call accordingly. |
| **Fork proliferation** | 40 repos today → potentially 100-200 with all Wave 1+2+3 forks. Naming, CODEOWNERS, search tooling need to handle this. |
| **Transitive deps still come from registries** | Forking `axum` doesn't fork `tokio` underneath it. The Rust slice has ~600 transitive crates; we're not vendoring those. The fork stops compromise *at the top-level dep*, not deeper. |
| **Native build deps are nasty** | `better-sqlite3`, `@tauri-apps/cli`, `wasmtime`, `torch` all do native compilation. Our fork has to keep up with toolchain drift independently of upstream. |
| **Public repos** | Out of scope until the post-Phase-2 decision point. They stay on public registries during Phases 0-2. |

---

## 7 · Effort estimate

| Phase | Calendar | Engineering effort |
|---|---|---|
| Phase 0 — baseline hygiene | 2 weeks | 1 engineer, ~40 PRs, mostly mechanical |
| Phase 1 — Wave 1 (12 forks + automation) | 4 weeks | 1 engineer + reviewer time |
| Phase 2 — Wave 2 (15 forks) | 6-8 weeks | 1 engineer, more upstream-sync friction |
| Phase 3 — Wave 3 long tail | rolling | quarterly budget, not deadline-driven |
| Ongoing — fork-sync + CVE response | continuous | 0.25-0.5 FTE indefinitely |

Phase 0 alone removes a big chunk of immediate risk for very little cost, and is worth doing regardless of whether Phase 1+ ever ships.

---

## 8 · How this doc is maintained

- Edit this file directly via PR. Update the **Status** line at the top when a phase advances.
- Tick off items in the tracking issue in [`erphq/MetaRepo`](https://github.com/erphq/MetaRepo) as each fork lands.
- When the public-repo posture decision lands after Phase 2, replace section 5's "Decision point" with the chosen direction and rescope Phase 3+ accordingly.
- Re-audit annually. Add new repos to the appropriate wave when they're created.

---

_Last audit:_ 2026-05-17 against `gh repo list erphq` (40 repos). Audited via three parallel language-specific dependency scans (Rust 9 repos · Python 7 repos · TS/JS 13 repos).
