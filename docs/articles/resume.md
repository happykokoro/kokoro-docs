# The Architect Behind Kokoro Tech: A Founder Profile

## One Developer. Fourteen Products. Half a Million Lines of Code.

There is a common assumption in the technology industry that building serious, institutional-grade infrastructure requires teams — squads of engineers, months of sprints, layers of management. The career of the founder behind Kokoro Tech challenges that assumption in a way that is difficult to dismiss.

Over the course of roughly eighteen months, a single developer — working across Rust, TypeScript, Python, Go, and Solidity — designed, built, and deployed a portfolio of fourteen products spanning quantitative trading research, blockchain protocol engineering, AI agent orchestration, and SaaS infrastructure. The combined codebase exceeds 530,000 lines of production code. It includes 1,860 automated tests, 100-plus Rust crates, twenty Anchor programs on Solana, and 115 purpose-built tools for AI agent interaction. Three cloud servers, distributed across DigitalOcean Singapore, AWS Ireland, and AWS London, run this infrastructure — all connected via a self-built WireGuard mesh VPN.

This is not a portfolio of side projects and prototypes. These are production systems with real deployments, real money, and real architectural decisions made under real constraints. Understanding what was built, how it was built, and why it matters requires tracing the journey from its foundations.

---

## The Journey: From Blockchain Foundations to a Full Trading Ecosystem

The story begins in 2021, when the developer first engaged seriously with distributed systems through blockchain infrastructure. Two years of foundational work — building a Go-based public blockchain implementation, a blockchain demonstration system, and a library of data structures used in coding interview preparation — established the systems thinking and low-level discipline that would define everything that followed.

The work remained in relative quiet through 2024. Then, in the first quarter of 2025, it accelerated sharply.

The Kokoro Protocol emerged as the first major vertical deliverable: twenty Anchor programs deployed on Solana, covering decentralized finance primitives (AMM, lending, yield vaults, liquidation, leveraged positions), six distinct casino game types, prediction markets, NFT auctions, and governance infrastructure. This was not a single smart contract with a few functions. It was a complete on-chain platform with house pool LP management, reward and rakeback systems, and circuit breakers — representing deep fluency in the Solana programming model.

The second and third quarters of 2025 brought the most ambitious undertaking: the Kokoro Alpha Lab, a 242,466-line Rust monorepo organized around a principle the developer calls the Clean Integration Layer (CIL). The philosophy is architectural: sixty-three crates in the monorepo contain pure business logic with zero I/O dependencies, while only three I/O binaries interact with the outside world. Every piece of trading logic — signal processing, factor computation, execution routing — can be tested as a pure function and is theoretically portable to WebAssembly. The monorepo carries 1,074 automated tests and was, in its entirety, built and managed by one person.

The fourth quarter of 2025 turned toward infrastructure hardening: self-hosted services, Docker orchestration, and the monitoring stack that would support everything deployed after it.

Then came the most productive single quarter in the portfolio's history. In January and February 2026, the developer shipped a multi-chain DeFi liquidation bot running across six EVM chains simultaneously, a wallet monitoring service capable of tracking 50,000 graph nodes with hourly Louvain community re-clustering, a real-time pricing service aggregating four concurrent DEX sources per token, a Polymarket trading bot running eight parallel strategy pipelines from a single binary, and a copy trading system deployed on AWS London. In March 2026, three more products shipped: Kokoro MM (a Polymarket automated market-making SaaS now live at mm.happykokoro.com), Kokoro Pipeline (a developer automation engine currently undergoing a Rust-to-TypeScript migration), and Kokoro VPN (a self-hosted WireGuard platform with a Tauri v2 desktop client). Alongside these, the developer published four developer tools: agent-orchestra, claude-init, claude-dev-pipeline, and a suite of 115 MCP tools that expose the full trading platform API to AI agents.

Every product in this timeline was built by a single developer leveraging AI-augmented development workflows.

---

## Deep Competency: Systems Programming at Scale

At the technical core of everything Kokoro Tech builds is Rust — and not Rust used superficially. The portfolio contains over 330,000 lines of production Rust code spanning more than 100 crates. This breadth covers trading engines, blockchain protocol adapters, signal processing pipelines, API servers, VPN infrastructure, and more.

