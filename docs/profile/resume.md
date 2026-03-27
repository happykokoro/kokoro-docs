# Professional Resume Profile

> Comprehensive professional profile suitable for resume, CV, LinkedIn, company promotion, and investor presentations. All claims are backed by specific, verifiable implementations.

---

## Professional Summary

Full-stack systems engineer and quantitative developer who single-handedly designed, built, and deployed a 14-product technology portfolio spanning quantitative trading, blockchain infrastructure, AI agent systems, and SaaS platforms. The combined codebase exceeds 530,000 lines of production code across Rust, TypeScript, Python, and Go, with 1,860+ automated tests, deployed across 3 cloud servers connected via self-built WireGuard mesh VPN.

Specializes in high-performance Rust systems for financial applications, real-time data pipelines, blockchain protocol integrations, and AI-augmented development workflows. Operates as a solo founder managing the full stack from Solidity smart contracts to React dashboards to Docker orchestration.

---

## Project Timeline

| Period            | Focus                   | Key Deliverables                                                                                               |
| ----------------- | ----------------------- | -------------------------------------------------------------------------------------------------------------- |
| 2021-2022         | Blockchain foundations  | PublicBlockChain (Go), blockchain-demo, coding interview prep                                                  |
| 2025 Q1           | Kokoro Protocol         | 20 Anchor programs on Solana (DeFi, gaming, prediction markets)                                                |
| 2025 Q2-Q3        | Kokoro Alpha Lab        | 242K-line Rust monorepo, signal processing pipeline, multi-asset trading                                       |
| 2025 Q4           | Infrastructure buildout | Self-hosted services, Docker orchestration, monitoring stack                                                   |
| 2026 Q1 (Jan-Feb) | Ecosystem expansion     | Liquidation bot (6 EVM chains), wallet monitor, pricing service, polymarket bot (8-profile fleet), copy trader |
| 2026 Q1 (Mar)     | SaaS products           | Kokoro MM (Polymarket AMM), Kokoro Pipeline (dev automation), Kokoro VPN (WireGuard mesh)                      |
| 2026 Q1 (Mar)     | Developer tools         | agent-orchestra, claude-init, claude-dev-pipeline, 115 MCP tools                                               |

> All products built by a single developer leveraging AI-augmented development workflows.

---

## Core Competencies

### Systems Programming & Performance Engineering

- **Rust expertise at scale**: 330,000+ lines of production Rust across 100+ crates spanning trading engines, blockchain adapters, signal processing pipelines, API servers, and VPN infrastructure
- **Async architecture design**: Multi-service single-binary patterns (tokio runtime), per-entity async task management, lock-free concurrent state (DashMap, AtomicBool, AtomicI64), cooperative shutdown
- **Clean Integration Layer (CIL)**: Invented and implemented at scale (242K lines, 63 pure-logic crates + 3 I/O binaries) — a monorepo architecture where business logic crates contain zero I/O, enabling pure-function testing and WASM portability
- **Trait-based plugin systems**: 21+ async trait hierarchies for pluggable factors, execution backends, protocol adapters, data sources, and risk gates

### Quantitative Finance & Algorithmic Trading

- **Signal processing pipeline**: Implemented 11 production-grade filters from mathematical foundations — H-infinity (4-state with innovation gating), UKF (Cholesky sigma points), particle filter (importance resampling), IMM (3-regime Kalman), RBPF, dual Kalman, wavelet CWT, Hilbert transform, Mellin transform, EWMA, Fourier
- **24 alpha factor implementations**: Each implementing the `AlphaFactor` trait — covering swap momentum, price trend, order flow, cluster activity, depth quality, Hawkes process (self-exciting point process), AMM state, regime detection, AI ensemble (DQN), whale flow, smart money, consensus, equity (4 factors), options (4 factors), forex, social sentiment
- **Market making engine**: Full Avellaneda-Stoikov implementation with multi-source fair value estimation (exponential freshness decay, EWMA filtering, velocity tracking), inventory-skewed quoting, adverse selection detection with cancellation waves, laddered breakout strategies
- **Risk management**: Composable risk gate chains (Pass/Reject/Resize), VaR/CVaR (parametric + historical), Kelly sizing, circuit breakers (AtomicBool), drawdown management, per-asset exposure limits, adaptive position sizing
- **Backtesting infrastructure**: BacktestRunner, grid/random parameter optimization, walk-forward analysis, Monte Carlo simulation, synthetic scenario generation
- **Statistical modeling**: GARCH(1,1) (grid search MLE), Hurst exponent (R/S analysis), copulas (Gaussian/Student-t/Clayton), conformal prediction, expert aggregation (Hedge algorithm), ADF stationarity test, jump detection

