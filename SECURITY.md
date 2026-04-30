# Security policy

## Reporting a vulnerability

**Don't open a public GitHub issue for security bugs.** Instead, email **security@erp.ai** with:

1. A description of the vulnerability and its impact.
2. Steps to reproduce. A minimal proof-of-concept beats a long writeup.
3. The version / commit you tested against.
4. Any disclosure deadline you'd like us to honour.

We'll acknowledge within **72 hours** and aim for a fix or mitigation within **14 days** for high-severity issues. We'll credit you in the release notes unless you ask us not to.

## Scope

In scope:
- Code-execution, auth-bypass, data-exfiltration in any repo under github.com/erphq.
- Crypto / signature mistakes in release artefacts (`neo-releases`, `erpai-cli-releases`).
- Storage-corruption or data-loss bugs in `FFS`, `clickr`, `processmind`, `agentsmith`.

Out of scope (don't bother reporting):
- Theoretical vulnerabilities without a working PoC.
- Self-XSS, social-engineering, physical attacks.
- Issues in third-party dependencies that don't affect us — go upstream.
- DoS / spam against public endpoints.
- Reports from automated scanners with no human triage.

## What we won't do

- We don't have a paid bug bounty program. We do credit reporters.
- We don't sign NDAs to receive a vulnerability report.
- We don't pre-disclose timelines beyond the 72h ack and 14d target.

## Old versions

Only the latest published release of each repo is in scope. If you've found a bug in a tagged version more than 6 months old and the same code path no longer exists in `main`, we'll thank you but won't ship a back-port.
