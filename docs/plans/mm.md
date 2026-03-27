# Kokoro MM — Business Plan

**Polymarket AMM SaaS Platform**
Kokoro Tech | https://mm.happykokoro.com | March 2026

---

## 1. Executive Summary

Kokoro MM is a Software-as-a-Service platform that enables individual traders to become automated market makers on Polymarket, the world's largest decentralized prediction market. Users connect a USDC wallet, choose a quoting strategy, and the platform handles everything else: discovering binary option rounds, minting Conditional Token Framework (CTF) token pairs, placing bid-ask quotes on the Central Limit Order Book (CLOB), and managing inventory risk in real time.

The core value proposition is simple: prediction markets are structurally profitable for market makers who can quote both sides of a binary event faster and smarter than manual traders. Until now, doing this at any scale required months of engineering work — building a Polymarket SDK from scratch, implementing the EIP-712 signing protocol, managing CTF approvals on Polygon, and running a live quoting loop. Kokoro MM collapses that into a subscription tier and a browser dashboard.

The platform is live at https://mm.happykokoro.com, deployed on AWS Ireland, serving the 24 active crypto binary markets on Polymarket (6 assets × 4 timeframes: BTC, ETH, SOL, XRP, DOGE, BNB at 5-minute, 15-minute, 1-hour, and 4-hour intervals). The quoting engine completes a full cycle — fair value estimation, spread calculation, inventory adjustment, adverse selection check, quote placement — in under 2 seconds per tick.

The business model is a four-tier SaaS subscription (FREE / MANUAL / SIGNAL / AUTOPILOT at $0 / $29 / $99 / $199 per month), supplemented by profit-sharing on fully autonomous AUTOPILOT accounts and a forthcoming strategy marketplace. The total addressable market is every active Polymarket participant who holds USDC and wants passive income from providing liquidity — a population growing with the platform's own volume explosion past $1 billion in cumulative trades.

---

## 2. Product Overview

### What Kokoro MM Does

Polymarket runs binary option markets on real-world events. Each market resolves to YES (price = 1.0) or NO (price = 0.0). For crypto markets, a typical contract asks: "Will BTC be above $X at 2:00 PM ET?" Traders buy YES or NO positions. Market makers provide liquidity by quoting prices on both sides, earning the bid-ask spread when both sides fill.

Kokoro MM automates the entire market-making lifecycle:

1. **Round Discovery** — The platform polls Polymarket's Gamma API every 30 seconds, discovering all active binary rounds across the 24 supported markets.
2. **CTF Minting** — For each round, the platform mints YES/NO conditional token pairs by splitting USDC through the CTF Exchange contract on Polygon, funding both sides of the book.
3. **Fair Value Estimation** — The engine fuses price signals from three sources: Polymarket's own CLOB mid-price, Binance spot data, and Pyth oracle prices. Each source carries an exponential freshness decay and confidence weight; the output is an EWMA-filtered estimate with velocity tracking.
4. **Avellaneda-Stoikov Quoting** — The canonical academic market-making model is applied in full: EWMA volatility estimation, inventory-skewed reservation price, adverse selection premium over the base spread. The result is asymmetric quotes that tighten automatically when inventory is balanced and widen when directional exposure grows.
5. **Adverse Selection Defense** — The engine monitors fill patterns in real time. When fills arrive consistently on one side (a signal of informed order flow), a cancellation wave fires, pulling all quotes before further losses occur.
6. **Settlement** — When a round resolves, the engine redeems winning tokens for USDC and closes the position.

### Strategy Types

The platform offers four quoting strategies, each targeting a different user profile:

1. **SymmetricSpread** — The baseline Avellaneda-Stoikov model with symmetric quotes around fair value. Suitable for users who want clean exposure to the spread without directional views.
2. **SignalSkewed** — Integrates external signal data (sourced from Kokoro Alpha Lab) to shift the mid-price before quoting. When the signal predicts BTC goes up, the ask is tightened and the bid is widened, expressing a directional view while still earning the spread.
3. **LadderedBreakout** — Places tiered sell orders on both sides. When a breakout is detected at fill (price moves decisively through a quote level), the engine cancels the opposite side and places a stop-loss, capturing asymmetric momentum moves.
4. **Manual** — The user specifies all parameters directly. No quoting logic runs automatically; this is for operators who want full control for testing or custom strategies.

