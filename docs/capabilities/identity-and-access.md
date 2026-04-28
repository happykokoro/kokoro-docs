---
description: Standards-compliant identity infrastructure — OAuth 2.0 / OIDC, RS256 JWTs, TOTP 2FA, entitlement management driven by upstream billing.
---

# Identity & access

Standards-compliant identity infrastructure for B2B and B2C platforms — federated authentication, JWT-based authorization, and entitlement management driven by upstream billing events.

## What we provide

- **OAuth 2.0 / OIDC authorization server.** Authorization Code flow with PKCE, refresh tokens, JWKS endpoint, OpenID Discovery. Single-use codes with tight TTL, hashed client secrets, scoped registrations.
- **RS256-signed JWTs.** Asymmetric signing only — symmetric algorithms disallowed for cross-service tokens. JWTs carry per-product entitlements as structured claims, verifiable by relying parties without an extra round-trip.
- **TOTP 2FA.** Standards-compliant time-based one-time passwords with secrets encrypted at rest under AES-256-GCM. QR provisioning, backup codes, and per-session enforcement policy.
- **Argon2id password hashing.** No legacy hash algorithms accepted. Tuned for the deployment's CPU profile.
- **Entitlement management.** Per-product subscription tiers driven by upstream billing webhooks (Stripe and equivalents). Service-to-service entitlement lookup gated by shared internal secrets.
- **Federation.** JWKS-based federation into Grafana, Gitea, Vault, internal admin tools, or any RP that speaks OIDC. Pre-built client registrations available; custom client registration via REST.
- **Session management.** Per-session and bulk revocation, IP-bound rate limiting on sensitive endpoints, audit log of administrative actions.

## Delivery models

- **Self-hosted IdP.** The full identity service, schema, and key-rotation tooling deployed onto customer-owned infrastructure. Customer holds keys.
- **Integration into existing IdP.** Federation and entitlement-management primitives layered onto the customer's existing identity provider (Auth0, Okta, AWS Cognito, Keycloak).
- **Custom scopes and claims.** Tenant-specific claim schemas, custom scopes, custom Stripe metadata mappings.
- **Migration.** From bcrypt or legacy hashing to Argon2id; from session-based auth to JWT; from monolithic auth to federated OIDC.

## Engagement

Identity work is governed by the customer's regulatory regime — GDPR, SOC 2, or HIPAA scope is determined during scoping. Deliverables include the running service, RS256 keypair generation and rotation procedure, OIDC integration guide for downstream products, and a runbook covering credential recovery, key rotation, and breach response.
