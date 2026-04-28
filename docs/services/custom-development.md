---
description: Ground-up implementation in any of our capability domains, against the customer's stated requirements.
---

# Custom development

Ground-up implementation in any of our capability domains, against the customer's stated requirements, technology constraints, and operating environment.

## What this is

A custom development engagement begins with a written specification — functional requirements, non-functional targets (latency, throughput, availability), regulatory regime, technology constraints, deployment topology — and produces source under proprietary or open-source license, deployable artifacts, and the runbooks needed to operate the system in production.

## Scope

Custom builds are scoped to a single capability domain or a defined intersection of two. Cross-domain platforms are quoted as multi-phase engagements, each phase exiting on a working surface.

## What you get

- Source under the agreed license, organized in the conventions documented in [How we work](../engineering/how-we-work.md).
- Deployable artifacts: container images, infrastructure-as-code, deployment scripts.
- CI/CD pipeline configuration on the customer's chosen platform (GitHub Actions, GitLab CI, Jenkins, Buildkite, or equivalent), wired with the test, lint, security-scan, and deployment gates documented in [quality standards](../engineering/quality-standards.md). Pipelines are activated as part of delivery.
- Observability and audit instrumentation: structured logging, metrics endpoints, alert rules, and audit-log writers — the long-term operational and forensic surface a serious system requires.
- Engineering documentation: software requirements specification, software design document, sequence diagrams for critical flows, verification matrix.
- Operational runbooks covering incident response, rollback, capacity scaling, and credential rotation.
- A handover engagement, scoped separately, where your team takes operational ownership.

## What we don't do

- Vague time-and-materials work without a written specification.
- Builds that bypass our [quality standards](../engineering/quality-standards.md) — e.g. shipping with disabled test suites, suppressed errors, or undocumented configuration.
- Open-ended scope creep absorbed into the existing fixed price. Mid-engagement changes are negotiated as a written change order with revised scope, timeline, and price.

## Pricing

Custom development is fixed-price per defined phase, with phase boundaries gated on working software. A scoping engagement (1-2 weeks, separately priced) precedes the build engagement and produces the specification the build is quoted against.