### Tier System

| Tier      | Price   | Rate Limit    | Automation                | Signals |
| --------- | ------- | ------------- | ------------------------- | ------- |
| FREE      | $0/mo   | 10 req/min    | None                      | No      |
| MANUAL    | $29/mo  | 60 req/min    | Manual quoting            | No      |
| SIGNAL    | $99/mo  | 300 req/min   | Signal-skewed strategy    | Yes     |
| AUTOPILOT | $199/mo | 1,000 req/min | Full autonomous operation | Yes     |

Rate limits are enforced per user at the API gateway level using a sliding-window token bucket. Tier gating is enforced on every protected route via middleware in the Axum HTTP server, with tier status sourced from the billing subsystem (Stripe) at request time.

### Technical Architecture

Kokoro MM is a single-binary Rust application built across 18 crates organized in four layers:

**L0 — Domain Primitives** (`mm-types`, `mm-proto`, `mm-traits`): All core types and async trait definitions. Zero I/O at this layer; pure domain logic.

**L1 — Domain Logic** (`mm-market`, `mm-minting`, `mm-order`, `mm-strategy`, `mm-data`, `mm-identity`): Market lifecycle state machine, CTF minting orchestrator, order lifecycle tracking, signal composition, book manipulation, authentication and encryption.

**L2 — Infrastructure** (`mm-polymarket`, `mm-polygon`, `mm-db`, `mm-redis`): The complete Polymarket SDK (CLOB REST + WebSocket, EIP-712/HMAC authentication, Gamma API), Polygon on-chain operations (splitPosition, mergePositions, redeem), PostgreSQL queries (21 query modules, 58 migration pairs), Redis pub/sub and streams.

**L3 — Services** (`mm-engine`, `mm-datahub`, `mm-gateway`): The quoting pipeline engine, data aggregation hub, and the Axum HTTP gateway with JWT/API-key middleware, tier middleware, and Prometheus metrics.

The binary hosts 69 HTTP routes across 24 modules, a React-based frontend (36 pages, Next.js 16, React 19, Tailwind v4), and 17 MCP tools for AI-driven operations. The frontend includes a visual strategy builder built on React Flow, live tick stream visualization, and a full analytics suite.

---

## 3. Market Analysis

### The Prediction Market Explosion

Polymarket surpassed $1 billion in cumulative trading volume in 2024, accelerating through major political and economic events. The platform's election markets generated nine-figure volumes in the months before the 2024 US presidential election, drawing attention from mainstream media, institutional traders, and retail participants who had never previously engaged with prediction markets. Monthly active volume has grown consistently quarter-over-quarter.

Polymarket operates as a decentralized venue on Polygon: orders are placed through a Central Limit Order Book, positions are represented as ERC-1155 conditional tokens, and settlement is determined by UMA's optimistic oracle. This architecture makes it resistant to regulatory closure compared to centralized prediction market platforms, and it makes all on-chain activity publicly auditable.

The emergence of dedicated Polymarket APIs (CLOB REST and WebSocket, Gamma metadata API) in 2024 made programmatic trading feasible for the first time, but the documentation and tooling remained sparse enough that only developers with significant blockchain and quantitative finance background could build against it. Kokoro MM is the first SaaS product purpose-built to lower that barrier.

### Market Size

The addressable market for Kokoro MM is every Polymarket user who holds USDC and wants to participate as a liquidity provider rather than a directional bettor. Market makers structurally capture the bid-ask spread regardless of event outcome — they profit from volume, not from being right about whether an event occurs. This risk profile is appealing to a large segment of traders who want exposure to prediction market economics without the binary resolution risk of directional positions.

Estimating conservatively:

- Polymarket currently has tens of thousands of active traders
- A sustained market-making operation on the 5-minute crypto rounds requires roughly $500–$5,000 in working capital to maintain meaningful quote depth
- Even at 1% penetration of active users, paid subscriber count would be in the hundreds
- At average revenue per user (ARPU) across tiers of approximately $80/month, the initial addressable revenue is in the low six figures monthly

