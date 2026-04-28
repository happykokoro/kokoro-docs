---
description: The engineering framework every engagement runs under — specification before code, mandatory disclosure, end-to-end audits, AI boundaries, senior review.
---

# How we work

Every engagement is delivered under a written engineering framework — the same framework our internal portfolio is built under. This page documents the operational rules a customer can expect.

## Specification before code

No build engagement begins without a written specification. The specification is the contract: it defines the deliverable, the acceptance criteria, and the boundary of scope. Specifications are produced during a scoping engagement, separately quoted, and are the customer's deliverable regardless of whether they choose to proceed with the build.

## Mandatory disclosure

Code that ships under our name does not contain suppressed problems. The following are caught at PR gate by automated audit and rejected:

- Unhandled error paths (`unwrap()`, `?` to a panic, empty catch blocks) outside test code.
- `TODO` / `FIXME` / `HACK` comments without a tracked issue link.
- Disabled or skipped tests without a tracked issue link.
- Weakened assertions (test changes that loosen what the test verifies).
- Commented-out code.

If we find one of these in delivered code, it's a defect and we fix it before invoicing. Customers receive the audit reports.

## End-to-end completeness

A feature is not complete until it is reachable end-to-end: backend handler registered in a router, route reachable via API, API consumed by a frontend caller, frontend element reachable from navigation. We run wiring audits at stage completion that verify this for every implemented feature. Backends that compile but no caller reaches do not count as delivered.

## Conventional commits and reviewable diffs

All commits follow the Conventional Commits specification with scoped types (`feat`, `fix`, `docs`, `chore`, etc.). Pull requests are scoped — one concern per PR, decomposable into independent reviewable units. Customers receive merge-quality git history.

## File and function size discipline

Hard limits enforced in CI: 400 lines per source file in Rust, Python, Go; 300 lines in TypeScript. Functions that exceed reasonable limits are decomposed. The result is code that fits in a reviewer's working memory and survives handover to the customer's team.

## AI-assisted development with explicit boundaries

We use AI-assisted development workflows. The boundaries are written and enforced: AI agents do not, on their own initiative, activate CI/CD pipelines, modify production credentials, alter cloud or DNS configuration, or take any other action whose blast radius extends beyond the local working tree — those actions require explicit human authorization. Agents disclose every file touched and every external call made during a session. Wiring audits, disclosure audits, and constitutional compliance checks run automatically at PR gate — the agent's work is verified the same way a human's would be.

This boundary is about how we operate AI tooling, not about what gets delivered. Customer engagements ship with CI/CD activated, monitoring instrumented, and audit logging wired as a matter of course — those are part of every build, configured by humans during the build phase, not deferred for the customer to enable later.

## Senior review on every change

Every change in delivered code, whether authored by a human, an AI agent, or both, is read line-by-line by a senior engineer, exercised against acceptance criteria, and signed off before merge. The principal personally reviews every diff in customer-delivered work.

Test failures, audit failures, or unexplained behavior block merge regardless of authorship. The automated audits (wiring, disclosure, constitutional compliance) run before human review and catch trivial defects, freeing the reviewer to spend attention on architecture, edge cases, and intent. They do not replace the review.

Customers receive a record of who or what authored each change and which audit caught what.

## Worklog discipline

Every state-mutating session writes a dated worklog entry. Customers receive these worklogs on engagements over a defined size — full forensic visibility into what happened and why.

## Direct push for trivial changes; PR for everything else

Documentation typo fixes and obvious one-line corrections may go direct to the default branch. Anything touching code, configuration, or schema goes through a pull request with at least one review. The branching model is documented per repository; we follow the customer's existing convention if they have one.
