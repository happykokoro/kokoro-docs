# kokoro-tech/governance/kokoro-docs

The public documentation site for verified Kokoro Tech projects. Built with MkDocs Material, deployed to Cloudflare Pages, served at https://docs.happykokoro.com.

## Content policy

This site documents only **verified** repos — those individually validated by the operator. Each project page has a factual one-line purpose plus an "under development" disclaimer. **No metrics, no deployment URLs for non-running services, no business plans, no production-readiness claims** appear in any page on this site. The strip pass of 2026-04-12 removed all unvalidated content; new content shall conform to the same discipline.

When adding a new project page, the operator (not the agent) shall first individually validate the repo per KT-DOCS-001 §11. Agent-drafted content shall be flagged in the page's authorship disclosure.

## Production hosts and triggers

**Per WORKFLOW.md §17.16 Diagnostic Discipline and CONSTITUTION.md §21 Incident Management.**

- **Repo class:** C — Supporting (documentation site; outage causes inconvenience and reputation impact, no operational or financial impact) per CONSTITUTION.md §6.
- **Production status:** Production — live at https://docs.happykokoro.com.
- **Hosting platform:** Cloudflare Pages, project name `kokoro-docs`.
- **DNS:** `docs.happykokoro.com` CNAME → `kokoro-docs.pages.dev`, proxied through the Cloudflare zone for happykokoro.com.
- **Build:** `python3 -m mkdocs build` produces `site/` (gitignored).
- **Deploy:** Manual — `wrangler pages deploy site --project-name kokoro-docs`. There is **no CI auto-deploy** (the GitHub Actions deploy.yml was deleted because the source GitHub account had Actions disabled). The operator runs the deploy command manually after merging to `main`. The helper script `deploy.sh` wraps the build + deploy steps and requires `CLOUDFLARE_EMAIL` and `CLOUDFLARE_API_KEY` env vars.
- **Authoritative monitoring source:** Cloudflare Pages dashboard (`kokoro-docs` project): build status, deploy history, traffic, uptime. Note: this site is NOT on the wg1 mesh; the `kokoro-tech/infra/monitoring` Prometheus stack does not cover Cloudflare-hosted CDNs.
- **Authoritative incident log:** [`governance/worklog/`](https://gitlab.com/kokoro-tech/governance/worklog).

### Incident triggers

Any of the following = incident territory per CONSTITUTION.md §21 (typically P3 — Class C):

- Site returns non-200 at https://docs.happykokoro.com or any sub-path
- Cloudflare reports an incident affecting the zone or this Pages project
- DNS resolution failure for `docs.happykokoro.com`
- Build pipeline (`mkdocs build`) fails on a routine deploy
- Customer report of broken behaviour or stale content
- Content-policy violation discovered (unvalidated claim, deployment URL for non-running service, etc.) — per KT-DOCS-001 §10

**First action: invoke `/incident-triage`** ([`kokoro-claude-skills`](https://github.com/happykokoro/kokoro-claude-skills)). For Class C, triage may abbreviate Step 2 source enumeration to: Cloudflare dashboard, DNS check, build log, operator's prior knowledge — full mesh-side enumeration is not applicable to externally-hosted CDN sites. Document the abbreviation in the triage record.

### Primary-source checklist

Before any narrative or remediation:

```bash
# DNS and HTTP reachability from the agent's host
dig docs.happykokoro.com
curl -I https://docs.happykokoro.com
curl -A "Mozilla/5.0" https://docs.happykokoro.com | head -50   # Cloudflare may block default agents
```

From a host that has Cloudflare credentials:

```bash
# Build status (Cloudflare Pages dashboard or wrangler)
CLOUDFLARE_EMAIL=... CLOUDFLARE_API_KEY=... wrangler pages deployment list --project-name kokoro-docs
```

Plus: check the Cloudflare Pages dashboard for build status, deploy history, and Cloudflare's own incident page for the zone. Search [`governance/worklog/*.md`](https://gitlab.com/kokoro-tech/governance/worklog) for prior site-related entries. Ask the operator: "Do you know what caused this, or have you observed related anomalies recently?"

### Cross-references

- CONSTITUTION.md §21 Incident Management; §21.7 Agent-Conducted Incident Response
- WORKFLOW.md §17.16 Diagnostic Discipline; §17.13.5 Diagnostic Confirmation Bias anti-pattern
- Skills: [`/incident-triage`](https://github.com/happykokoro/kokoro-claude-skills/blob/main/skills/incident-triage/SKILL.md), [`/pir`](https://github.com/happykokoro/kokoro-claude-skills/blob/main/skills/pir/SKILL.md)
- Note: site is externally hosted on Cloudflare Pages; mesh-side monitoring (Prometheus + Grafana on wg1) does not apply.
- Known content gap (operator-actionable): `docs/projects/claude-skills.md` line 3 links to `github.com/happykokoro/kokoro-claude-skills` without noting the repo's unvalidated/at-risk status. Recommend adding a one-line caveat consistent with the site's content policy.
