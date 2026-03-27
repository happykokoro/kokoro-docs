# Kokoro Tech

**Deep technology studio building quantitative trading infrastructure, blockchain protocols, and AI-augmented developer tools.**

---

## What We Build

A distributed SaaS platform spanning 7+ coordinated repositories — not 14 isolated projects, but one logical system with clearly defined service boundaries, shared type contracts, and encrypted inter-server communication.

The core monorepo (65 Rust crates, 3 application binaries) is surrounded by satellite repositories extracted as they reached operational maturity: an independent frontend, two upstream data microservices, a dedicated MCP tool server, and two consumer-side trading applications that depend on shared library releases. All repositories coordinate through a shared type crate versioned with semantic tags, ensuring type safety across repository boundaries without tight coupling.

Services communicate across 3 cloud servers (Singapore, Ireland, London) via a self-built WireGuard mesh VPN — all cross-server traffic stays on the encrypted 10.10.0.0/24 subnet, making physical server boundaries transparent to the application layer. Within the Singapore server alone, Docker Compose orchestrates 12+ containers. Across the full mesh, 10 named streaming data channels carry real-time events between services in dual JSON/protobuf format, enabling gradual protocol migration without downtime.

115 AI tool interfaces across two MCP servers expose the platform for autonomous operation — research, backtesting, execution, and system management can all be delegated to AI agents through structured API contracts.

530,000+ lines of production code. 1,860+ automated tests. Built and operated by a single founder leveraging AI-augmented development workflows.

---

## Quick Navigation

### Technical Profile

Detailed technical specifications extracted from every codebase in the ecosystem.

- [**Technology Stack**](profile/technology-stack.md) — Complete inventory of every language, framework, library, and tool
- [**Projects Portfolio**](profile/projects-portfolio.md) — All 20 projects with architecture, algorithms, and API surfaces
- [**Skills & Expertise**](profile/skills-and-expertise.md) — 11 skill domains with mathematical foundations
- [**Coding Style & Architecture**](profile/coding-style.md) — Conventions, design decisions, and engineering philosophy
- [**Resume Profile**](profile/resume.md) — Professional summary, timeline, achievements, and business thesis

### Articles

Long-form prose versions of the technical profile — suitable for reading, sharing, and publishing.

- [**Technology Deep Dive**](articles/technology-stack.md) — Why each technology was chosen and how they fit together
- [**Projects Deep Dive**](articles/projects-portfolio.md) — The full story of every product in the ecosystem
- [**Skills & Expertise**](articles/skills-and-expertise.md) — Technical capabilities whitepaper
- [**Architecture Philosophy**](articles/coding-style.md) — How and why the code is structured the way it is
- [**Founder Profile**](articles/resume.md) — The journey from blockchain foundations to a 14-product portfolio

### Business Plans

Comprehensive business plans for each product line — market analysis, revenue models, financial projections.

- [**Kokoro Alpha Lab**](plans/alpha-lab.md) — Quantitative trading research platform ($49-$499/mo SaaS)
- [**Kokoro MM**](plans/mm.md) — Polymarket AMM-as-a-Service (first in market)
- [**Kokoro Liquidation Bot**](plans/liquidation-bot.md) — Zero-capital DeFi liquidation across 6 EVM chains
- [**Kokoro VPN**](plans/vpn.md) — Self-hosted WireGuard platform
- [**Trading Bots**](plans/trading-bots.md) — Polymarket quant bot + copy trader ecosystem
- [**Developer Tools**](plans/developer-tools.md) — 115 MCP tools, agent orchestration, dev pipeline

---

## Key Numbers

| Metric                | Value                             |
| --------------------- | --------------------------------- |
| Total production code | 530,000+ lines                    |
| Rust code             | 330,000+ lines across 100+ crates |
| Products              | 14 active                         |
| Automated tests       | 1,860+                            |
| Blockchain chains     | 23 integrated                     |
| MCP tools             | 115                               |
| Anchor programs       | 20 on Solana                      |
| Production servers    | 3 (Singapore, Ireland, London)    |

---

## Links

- **Company Website**: [tech.happykokoro.com](https://tech.happykokoro.com)
- **Portfolio**: [happykokoro.com](https://happykokoro.com)
- **GitHub (Org)**: [github.com/happykokoro](https://github.com/happykokoro)
- **GitHub (Personal)**: [github.com/anescaper](https://github.com/anescaper)
