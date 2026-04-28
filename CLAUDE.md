# kokoro-tech/governance/kokoro-docs

The public documentation site for Kokoro Tech engagements. Built with MkDocs Material, deployed to Cloudflare Pages, served at https://docs.happykokoro.com.

## Content policy

The site is a **B2B capabilities catalogue** for technical procurement personnel and prospective partners. It documents what Kokoro Tech delivers (capability domains: network services, IoT & embedded, identity & access, payments, trading & data, DeFi & on-chain, enterprise platforms, infrastructure & monitoring) and how engagements are structured (custom development, customisation & extension, managed operations, engagement models). It is not a project listing.

The site replaced the prior "verified projects listing" structure (per the 2026-04-12 strip pass) on 2026-04-28.

### Content discipline

- **No internal product names** appear in public pages. Capability surfaces are described in customer-functional terms.
- **No internal personal background** (employer history, academic background, etc.) appears in public pages.
- **No track-record claims that imply customer history we lack.** Forward-looking structural claims are appropriate; "many of our customers", "commonly span X years", and similar present-perfect constructions are not.
- **No marketing-speak.** Banned vocabulary: "transform", "revolutionize", "world-class", "cutting-edge", "seamless", "robust", "powerful", "leverage", "next-generation", "industry-leading", "best-in-class".
- **No rhetorical "X, not Y" or "X rather than Y" patterns.** Direct factual claims only. Aphoristic single-sentence paragraphs are also out.
- **No defensive disclaimers against unstated competitor patterns.** Define ourselves by what we do, not what others fail to do.
- **Defect-liability commitments are bounded and documented.** Universal section in `services/engagement-models.md`; capability-specific intensifiers on `payments.md`, `defi-and-onchain.md`, `trading-and-data.md`. Match the structure of Modern Treasury's published warranty rather than unbounded "full responsibility" language.

### Rules of voice

- Top-tier B2B register (Stripe / Cloudflare / Plaid / Modern Treasury territory).
- Capability-organised, not product-name-organised.
- Standards-anchored claims (ISO/IEC/IEEE 12207, 29148, 42010; IEEE 1012, 730; ISO/IEC 25010; NIST SP 800-53; OWASP ASVS).
- Per-page `description:` front matter for SEO and OG previews.

### Editing process

When adding or modifying public pages: pull-request review by the operator. Voice and structural rules above are the enforcement criteria. The 2026-04-28 overhaul produced systematic edits removing X-not-Y patterns and self-conscious framing — preserve that voice in any future addition.

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