The long-term market extends to any binary prediction market that supports programmatic CLOB access — Kalshi for regulated US prediction markets, Manifold Markets for community-created questions, and emerging competitors. Kokoro MM's multi-venue router (`mm-market` crate) already has architecture stubs for Kalshi and Manifold routing, making this expansion path a configuration and SDK question rather than an architectural rewrite.

### Competitive Landscape

There is no direct competitor offering AMM-as-a-service for Polymarket. The competitive alternatives are:

**Manual trading through Polymarket.com** — The official interface supports manual order placement but has no automation, no quoting strategies, and no inventory management. This is the status quo for most traders.

**General-purpose trading bots** — Products like Hummingbot and similar DEX market-making frameworks support centralized exchange order books. Adapting them to Polymarket's CTF token model, EIP-712 signing requirements, and CLOB-specific latency characteristics requires substantial custom development that these platforms do not provide.

**Custom scripts** — A small number of technically sophisticated Polymarket traders run custom Python or JavaScript scripts. These are single-user, unmaintained, and not comparable to a maintained SaaS platform with a frontend, billing, and ongoing updates.

**No-code crypto bots** — Platforms like 3Commas and Pionex target centralized exchange trading with simple grid strategies. They have no prediction market support and no understanding of CTF token mechanics.

The competitive moat is therefore structural: Kokoro MM requires deep, concurrent expertise in quantitative market making (Avellaneda-Stoikov, adverse selection theory, inventory management), Polymarket-specific protocol knowledge (CTF, CLOB, EIP-712, Gamma API), and production Rust systems engineering. These three competencies together are rare; products requiring all three simultaneously have essentially zero existing competition.

### Market Timing

The current moment is favorable for several compounding reasons.

**Volume growth has broken records.** As of early 2026, Polymarket hit $7 billion in monthly trading volume in February 2026, with a single-day record of $425 million — surpassing even the 2024 US election peak. Combined Polymarket and Kalshi volume is running at a $200B+ annual run rate, with analyst forecasts pointing toward $325 billion. CNBC projects the prediction market sector reaching $1.1 trillion by 2030.

**Mainstream product adoption is driving new participants.** DraftKings, FanDuel, and Robinhood all launched prediction market products for the 2026 FIFA World Cup — marking the first time prediction markets have been offered through household consumer finance brands. This is converting millions of mainstream users into potential prediction market participants, many of whom will seek more sophisticated tools.

**Non-election categories are exploding.** Tech and Science prediction markets grew 1,637% year-over-year as of early 2026; Economics grew 905%. This demonstrates that the market is not a single-event phenomenon dependent on electoral cycles — it is a structurally growing asset class across many domains.

**The CLOB API window is still open.** Polymarket's programmatic CLOB API matured only in 2024, meaning the window for first-mover SaaS products built on top of it is still open. Kokoro MM is already live and battle-tested — six protocol-level bugs were found and fixed before deployment. That accumulated knowledge cannot be purchased or shortcut.

**Regulatory legitimacy is increasing.** Kalshi received CFTC approval for election markets in 2024, and the broader regulatory environment is shifting toward legitimacy for prediction markets. Institutional and US-based retail participation is opening up in regulated venues — expanding the total addressable market and validating the asset class as a legitimate trading venue.

---

## 4. Revenue Model

### Subscription Tiers

The primary revenue stream is monthly SaaS subscriptions on a four-tier model. Billing is handled through Stripe (checkout sessions, subscription management, webhook events) and enforced in real time by the tier middleware layer.

**FREE ($0/month)** — Provides read-only access to markets, book data, and round history. Rate-limited to 10 API requests per minute. Users can register, explore the dashboard, and paper-trade (simulated minting with no real funds). This tier functions as an acquisition channel: users can evaluate the platform before committing capital or payment.

**MANUAL ($29/month)** — Enables real wallet connection, actual CTF minting, and manual order placement via the dashboard UI. Rate limit increases to 60 requests per minute. No automated quoting runs. This tier targets traders who want control over their quotes but need the infrastructure layer (Polygon interactions, CTF mechanics, position accounting) handled automatically.

