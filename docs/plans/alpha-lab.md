# Kokoro Alpha Lab — Business Plan

**Prepared by**: Kokoro Tech
**Date**: March 2026

---

## 1. Executive Summary

Kokoro Alpha Lab is a multi-asset quantitative trading research and execution platform built as a 242,000-line Rust monorepo. It provides the full pipeline from raw market data ingestion through signal processing, factor composition, risk management, and live order execution — across crypto (Solana DEX), equities (Alpaca), options, forex, and prediction markets (Polymarket). The platform is currently deployed in production on DigitalOcean Singapore.

**The core problem it solves**: Individual algorithmic traders and small quant funds lack access to institutional-grade signal infrastructure. Hedge funds spend millions building Kalman filter pipelines, regime detection systems, and composable risk engines. Retail traders are left with moving averages, RSI, and single stop-loss bots. Kokoro Alpha Lab closes this gap by offering the tooling of an institutional quant desk as a self-hosted, privacy-first platform.

**Market opportunity**: The global algorithmic trading market is valued at approximately $15 billion and growing at 10–12% annually. The addressable segment — individual quant developers, algorithmic traders, and small crypto funds seeking self-hosted infrastructure — is considerably smaller but highly underserved. Existing tools (QuantConnect, TradingView, 3Commas) either lack depth, require cloud dependency, or are built for a different asset class. No direct competitor offers a self-hosted Rust-native quantitative research platform that spans crypto, equities, and prediction markets simultaneously.

