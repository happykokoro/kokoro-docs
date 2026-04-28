---
description: Multi-chain stablecoin payment infrastructure with treasury, invoicing, subscription billing, and structured defect liability.
---

# Payments

Multi-chain stablecoin payment infrastructure with treasury management, invoicing, and subscription billing — self-hosted, single-tenant, merchant-operated.

## What we provide

- **Stablecoin acceptance across six chains.** USDC and USDT on Solana, Ethereum, Base, Polygon, Arbitrum, and Tron, plus native SOL. Per-chain confirmation depth is configurable.
- **Fiat checkout in parallel.** Stripe-backed fiat acceptance on the same order surface; merchants can offer crypto and card without operating two systems.
- **Order lifecycle.** Order creation, on-chain deposit detection, exact-amount verification against the configured token contract and recipient address, signed webhook delivery, refund processing for both crypto and fiat rails.
- **Treasury.** On-chain balance queries against merchant-owned vaults, snapshot history, multi-currency rollups, P&L and revenue reporting.
- **Invoicing and subscriptions.** Recurring billing, payment-link issuance, expense tracking, and a CSPRNG-backed activation-code mechanism for payment-gated product unlocks.
- **Organizations and RBAC.** Multi-user organizations, role-based access control, scoped API keys with SHA-256-hashed storage.
- **Plugin hooks.** Documented extension points across the order pipeline for custom routing, custom verification, and downstream integrations. Monetary values are stored in micro-unit integers — no floating-point drift.

## Delivery models

- **Self-hosted deployment.** The full server, merchant dashboard, schema, and chain configuration deployed onto customer-owned infrastructure via Docker Compose or equivalent. Customer controls keys and treasury addresses.
- **Custom chain support.** Additional chains, custom token registries, and bespoke chain-adapter implementations under integration engagement.
- **Webhook integration.** Signed webhooks into the customer's existing order management, accounting, or fulfillment systems.
- **Embedded payments.** Payment primitives embedded into a customer's existing application, with the merchant dashboard either bundled or omitted.

## Engagement

Payments engagements are governed by the customer's settlement requirements (fiat treasury, crypto custody, banking jurisdiction) and accounting cadence. Deliverables include the running service, deployment configuration, integration guide covering 55+ documented endpoints (orders, codes, plans, treasury, expenses, invoices, reports, organizations, plugins), and operational runbooks for chain-monitor uptime and webhook retry behavior.

Defect liability is structured into every payments engagement. If delivered work fails to operate materially as specified, we correct it at our cost within the cure window agreed in the SOW; if correction is not possible within that window, we refund the fees attributable to the affected work. Cure windows, response times, remediation scope, and overall liability cap are sized per engagement to system class and SLA tier.