**SIGNAL ($99/month)** — Unlocks the signal-integrated quoting strategies. The platform connects to Kokoro Alpha Lab's prediction market signals, incorporating regime detection, price momentum, and conformal prediction bounds into mid-price adjustments before quoting. Rate limit: 300 requests per minute. Target user: a trader with conviction on directional moves who wants to express those views through market-making positions rather than outright binary bets.

**AUTOPILOT ($199/month)** — Full autonomous operation. The engine runs continuously without user intervention, managing round discovery, minting, quoting, inventory rebalancing, and settlement. Rate limit: 1,000 requests per minute. The five autopilot risk gates (drawdown circuit breaker, max exposure per round, minimum edge threshold, position count limiter, volatility filter) run before every quoting cycle. This tier is designed for hands-off passive income generation.

### Profit Sharing

AUTOPILOT subscribers will be subject to an optional profit-sharing arrangement: the platform takes 10% of net monthly profit on accounts that exceed a minimum profit threshold. This creates aligned incentives — the platform earns more when users earn more — and supplements the flat subscription fee with performance-linked revenue on the highest-activity accounts.

### Strategy Marketplace

The platform includes a marketplace architecture where strategy developers can publish configurable quoting strategies, set subscription prices, and earn recurring revenue when other users subscribe. The platform collects a 20% commission on marketplace strategy subscriptions. This creates a community-driven layer of strategy diversity without requiring in-house development of every possible quoting approach.

### Unit Economics

A paying subscriber cohort of 100 users distributed across tiers as follows (conservative estimate based on typical SaaS conversion patterns):

| Tier      | Users   | Monthly Revenue |
| --------- | ------- | --------------- |
| MANUAL    | 50      | $1,450          |
| SIGNAL    | 35      | $3,465          |
| AUTOPILOT | 15      | $2,985          |
| **Total** | **100** | **$7,900/mo**   |

At 500 subscribers (achievable at modest Polymarket community penetration):

| Tier      | Users   | Monthly Revenue |
| --------- | ------- | --------------- |
| MANUAL    | 250     | $7,250          |
| SIGNAL    | 175     | $17,325         |
| AUTOPILOT | 75      | $14,925         |
| **Total** | **500** | **$39,500/mo**  |

Infrastructure costs at this scale are modest: the current AWS Ireland EC2 instance runs at approximately $50/month. PostgreSQL, Redis, and the binary itself are self-hosted on the same instance with Docker Compose. Scaling to 1,000+ active users would require vertical scaling or a managed database tier, estimated at $200–$500/month additional.

Gross margins therefore exceed 95% at any meaningful subscriber count, which is characteristic of software businesses where the primary cost structure is compute, not people or inventory.

---

## 5. Product Roadmap

### Current State (v1.1.0, Live)

Kokoro MM is deployed at https://mm.happykokoro.com and fully operational. The current feature set includes:

- All four quoting strategies (SymmetricSpread, SignalSkewed, LadderedBreakout, Manual)
- 24 active market pairs (6 assets × 4 timeframes) discovered from live Polymarket Gamma API
- CTF minting wizard with balance checks and approval flow
- Real-time order book visualization via WebSocket CLOB feed
- Full authentication stack (JWT, Argon2 password hashing, TOTP 2FA, API key management)
- AES-256-GCM wallet encryption with HKDF-SHA256 per-user key derivation
- Stripe billing integration
- Prometheus metrics and structured logging
- CI pipeline (build, clippy, fmt, test, file-size gate via GitHub Actions)
- 33 frontend pages including the SaaS landing page, dashboard, markets browser, and strategy builder

Six critical Polymarket protocol bugs were identified and fixed prior to deployment by cross-referencing the implementation against Polymarket's reference repositories: collection ID computation (BN128 EC point derivation), position ID encoding (ABI packed encoding), WebSocket reconnection loop, fee formula (min-price CTF model), signature type selection (PolyProxy for maker-not-signer cases), and salt masking (IEEE 754 precision mask).

### Phase 8 — Scale (Planned)