### Blockchain & DeFi Engineering

- **Solana/Anchor**: 20 Anchor programs spanning DeFi (AMM, lending, yield vaults, liquidation, leveraged positions), gaming (6 casino types), prediction markets, NFT auctions, governance — complete with house pool LP management, reward/rakeback system, and circuit breakers
- **Multi-chain EVM**: Production liquidation bot across 6 EVM chains (Ethereum, Base, Arbitrum, Polygon, Optimism, Avalanche), 4 lending protocols (Aave V3, Compound V3, Seamless, Moonwell), flash loan execution via custom Solidity contract (zero capital required)
- **Prediction market integration**: Complete Polymarket SDK (CLOB REST + WebSocket, EIP-712 signing, HMAC auth, CTF token operations), multi-venue routing (Polymarket/Kalshi/Manifold), 8-profile fleet trading bot with 3 strategy tiers
- **DEX integrations**: Jupiter V6 (swap routing, quotes), Raydium AMM (pool state), Orca Whirlpool (position tracking), Uniswap V3 (exactInputSingle, QuoterV2, fee tier selection), Pump.fun detection
- **On-chain intelligence**: Wallet cluster detection (Louvain community detection on petgraph), whale tracking, smart money consensus, token flow analysis, MEV strategy framework (arb, JIT, liquidation, sandwich)
- **Cryptographic implementations**: EIP-712 typed signing (manual Keccak256), ECDSA key management, AES-256-GCM encryption, HKDF key derivation, Argon2 password hashing, TOTP 2FA

### Full-Stack Web Development

- **Backend**: Axum (Rust, 200+ API endpoints), Express/Node.js (50+ routes), FastAPI (Python), Gin (Go) — JWT/API-key/TOTP auth, tier-gated middleware, rate limiting, Prometheus metrics
- **Frontend**: Next.js 15/16 (200+ pages), React 19, Tailwind v4, 6 charting libraries (TradingView, Recharts, Chart.js, Plotly, D3, React Flow), real-time SSE with exponential backoff, Zustand + SWR state management
- **Desktop**: Tauri v2 VPN client (React 19 + Vite 6)
- **CMS**: Payload CMS 3.77 with custom blocks, lexical editor, form-builder, SEO, live preview
- **Database design**: PostgreSQL (complex schemas, 21+ query modules, repository pattern), Redis Streams (10 streams, dual JSON/proto, consumer groups), SQLite (lightweight persistence), JSONL (event sourcing)

### Infrastructure & DevOps

- **Multi-server deployment**: 3 cloud servers (DigitalOcean Singapore, AWS Ireland, AWS London) connected via self-built WireGuard mesh VPN (10.10.0.0/24)
- **Container orchestration**: Docker Compose stacks with multi-stage Rust builds, health checks, volume management, network isolation
- **Self-hosted ecosystem**: 11 utility services (Umami analytics, Gitea, Uptime Kuma, Excalidraw, Shlink, PrivateBin, Linkding, Syncthing, Homepage, Grafana, Prometheus)
- **Reverse proxying**: Caddy (auto-HTTPS) + Nginx + Cloudflare DNS/CDN/DDoS
- **Monitoring**: Prometheus metrics on all services, Grafana dashboards, OpenTelemetry tracing, Uptime Kuma, structured logging (tracing crate)
- **Security**: WireGuard mesh networking, SOPS secrets management, Flashbots MEV protection, per-user key derivation, feature-gated live-signing

### AI Agent Systems & Developer Tooling

- **MCP Protocol mastery**: Built 2 MCP servers with 115 tools total, exposing full trading platform APIs to Claude for autonomous research and execution
- **Agent orchestration**: Built `agent-orchestra` — Python platform managing Claude Code agent teams with WebSocket dashboard, 7-phase automated lifecycle, worktree isolation, approval gates, critical error auto-kill
- **Development pipeline**: `claude-dev-pipeline` skill implementing 4-phase parallel execution (research → team → review → merge) with atomic PRs and dependency-aware merge order
- **Claude Code tooling**: `claude-init` CLI (1,229 lines Python, zero deps) auto-generates `.claude/` config for any project by detecting language (9), framework (18), and project structure
- **Custom skills**: 7 domain-specific Claude Code skills (dev-pipeline, signal-pipeline, risk-management, kalman-filter, polymarket-arbitrage, anchor-patterns, dex-integration)

