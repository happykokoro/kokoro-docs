---
description: Security posture for Kokoro Tech engagements — cryptographic baseline, key management, secrets, access controls, and incident notification.
---

# Security

Security is structured into every engagement. The controls below apply uniformly across customer engagements; engagement-class-specific tightening (Class A / B / C) is documented in [quality standards](../engineering/quality-standards.md#software-classification).

## Cryptographic baseline

- **Argon2id** for password hashing. No legacy hash functions accepted (MD5, SHA-1, plain SHA-256, bcrypt only on legacy migrations with documented rotation plan).
- **RS256** (or stronger asymmetric) for cross-service JWTs. HS256 disallowed for cross-service tokens.
- **AES-256-GCM** for symmetric encryption at rest. Authenticated encryption only; no AES-CBC without separate MAC.
- **TLS 1.3** for transport, modern cipher suites only, HSTS enabled.
- **Ed25519** for device-bound keypairs in IoT and hardware engagements.

## Secret management

- Secrets in deployment-time secret stores (HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, Cloudflare Worker secrets, or equivalent). Never in source control; never in environment-variable defaults; never in container images.
- Per-environment isolation (development / staging / production) with no cross-environment credential reuse.
- Rotation cadence agreed in the SOW; quarterly minimum for credentials with persistent access; immediate on personnel change.

## Access controls

- Rate limiting on authentication and other high-cost endpoints by default.
- Audit logging of administrative actions, with append-only retention sized to the customer's regulatory regime.
- Per-session and bulk session revocation on identity products.
- Least-privilege IAM at deployment time; admin paths gated behind separate authentication.

## Incident notification

For systems we operate or have built, we commit to:

- Acknowledge confirmed customer impact within 4 hours of detection.
- Notify the customer's named security contact in writing within 24 hours.
- Deliver a written post-incident review within 5 business days, covering: root cause, customer impact, mitigation taken, follow-up actions.

Specific severity tiers, notification channels, and SLA windows are negotiated per engagement and documented in the SOW.

## Vulnerability disclosure

We accept reports of security vulnerabilities affecting this site, our published software, and any system we operate under an active engagement. See the [vulnerability disclosure](vulnerability-disclosure.md) page for reporting and response procedures.

## Standards alignment

Security controls are designed to align with:

- **NIST SP 800-53** — security and privacy controls relevant to the engagement class.
- **OWASP ASVS** — application security verification standard, with verification level scaled to engagement class.
- **ISO/IEC 27001** Annex A controls relevant to the customer's regime.

We do not currently hold formal certifications under these regimes; we engineer to the controls and produce evidence appropriate to the customer's audit requirements. Compliance posture is documented per engagement.

## Engagement-class controls

Class A (revenue-critical or financial) engagements include, on top of the baseline above: independent code review by a second senior engineer, security review before go-live, integration tests against a real database (no mocks at the persistence boundary), backup-restore drills, and a documented rollback path. See [quality standards](../engineering/quality-standards.md#software-classification) for the full classification matrix.