The next major development phase targets institutional-grade capabilities and multi-venue expansion:

**Multi-Venue Routing** — Wire the existing Kalshi and Manifold multi-venue router architecture with live SDK implementations. Kalshi's CFTC-regulated environment opens institutional and US-based retail participation. Manifold's open market creation enables long-tail event coverage beyond crypto.

**FIX Protocol Gateway** — Implement FIX 4.4 / 5.0 connectivity for institutional clients who require standard financial messaging protocol rather than REST/WebSocket interfaces. This opens the platform to hedge funds and prop trading desks.

**WASM Strategy Plugins** — The `factor-wasm` / `factor-sdk` architecture from Kokoro Alpha Lab will be adapted for the MM platform. Users will compile their own quoting strategies to WebAssembly, upload them to the platform, and run them in a sandboxed environment. This enables custom strategies without sharing source code with the platform operator.

**VaR Scaling** — Current risk management uses historical simulation VaR/CVaR at the position level. Phase 8 will extend this to portfolio-level correlated VaR (using the Gaussian copula and Student-t copula implementations already present in Kokoro Alpha Lab), enabling proper risk capital allocation across all simultaneous positions.

**Institutional Features** — Multi-account management under a single organization, sub-account tiering, audit log export, SOC 2-style compliance reporting, and dedicated support SLAs.

---

## 6. Go-to-Market Strategy

### Primary Channel: Polymarket Community

The Polymarket community operates primarily through Discord, Reddit (r/Polymarket and r/PredictionMarkets), and Twitter/X. These channels have a high concentration of technically sophisticated users who already hold USDC, understand binary markets, and are actively looking for edges. The free tier provides a no-friction entry point: any Polymarket user can register, connect their wallet in read-only mode, explore the market data, and paper-trade before committing real funds.

The go-to-market playbook for community penetration:

1. **Free tier as foot-in-the-door** — Target active Polymarket Discord members and Twitter accounts with $0 entry. The value is visible immediately: the platform surfaces real-time order book data, resistance levels, and market analytics that are not easily accessible elsewhere.
2. **Transparent performance sharing** — The leaderboard feature (weekly/monthly P&L ranking by strategy type) provides social proof. Real user results in public leaderboards are more persuasive than marketing copy.
3. **Educational content** — Prediction market market-making is not widely understood. Technical explainers on Avellaneda-Stoikov, CTF mechanics, and adverse selection — published in the Polymarket community channels — position Kokoro MM as the authoritative technical resource and drive organic search traffic.

### Secondary Channel: Crypto Twitter

Crypto Twitter has a dedicated prediction market subculture that grew substantially during the 2024 election cycle. Accounts with established credibility in this community reach tens of thousands of engaged followers. The strategy is to engage authentically: share real quoting results, post about strategy improvements, discuss market microstructure observations. Sponsored posts or influencer arrangements are not planned for the initial phase — earned attention from demonstrated expertise is more credible in this audience.

### Tertiary Channel: Algorithmic Trading Communities

Forums like QuantConnect community, the Systematic Investor community, and quantitative finance subreddits have users with technical backgrounds who understand market making but may not have followed prediction markets closely. Polymarket's crypto binary rounds (frequent, liquid, short-duration) present an interesting backtesting and live-trading use case for this audience. Kokoro MM's backtest harness (60-tick historical replay per round) provides the research tools this audience expects.

### Conversion Funnel

The acquisition funnel is designed around the free tier as the top of funnel:

1. **Awareness** — Community engagement, technical content, organic search
2. **Registration (FREE)** — Zero-friction, no credit card, immediate access to market data and paper trading
3. **Activation** — User connects a wallet, observes live quotes in paper mode, sees P&L simulated
4. **Upgrade to MANUAL ($29)** — First paying conversion when user wants to go live with real USDC
5. **Upgrade to SIGNAL or AUTOPILOT** — Conversion when user wants signal integration or full automation, typically after 30-60 days of manual operation

The hypothesis is that users who experience working paper-mode quotes before paying are dramatically more likely to convert and retain. The free tier is not a truncated product — it is a complete market analytics and paper trading tool that delivers real value without payment.

---

