---
description: Egress, identity, and routing infrastructure — stable outbound IPs, geographic egress routing, restrictive-network transports, IP rotation defense.
---

# Network services — software

Egress, identity, and routing infrastructure for organizations whose traffic profile breaks the assumptions of off-the-shelf VPNs and SaaS proxies.

## What we provide

- **Stable outbound identity.** A single egress IP per region for an entire workforce or fleet, eliminating the IP-reputation friction that flags accounts on GitHub, AWS, banking portals, B2B SaaS, and AI APIs when employees travel or rotate IPs.
- **Geographic egress routing.** Per-connection choice of egress region, decoupled from where the client device sits. Source IP geography becomes a deployment variable.
- **Restrictive-network transports.** DPI-resistant transports that survive deep packet inspection in jurisdictions where commercial VPN protocols are blocked. Per-region transport extensions are scoped per engagement.
- **Mesh and hub-and-spoke topologies.** Star topology for centralized egress; full mesh for low-latency peer-to-peer. Both supported in the same control plane; topology is a deployment choice.
- **IP rotation defense.** Pin all client traffic to a stable upstream IP. Eliminates account-flagging, MFA-rechallenge loops, and IP-reputation contamination from shared exit nodes.
- **Whitelisted intranet communication.** Per-peer ACLs and subnet-scoped routing for cases where the network must reach internal services without exposing them to the public internet.
- **Operator admin API.** REST surface for user, device, key, and topology management. Drives white-label admin consoles, customer SSO integration, or programmatic provisioning from the customer's existing IT systems.

## Delivery models

- **Custom build.** Ground-up implementation against a defined transport, region, and threat model. Customer owns source under proprietary license.
- **Framework deployment.** Our framework codebase deployed onto customer-owned infrastructure. Single-tenant per customer; no customer traffic shares servers with another customer.
- **Customization on the framework.** Per-region transport extensions, customer-issued attestation roots, custom admin workflows, integration with the customer's identity provider.
- **Managed operations.** Customer owns the infrastructure; we operate day-2 (key rotation, capacity, incident response) under contract.

## Engagement

Engagements typically open with a scoped review of the customer's traffic profile, threat model, and target jurisdictions under NDA. Single-tenant deployments are mandatory; multi-tenant SaaS is a separate product line not currently activated. Pricing is per-deployment; ongoing operations are priced separately.