The architectural sophistication runs deep. The async patterns across these systems use the Tokio runtime with per-entity task management, lock-free concurrent state via DashMap, AtomicBool, and AtomicI64 primitives, and cooperative shutdown handling that ensures clean process termination under error conditions. The Clean Integration Layer architecture, invented and applied at scale across the Alpha Lab, represents an original contribution to monorepo design: by enforcing that business logic crates contain zero I/O, the developer made the entire trading logic surface area unit-testable as pure functions and WASM-portable without modification.

Across the codebase, 21-plus async trait hierarchies define pluggable extension points for factors, execution backends, protocol adapters, data sources, and risk gates. This is not over-engineering — it is the trait-based plugin system that allows a single binary to run eight strategy pipelines, swap in different execution backends per deployment, and integrate new blockchain protocols without restructuring existing code.

---

## Deep Competency: Quantitative Finance

The quantitative finance capabilities built into the Kokoro ecosystem are the kind typically found inside proprietary trading desks, not individual developer portfolios.

The signal processing pipeline in Kokoro Alpha Lab implements eleven production-grade digital signal processing filters from mathematical foundations — not wrappers around existing libraries, but direct implementations of H-infinity filtering with a four-state model and innovation gating, the Unscented Kalman Filter using Cholesky sigma points, a particle filter with importance resampling, the Interacting Multiple Model filter running three-regime Kalman transitions, the Rao-Blackwellized Particle Filter, a dual Kalman architecture, wavelet Continuous Wavelet Transform, Hilbert transform, Mellin transform, EWMA, and Fourier analysis. Each of these is a non-trivial numerical implementation. Together they form a pipeline that can track, smooth, and decompose price signals at a level institutional systems handle but retail tooling does not offer.

Sitting on top of that signal infrastructure are twenty-four alpha factor implementations, each conforming to the AlphaFactor trait: swap momentum, price trend, order flow, cluster activity, depth quality, a Hawkes process (a self-exciting point process borrowed from seismology and applied to order arrival dynamics), AMM state factors, regime detection, an AI ensemble built on a Deep Q-Network, whale flow, smart money consensus, equity factors (four), options factors (four), forex, and social sentiment. This breadth reflects genuine domain coverage, not surface-level familiarity.

The market-making engine at the heart of Kokoro MM implements the full Avellaneda-Stoikov framework — the academic market-making model that derives optimal bid-ask spreads under inventory risk. The implementation includes multi-source fair value estimation with exponential freshness decay, EWMA filtering, and velocity tracking; inventory-skewed quoting that adjusts spreads as positions accumulate; adverse selection detection with cancellation waves to protect against toxic order flow; and laddered breakout strategies for when directional signals are strong. The full quoting cycle — discover, compute fair value, size the spread, submit quotes, sync state, settle — completes within a two-second engine tick.

Risk management throughout the platform is composable: risk gates form chains that return Pass, Reject, or Resize decisions. VaR and CVaR are implemented in both parametric and historical forms. Kelly criterion sizing is available with configurable fractions (the Polymarket bot uses quarter-Kelly at 0.25). Circuit breakers use AtomicBool for lock-free trips. Drawdown management, per-asset exposure limits, and adaptive position sizing round out a risk stack that gives the platform institutional-grade guardrails.

The statistical modeling layer adds GARCH(1,1) fitted via grid-search maximum likelihood estimation, Hurst exponent analysis using R/S analysis for regime classification, copula modeling in Gaussian, Student-t, and Clayton families, conformal prediction, the Hedge algorithm for expert aggregation, the Augmented Dickey-Fuller stationarity test, and jump detection at a configurable sigma threshold.

---

## Deep Competency: Blockchain and DeFi Engineering

The blockchain work spans multiple chains, multiple protocol paradigms, and multiple layers of the stack — from Solidity at the contract level to Rust protocol adapters to React frontends that display on-chain data in real time.

On Solana, the twenty Anchor programs constitute a complete DeFi ecosystem. The AMM, lending, yield vault, liquidation, and leveraged position programs implement the standard building blocks of on-chain finance, while the six casino game contracts demonstrate the breadth of composability possible on Solana's high-throughput architecture. The prediction market and NFT auction programs, combined with governance infrastructure, round out a protocol suite that could support an independent DeFi application.

