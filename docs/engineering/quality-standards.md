---
description: Engineering rules anchored to ISO/IEEE/NIST standards, applied across every engagement.
---

# Quality standards

The engineering rules that apply to every engagement, anchored to recognized standards.

## Standards we anchor to

- **ISO/IEC/IEEE 12207** — software lifecycle processes.
- **ISO/IEC/IEEE 29148** — requirements engineering.
- **ISO/IEC/IEEE 42010** — architecture description.
- **IEEE 1012** — verification and validation.
- **IEEE 730** — software quality assurance plans.
- **ISO/IEC 25010** — software quality model.
- **NIST SP 800-53** and **OWASP ASVS** for security controls relevant to the engagement class.

We cite the applicable section in deliverables so audits and due diligence land on familiar ground.

## Software classification

Every system we deliver is classified by criticality and that classification drives the gates that apply.

- **Class A** — revenue-critical or financial systems. Mandatory: independent code review, security review, integration tests against a real database (no mocks at the persistence boundary), backup-restore drills before go-live.
- **Class B** — business-critical operational systems. Mandatory: code review, integration tests, documented incident response.
- **Class C** — internal tooling and non-customer-facing systems. Mandatory: code review and the constitutional baseline.

Classification is documented in the engagement specification and reviewed at each phase exit.

## Testing requirements

- Unit tests for business logic, executable on every commit.
- Integration tests against a real database for any system that persists state. Mocks at the persistence boundary mask migration defects and produce false-green builds; we do not use them.
- End-to-end tests for golden-path user flows, executable in CI.
- Security tests scaled to engagement class: dependency audit and SAST baseline for Class C; add SCA, fuzzing where applicable, and security review for Class A and B.

## Security baseline

The full security posture — cryptographic primitives, secret management, access controls, incident notification, and engagement-class-specific tightening — is documented under [trust → security](../trust/security.md). The procurement-relevant summary lives there; this page concerns engineering rules.

## Operational baseline

- Health endpoints on every service, returning structured per-dependency status.
- Structured logging with correlation IDs across service boundaries.
- Metrics exposure (Prometheus or equivalent) for every long-running service.
- Documented backup and restore procedures with periodic restore drills. Backups without verified restores are not backups.
- Runbooks for incident response, rollback, capacity scaling, and credential rotation, version-controlled alongside the source.

## What we will not ship

- Builds that pass tests because tests were disabled.
- Code with suppressed error handling outside explicit, documented escape hatches.
- Systems whose operational documentation lives only in the heads of the people who built it.
- Deployments without a documented rollback path.

If meeting a deadline would require shipping any of the above, the deadline moves.
