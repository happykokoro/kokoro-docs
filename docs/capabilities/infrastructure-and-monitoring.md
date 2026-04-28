---
description: Self-hosted operational infrastructure and observability — utility stacks, cross-cloud monitoring, SMTP-bypassed alert routing.
---

# Infrastructure & monitoring

Self-hosted operational infrastructure and observability for organizations that run their own utility stack.

## What we provide

- **Self-hosted developer and ops stack.** Internal git hosting, product analytics, link shortening, status pages, paste sharing, whiteboarding, bookmarks, file sync, homepage dashboards. Single VPS, Docker Compose, NGINX-fronted, reverse-proxied through a CDN. The stack we run for ourselves, available as a deployment recipe for customers who want data sovereignty without operational burden.
- **Cross-cloud observability.** Prometheus, Grafana, and Alertmanager bound to a private mesh — every metric travels over WireGuard, nothing is reachable from the public internet, Grafana access requires an active mesh peer. Pattern works across DigitalOcean, AWS, Hetzner, and GCP.
- **SMTP-bypassed alert routing.** Cloud providers commonly block outbound SMTP. We route Alertmanager webhooks through a Cloudflare Worker that authenticates via a shared secret and forwards to a transactional email API over HTTPS. Pattern is reusable for any team behind a SMTP-egress block.
- **Alert rules out of the box.** Node-down, disk-filling-fast (predictive), high-CPU, high-memory, high-disk-pressure, blackbox HTTP probes. Per-severity routing into pager and ticket queues.
- **Inventories and incident triage.** Authoritative DNS inventories, infrastructure inventories, communications inventories. Incident triage runbooks with primary-source checklists; status page is a primary source, not a derivative.
- **Backup and rotation.** Snapshot scheduling, off-site storage, and periodic restore drills. Volume-level for stateful services; logical for databases.

## Delivery models

- **Reference deployment.** The full Compose stack as a starting point for customers building their own. Ships with infrastructure documentation, DNS templates, and incident triage runbooks.
- **Managed operations.** We operate the stack on the customer's infrastructure under contract — uptime monitoring, alert response, backup verification, capacity planning.
- **Custom observability builds.** Equivalent mesh-bound monitoring planes for customer environments, including the SMTP-egress workaround, integrated with the customer's existing alert routing or ticketing.
- **Migration from SaaS.** Migrations off Datadog, New Relic, or other paid observability platforms onto self-hosted equivalents, with capacity sizing and cost modeling.

## Engagement

Infrastructure engagements are scoped against the customer's data-sovereignty requirements (which workloads must stay on-prem, which jurisdictions data may transit), uptime targets, and on-call rotation. Deliverables include the deployed stack, the runbooks we use ourselves, and a documented handover to the customer's ops team.