On the EVM side, the liquidation bot represents a production-grade multi-chain operation. Six chains run simultaneously — Ethereum, Base, Arbitrum, Polygon, Optimism, and Avalanche — with four lending protocol integrations: Aave V3, Compound V3, Seamless, and Moonwell. The bot monitors positions with health factors below 1.05, scans every five seconds, and triggers liquidations via a custom Solidity contract that performs the full flash loan sequence — atomic borrow, liquidate, swap, repay — without requiring any capital from the operator. The circuit breaker trips after five consecutive on-chain reverts, protecting against systematic execution failures. The minimum profit threshold per liquidation is one dollar USD, with a maximum gas price ceiling of five Gwei and per-transaction gas budgets of 0.01 ETH. At last count, approximately 270 borrowers are in the discovery database and roughly 21 positions are actively monitored, with Ethereum as the primary chain.

Polymarket integration goes beyond basic API access. The implementation includes the complete CLOB REST and WebSocket interface, EIP-712 typed data signing implemented via manual Keccak256 (not a library wrapper), HMAC authentication, and CTF token operations for the conditional token framework that underlies Polymarket's prediction market mechanism. Multi-venue routing extends this to Kalshi and Manifold. The eight-profile trading bot fleet runs eight parallel strategy pipelines — each with different quantitative models including GARCH, Hurst exponent, Brownian Bridge path conditioning, bilateral market making, and momentum — all sharing a single data feed from a single binary process.

DEX integration covers Jupiter V6 (swap routing, quotes), Raydium AMM (pool state), Orca Whirlpool (position tracking), Uniswap V3 (exactInputSingle, QuoterV2, fee tier selection), and Pump.fun detection. The on-chain intelligence layer adds Louvain community detection via the petgraph library for wallet cluster analysis, whale tracking, smart money consensus signals, token flow analysis, and a MEV strategy framework covering arbitrage, just-in-time liquidity, liquidation, and sandwich patterns.

The cryptographic implementations throughout these systems are deliberate and correct: EIP-712 typed signing, ECDSA key management, AES-256-GCM encryption, HKDF key derivation, Argon2 password hashing, and TOTP two-factor authentication — none of these delegated to third-party identity providers.

---

## Deep Competency: Full-Stack Web Development

The backend APIs across the Kokoro ecosystem — primarily Axum for the Rust services — expose over 200 REST endpoints. JWT, API-key, and TOTP authentication are all implemented, with tier-gated middleware enforcing access levels across the SaaS products. Rate limiting, Prometheus metrics instrumentation, and structured logging via the Rust tracing crate are standard across services. Express and Node.js handle additional routes (50-plus), FastAPI serves Python components, and Gin underpins the Go services.

On the frontend, the portfolio includes over 200 pages and routes built in Next.js 15 and 16 with React 19 and Tailwind v4. Six charting libraries are in active use — TradingView for candlestick and order book visualization, Recharts and Chart.js for analytics dashboards, Plotly for statistical outputs, D3 for custom visualizations, and React Flow for the strategy builder canvas in Kokoro Pipeline. Real-time updates throughout the frontends use Server-Sent Events with exponential backoff reconnection logic. State management uses Zustand for client state and SWR for data fetching and cache invalidation.

The Kokoro VPN desktop application is built on Tauri v2 with React 19 and Vite 6 — a native desktop binary that provides a full GUI for WireGuard peer management, firewall ACL configuration, and Prometheus-backed monitoring of mesh network health.

Database design across the ecosystem covers PostgreSQL with complex schemas, 21-plus query modules, and the repository pattern implemented via SQLx and Prisma; Redis Streams with 10 named streams, dual-format encoding in both JSON and Protocol Buffers with consumer groups for parallel processing; SQLite for lightweight embedded persistence; and JSONL-format event sourcing for audit trails.

---

## Deep Competency: Infrastructure and DevOps

The three cloud servers running this ecosystem — a DigitalOcean Singapore droplet, an AWS Ireland instance, and an AWS London instance — are not independent deployments. They form a unified mesh connected by a self-built WireGuard VPN on the 10.10.0.0/24 subnet, with per-node ACL firewall rules generated programmatically from the VPN configuration. The mesh was built as an internal tool to secure inter-service communication, then productized into Kokoro VPN as a self-hosted platform others can run.

