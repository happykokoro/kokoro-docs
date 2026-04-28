# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Site repositioned from "verified projects listing" to **B2B capabilities catalogue** for technical procurement personnel and prospective partners.
- `mkdocs.yml` nav restructured around the capability / services / engineering / trust hierarchy. `navigation.tracking` removed (was setting cookies without a privacy notice). `extra.generator` disabled, `copyright` set, `edit_uri` cleared (private repo). Theme extended with palette toggle, custom font, and footer contact icon.
- `deploy.sh` copies `docs/.well-known/` into the build output; MkDocs by default ignores dotfile directories.
- `docs/index.md` rewritten as the capabilities-catalogue front page.
- `docs/contact.md` rewritten with engagement-cycle expectations and procurement-clarifying boundaries.
- `engineering/quality-standards.md` security baseline section relocated to `trust/security.md` and replaced with a one-line cross-reference; "What we will not ship" tightened; track-record-implying language removed from testing-requirements.
- Voice pass site-wide: removed rhetorical "X, not Y" and "X rather than Y" patterns; removed aphoristic single-sentence paragraphs and self-conscious framing; tightened the homepage Studio section.
- `CLAUDE.md` content policy updated to reflect the capabilities-catalogue direction.

### Added
- Eight capability domain pages: network services (software, hardware), IoT & embedded systems, identity & access, payments, trading & data, DeFi & on-chain, enterprise platforms, infrastructure & monitoring.
- Four services pages: custom development, customisation & extension, managed operations, engagement models. Engagement models includes a universal defect-liability section; payments, DeFi, and trading capability pages carry domain-specific intensifiers with cure-window and refund mechanics modelled on Modern Treasury's published warranty.
- Two engineering practice pages: how we work, quality standards. Includes the senior-review commitment for all delivered code (human or AI-authored).
- Trust hub: overview, security (cryptographic baseline, secret management, access controls, incident notification), vulnerability disclosure (RFC 9116-aligned scope, response SLAs, safe harbor).
- `docs/.well-known/security.txt` (RFC 9116).
- `docs/robots.txt` referencing the sitemap.
- Per-page `description:` front matter on all 19 pages for SEO and Open Graph previews.

### Removed
- `docs/projects/auth.md`, `docs/projects/claude-skills.md`, `docs/projects/constitution.md`, `docs/projects/pay.md`, `docs/projects/staking.md`, `docs/projects/terminal.md`, `docs/projects/vpn.md` — superseded by capability-domain pages.

### Deployed
- All changes deployed to https://docs.happykokoro.com via Cloudflare Pages on 2026-04-28. Multiple in-session deploys, each verified 200 OK.
