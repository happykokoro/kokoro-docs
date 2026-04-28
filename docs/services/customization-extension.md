---
description: Adaptation of our framework codebases to a customer's specific deployment context — region, transport, identity provider, regulatory regime.
---

# Customization & extension

Adaptation of one of our framework codebases to a customer's specific deployment context — region, transport, identity provider, billing provider, regulatory regime, or operational workflow.

## What this is

Where [custom development](custom-development.md) starts from a blank repository, customization starts from one of our existing framework codebases and adapts it. The customer receives the adapted source under proprietary license, with all upstream improvements available via merge for the duration of the support window.

## Typical customizations

- **Regional transport extensions** for the network services framework — adding support for a transport profile not currently in the upstream codebase.
- **Custom chain or token support** in the payments stack — new chain adapters, custom token registries, custom verification logic.
- **Tenant-specific identity claims** — custom OIDC scopes, custom JWT claim schemas, custom Stripe metadata mappings.
- **Bespoke admin workflows** — admin console resources tailored to the customer's operational cadence, audit-log retention configured to their regulatory regime, telemetry rollups tuned to their reporting cycle.
- **Custom plugin hooks** — extension points across our pipelines for routing, verification, or downstream integration.

## What you get

- Adapted source as a maintained fork, branched from a pinned upstream version.
- Documentation covering what changed from upstream and why.
- A merge contract: a defined cadence and process for pulling upstream improvements into the fork.
- Tests covering both the adapted surface and the unchanged inherited surface.

## What we don't do

- Customization that violates the framework's constitutional invariants: single-tenant isolation in the network framework, asymmetric JWT signing in identity, exact-amount verification in payments.
- Forks without a documented merge contract — they become unmaintained surface within a quarter.

## Pricing

Customization is fixed-price per scope of work. Ongoing upstream-merge support is priced as an annual retainer separate from the customization engagement.