Production workloads run in Docker Compose stacks with multi-stage Rust build pipelines (keeping final images lean), health checks, named volumes, and network isolation between service groups. The self-hosted ecosystem includes eleven utility services: Umami analytics, Gitea, Uptime Kuma, Excalidraw, Shlink URL shortener, PrivateBin, Linkding, Syncthing, a Homepage dashboard, Grafana, and Prometheus. Reverse proxying uses Caddy for automatic HTTPS certificate management on public endpoints, Nginx for internal routing, and Cloudflare for DNS, CDN acceleration, and DDoS mitigation.

Observability is first-class: Prometheus metrics are instrumented on all services, Grafana dashboards provide visualization, OpenTelemetry tracing gives distributed traces across service boundaries, Uptime Kuma monitors external availability, and structured logging via the tracing crate provides consistent log formats for programmatic analysis.

Security is treated as a design constraint rather than an afterthought. WireGuard mesh networking eliminates public exposure of internal services. SOPS manages secrets in version-controlled configuration. Flashbots integration protects MEV-sensitive transactions from front-running. Per-user key derivation isolates cryptographic material between accounts. Feature-gated live signing ensures that live execution paths require explicit enablement.

---

## Deep Competency: AI Agent Systems and Developer Tooling

One of the more unusual elements of this portfolio is the meta-tooling layer: the developer built dedicated systems to make themselves more productive, and several of those systems became products in their own right.

The MCP (Model Context Protocol) servers expose the full trading platform to AI agents. Two MCP servers with 115 tools between them allow Claude — Anthropic's AI assistant — to query live signal data, inspect factor states, run backtests, check positions, and interact with the trading engine through a structured protocol. This is not a convenience layer; it is the interface through which the developer conducts research and interacts with running systems during the trading day.

Agent Orchestra is the orchestration platform that manages teams of Claude Code agents. Built in Python with a WebSocket-based dashboard, it implements a seven-phase automated lifecycle: launch agents in parallel → wait for completion → analyze outputs → merge pull requests in dependency order → run build → run tests → report results. Worktrees provide isolation between agents working on the same repository simultaneously. An approval gate pauses the pipeline on merge conflicts, build failures, or test failures, broadcasting a decision card to the dashboard. Critical errors (out-of-space, out-of-memory) trigger automatic agent termination. This system was used to build Phase 2 of the Alpha Lab with six parallel agents — a real-world demonstration of multi-agent software development at scale.

Claude Init is a 1,229-line Python CLI with zero external dependencies that auto-generates the complete .claude/ configuration directory for any project. It detects the primary language from nine possibilities, identifies the framework from eighteen options, and produces settings.json, agent definitions, skills, and command configurations tailored to the detected stack. Published open source on GitHub.

The claude-dev-pipeline skill implements a four-phase parallel execution pattern — research, team, review, merge — with atomic pull requests and dependency-aware merge ordering. Domain-specific skills are also available for signal pipeline development, risk management, Kalman filter implementation, Polymarket arbitrage, Anchor program patterns, and DEX integration.

---

## The Failure That Made the Portfolio Credible: Notable Feat #9

A portfolio of this scale, built this quickly, by one person, raises an obvious question: has any of this been tested against reality? The answer is unambiguous — and the most instructive data point comes from a failure.

In early 2026, the Kokoro Polymarket Bot went live. The strategy at the time was fair-value dislocation: find markets where the current price diverged from an estimated fair value, and trade the convergence. The strategy had been backtested. The infrastructure was solid. The risk gates were configured.

Twelve minutes of live trading produced a $55 loss.

The instinctive response to this kind of failure is often to blame execution — slippage, bad fills, technical issues. The developer did not take that path. Instead, a formal post-mortem was conducted. Historical data from 11,348 Polymarket markets was analyzed. The research surfaced the real problem: the strategy had a structural directional bias toward Down outcomes, and the backtesting validation was tautological — it validated the model against data that shared the same structural bias. The fair-value dislocation strategy was dead.

But the research did not stop at the diagnosis. Fifteen specific quantitative questions were formulated and analyzed. The Brownian Bridge path conditioning signal — which conditions probability estimates on the known start and end constraints of a prediction market resolution — was validated at 100% accuracy across a sample of eighteen test cases. A hierarchical cascade approach achieved 77.8% accuracy. Per-asset volatility profiles were characterized. A replacement strategy architecture was designed with explicit ranked signal priority: path conditioning first, one-hour spread second, hierarchical cascade third, fifteen-minute lock fourth, five-minute spread fifth, and momentum sixth — the current strategy had been using only the sixth-ranked signal.