---

## Product Portfolio

### Live / Deployed Products (8)

| Product                    | Stack                                             | Description                                                                                                                                    |
| -------------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **Kokoro Alpha Lab**       | Rust (242K LOC), 65 crates, 1074 tests            | Multi-asset quantitative trading research platform with 24 alpha factors, 11 DSP filters, role-based signal composition, multi-chain execution |
| **Kokoro MM**              | Rust (63K LOC) + Next.js 16, 18 crates, 690 tests | Polymarket AMM SaaS with Avellaneda-Stoikov quoting, 4 strategies, autopilot mode, tier-gated billing                                          |
| **Kokoro Liquidation Bot** | Rust (5.1K LOC) + Solidity                        | Multi-chain DeFi liquidation engine: 6 EVM chains, 4 protocols, flash loan execution, zero capital                                             |
| **Kokoro VPN**             | Rust + Tauri v2                                   | Self-hosted WireGuard platform: client VPN + mesh VPN, desktop app, firewall ACL, Prometheus monitoring                                        |
| **Kokoro Protocol**        | Rust/Anchor (20 programs)                         | On-chain DeFi platform: AMM, lending, yield vaults, 7 casino games, prediction market, governance                                              |
| **Kokoro Tech**            | Next.js 16, static export                         | Company marketing website at tech.happykokoro.com                                                                                              |
| **HappyKokoro**            | Next.js 15 + Payload CMS                          | Company website and blog with CMS, contact form, project showcase                                                                              |
| **Kokoro Services**        | Docker Compose                                    | 11 self-hosted productivity services                                                                                                           |

### Trading Bots (2)

| Bot                       | Stack                     | Strategy                                                                             |
| ------------------------- | ------------------------- | ------------------------------------------------------------------------------------ |
| **Kokoro Polymarket Bot** | Rust (15.5K LOC) + Python | 8-profile fleet: GARCH, Hurst, Brownian Bridge, bilateral MM, momentum, regime-aware |
| **Kokoro Copy Trader**    | Python 3.12               | Copy trading: discover top traders, mirror positions, hold to resolution             |

### Developer Tools (4)

| Tool                    | Stack                       | Purpose                                                                  |
| ----------------------- | --------------------------- | ------------------------------------------------------------------------ |
| **Agent Orchestra**     | Python + Rust               | Multi-agent Claude Code orchestration with WebSocket dashboard           |
| **Claude Init**         | Python (zero deps)          | Auto-generate .claude/ config for any project                            |
| **Claude Dev Pipeline** | Markdown skill              | Parallel agent development with atomic PRs                               |
| **Kokoro Pipeline**     | Rust → TypeScript migration | Dev pipeline engine with visual designer, marketplace, multi-tenant SaaS |

### Multi-Chain Staking (1)

| Product            | Stack           | Chains                                               |
| ------------------ | --------------- | ---------------------------------------------------- |
| **Kokoro Staking** | Go + Next.js 16 | 17 chains: ETH, SOL, ATOM, DOT, AVAX, BNB, + 11 more |

---

## Current Status

| Product                | Status                | Notes                                                          |
| ---------------------- | --------------------- | -------------------------------------------------------------- |
| Kokoro Alpha Lab       | Deployed (production) | DigitalOcean Singapore, MAINTENANCE_MODE=true                  |
| Kokoro MM              | Deployed (production) | AWS Ireland, https://mm.happykokoro.com                        |
| Kokoro Liquidation Bot | Deployed (paper mode) | DigitalOcean, ~270 borrowers monitored                         |
| Kokoro VPN             | Deployed (production) | 3-node WireGuard mesh active                                   |
| Kokoro Polymarket Bot  | Stopped               | Fair-value strategy failed live, Brownian Bridge pivot pending |
| Kokoro Copy Trader     | Deployed (paper mode) | AWS London, $100 bankroll                                      |
| Kokoro Protocol        | Development           | Localnet/devnet, not mainnet                                   |
| Kokoro Staking         | Plan only             | Architecture designed, 17 chain adapters coded                 |
| Kokoro Pipeline        | Active development    | Rust→TypeScript migration in progress                          |
| Other services         | Various               | Wallet monitor, pricing service, payment service all deployed  |

---

## Technical Achievements

### Scale Metrics