**Competitive advantage**: Kokoro Alpha Lab is differentiated on three dimensions: technical depth (11 DSP filters, 24 alpha factors, the Clean Integration Layer architecture), execution speed (sub-second pipeline cycles in Rust vs. Python-based competitors), and privacy (self-hosted by default; strategy logic never leaves the user's infrastructure).

**Revenue model**: Tier-based SaaS subscriptions (Free, Level1, Level2, ProMax), self-hosted enterprise licenses, factor marketplace commissions, and optional consulting. Recurring subscription revenue is the primary driver.

---

## 2. Product Overview

### What It Is

Kokoro Alpha Lab is a quantitative trading research and execution environment. Users research strategies (backtesting, factor analysis, signal visualization), run paper or live trading, and manage risk — all from a single integrated platform. The 107-page web frontend provides dashboards across Lab (research), Engine (live execution), Market (data browser), Polymarket, Liquidation, and Marketplace sections.

### Architecture Overview

The platform uses a **Clean Integration Layer (CIL)** architecture: 63 pure-logic Rust crates under `crates/` contain zero I/O. All network, database, and filesystem operations are confined to three application binaries and four service crates. This makes the business logic trivially testable, portable to WASM, and free of external dependencies for core trading computation.

The three binaries are:

- **Lab** (port 4100) — Research environment: factor pipeline, backtesting, HTTP API, gRPC, SSE streaming, replay mode
- **Engine** (port 4200) — Execution environment: frozen strategy, real execution, live trading
- **Platform** (port 4000) — Gateway: authentication, billing, tier gates, gRPC-to-REST proxy

Inter-service communication uses Redis Streams (10 active streams with dual JSON/proto format), gRPC (tonic), REST (axum), and SSE for real-time frontend streaming.

### Key Feature Modules

**Signal Processing Pipeline**: The platform implements 11 production-grade digital signal processing filters from mathematical foundations — not library wrappers. These include: H-infinity filter (4-state: position/velocity/acceleration/jerk with innovation gating), Unscented Kalman Filter (Cholesky sigma points), particle filter (importance resampling), Interacting Multiple Model filter (3-regime: Trending/Ranging/Volatile), Rao-Blackwellized particle filter, dual Kalman for stochastic volatility, Morlet wavelet CWT, Hilbert transform, Mellin transform, EWMA, and Fourier analysis. Each filter is implemented with full mathematical rigor — the UKF implementation uses nalgebra Cholesky decomposition for sigma point generation, not approximations.

**24 Alpha Factor Implementations**: Every factor implements the `AlphaFactor` trait and participates in role-based signal composition (Primary → Confirmation → Filter → Observer). Factors span the breadth of market microstructure: order flow imbalance (OFI) at ±0.5/±2.0 normalized thresholds, Hawkes process (self-exciting point process λ(t) = μ + Σα·exp(-β·Δt)), AMM state (LP repositioning detection, liquidity density), Ensemble DQN (experience replay, epsilon-greedy), whale flow (exchange inflow/outflow consensus with decay), smart money (tracked wallet consensus accumulator), equity factors (momentum, mean reversion, pairs, sector rotation), options factors (vol surface, skew, gamma scalping, calendar spread), and social sentiment (Twitter/Discord/Telegram).

**Prediction and Autotune Module**: A 51-test suite covering IMM filter for regime detection, RBPF for per-particle regime tracking, stochastic volatility dual Kalman, expert aggregator using the Hedge algorithm with multiplicative weights, conformal prediction for calibrated uncertainty (rolling 95% coverage), and Nelder-Mead simplex optimization for automated parameter tuning.

**Backtesting Infrastructure**: BacktestRunner with configurable parameters, grid and random search parameter optimization, walk-forward analysis, Monte Carlo simulation, and synthetic scenario generation. Results include equity curves, drawdown metrics, Sharpe ratios, and per-factor P&L attribution.

**Quant Core Library**: Black-Scholes pricing and Greeks, Monte Carlo simulation with importance sampling and antithetic variates, Gaussian/Student-t/Clayton copulas, Markowitz MVO (analytical Lagrangian plus projected gradient descent via nalgebra), GARCH(1,1) MLE, Hurst exponent (R/S analysis), ADF stationarity test, k-means clustering, and Kelly criterion. These are available as both API endpoints and MCP tools.

**Multi-Chain Execution**: Chain adapter trait with EVM implementations for Ethereum, Base, Arbitrum, and Polygon. On-chain intelligence crates for smart money tracking, whale detection, wallet cluster detection (Louvain community detection), and MEV strategy framework.

**Risk Management**: Composable risk gate chain (Pass/Reject/Resize), per-asset-class exposure limits, drawdown circuit breaker (AtomicBool for lock-free state), adaptive position sizing, VaR/CVaR (parametric and historical), Sharpe ratio tracking, options Greeks aggregation.

**WASM Plugin Ecosystem**: The `factor-sdk` and `factor-wasm` crates expose a `kokoro_factor!` macro enabling users to write custom factors in Rust, compile to WASM, and load them at runtime without recompiling the platform. This is a long-term differentiator — strategy logic can be distributed as compiled WASM modules, keeping implementation private.

**MCP Integration**: 98 tools across 13 categories accessible via the Model Context Protocol. Users can interact with the entire platform — running backtests, checking positions, querying signals, adjusting risk parameters — via Claude Code or any MCP-compatible AI client.

### What Makes It Unique

Three things distinguish Kokoro Alpha Lab from any competitor in the market:

First, **depth of signal processing**. No SaaS trading platform at any price point offers 11 production-grade DSP filters implemented from scratch. Most competitors provide moving averages, Bollinger Bands, and RSI. The H-infinity filter and UKF are tools used in aerospace guidance systems; applying them to financial time series requires both mathematical expertise and careful implementation. These are not bolted-on features — they are the core of the signal generation pipeline.

Second, **the Clean Integration Layer architecture**. By isolating all I/O to three binaries and keeping 63 crates pure-logic, the platform achieves a testing discipline (1,074 unit and integration tests) that is structurally impossible with tightly coupled architectures. This means factors and filters can be tested deterministically, backtested with exact reproducibility, and eventually compiled to WASM for sandboxed execution.

Third, **multi-asset breadth on a single platform**. A quant researcher studying equity momentum, crypto order flow, and Polymarket prediction market arbitrage simultaneously does not need to switch tools. All three live in the same factor pipeline, share the same backtesting infrastructure, and execute through the same risk management layer.

---

## 3. Market Analysis

### Target Market Segments

**Segment 1: Individual Quantitative Algorithmic Traders (Primary)**
Estimated market size: 50,000–100,000 globally. These are developers and traders with quantitative backgrounds who write their own trading strategies. They currently use a patchwork of Python libraries (pandas, scipy, zipline, backtrader) with manual data pipelines, ad-hoc risk management, and fragile exchange API integrations. They have the technical capability to self-host and the motivation to avoid cloud dependency. They value correctness, testability, and execution speed. This segment is the ideal early adopter — technically sophisticated enough to appreciate the CIL architecture and DSP filters, and frustrated enough with existing tools to switch.

**Segment 2: Crypto-Native Quant Funds and Prop Traders (Secondary)**
Smaller funds (AUM $1M–$50M) running algorithmic strategies on crypto, DeFi, and prediction markets. They typically have one to five engineers and are building custom infrastructure rather than using off-the-shelf tools. For these teams, Kokoro Alpha Lab as a self-hosted enterprise license eliminates the cost of building and maintaining a signal pipeline from scratch. The value proposition is time-to-market: skip 12–18 months of infrastructure development and start refining alpha on Day 1.

**Segment 3: Prediction Market Traders (Emerging)**
A rapidly growing segment. Polymarket's monthly trading volume reached hundreds of millions of dollars in 2024–2025. The Brownian Bridge path conditioning research in the Alpha Lab codebase (100% historical accuracy on n=18 validated markets) demonstrates unique analytical capability for this asset class. As prediction markets mature, the demand for systematic approaches will increase.

**Segment 4: DeFi Researchers and On-Chain Analysts (Adjacent)**
Researchers studying MEV, liquidity dynamics, and on-chain market microstructure. The `onchain-intel` crate (smart money tracking, whale detection, Louvain clustering on fund flows) provides infrastructure that would otherwise require building custom Ethereum archive node queries and graph analysis pipelines.

### Market Size

As of early 2026, the global algorithmic trading market is valued at $25–33 billion, growing at 14.4% CAGR and projected to reach $44 billion by 2030. This is a significant upward revision from prior estimates, driven by AI-driven algorithms, real-time execution optimization, and cross-asset expansion across crypto, prediction markets, and traditional markets simultaneously. The more relevant sub-market is quantitative trading tools and infrastructure for individual traders and small funds. No precise figure is publicly available, but indicators include:

- QuantConnect (self-reported): 200,000+ registered users
- TradingView: 50M+ users (mostly non-quant retail, but meaningful overlap)
- Alpaca: 500,000+ developer accounts
- 3Commas/Shrimpy: target the automated retail trader, not the quant developer

The serviceable addressable market for a self-hosted, depth-first quant platform is conservatively 20,000–50,000 potential users globally, with the realistic early-stage target being the top 1,000–5,000 technically sophisticated users willing to pay for premium tools.

**Rust adoption as a market signal.** As of early 2026, approximately 709,000 developers use Rust as their primary language, with adoption accelerating fastest in fintech. Senior engineers at banks and trading firms describe Rust as "non-negotiable for serious HFT" — and migrations from C++ to Rust are underway at institutional desks. Kokoro Alpha Lab's 330,000+ lines of Rust, its sub-second pipeline cycle, and its zero-copy async architecture are not incidentally chosen — they reflect exactly the technical direction the industry is moving. A quant platform built in Python cannot credibly compete on execution latency with Rust-native alternatives, and the market is now large enough to recognize the difference.

**DeFi lending market as a secondary tailwind.** The DeFi market reached $238.5B in early 2026, projected to grow to $770.6B by 2031 (26.4% CAGR). As of early 2026, Aave holds $27.29B TVL, $83.3M in monthly fees, and surpassed $1 trillion in cumulative loans. $675M in DeFi liquidations occurred in the first nine months of 2026, with $429M liquidated in a single week (January 31–February 5). This is relevant for Alpha Lab because on-chain intelligence — wallet clustering, MEV detection, liquidation opportunity scoring — is part of the Alpha Lab signal pipeline. The growth of DeFi lending directly increases the value of the on-chain alpha factors and the execution routes that depend on them.

### Competitor Landscape

**QuantConnect**: The most direct comparable. Cloud-based algorithmic trading with factor models, backtesting, and brokerage integration. Strengths: large community, multi-asset, Python/C#. Weaknesses: cloud-only (no self-hosting), Python performance bottleneck, no DSP filter infrastructure, no prediction market support, no on-chain intelligence. Kokoro Alpha Lab's differentiation: self-hosted, Rust performance, broader asset class coverage, deeper signal processing.

**Alpaca**: Brokerage-first with an API and some strategy tooling. Primarily an execution layer, not a research platform. Useful as an execution backend (Alpaca's REST/WS API is supported in Kokoro Alpha Lab's `exec-alpaca` crate) rather than a competitor.

**TradingView**: Charting and script-based strategy testing. Excellent UX and community. Not a quantitative research platform — Pine Script cannot implement Kalman filters or custom factor pipelines. Targets chartists, not quants. Not a direct competitor.

**3Commas / Shrimpy / Pionex**: Automated trading bots for retail cryptocurrency traders. Template-based strategies, grid trading, copy trading. High-frequency users but low technical depth. Not a competitor — different buyer profile entirely.

**Lean / QuantLib / Zipline**: Open-source Python libraries. Used by quant developers directly, not as platforms. Require significant integration work. Kokoro Alpha Lab competes by offering the integrated platform on top of equivalent or superior mathematical capabilities.

**The gap**: No competitor offers a self-hosted, Rust-native quantitative research platform with DSP-grade signal processing, 24 pluggable alpha factors, WASM strategy plugins, multi-chain on-chain intelligence, and prediction market support under one roof.

---

## 4. Revenue Model

### Tier-Based SaaS Subscriptions

The platform's `tenant` crate implements four access tiers — Free, Level1, Level2, and ProMax — enforced at the Platform gateway with per-tier resource limits. This maps naturally to a subscription revenue model.

**Free Tier** — $0/month
Access to core research features: factor pipeline, basic backtesting, paper trading, limited signal history, limited data sources. Designed to demonstrate value and build user familiarity. No live execution.

**Level 1 ("Researcher")** — estimated $49/month
Full backtesting suite including walk-forward analysis and Monte Carlo simulation, all 24 alpha factors, DSP filter visualization, extended signal history, equity data via Alpaca paper, up to 3 concurrent backtest jobs. No live execution.

**Level 2 ("Trader")** — estimated $149/month
Everything in Level 1 plus: live paper and live execution (crypto and equities), full risk management dashboard, Polymarket execution module, on-chain intelligence feeds, consensus module, 10 concurrent backtest jobs, MCP tool access, SSE real-time streaming, strategy export and import.

**ProMax ("Professional")** — estimated $499/month
Everything in Level 2 plus: unlimited backtest concurrency, WASM plugin deployment, full quant-core API (Markowitz MVO, copulas, conformal prediction), multi-asset correlation analysis, LLM Copilot (factor advisor, risk explainer, strategy generator), priority support, and self-hosted license option.

### Self-Hosted Enterprise Licenses

Small funds and prop trading teams that require full data sovereignty and cannot use a shared cloud service would license the Alpha Lab binary and Docker Compose stack for on-premise deployment. Pricing: estimated $2,000–$5,000/month for teams of 1–5 researchers, with custom pricing for larger deployments. This segment requires dedicated support but generates higher contract value.

### Factor Marketplace

The platform includes a marketplace module where users can publish factor implementations (as compiled WASM plugins) and other users subscribe to them. The platform takes a commission on subscription revenue (estimated 20–30%). This creates a flywheel: high-quality factor authors generate recurring income, which incentivizes more contributions, which increases platform value for all subscribers.

### Consulting and Strategy Development

For firms wanting custom factor implementations, signal pipeline architecture, or integration with proprietary data sources, Kokoro Tech provides consulting services billed at hourly or fixed-project rates. This is secondary revenue and doubles as market intelligence for product development.

### Revenue Mix (Projected, Year 3)

| Stream                          | Share |
| ------------------------------- | ----- |
| SaaS subscriptions              | 65%   |
| Self-hosted enterprise licenses | 20%   |
| Factor marketplace commissions  | 10%   |
| Consulting                      | 5%    |

---

## 5. Product Roadmap

### Current State (March 2026)

The platform is deployed in production on DigitalOcean Singapore with MAINTENANCE_MODE=true — meaning the infrastructure is live but not actively acquiring new users. The codebase is at 65 crates, 242,466 lines of Rust, 1,074 tests. The frontend has 107 routes covering all major research, execution, and market data workflows. The MCP server exposes 98 tools.

Key capabilities operational: full factor pipeline, backtesting suite, paper trading on crypto and equities, Polymarket execution module, on-chain intelligence, risk management engine, real-time SSE streaming, JWT/TOTP authentication, and tier gating.

### Near-Term (Q2–Q3 2026)

**Architecture migration** (tracked in monorepo issue #280): Refactor the inter-service communication layer to improve startup time and reduce deployment complexity. This is primarily a developer experience and reliability improvement, not a user-facing change, but it is a prerequisite for a stable public launch.

**User onboarding flow**: The existing frontend has an onboarding wizard stub. Complete this to reduce time-to-first-value for new users. Include an interactive factor playground where users can see how signals are generated on live market data without needing to configure a strategy.

**Tier enforcement hardening**: Audit the Platform gateway's tier gate implementation for edge cases before accepting paying customers. Add usage metering and in-app usage dashboards.

**Payment integration**: Wire Stripe billing to the subscription tiers (groundwork exists in the codebase). This is required before any paid tier can be activated.

**Documentation site**: The platform has 98 MCP tools and 24 factors. Users need indexed reference documentation and at least 5–10 tutorial articles to onboard effectively.

### Medium-Term (Q4 2026)

**WASM plugin marketplace launch**: The `factor-sdk` and `factor-wasm` crates are implemented. The remaining work is the marketplace UI, submission workflow, review process, and billing integration for creator revenue sharing. This unlocks the network effect dimension of the product.

**Social sentiment live feeds**: The `factor-social` crate (SocialSentimentFactor for Twitter/Discord/Telegram) is stubbed. Wiring live data sources requires API key management and a data pipeline service. Priority given that social sentiment is a well-understood alpha signal in crypto markets.

**Postgres persistence for Engine state**: The Engine currently operates with in-memory state. Adding PostgreSQL persistence for live positions and execution history improves reliability during server restarts and enables historical performance reporting.

**Interactive Brokers live execution**: The `exec-ib` crate is implemented as a TWS adapter stub. Full integration with IB Gateway would open the platform to futures and FX live trading, significantly expanding the addressable market for institutional users.

### Long-Term (2027+)

**Multi-tenant cloud offering**: The existing single-tenant self-hosted architecture would need multi-tenancy work (database isolation, compute sandboxing, billing per workspace) to offer a managed cloud version at lower price points. This requires significant infrastructure investment but dramatically expands the addressable market.

**Additional chain adapters**: The `chain-adapter` trait supports pluggable implementations. Priority: Solana DEX via Jupiter (partially wired via the `pricing-service`), then additional EVM chains as TVL warrants.

**Strategy co-pilot GA**: The `copilot` crate (LLM-assisted factor advisor, risk explainer, strategy generator) is implemented but requires a production LLM backend integration. When operational, this becomes a key differentiator for non-technical quant researchers.

**FIX protocol adapter**: For institutional equity trading desks, a FIX protocol execution backend would open integration with prime brokers and custodians.

---

## 6. Go-to-Market Strategy

### Phase 1: Technical Community Seeding (Months 1–3)

The initial user acquisition strategy targets developers and quantitative traders who already understand the problem Kokoro Alpha Lab solves. The goal is not broad awareness but rather finding the 50–100 early adopters who will give high-quality feedback, find bugs, and become advocates.

**Open-source factor examples**: Publish 3–5 example factor implementations as public GitHub repositories with permissive licenses. These serve as technical demonstrations of the `AlphaFactor` trait architecture and signal composition system. Developers who find these interesting are the ideal customer profile.

**Quant and crypto developer forums**: Write technical posts on r/algotrading, r/quant, Hacker News, and relevant Discord servers about specific technical decisions — why H-infinity over a standard Kalman filter for financial data, how the CIL architecture enables deterministic backtesting, how to implement a Hawkes process for order arrival modeling. These posts should teach something genuinely useful and reference the platform where relevant. No self-promotion without substance.

**Claude Code / MCP community**: Kokoro Alpha Lab is among the most MCP-instrumented trading platforms in existence (98 tools). The emerging developer community around MCP-enabled AI coding workflows is a natural audience. A technical demonstration of using Claude Code with the Alpha Lab MCP to research and backtest a strategy would generate interest in both communities.

### Phase 2: Content and Conversion (Months 4–9)

**Educational content**: A documentation site with concept explanations (not just API docs) targeting the search intent of quant developers. Topics: "Kalman filter for financial time series," "order flow imbalance factor construction," "walk-forward analysis vs. in-sample optimization," "regime detection for crypto markets." These articles both educate and establish the platform as credible.

**Factor library documentation**: Each of the 24 alpha factors has a mathematical basis. Publish a public reference for each: what problem it solves, the mathematical formulation, typical parameter settings, and known failure modes. This creates value independent of any product and positions Kokoro Alpha Lab as a serious quant research environment.

**Discord community**: Launch a Discord server for quantitative trading with Kokoro tools. Channels for factor research, strategy sharing, platform issues, and general quant discussion. Community building takes time but creates durable retention.

**Free tier onboarding optimization**: Instrument the free tier funnel to identify where users drop off. Iterate on the onboarding flow with A/B testing. Target: 20% of free users who complete onboarding should activate at least one paid feature within 30 days.

### Phase 3: Conversion and Expansion (Months 10–18)

**Self-hosted license program**: Reach out directly to small crypto funds and prop trading shops in jurisdictions with strong algorithmic trading communities (Singapore, London, New York, Amsterdam). A personalized technical demo of the backtesting infrastructure and execution layer is more effective than content marketing for this segment.

**Referral program**: Offer Level 1 upgrades for successful referrals. Quant developers are well-networked and will refer peers if the product delivers genuine value.

**Integration partnerships**: Partner with data providers (Kaiko, Glassnode, Santiment) to offer premium data feeds as add-ons. These partnerships bring distribution (the data provider's user base learns about the platform) and improve product quality.

---

## 7. Technical Moat

### Codebase Scale and Depth

The 242,466-line Rust codebase with 65 crates represents 8–12 months of full-time development. For a competitor starting from scratch, replicating this would require a team of 3–5 senior engineers over 12–18 months, representing a minimum investment of $1.5–3M in engineering labor at market rates. A developer replicating this timeline, even with AI augmentation, would take several years.

More importantly, the codebase's depth is not uniformly distributed. The signal processing implementations — H-infinity filter, UKF, RBPF, wavelet CWT — are non-trivial mathematical systems requiring domain expertise to implement correctly. The expert aggregator using the Hedge algorithm with multiplicative weights, the conformal prediction calibration system, the Nelder-Mead parameter optimization — these are not commodity implementations. They reflect a combination of mathematical knowledge and engineering execution that is genuinely rare.

### Clean Integration Layer Architecture

The CIL pattern — 63 pure-logic crates with zero I/O, enforced by Rust's trait system and workspace structure — is an architectural pattern that pays compounding dividends over time. It means:

- Every factor and filter is independently testable without mocking
- WASM compilation is structurally guaranteed (no I/O means no WASM-incompatible syscalls)
- The test suite (1,074 tests) is deterministic and fast, enabling confident refactoring
- New execution backends and data sources can be added without touching business logic

This architecture is the opposite of the typical growth-stage startup codebase, which accumulates coupling faster than it accumulates features. The deliberate upfront investment in clean architecture reduces the technical debt cost at scale.

### WASM Plugin Ecosystem

The `factor-wasm` crate with `kokoro_factor!` macro creates a distribution channel that competitors cannot easily replicate. Once users build custom factors and see them running as WASM plugins in the platform, switching costs increase dramatically. The factor becomes an asset tied to the platform's infrastructure. The marketplace enables factor creators to monetize, which incentivizes high-quality contributions.

### Battle-Tested Risk Management

The risk management system was designed under real-money trading conditions. The Polymarket bot's live trading failure — $55 lost in 12 minutes with a structural down-bias discovered only in live conditions — led directly to the circuit breaker design, the conformal prediction calibration system, and the per-asset risk gate parameterization. Risk infrastructure built this way tends to be qualitatively better than risk infrastructure built theoretically, because failure modes were discovered empirically.

### AI-Augmented Development Velocity

The platform includes 98 MCP tools that make the entire codebase and runtime state accessible to Claude Code for automated research and debugging. Combined with the Agent Orchestra system (multi-agent parallel development with automated merge, build, and test pipelines), a lean founder-led team can maintain a codebase of this scale with the iteration speed of a much larger organization. This development velocity is itself a competitive moat — the ability to ship new factors, fix bugs, and respond to user requests faster than competitors with traditional coordination overhead. Importantly, this advantage persists as the team grows: Agent Orchestra scales to coordinate human+AI teams, and the MCP tools remain the operational interface regardless of team size.

---

## 8. Financial Projections

_The following projections are hypothetical estimates for planning purposes. They are not actuals, not forward-looking statements, and not representations of achievable outcomes. They are scenario analyses based on industry benchmarks for developer-focused SaaS products._

### Assumptions

- Product enters public beta in Q3 2026
- Free tier available at launch; paid tiers activated Q4 2026
- Monthly churn: 5% (industry average for developer tools is 3–7%)
- Average revenue per paying user (ARPU): blended ~$180/month (mix of Level1, Level2, ProMax, and enterprise)
- Free-to-paid conversion rate: 8–12% (developer SaaS benchmark)
- Customer acquisition cost (CAC): ~$200 via organic content and community (lower than paid channels)
- Gross margin: ~85% (SaaS infrastructure costs, server time, LLM API for Copilot)

### Year 1 (2026, partial — Q4 launch)

| Metric                     | Value         |
| -------------------------- | ------------- |
| Free tier registrations    | 500           |
| Paying users               | 50            |
| MRR (month 12)             | ~$9,000       |
| ARR run rate (end of year) | ~$108,000     |
| Infrastructure cost        | ~$1,500/month |

### Year 2 (2027)

| Metric                               | Value     |
| ------------------------------------ | --------- |
| Free tier registrations (cumulative) | 3,000     |
| Paying users                         | 250       |
| MRR                                  | ~$45,000  |
| ARR                                  | ~$540,000 |
| Enterprise license contracts         | 3–5       |
| Enterprise ARR contribution          | ~$100,000 |
| Total ARR                            | ~$640,000 |

### Year 3 (2028)

| Metric                               | Value       |
| ------------------------------------ | ----------- |
| Free tier registrations (cumulative) | 12,000      |
| Paying users                         | 800         |
| MRR (subscriptions)                  | ~$145,000   |
| Marketplace GMV                      | ~$200,000   |
| Marketplace commission (25%)         | ~$50,000    |
| Enterprise license ARR               | ~$300,000   |
| Total ARR                            | ~$2,000,000 |

### Unit Economics (Steady State)

| Metric              | Value       |
| ------------------- | ----------- |
| ARPU                | ~$180/month |
| Monthly churn       | 5%          |
| LTV (ARPU / churn)  | ~$3,600     |
| CAC (organic heavy) | ~$200       |
| LTV:CAC             | ~18x        |
| Gross margin        | ~85%        |
| Payback period      | ~1.1 months |

These unit economics are favorable because organic developer acquisition through technical content has low CAC, and developer tools have relatively high retention once the user has wired their strategy to the platform's infrastructure.

### Path to Profitability

At current infrastructure costs (~$1,500/month for DigitalOcean Singapore), the platform reaches contribution margin break-even at approximately 10 paying users (MRR ~$1,800). Full profitability, accounting for the founder's time at a market rate of $200/hour, requires approximately 50–100 paying users depending on hours invested. This is a conservative threshold achievable within the first year of paid operations.

---

## 9. Team and Operations

### Founding Team

Kokoro Alpha Lab is built and operated by a technical founder — a full-stack systems engineer and quantitative developer with a 9-year career arc from undergraduate control systems education through hardware cryptocurrency mining development to distributed SaaS platforms. The 242,466-line Rust codebase, the 107-page frontend, the 98-tool MCP server, the Docker-orchestrated production deployment on DigitalOcean Singapore — all represent the work of a founder who deliberately built the architecture for team growth from the start.

**Why the signal processing runs from mathematical foundations, not library wrappers**: The founder holds a primary bachelor's degree in Vehicle Engineering, with core coursework in Automatic Control Principles (PID controllers, transfer functions, state-space models, stability analysis) and Signals & Systems (Fourier transforms, Laplace transforms, filter design, frequency domain analysis). These are the exact mathematical foundations behind the Kalman filter family, H-infinity filters, wavelet transforms, and the full DSP pipeline. The implementations in Kokoro Alpha Lab are not bolted-on library calls — they are the direct application of formally trained control systems expertise to financial time series. This is the reason the H-infinity filter implementation includes 4-state modeling with innovation gating, the UKF uses Cholesky sigma points from nalgebra, and the wavelet CWT operates across 20 log-spaced scales for multi-resolution analysis. Each choice reflects mathematical understanding, not API usage.

**Why the financial modeling is correct from foundations**: The founder also holds a double degree in Financial Engineering, with coursework in portfolio theory (Markowitz MVO, CAPM), derivatives pricing (Black-Scholes, options Greeks), risk management (VaR, CVaR, stress testing), and financial mathematics (stochastic processes, Ito's lemma). The quantitative finance implementations across the platform — Markowitz optimization with Lagrangian and projected gradient descent, Black-Scholes with full Greeks, GARCH MLE, conformal prediction calibration — are textbook knowledge applied to production systems, not reimplementations from Stack Overflow.

The AI-augmented development infrastructure — the Agent Orchestra system (multi-agent Claude Code orchestration), the 98-tool MCP server for autonomous platform interaction, and the `claude-dev-pipeline` skill for parallel feature development — provides development velocity equivalent to a team of 3–5 engineers. But this infrastructure is not a permanent substitute for hiring; it is the infrastructure that makes hiring efficient. When the first Rust engineer joins, they inherit an orchestration pipeline, a complete test suite, and a codebase where each of 63 crates is independently testable. When the first frontend engineer joins, they find stable API contracts and over 200 existing pages as a reference. This is what investment-ready architecture looks like.

The founder brings expertise across: Rust systems programming (330,000+ lines across 100+ crates), quantitative finance (11 DSP filter implementations, 24 alpha factors, backtesting infrastructure — grounded in formal control systems + financial engineering education), blockchain and DeFi engineering (6 EVM chains, 20 Anchor programs, complete Polymarket SDK), full-stack web development (200+ API endpoints, 200+ frontend pages), and infrastructure and DevOps (3-server deployment across 3 cloud providers, self-built WireGuard mesh VPN).

### Scalability Architecture: How the Codebase Enables Team Growth

The Clean Integration Layer (CIL) architecture is not just a technical discipline — it is a hiring architecture. Each of the 63 pure-logic crates is an independently assignable unit of work:

- **Factor crates** (`factor-momentum`, `factor-regime`, `factor-equity`, etc.): A new quant researcher or Rust engineer can own a single factor crate. The `AlphaFactor` trait defines the interface contract. The test suite provides acceptance criteria. The crate compiles independently with zero I/O dependencies. Onboarding to productive contribution is measured in days.
- **Execution backend crates** (`exec-alpaca`, `exec-ib`, `chain-adapter`): A blockchain specialist or systems engineer can own the execution layer for a specific venue or chain without touching the signal processing or risk management layers.
- **Frontend pages**: The 107-route frontend has stable API contracts backed by the 98 MCP tools. A frontend specialist can ship pages independently without coordinating with the Rust team.
- **Infrastructure boundary**: The DigitalOcean Singapore server is a self-contained boundary. A DevOps engineer can own it — Docker Compose files are self-documenting, Prometheus and Grafana provide complete observability, and the WireGuard mesh handles inter-server routing transparently.

### Operations Model

**Development**: Feature development uses AI-augmented workflows. New crates and features are developed in git worktrees using the Agent Orchestra system for parallel execution. The typical cycle: research phase (identify requirements, review codebase), implementation (parallel agents if multiple independent features), review (automated code review agent), merge and test, deploy. This same pipeline accommodates human engineers at every step — it was designed for hybrid human+AI teams, not just AI-only operation.

**Customer support**: Initially handled directly by the founder. At scale, a help documentation site and Discord community reduce direct support load. Enterprise customers receive dedicated Slack or Discord channel support as part of their contract.

**Infrastructure**: The current three-server deployment (DigitalOcean Singapore as primary, AWS Ireland and AWS London for secondary services) connected via self-built WireGuard mesh provides a solid foundation. Scaling compute for additional users is straightforward given the Rust binary's low per-request overhead. Horizontal scaling requires adding a load balancer and shared PostgreSQL instance — standard work.

**Hiring plan**: The path is defined by the architecture.

| Stage     | ARR Trigger | First Hire                | Why                                                                         |
| --------- | ----------- | ------------------------- | --------------------------------------------------------------------------- |
| Near-term | $250K       | Customer success / devrel | Reduce founder time on support, grow the community                          |
| Growth    | $500K       | Rust backend engineer     | Own `factor-X` and `exec-Y` crate development — plug into existing pipeline |
| Scale     | $1M         | Quant researcher          | Full-time factor research and backtesting — owns the research environment   |
| Expansion | $2M         | Frontend + DevOps         | Accelerate product surface and infrastructure — own their boundaries        |

Each hire boundary is already defined in the codebase. The architecture is not waiting for investment to become team-ready — it is team-ready today.

---

## 10. Risks and Mitigations

### Key-Person Concentration Risk

**Risk**: In the current founder-led phase, key technical decisions and operational knowledge are concentrated with the founder. Illness, burnout, or a transition period could slow development.

**Mitigation**: The architecture is the mitigation. The CIL's 63 independently testable crates, the 1,074-test suite, the `constitution.md` architectural intent document, and the CLAUDE.md system mean the codebase is accessible to a new engineer without extended knowledge transfer. The Agent Orchestra system enables development work to proceed with minimal active supervision. The MCP tools expose all operational tasks through a structured interface. The hiring plan above defines the path to reducing key-person concentration as soon as revenue allows.

### Market Adoption Risk

**Risk**: The product is technically deep but inaccessible to its target market. Quant developers are sophisticated buyers who evaluate tools rigorously. A tool that takes weeks to understand will not be adopted.

**Mitigation**: The free tier strategy allows risk-free evaluation. The onboarding wizard, interactive factor playground, and tutorial content reduce time-to-first-value. The MCP integration means users familiar with Claude Code can interact with the platform immediately without learning a proprietary UI. The documentation investment (factor reference, API docs, tutorial articles) directly addresses this risk.

### Regulatory Risk

**Risk**: Algorithmic trading tools may face regulation in certain jurisdictions. Prediction market access is restricted or illegal in some regions. The platform's multi-asset execution capabilities could attract regulatory scrutiny.

**Mitigation**: The platform is a research and execution infrastructure tool, not a financial advisor or regulated broker. Users are responsible for their own trading activities and regulatory compliance. The self-hosted deployment model means Kokoro Tech does not hold user funds or execute trades on users' behalf. Clear terms of service and geographic access controls for restricted jurisdictions are standard precautions. Consulting legal counsel before any public launch is advisable.

### Competition Risk

**Risk**: A well-funded competitor (Quantopian successor, QuantConnect with a self-hosted offering, or a crypto-native quant platform) enters the market with a larger engineering team.

**Mitigation**: The CIL architecture and WASM plugin ecosystem create structural switching costs once adopted. The technical depth of the DSP filter implementations is defensible — replicating them requires domain expertise that cannot be purchased quickly. The community and marketplace flywheel (once activated) creates network effects that compound over time. Speed of iteration via AI-augmented development is a durable advantage because it is embedded in the development workflow, not just a temporary sprint.

### Technical Debt and Maintenance Risk

**Risk**: A 242,000-line codebase maintained by a lean founder-led team can accumulate subtle technical debt, especially under production load. The Redis Streams dual JSON/proto migration, the gRPC cross-binary communication, the 65-crate workspace dependency graph — each is a potential failure mode under production load.

**Mitigation**: The 1,074-test suite provides regression coverage. The CIL architecture limits coupling between components. The Redis Streams migration to proto format was designed with backward compatibility (dual-format auto-detection at the consumer level). The platform has been running in production continuously, which means the most common failure modes have been encountered and fixed. Systematic monitoring (Prometheus metrics, Grafana dashboards, structured logging via the tracing crate) provides early warning of degradation.

### Execution and Funding Risk

**Risk**: The platform requires investment in go-to-market, documentation, and customer success to convert from a technically impressive project to a sustainable business. Without external funding, growth is constrained by the founder's time.

**Mitigation**: The SaaS model is designed for bootstrapped growth — infrastructure costs are low, gross margins are high, and the free tier generates organic growth without paid acquisition. The path to profitability requires only 10–15 paying customers, which is achievable through direct outreach to the quant developer community before any significant marketing spend. Keeping operating costs low and reinvesting early subscription revenue into content and documentation extends the runway without requiring outside capital.

---

## Conclusion

Kokoro Alpha Lab occupies a genuinely underserved position in the quantitative trading tools market: institutional-grade signal processing and factor research infrastructure, available as a self-hosted platform, built in Rust for performance and correctness, with depth that no existing commercial product matches. The 242,000-line codebase, 24 alpha factors, 11 DSP filters, and WASM plugin ecosystem represent a durable technical foundation.

The path from current state (production deployment, maintenance mode) to commercial product is primarily a go-to-market and product polish challenge — the technical infrastructure is built. The key milestones are: architecture migration, payment integration, documentation site launch, free tier public opening, and first 50 paying users. Each is achievable within 6–12 months with disciplined execution.

The financial projections are modest and deliberately conservative. Reaching $500K ARR in the first 18 months of paid operation would position the platform as a sustainable independent business with the resources to accelerate development and expand the team. The combination of technical depth, clean architecture, and AI-augmented development velocity makes this a realistic objective.

---

_All financial projections are hypothetical and based on industry benchmarks, not historical actuals. Forward-looking statements involve risk and uncertainty. Actual results may differ materially._

---

**Next steps:** [Contact us →](../services/contact.md) | [How We Work →](../services/how-we-work.md) | [View technical profile →](../profile/resume.md)

---

_Kokoro Tech — [tech.happykokoro.com](https://tech.happykokoro.com) · [GitHub](https://github.com/happykokoro) · [Contact](../services/contact.md)_