The trading account carries approximately $376 in portfolio value against a deposit of $504.75, representing a loss of about $128. The strategy is currently stopped. The replacement architecture is specified, awaiting implementation. The three confirmed infrastructure bugs — GTC exposure handling in risk gates, hold-to-resolution logic, and round-ended skip on SELL — have been patched in code but not yet committed.

This is not a story about failure. It is a story about the kind of rigorous empirical methodology that distinguishes experienced practitioners from theoretical ones. The response to a live trading loss was not abandonment and not denial — it was systematic investigation, quantitative validation, and a better-specified replacement. That is how research-driven trading organizations behave.

---

## The Business Thesis: Institutional Tools for Independent Traders

Kokoro Tech operates from a clear and defensible premise: the quantitative trading tools that hedge funds spend millions of dollars building are inaccessible to individual traders and small teams — not because the mathematics is proprietary, but because no one has built the infrastructure layer that makes them deployable.

Consider the gap. Institutional trading desks use Kalman filters, regime detection models, and multi-factor alpha frameworks as standard practice. Retail traders use moving averages and RSI. Institutional risk management includes composable VaR, CVaR, circuit breakers, and per-position exposure limits. Most retail bots implement a single stop-loss parameter. Trading across prediction markets, decentralized exchanges, and centralized venues requires custom integration work for every combination. Becoming an automated market maker on a prediction market like Polymarket has required bespoke infrastructure that does not exist off-the-shelf.

Kokoro Tech is addressing this gap through a suite of products that can be self-hosted by any trader with basic infrastructure access.

Kokoro Alpha Lab is the quantitative research platform — a self-hosted system with twenty-four alpha factors, eleven DSP filters, walk-forward backtesting, Monte Carlo simulation, and multi-asset execution routing. The value proposition is precise: institutional-grade quantitative research capability, deployable by a single trader, with full data sovereignty. No cloud dependency for core functionality, no telemetry, no strategy logic leaving the user's infrastructure.

Kokoro MM is the market-making SaaS for Polymarket. It implements a complete automated market-making workflow — mint CTF tokens, compute Avellaneda-Stoikov optimal quotes, manage inventory, detect adverse selection, cancel when necessary — on a tiered subscription model. Free tier allows manual operation; MANUAL, SIGNAL, and AUTOPILOT tiers progressively increase API rate limits (from 10 requests per minute at Free to 1,000 at Autopilot), add signal access, and enable full automation. The product is live at mm.happykokoro.com.

Kokoro Liquidation Bot offers DeFi power users passive income from flash-loan liquidations across six EVM chains. Zero capital is required because the custom Solidity contract performs the entire sequence atomically: borrow flash loan, execute liquidation, swap collateral, repay loan. The profit threshold, gas budget, and per-protocol gas estimates are all configurable.

Kokoro Staking, still in the architecture and implementation phase, targets multi-chain validators with a unified portfolio dashboard across seventeen chains — Ethereum, Solana, Cosmos, Polkadot, Avalanche, BNB, and eleven more — with analytics and rebalancing capabilities.

The revenue model across the portfolio combines SaaS subscriptions (Kokoro MM tiers), profit sharing on trading bot deployments (configurable percentage of net profits), marketplace commission on the strategy marketplace planned for Kokoro Pipeline (where strategy creators publish and users subscribe), and enterprise self-hosted licenses for Alpha Lab deployments requiring full data sovereignty.

The competitive advantages are structural. Full-stack ownership means no third-party dependencies for core trading logic — the developer controls the execution path from smart contract to dashboard, enabling faster iteration and eliminating vendor lock-in. Rust performance means signal processing and execution complete in sub-second cycles; the MM engine's two-second quoting loop is a direct result of implementing the critical path in a compiled, zero-overhead language rather than Python. The AI-augmented development model — 115 MCP tools, agent orchestration, custom skills — enables maintenance velocity equivalent to a team while preserving the architectural coherence of a single designer. Privacy-first by default means strategy logic never leaves the user's infrastructure. And the portfolio is battle-tested: real money has been deployed, a live strategy has failed, and the post-mortem produced a better-specified replacement. These are not theoretical systems.

---

## Technical Skills: The Full Stack