| Metric                         | Value                                                   |
| ------------------------------ | ------------------------------------------------------- |
| Total production code          | 530,000+ lines (Rust, TypeScript, Python, Go, Solidity) |
| Rust code specifically         | 330,000+ lines across 100+ crates                       |
| Automated tests                | 1,860+ across all projects                              |
| MCP tools built                | 115 (98 + 17)                                           |
| REST API endpoints             | 200+                                                    |
| Frontend pages/routes          | 200+                                                    |
| Anchor programs                | 20                                                      |
| Blockchain chains integrated   | 23 (6 EVM + Solana + 17 staking)                        |
| DeFi protocols integrated      | 8+                                                      |
| Exchange data feeds            | 5 (Binance, Coinbase, Deribit, Pyth, Polymarket)        |
| Production servers             | 3 (connected via WireGuard mesh)                        |
| Docker containers (production) | 12+                                                     |
| Self-hosted services           | 11                                                      |

### Performance Characteristics

Real numbers extracted from production code — not estimates.

**Kokoro MM (Market Making Engine)**

- Engine tick interval: **2s** — every quoting cycle (discover → fair value → spread → quote → sync → settle) completes within one tick
- Round discovery: every **30s** via Polymarket Gamma API
- CLOB WebSocket: real-time order book diffs, **500ms** read timeout per message, reconnect with exponential backoff (1s → 2s → 4s → max 60s)
- Binance/Pyth data feeds: same backoff pattern (1s → max 60s)
- Balance polling: every **15s** for on-chain USDC balance
- API rate limits: 10 req/min (Free) → 60 (Manual) → 300 (Signal) → 1,000 (Autopilot)
- SSE keepalive: **15s** heartbeat interval
- Webhook delivery: max 3 retries with exponential backoff (1s, 2s, 4s), 10s HTTP timeout
- Backtest resolution: **60 ticks per round** for historical replay

**Kokoro Alpha Lab (Signal Pipeline)**

- Redis Streams consumption: **COUNT 10, BLOCK 5000ms** — batches of 10 messages with 5s max wait
- Factor warmup: minimum **20 observations** before producing signals (configurable per factor)
- Kalman filter parameters: Q_price=0.001, Q_velocity=0.0001, R_measurement=0.01, velocity_decay=0.98
- Correlation window: **100 samples** rolling for pairwise factor correlation (FFT-based)
- Factor cache TTL: **1 hour** (moka cache, time-to-idle)
- Strategy reload interval: **300s** (5 minutes)
- Metrics publishing: every **60s**
- Arbitrage scanner: adaptive rate limiter **200ms base → 10s max** between scans
- Jupiter execution timeout: **5s**, Jito bundle timeout: **8s**, max 3 concurrent executions with 1s cooldown
- Jito tip: default 10,000 lamports, max 10M lamports, 50% of profit

**Kokoro Liquidation Bot**

- Health factor scan: every **5s** across all monitored positions
- Borrower discovery: **1,000 blocks** per getLogs batch (free RPC safe)
- Health factor threshold: positions below **1.05** are monitored
- Minimum collateral: **$100 USD** (skip dust)
- Circuit breaker: trips after **5 consecutive reverts**, blocks all execution
- Gas budget: **0.01 ETH per-tx**, **0.1 ETH daily** maximum
- Max gas price: **5 Gwei** ceiling
- Swap slippage: **30 bps** (0.3%)
- Min profit threshold: **$1 USD** per liquidation
- Protocol gas estimates: Aave V3 = 500K gas, Compound V3 = 300K gas, Moonwell = 350K gas
- ETH price refresh: every **60s** from CoinGecko
- P&L aggregation: hourly snapshots

**Kokoro Polymarket Bot**

- Adaptive pipeline frequency: **1s** (final 30s of round) → **2s** (31-60s) → **3s** (61-120s) → **5s** (>120s)
- General (non-crypto) pipeline: **300s** interval
- Risk gates: min edge **12%**, max drawdown **25%**, max **10 positions**, quarter-Kelly (0.25)
- Entry price bounds: **0.12 – 0.88** (avoid extremes)
- Jump detection threshold: **3.0σ**
- Data watchdog: 3x adapter poll interval triggers reconnect
- CLOB WS ping: every **10s**, stale timeout **120s**
- Data feed inactivity timeouts: Coinbase 30s, Binance spot 30s, futures 600s, Deribit 120s

**Kokoro Pricing Service**

