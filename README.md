# kokoro-docs

Source for [docs.happykokoro.com](https://docs.happykokoro.com/) — the public B2B capabilities catalogue for Kokoro Tech engagements.

The site documents what we deliver (eight capability domains), how engagements are structured (custom development, customisation, managed operations, engagement models), the engineering practice that governs every engagement, and a procurement trust hub (security, vulnerability disclosure). Audience: technical procurement personnel and prospective partners.

## Build

Requires Python 3 with `mkdocs-material` installed:

```bash
pip install mkdocs-material
python3 -m mkdocs serve     # local dev at http://127.0.0.1:8000
python3 -m mkdocs build     # produces site/ for deployment
```

## Deploy

Deployment is manual — there is no CI auto-deploy.

```bash
CLOUDFLARE_EMAIL=... CLOUDFLARE_API_KEY=... ./deploy.sh
```

The script wraps the build, the `.well-known/` copy step (MkDocs ignores dotfile directories), and the `wrangler pages deploy` invocation. See [`CLAUDE.md`](CLAUDE.md) for deployment policy, hosting topology, and incident triggers.

## Layout

```
docs/
├── index.md                              Capabilities catalogue front page
├── capabilities/
│   ├── network-services/{software,hardware}.md
│   ├── iot-and-embedded.md
│   ├── identity-and-access.md
│   ├── payments.md
│   ├── trading-and-data.md
│   ├── defi-and-onchain.md
│   ├── enterprise-platforms.md
│   └── infrastructure-and-monitoring.md
├── services/
│   ├── custom-development.md
│   ├── customization-extension.md
│   ├── managed-operations.md
│   └── engagement-models.md             includes universal defect-liability section
├── engineering/
│   ├── how-we-work.md
│   └── quality-standards.md
├── trust/
│   ├── index.md
│   ├── security.md
│   └── vulnerability-disclosure.md
├── contact.md
├── robots.txt
└── .well-known/security.txt              copied into site/ post-build (RFC 9116)
```

## Content policy

See [`CLAUDE.md`](CLAUDE.md). In short: capabilities catalogue, no internal product names, no marketing-speak, bounded defect-liability commitments, standards-anchored claims, top-tier B2B register.

## Governance

Engineering standards are defined in [`kokoro-constitution`](https://gitlab.com/kokoro-tech/governance/kokoro-constitution). See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the contribution workflow.

## Mirrors

- **Canonical**: [gitlab.com/kokoro-tech/governance/kokoro-docs](https://gitlab.com/kokoro-tech/governance/kokoro-docs)
- **Public read-only mirror**: [github.com/happykokoro/kokoro-docs](https://github.com/happykokoro/kokoro-docs)

The GitLab repository is canonical. The GitHub repository is maintained as a one-way push mirror configured in GitLab (Settings → Repository → Mirroring repositories).