## 7. Technical Moat

### Complete Proprietary Polymarket SDK

The `mm-polymarket` crate (L2 infrastructure) is a complete, production-tested Polymarket SDK: CLOB REST and WebSocket with full EIP-712/HMAC authentication, Gamma API market discovery, CTF token operations, fill detection, and an ACL anti-corruption layer that insulates the rest of the codebase from Polymarket's frequently evolving API surface. Building this correctly required cross-referencing Polymarket's reference JavaScript/Python repositories, finding and fixing six protocol-level bugs that would silently produce incorrect behavior in production. This SDK does not exist in the public Rust ecosystem; it is proprietary to Kokoro MM.

### Avellaneda-Stoikov with Adverse Selection

The academic A-S model is well-understood theoretically. Implementing it in a live trading system with real adverse selection pressure is substantially harder. The `mm-engine`'s quoting pipeline implements:

- EWMA volatility estimation with configurable lambda (adapts to market regimes)
- Multi-source fair value fusion with exponential freshness decay (prevents stale data from poisoning quotes)
- Inventory-skewed reservation price (automatically adjusts quotes as exposure grows)
- Adverse selection detection with CancellationWave (toxic flow response in under one engine tick, i.e., under 2 seconds)
- Conformal prediction bounds from Kokoro Alpha Lab signal integration (calibrated uncertainty intervals rather than point estimates)

This combination — A-S quoting with live adverse selection detection, multi-source price fusion, and calibrated uncertainty — is not reproduced by any comparable public product.

### AES-256-GCM Wallet Encryption

Kokoro MM manages real user wallets and private keys for the AUTOPILOT tier. The security architecture uses AES-256-GCM authenticated encryption with HKDF-SHA256 per-user key derivation — each user's wallet is encrypted with a key derived from a combination of the user's credential and a server-side secret. This means a database breach does not expose wallet keys unless the attacker also has server access, and a server breach does not expose wallet keys without database access. The implementation is in `mm-identity`, peer-reviewed against the Rust `aes-gcm` and `hkdf` crate documentation.

### Rust Performance

The quoting engine is implemented in Rust with Tokio async runtime. A full quoting cycle — round discovery, fair value computation, spread calculation, inventory check, adverse selection evaluation, order placement — completes in under 2 seconds. Python-based alternatives would introduce latency that, in a 5-minute binary round with dozens of quote updates per round, meaningfully reduces the number of profitable fill opportunities.

The single-binary architecture means there is no inter-service serialization overhead; components communicate via in-process function calls and shared state. This is deliberately simpler than the microservice architecture of Kokoro Alpha Lab, and it allows the engine to run reliably on a single $50/month EC2 instance.

### Signal Integration from Kokoro Alpha Lab

The SIGNAL tier connects to the Kokoro Alpha Lab prediction pipeline: a 242,466-line Rust monorepo running 24 alpha factors, 11 DSP filters, and a conformal prediction module that provides calibrated 95% coverage probability intervals. These signals are sourced from one of the most technically sophisticated self-built prediction market research systems in existence. For SIGNAL and AUTOPILOT users, this means the quoting engine is not just mechanically market-making — it is expressing informed views backed by a full quantitative research pipeline.

---

## 8. Financial Projections

### Assumptions

- Platform launched March 2026 at mm.happykokoro.com
- Free tier conversion to paid: 10% (industry benchmark for developer/technical SaaS is 5-15%)
- Paid tier distribution: 50% MANUAL, 35% SIGNAL, 15% AUTOPILOT (conservative; AUTOPILOT is the target long-run distribution as user confidence in the engine grows)
- Monthly churn: 5% for paid tiers (prediction market volume is seasonal and event-driven, which creates natural churn in quiet periods)
- AUTOPILOT profit share applies to accounts with positive monthly P&L; assumed 60% of AUTOPILOT users are in profit in any given month at an average net profit of $500/month per account

### 12-Month Projection