- Pyth oracle poll: every **3s** (fastest feed)
- General token poll: every **30s**
- OFI calculation: **1s** L2 snapshot poll, **5s** summary publish
- Jupiter quote rate limit: **100ms** between calls (10 calls/sec)
- Depth estimation sizes: [0.1, 0.5, 1.0, 5.0, 10.0] SOL
- Max tracked tokens: **20** simultaneous
- 4 concurrent DEX sources per aggregation (Pyth + Jupiter + Raydium + Orca)

**Kokoro Wallet Monitor**

- One tokio task **per wallet** — fully concurrent, no concurrency limit
- WebSocket reconnect: **1s → 2s → 4s → max 60s** on error, instant reconnect on clean close
- Louvain graph re-clustering: every **1 hour**
- Coordination check: every **5 minutes**
- Max graph nodes: **50,000**
- Graph pruning: entries older than **30 days** removed

### Notable Engineering Feats

1. **242,466-line Rust monorepo** with Clean Integration Layer — 63 pure-logic crates, 3 I/O binaries, 1,074 tests, all managed by a single developer
2. **11 DSP filters implemented from mathematical foundations** — not wrappers around libraries, but direct implementations of H-infinity, UKF, particle filter, IMM, RBPF, wavelet, Hilbert, Kalman algorithms
3. **Flash loan liquidation bot** operating across 6 EVM chains simultaneously — zero capital required, custom Solidity contract for atomic borrow-liquidate-swap-repay
4. **20 Solana Anchor programs** spanning DeFi (AMM, lending, yield, liquidation, leverage), gaming (6 types), prediction markets, NFT, and governance
5. **Multi-agent orchestration system** managing Claude Code agent teams with automated merge, build, test pipeline — used to build Phase 2 of alpha-lab with 6 parallel agents
6. **Dual-format Redis Streams migration** — seamless JSON→proto transition across 10 streams with zero-downtime auto-detection at consumer level
7. **Self-built WireGuard mesh VPN** connecting 3 servers across 3 cloud providers (DigitalOcean Singapore, AWS Ireland, AWS London) with per-node ACL firewall generation
8. **8-profile trading bot fleet** — single binary running 8 parallel strategy pipelines sharing one data feed, each with different quant models (GARCH, Hurst, Brownian Bridge, bilateral MM)
9. **Live trading failure → data-driven pivot**: Polymarket bot's fair-value dislocation strategy lost $55 in 12 minutes of live trading. Conducted post-mortem, analyzed 11,348 historical markets, validated Brownian Bridge path conditioning (100% accuracy n=18), and designed replacement strategy architecture — demonstrating real-world trading experience and rigorous empirical research methodology

### Open Source Contributions

- **claude-init** — Auto-generate .claude/ configuration for any project (public, GitHub)
- **claude-dev-pipeline** — Parallel development pipeline skill for Claude Code (public, MIT license)
- **kokoro-vpn** — Self-hosted WireGuard VPN platform (public, MIT license)

---

## Technical Skills Summary

### Languages (by proficiency)

```
Expert:    Rust, TypeScript
Advanced:  Python, Go, Solidity, SQL
Competent: Shell/Bash, Java, C/C++
```

### Frameworks & Libraries

```
Backend:     Axum, Tokio, Tonic, Express, FastAPI, Gin, Anchor
Frontend:    Next.js, React, Tailwind, Radix UI, Zustand, SWR
Desktop:     Tauri v2
Database:    PostgreSQL (SQLx/Prisma), Redis Streams, SQLite
Blockchain:  Solana SDK, Anchor, Alloy (EVM), Jupiter, Raydium, Orca
Charting:    TradingView, Recharts, Plotly, D3, React Flow
AI/ML:       MCP Protocol, Claude API, DQN, WASM plugins
Math:        nalgebra, statrs, rustfft, good_lp, criterion
Testing:     cargo test, Vitest, Playwright, criterion benchmarks
```

### Infrastructure

```
Cloud:       AWS (EC2), DigitalOcean (Droplets)
Containers:  Docker, Docker Compose
Networking:  WireGuard, Caddy, Nginx, Cloudflare
Monitoring:  Prometheus, Grafana, OpenTelemetry, Uptime Kuma
CI/CD:       GitHub Actions
Security:    SOPS, Flashbots, AES-256-GCM, HKDF, TOTP, JWT
```

### Domain Knowledge

