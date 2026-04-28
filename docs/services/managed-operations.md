---
description: Day-2 operations of a deployed system on the customer's own infrastructure — incident response, capacity planning, key rotation, backup verification.
---

# Managed operations

Day-2 operations of a deployed system on the customer's own infrastructure — incident response, capacity planning, key rotation, backup verification, and the operational discipline that keeps a system running without burning out an in-house team.

## What this is

The customer holds the infrastructure and the contracts (cloud accounts, domain registrations, vendor relationships). We hold the on-call rotation and the operational runbooks. The system is the customer's; the operational burden is ours.

## What we operate

- Systems we built or customized for the customer, where we already understand the failure modes.
- Self-hosted infrastructure stacks (analytics, git, status pages, observability) deployed onto customer-owned hardware.
- On-chain off-chain services (listeners, keepers, liquidation engines) for protocols the customer has deployed.
- Cross-cloud monitoring planes, including the alert-routing workarounds for cloud providers that block SMTP egress.

## What's included

- 24/7 on-call rotation against documented severity-1 / severity-2 / severity-3 response times.
- Monthly capacity reviews with right-sizing recommendations.
- Quarterly secret-rotation: TLS certificates, API keys, signing keys, database credentials.
- Backup verification: scheduled snapshots are useless without periodic restore drills, which we run.
- Post-incident reviews on every severity-1 with documented action items.
- A monthly operational report: uptime, incidents, capacity headroom, upcoming risks.

## What's not included

- New feature development. That's a [custom development](custom-development.md) or [customization](customization-extension.md) engagement.
- Compliance audit work. We can prepare evidence; the audit itself is between the customer and the auditor.
- Vendor management. The customer holds the contracts; we operate against them.

## Pricing

Managed operations is priced as a monthly retainer keyed to system class (Class A: revenue-critical or financial; Class B: business-critical; Class C: internal tooling) and on-call SLA. Pricing is per-system at a flat monthly rate.