| Month | Free Users | Paid Users | MRR     | Profit Share | Total Revenue |
| ----- | ---------- | ---------- | ------- | ------------ | ------------- |
| 1     | 50         | 5          | $395    | $0           | $395          |
| 3     | 200        | 20         | $1,580  | $180         | $1,760        |
| 6     | 600        | 60         | $4,740  | $540         | $5,280        |
| 9     | 1,200      | 120        | $9,480  | $1,080       | $10,560       |
| 12    | 2,000      | 200        | $15,800 | $1,800       | $17,600       |

Infrastructure costs at month 12: estimated $200/month (database scaling, bandwidth, AWS compute).

**Month 12 net revenue: approximately $17,400/month ($208,800 ARR)**

This projection is deliberately conservative. It assumes zero marketing spend, organic growth only, and no viral or event-driven spikes. Polymarket volume is strongly correlated with major geopolitical and financial events; a significant US election, market crash, or sports championship cycle can multiply platform volume (and therefore market maker profitability) by 5-10x, which would drive proportional subscriber growth.

### Upside Case (Multi-Venue + Institutional)

If Phase 8 multi-venue routing launches by month 18 and captures even modest Kalshi volume, the addressable market expands significantly. Kalshi's CFTC regulation opens US institutional participation — a segment that currently cannot participate in Polymarket at scale due to regulatory uncertainty. A single institutional client operating at scale on AUTOPILOT could generate $500–$2,000/month in subscription plus profit sharing revenue, and institutional clients churn at much lower rates than retail.

---

## 9. Team & Operations

### Solo Founder, AI-Augmented

Kokoro MM was designed, built, and deployed by a single developer with full-stack systems engineering capability across Rust, TypeScript, Solidity, and Go. The development timeline demonstrates the efficiency of AI-augmented development: the core platform (18 Rust crates, 36 frontend pages, 17 MCP tools, 690 tests, full deployment) was built and deployed in approximately two weeks of calendar time.

This is not an accident. The development workflow is systematically augmented by AI at every layer:

- **MCP Tools** — 17 Kokoro MM MCP tools expose the full platform API to Claude, enabling autonomous research, strategy optimization, and operations tasks without manual API calls. An operator can ask the AI to "analyze quoting performance on BTC 5-minute markets for the past week and suggest parameter adjustments" and receive a structured analysis with specific recommendations.
- **Agent Orchestra** — The multi-agent orchestration system (`agent-orchestra`) can deploy multiple Claude Code instances as parallel development agents, each working on an isolated git worktree, with automated build and test verification before merge. This was used to complete multiple development phases of Kokoro Alpha Lab in parallel and will be used for Phase 8 scaling work.
- **Kokoro Pipeline** — An automated development pipeline engine in active development that provides structured multi-phase workflows (research → plan → execute → audit → report) for systematic feature development.

### Operations Model

Production operations are managed through the following tooling:

- **Monitoring** — Prometheus metrics on all services, Grafana dashboards, structured logging with the Rust `tracing` crate
- **Deployment** — Docker Compose on AWS Ireland, with Caddy as the HTTPS reverse proxy and Cloudflare for DNS and DDoS mitigation
- **Security** — UFW firewall, CORS restricted to production domain, metrics endpoint protected by token header, Postgres and Redis ports bound to localhost only
- **Incident Response** — Uptime Kuma for availability monitoring, alerting to configured channels, WebSocket-based real-time platform health dashboard
- **Code Quality** — CI pipeline enforcing build success, Clippy linting, rustfmt formatting, file-size gates (no file exceeds 400 lines, no function exceeds 50 lines), and cargo-deny for license and advisory compliance

---

## 10. Risks & Mitigations

### Polymarket Regulatory Risk

Polymarket's legal status has been under scrutiny from US financial regulators. In 2022, Polymarket settled with the CFTC for $1.4 million over offering unregistered binary option contracts to US persons. The platform subsequently blocked US IP addresses. If further regulatory action restricts Polymarket's operations — including a forced shutdown or restriction of programmatic API access — Kokoro MM's primary market would be impacted.

**Mitigation**: The multi-venue architecture is the primary hedge. The `mm-market` crate's multi-venue router and the planned Phase 8 Kalshi and Manifold integrations are not optional features — they are the primary business continuity mechanism. Kalshi's CFTC approval means there is already a regulated alternative that Kokoro MM's engine can route to. The codebase is explicitly architected to abstract away venue-specific implementations behind a `MarketProvider` trait, meaning adding a new venue is an SDK and configuration problem rather than an architectural rewrite.