```
Quantitative Finance:  Signal processing, factor models, market making, backtesting,
                       risk management (VaR/CVaR/Kelly), portfolio optimization (Markowitz)
Blockchain/DeFi:       Solana programs, EVM contracts, flash loans, DEX integration,
                       prediction markets, NFTs, lending protocols, liquidation engines
Market Microstructure: Order flow imbalance, Hawkes processes, adverse selection,
                       liquidity density, whale detection, cluster analysis
Cryptography:          EIP-712, ECDSA, AES-GCM, HKDF, Argon2, TOTP, WireGuard
AI Agent Systems:      MCP servers, agent orchestration, skill protocols, WASM plugins
```

---

## Company Profile (Kokoro Tech)

**Kokoro Tech** is a deep technology studio building quantitative trading infrastructure, blockchain protocols, and AI-augmented developer tools.

### Mission

Democratize institutional-grade quantitative trading technology for individual traders and small teams. The tools that hedge funds spend millions building — signal processing pipelines, risk management engines, multi-chain execution infrastructure — should be accessible as self-hosted, privacy-first SaaS products.

### Problem

Individual crypto and prediction market traders lack access to:

- **Signal processing**: Institutional desks use Kalman filters, regime detection, and factor models. Retail traders use moving averages and RSI.
- **Risk management**: No composable risk gates, no VaR/CVaR, no circuit breakers. Most retail bots have a single stop-loss.
- **Multi-venue execution**: Trading across Polymarket, DEXes, and centralized exchanges requires separate tools with no unified view.
- **Market making**: Becoming an AMM liquidity provider on prediction markets requires custom infrastructure that doesn't exist off-the-shelf.

### Products Addressing This

| Product                    | Target User                     | Value Proposition                                                                                                                                                         |
| -------------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Kokoro Alpha Lab**       | Quant researchers, algo traders | Self-hosted trading research platform with 24 alpha factors, 11 DSP filters, backtesting, and multi-asset execution — the "QuantConnect for crypto" but fully self-hosted |
| **Kokoro MM**              | Prediction market traders       | One-click market making on Polymarket — mint CTF tokens, quote spreads, manage inventory automatically. Tiered from free manual to full autopilot                         |
| **Kokoro Liquidation Bot** | DeFi power users                | Passive income from liquidating undercollateralized loans across 6 EVM chains — zero capital via flash loans                                                              |
| **Kokoro Staking**         | Multi-chain validators          | Unified staking dashboard across 17 chains with portfolio analytics and rebalancing                                                                                       |

### Revenue Model

- **SaaS subscriptions**: Kokoro MM — FREE / MANUAL / SIGNAL / AUTOPILOT tiers with increasing API rate limits, signal access, and automation
- **Profit sharing**: Trading bots take a percentage of net profits (configurable per deployment)
- **Marketplace commission**: Strategy marketplace in Kokoro Pipeline — creators publish, users subscribe, platform takes commission
- **Self-hosted licenses**: Enterprise deployments of Alpha Lab for teams wanting full data sovereignty

### Competitive Advantage

1. **Full-stack ownership**: From Solidity contracts to Rust engines to React dashboards — no third-party dependencies for core trading logic. This means faster iteration, no vendor lock-in, and complete control over the execution path
2. **Rust performance**: Signal processing and execution in Rust (not Python) enables sub-second pipeline cycles. The MM engine completes a full quoting cycle in under 2 seconds
3. **AI-augmented development**: 115 MCP tools + agent orchestration system enables a single developer to maintain 14 products. The development velocity of a team, the coherence of a single architect
4. **Privacy-first**: Self-hosted by default. Strategy logic never leaves the user's infrastructure. No telemetry, no cloud dependency for core functionality
5. **Battle-tested**: Real money deployed on Polymarket (including a failed strategy that led to a data-driven pivot) — not theoretical, not backtested-only

### Key Numbers

- 14 products in portfolio
- 530,000+ lines of production code
- 100+ Rust crates
- 20 Anchor programs on Solana
- 115 MCP tools
- 23 blockchain chains integrated
- 3 production servers across 3 regions
- 11 self-hosted infrastructure services
- 1,860+ automated tests
- Single founder, full-stack operation

**Website**: https://tech.happykokoro.com
**GitHub**: github.com/happykokoro (organization), github.com/anescaper (personal)

---

## Contact & Links

|                           |                                |
| ------------------------- | ------------------------------ |
| **GitHub (Organization)** | https://github.com/happykokoro |
| **GitHub (Personal)**     | https://github.com/anescaper   |
| **Company Website**       | https://tech.happykokoro.com   |
| **Portfolio**             | https://happykokoro.com        |

> Email and LinkedIn available upon request.
