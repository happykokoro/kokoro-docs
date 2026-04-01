# Kokoro Auth — Business Plan

**Unified SSO and Subscription Management**
Kokoro Tech | March 2026

---

## 1. Executive Summary

Kokoro Auth is the central identity provider for the entire Kokoro product ecosystem. A single Kokoro account gives users access to all products — Terminal, MM, Alpha Lab, and future products — with separate billing and subscription tiers per product. This eliminates the friction of managing multiple accounts and enables cross-product features like unified API keys and single sign-on.

The service is built with Bun and Hono, uses RS256 asymmetric JWT tokens, and integrates with PostgreSQL for persistence and Stripe for subscription billing. It is deployed as a standalone Docker container accessible to all Kokoro products.

---

## 2. Product Overview

### What It Does

Kokoro Auth handles authentication (registration, login, session management), authorization (role-based access, per-product tier gating), two-factor authentication (TOTP), cross-product API key management, and OIDC provider functionality for internal tools.

### Architecture

The service uses asymmetric RS256 JWT tokens. The auth service holds the private key for signing; all product services verify tokens using only the public key. This means no product ever needs access to the signing secret, and token verification can happen locally without network calls to the auth service.

Each JWT contains a `products` map with the user's subscription tier for each product:

```json
{
  "products": {
    "terminal": "pro",
    "mm": "free",
    "alpha_lab": "level2"
  }
}
```

Products read only their own field from this map. No product sees another product's subscription tier.

### Features

- **Single Sign-On (SSO)**: One account for all Kokoro products
- **RS256 JWT**: Asymmetric tokens — products verify with public key only
- **Per-Product Subscriptions**: Each product has its own tier with separate Stripe billing
- **Two-Factor Authentication**: TOTP-based 2FA with enrollment flow
- **API Keys**: Cross-product `ka_` prefixed keys for programmatic access
- **OIDC Provider**: OpenID Connect for internal tools (Gitea, Grafana, Uptime Kuma)
- **Audit Logging**: All auth events logged (login, logout, 2FA, subscription changes)
- **Atomic Refresh Token Rotation**: Reuse detection prevents token theft
- **Login Throttling**: Rate-limited auth endpoints to prevent brute force

### Products Supported

| Product          | Domain                   | Subscription Tiers              |
| ---------------- | ------------------------ | ------------------------------- |
| Kokoro Terminal  | terminal.happykokoro.com | Free, Pro, Trader, API          |
| Kokoro MM        | mm.happykokoro.com       | Free, Manual, Signal, Autopilot |
| Kokoro Alpha Lab | alpha.happykokoro.com    | Free, Level1, Level2, ProMax    |
| Internal Tools   | \*.happykokoro.com       | OIDC SSO                        |

---

## 3. Technical Stack

| Component | Technology                                 |
| --------- | ------------------------------------------ |
| Runtime   | Bun                                        |
| Framework | Hono                                       |
| Database  | PostgreSQL (6 tables)                      |
| JWT       | RS256 (2048-bit RSA via jose library)      |
| Passwords | argon2id (64MB memory, 3 iterations)       |
| 2FA       | TOTP (RFC 6238, 6-digit, 30-second)        |
| Billing   | Stripe (checkout, subscriptions, webhooks) |
| Email     | Resend (transactional emails)              |
| API Keys  | SHA-256 hashed, `ka_` prefix               |
| Port      | 4050                                       |

### API Surface

The service exposes 20+ REST endpoints covering:

- Authentication (register, login, 2FA, refresh, logout, profile)
- Session management (list, revoke)
- Product subscriptions (per-product tier queries)
- API key management (create, list, revoke, validate)
- Admin operations (user management, audit log)
- OIDC discovery (`.well-known/openid-configuration`, JWKS)

---

## 4. Security Model

- Passwords hashed with argon2id (memory-hard, side-channel resistant)
- JWT tokens signed with RS256 (asymmetric — products never hold the signing key)
- Refresh tokens stored hashed (SHA-256) with atomic rotation and reuse detection
- Login throttling: 5 attempts per email per 5-minute window
- TOTP: 6-digit codes, 30-second step, 1-step time tolerance
- API keys stored as SHA-256 hashes, never in plaintext
- All authentication events logged to audit table

---

## 5. Integration Model

For any Kokoro product to integrate with Auth:

1. Download the public key from `/.well-known/jwks.json`
2. Verify incoming JWT with RS256 and the public key
3. Read the product-specific tier from `jwt.products.{product_name}`
4. For API key validation, call `/auth/api-keys/validate` (service-to-service)

This model scales to any number of products without modifying the auth service.

---

## 6. Current Status

- **Version**: v1.1.0 (git tag)
- **Deployed**: Docker container on production server
- **Database**: 6 tables (users, product_subscriptions, sessions, api_keys, audit_log, oidc_clients)
- **Integrated with**: Kokoro Terminal, Kokoro MM, Kokoro Alpha Lab

---

**Next steps:** [Contact us](../services/contact.md) | [How We Work](../services/how-we-work.md) | [View technical profile](../profile/resume.md)

---

_Kokoro Tech — [tech.happykokoro.com](https://tech.happykokoro.com) · [GitHub](https://github.com/happykokoro) · [Contact](../services/contact.md)_