### Single-Venue Dependency (Near-Term)

Before Phase 8 multi-venue launches, Kokoro MM operates exclusively on Polymarket. A temporary API outage, CLOB infrastructure problem, or sudden change in Polymarket's authentication or fee structure could disrupt service.

**Mitigation**: The CLOB WebSocket reconnection loop implements exponential backoff (1s → 2s → 4s → max 60s) with clean-close instant reconnect. The Gamma API polling loop is similarly resilient. For authentication or fee formula changes: the anti-corruption layer in `mm-polymarket` is designed to isolate change — when Polymarket updates an API surface, only one layer of the codebase needs to change. The six pre-deploy bug fixes demonstrated this pattern in practice: they were contained to `mm-polymarket` without touching the engine or gateway layers.

### Market Making Risk

Market making is not risk-free. An adverse selection scenario — a persistent pattern of informed traders filling quotes just before a large move — can produce net losses even with the A-S model's inventory management. A black-swan price movement during a live round could result in significant mark-to-market losses on minted CTF positions before the round settles.

**Mitigation**: The five autopilot risk gates provide multiple independent layers of protection: drawdown circuit breaker (stops quoting if cumulative loss exceeds threshold), max exposure per round (limits the size of any single position), minimum edge threshold (requires minimum expected spread before placing quotes), position count limiter (caps the number of simultaneous active rounds), and volatility filter (suppresses quoting during anomalously high volatility). Users can configure all gate thresholds from the dashboard. The paper trading mode allows any user to run the full quoting pipeline against live market data with simulated fills before committing real capital.

### Live Trading Execution Risk

Real-money market making on a decentralized platform requires on-chain transactions (CTF splits on Polygon, USDC approvals, CTF merges on settlement). These transactions have gas costs, can fail due to gas spikes or network congestion, and are not reversible. An incorrectly constructed transaction can result in permanent loss of funds.

**Mitigation**: The AUTOPILOT live execution path is currently gated behind a credential requirement (Polygon wallet with USDC balance and signed authorization). Paper mode is the default for all users regardless of tier. The on-chain layer (`mm-polygon`) estimates gas before every transaction, applies a configurable maximum gas price ceiling, and uses pre-flight balance checks to ensure sufficient USDC and native MATIC for fees before initiating any contract interaction.

### Competition Risk

The absence of direct competition is a current advantage that could narrow. If Polymarket's growth trajectory continues, larger development teams or well-funded startups could build competing products. The lead time required to match the current feature set (complete Polymarket SDK, A-S quoting engine, CTF operations, full frontend, billing, MCP tools, and six months of production hardening) is substantial but not infinite.

**Mitigation**: The moat is not merely code — it is accumulated production knowledge. The six protocol bugs fixed before deployment represent the kind of hard-won understanding that only comes from building against the real system with real money. The integration with Kokoro Alpha Lab's signal pipeline is proprietary and not easily replicated. Continued investment in Phase 8 institutional features and multi-venue routing widens the gap as the platform matures.

---

## Appendix: Key Numbers

| Metric                   | Value                                           |
| ------------------------ | ----------------------------------------------- |
| Rust codebase            | 62,641 lines (126,873 with tests)               |
| TypeScript (frontend)    | ~80,000 lines                                   |
| Rust crates              | 18                                              |
| Automated tests          | 690 (Rust) + Vitest frontend tests              |
| API routes               | 69                                              |
| Frontend pages           | 36                                              |
| MCP tools                | 17                                              |
| PostgreSQL migrations    | 58 pairs                                        |
| Active market pairs      | 24 (6 assets × 4 timeframes)                    |
| Engine tick interval     | 2 seconds                                       |
| Round discovery interval | 30 seconds                                      |
| Deployment               | AWS Ireland (54.155.125.66), mm.happykokoro.com |
| Status                   | Production (live)                               |

---

_Prepared March 2026. Kokoro Tech — https://tech.happykokoro.com_