**Languages.** Expert-level in Rust and TypeScript. Advanced in Python, Go, Solidity, and SQL. Competent in Shell/Bash, Java, and C/C++.

**Backend frameworks.** Axum and Tokio for high-performance Rust APIs; Tonic for gRPC; Express and Node.js for JavaScript services; FastAPI for Python; Gin for Go; Anchor for Solana program development. Authentication covers JWT, API-key, and TOTP. Middleware covers tier-gating, rate limiting, and Prometheus instrumentation.

**Frontend.** Next.js 15 and 16, React 19, Tailwind v4, Radix UI component primitives, Zustand for state management, SWR for data fetching. Six charting libraries: TradingView, Recharts, Chart.js, Plotly, D3, and React Flow.

**Desktop.** Tauri v2 with React 19 and Vite 6 for the Kokoro VPN client.

**CMS.** Payload CMS 3.77 with custom block types, lexical editor, form builder, SEO plugin, and live preview.

**Database.** PostgreSQL with SQLx and Prisma, Redis Streams, SQLite, and JSONL event sourcing.

**Blockchain.** Solana SDK, Anchor, Alloy for EVM interactions, Jupiter, Raydium, and Orca SDKs, Uniswap V3 interface.

**AI and ML.** MCP Protocol, Claude API, Deep Q-Network implementation, WASM plugin architecture.

**Mathematics libraries.** nalgebra for linear algebra, statrs for statistical distributions, rustfft for FFT, good_lp for linear programming, criterion for benchmarking.

**Testing.** cargo test, Vitest, Playwright end-to-end tests, criterion benchmarks.

**Cloud and containers.** AWS EC2, DigitalOcean Droplets, Docker, Docker Compose with multi-stage builds.

**Networking.** WireGuard, Caddy, Nginx, Cloudflare DNS/CDN/DDoS protection.

**Monitoring.** Prometheus, Grafana, OpenTelemetry, Uptime Kuma, structured logging via the tracing crate.

**CI/CD.** GitHub Actions.

**Security.** SOPS secrets management, Flashbots MEV protection, AES-256-GCM, HKDF, TOTP, JWT, per-user key derivation.

**Domain knowledge.** Quantitative finance (signal processing, factor models, market making via Avellaneda-Stoikov, backtesting, VaR/CVaR/Kelly, Markowitz portfolio optimization). Blockchain and DeFi (Solana programs, EVM contracts, flash loans, DEX integration, prediction markets, NFTs, lending protocols, liquidation engines). Market microstructure (order flow imbalance, Hawkes processes, adverse selection detection, liquidity density estimation, whale detection, Louvain cluster analysis). Cryptography (EIP-712, ECDSA, AES-GCM, HKDF, Argon2, TOTP, WireGuard). AI agent systems (MCP servers, agent orchestration, skill protocols, WASM plugins).

---

## The Numbers at a Glance

The scale of this portfolio is best understood through its aggregate metrics. Over 530,000 lines of production code in Rust, TypeScript, Python, Go, and Solidity. Over 330,000 of those lines in Rust specifically, across more than 100 crates. 1,860-plus automated tests across all projects. 115 MCP tools built across two servers (98 in the lab MCP server, 17 in the Kokoro MM MCP server). Over 200 REST API endpoints. Over 200 frontend pages and routes. Twenty Anchor programs on Solana. Twenty-three blockchain chains integrated — six EVM chains for the liquidation bot plus Solana, plus seventeen staking chains in the Staking product. Eight-plus DeFi protocols integrated. Five exchange data feeds (Binance, Coinbase, Deribit, Pyth, Polymarket). Three production servers across three regions and three cloud providers. Twelve-plus Docker containers in production. Eleven self-hosted utility services. One founder.

---

## Open Source Contributions

Three projects from this portfolio are publicly available. **claude-init** auto-generates .claude/ configuration directories for any project by detecting language and framework from project structure — available on GitHub. **claude-dev-pipeline** implements a parallel development pipeline skill for Claude Code under the MIT license. **kokoro-vpn** is the self-hosted WireGuard VPN platform, also published under the MIT license.

---

## Contact

**GitHub (Organization):** https://github.com/happykokoro

**GitHub (Personal):** https://github.com/anescaper

**Company Website:** https://tech.happykokoro.com

**Portfolio:** https://happykokoro.com

Email and LinkedIn available upon request.
