# Professional Resume Profile

> Comprehensive professional profile suitable for resume, CV, LinkedIn, company promotion, and investor presentations. All claims are backed by specific, verifiable implementations.

---

## Professional Summary

Technical founder with 9 years of experience spanning formal dual-degree education in Vehicle Engineering (control theory, signals & systems) and Financial Engineering (portfolio theory, derivatives pricing, risk management), hardware cryptocurrency mining algorithm development, professional software development and server operations, and the design and deployment of a 14-product distributed SaaS platform. The journey runs from undergraduate control systems coursework that directly produced the signal processing expertise in the platform, through hands-on mining algorithm development during the 2017 crypto boom, through professional programming and server administration (Jenkins, Kubernetes, SSH), through graduate-level PHP/Laravel enterprise development and the first quantitative trading robot (the direct precursor to Kokoro Alpha Lab), to founding Kokoro Tech in 2025 and scaling that grad school prototype into a production-grade quantitative trading and blockchain infrastructure ecosystem with AI-augmented development workflows.

The platform's signal processing pipeline — 11 production-grade DSP filters including H-infinity, UKF, particle filter, wavelet CWT, and Hilbert transform — originates from formal academic training in Automatic Control Principles and Signals & Systems, the foundational courses of Vehicle Engineering. The financial modeling — Black-Scholes, Markowitz MVO, VaR/CVaR, Kelly criterion, options pricing — originates from a double degree in Financial Engineering. This is academically grounded quant infrastructure, not self-taught approximation.

What appears as 14 separate projects is, in practice, one logical distributed system: 7+ coordinated repositories sharing versioned type contracts (tagged semantic releases), communicating across 3 cloud servers via an encrypted WireGuard mesh VPN, connected by 10 real-time streaming data channels, and exposed through 115 AI tool interfaces for autonomous operation.

The combined codebase exceeds 530,000 lines of production code across Rust, TypeScript, Python, and Go, with 1,860+ automated tests. Each repository is independently deployable, but participates in the larger system through well-defined message contracts — protobuf schemas on Redis Streams, gRPC service definitions between application binaries, and REST APIs at the boundary with external consumers. The infrastructure spans DigitalOcean Singapore (12+ Docker containers), AWS Ireland, and AWS London — all connected as a single network via self-built WireGuard mesh, with SaaS-grade reliability practices: tiered billing, per-tenant resource limits, monitoring on every service, and CI/CD across 8+ repositories.

Specializes in high-performance Rust systems for financial applications, multi-repo architecture with shared library versioning, real-time cross-service data pipelines, blockchain protocol integrations, and AI-augmented development workflows. The quantitative core implements 11 DSP filters from mathematical foundations (H-infinity, UKF, particle filter, IMM, RBPF, wavelet, Hilbert, Kalman, and more), 24 alpha factor implementations, market making via the Avellaneda-Stoikov model, risk management (VaR, CVaR, composable risk gates), statistical modeling (GARCH, Hurst exponent, copulas, conformal prediction), and options pricing (Black-Scholes, Monte Carlo simulation). Blockchain coverage includes 20 Anchor programs on Solana and production liquidation across 6 EVM chains. The architecture was deliberately designed for team scaling — trait-based plugin systems, Clean Integration Layer, and 115 MCP tools mean every crate is an independently assignable unit of work and every service boundary is a natural hire boundary.

---

## Project Timeline

| Period            | Focus                       | Key Deliverables                                                                                                                                                                                                                                                   |
| ----------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2017-2021         | Undergraduate (dual degree) | Vehicle Engineering (control theory, signals & systems) + Financial Engineering (economics, portfolio theory, derivatives). Mining algorithm development during the 2017 crypto boom; partnership ended when blockchain systems updated and partners moved abroad. |
| 2021-2022         | Professional programmer     | Software development + server administration (Jenkins, Kubernetes, SSH-based manual ops, coding interview prep)                                                                                                                                                    |
| 2022-2024         | Graduate studies            | PHP Laravel enterprise applications (Eloquent ORM, Pest testing, Breeze auth). Built first automated trading quantitative robot — the direct precursor to Kokoro Alpha Lab.                                                                                        |
| 2025-2026         | Founded Kokoro Tech         | Scaled the grad school quant robot into a 530K-line distributed platform spanning 7 repos, 3 servers, and 14 products                                                                                                                                              |
| 2025 Q1           | Kokoro Protocol             | 20 Anchor programs on Solana (DeFi, gaming, prediction markets)                                                                                                                                                                                                    |
| 2025 Q2-Q3        | Kokoro Alpha Lab            | 242K-line Rust monorepo, signal processing pipeline, multi-asset trading                                                                                                                                                                                           |
| 2025 Q4           | Infrastructure buildout     | Self-hosted services, Docker orchestration, monitoring stack                                                                                                                                                                                                       |
| 2026 Q1 (Jan-Feb) | Ecosystem expansion         | Liquidation bot (6 EVM chains), wallet monitor, pricing service, polymarket bot (8-profile fleet), copy trader                                                                                                                                                     |
| 2026 Q1 (Mar)     | SaaS products               | Kokoro MM (Polymarket AMM), Kokoro Pipeline (dev automation), Kokoro VPN (WireGuard mesh)                                                                                                                                                                          |
| 2026 Q1 (Mar)     | Developer tools             | agent-orchestra, claude-init, claude-dev-pipeline, 115 MCP tools                                                                                                                                                                                                   |

> Built by a technical founder leveraging AI-augmented development workflows — architecture designed from day one for team scaling.

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
- **PHP/Laravel**: Enterprise-level Laravel applications with Eloquent ORM, Breeze authentication, Blade templating, MySQL, Pest testing (graduate studies focus)

### Infrastructure & DevOps

- **Multi-server deployment**: 3 cloud servers (DigitalOcean Singapore, AWS Ireland, AWS London) connected via self-built WireGuard mesh VPN (10.10.0.0/24)
- **Container orchestration**: Docker Compose stacks with multi-stage Rust builds, health checks, volume management, network isolation
- **Self-hosted ecosystem**: 11 utility services (Umami analytics, Gitea, Uptime Kuma, Excalidraw, Shlink, PrivateBin, Linkding, Syncthing, Homepage, Grafana, Prometheus)
- **Reverse proxying**: Caddy (auto-HTTPS) + Nginx + Cloudflare DNS/CDN/DDoS
- **Monitoring**: Prometheus metrics on all services, Grafana dashboards, OpenTelemetry tracing, Uptime Kuma, structured logging (tracing crate)
- **Security**: WireGuard mesh networking, SOPS secrets management, Flashbots MEV protection, per-user key derivation, feature-gated live-signing
- **Server administration**: Production server scheduling and maintenance across 3 servers — systemd services, cron scheduling, Docker orchestration, SSL management, database backups, log rotation, resource monitoring

### AI Agent Systems & Developer Tooling

- **MCP Protocol mastery**: Built 2 MCP servers with 115 tools total, exposing full trading platform APIs to Claude for autonomous research and execution
- **Agent orchestration**: Built `agent-orchestra` — Python platform managing Claude Code agent teams with WebSocket dashboard, 7-phase automated lifecycle, worktree isolation, approval gates, critical error auto-kill
- **Development pipeline**: `claude-dev-pipeline` skill implementing 4-phase parallel execution (research → team → review → merge) with atomic PRs and dependency-aware merge order
- **Claude Code tooling**: `claude-init` CLI (1,229 lines Python, zero deps) auto-generates `.claude/` config for any project by detecting language (9), framework (18), and project structure
- **Custom skills**: 7 domain-specific Claude Code skills (dev-pipeline, signal-pipeline, risk-management, kalman-filter, polymarket-arbitrage, anchor-patterns, dex-integration)

---

## Professional Experience

### Undergraduate — Vehicle Engineering & Financial Engineering (2017-2021)

The career began in 2017, when the founder entered university carrying both a primary degree in Vehicle Engineering and a double degree in Financial Engineering — and immediately encountered the 2017 Ethereum bull run. The combination of formal academic training and hands-on crypto engagement set the trajectory for everything that followed.

**Vehicle Engineering (Primary Degree) — Control Theory and Signal Processing Foundations**

The Vehicle Engineering curriculum centered on control systems — the mathematical discipline that governs how dynamic systems are modeled, analyzed, and stabilized. Key coursework:

- **Automatic Control Principles**: PID controllers, transfer functions, state-space models, feedback systems, stability analysis. These are the mathematical foundations of the Kalman filter family.
- **Signals & Systems**: Fourier transforms, Laplace transforms, frequency domain analysis, filter design, convolution. These are the mathematical foundations of the wavelet CWT, Hilbert transform, and the full DSP filter pipeline in Kokoro Alpha Lab.

The 11 signal processing filters in the platform — H-infinity, UKF, particle filter, IMM, RBPF, wavelet CWT, Hilbert transform, Mellin transform, and more — are direct applications of control theory coursework. The H-infinity filter is a control-theoretic estimator (minimax optimal under bounded disturbances). The UKF extends the Kalman filter using sigma point transforms taught in state-space estimation courses. This is formally trained expertise, not self-study.

**Financial Engineering (Double Degree) — Quantitative Finance Foundations**

The Financial Engineering degree provided structured academic training in:

- **Economics and Financial Mathematics**: Stochastic processes, Ito's lemma, Brownian motion — the mathematical foundations of options pricing and algorithmic trading
- **Portfolio Theory**: Markowitz mean-variance optimization, the efficient frontier, CAPM — the exact frameworks implemented in the `quant-core` crate
- **Derivatives Pricing**: Black-Scholes model and Greeks, options strategies — the textbook knowledge behind the Black-Scholes and Monte Carlo implementations
- **Risk Management**: VaR, CVaR, stress testing, scenario analysis — the frameworks behind the composable risk gate architecture

The founder also grew up in a family with extensive experience in stocks and investment, meaning financial markets were familiar territory long before formal study. The Financial Engineering degree formalized and deepened that background.

**Mining Algorithm Development (2017 Crypto Boom)**

During undergraduate years, worked as a developer on cryptocurrency mining machine algorithms — real software engineering at the intersection of cryptography, hardware, and economic systems:

- **Mining rig hardware**: PCB design considerations, thermal management systems, power efficiency calculations — understanding physical constraints of sustained computational workloads
- **Hash algorithm optimization**: Studied and optimized SHA-256 and Ethash (memory-hard PoW) implementations, exploring tradeoffs between parallelism, memory bandwidth, and power consumption
- **Partnership end**: The mining algorithm work ended when blockchain systems updated (algorithm changes forced hardware obsolescence) and partners moved abroad — but the crypto developer expertise remained

### Professional Programmer & Server Administrator (2021-2022)

Following graduation, worked as both a programmer and server administrator — software development alongside production infrastructure management in the pre-AI era. Responsibilities included:

- **Software development**: Active programming work building and maintaining production applications
- **CI/CD pipeline management** using Jenkins — build, test, and deployment automation
- **Container orchestration** with Kubernetes — cluster management, pod scheduling, service discovery
- **Manual server maintenance** via SSH — health checks, monitoring setup, log analysis, troubleshooting
- **Development environments** on Windows VMs running Ubuntu
- **Documentation discipline** — shell commands documented in physical notebooks for reference during maintenance
- **Monitoring and health checks** via UI management panels and manual inspection

This foundational hands-on experience — where every deployment was manual and every command was memorized — directly informed the current infrastructure design. The progression from notebook-documented shell commands to AI-orchestrated 22-agent parallel development represents a complete evolution in software engineering methodology.

### Graduate Studies — Enterprise Software & First Quant Robot (2022-2024)

Graduate studies brought enterprise PHP/Laravel development alongside a project that would change everything: the first automated trading quantitative robot.

- **PHP Laravel enterprise applications**: Eloquent ORM, Breeze authentication, Blade templating, Pest testing, MySQL, Artisan CLI — production-grade enterprise PHP at the architectural level
- **First quantitative trading robot**: Built the direct precursor to Kokoro Alpha Lab during grad school. This was not an academic toy — it was a working automated trading system, and it was never abandoned. It evolved, grew, and became the 530,000-line distributed platform that Kokoro Tech runs today.

The grad school robot is the origin point. Kokoro Alpha Lab is that robot scaled.

---

## Education

| Degree                     | Field                 | Period    | Key Coursework / Focus                                                                                                                                                                                                                        |
| -------------------------- | --------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Bachelor's (Primary)       | Vehicle Engineering   | 2017-2021 | Automatic Control Principles, Signals & Systems, control theory (PID, transfer functions, state-space models, feedback systems, stability analysis), signal processing (Fourier/Laplace transforms, filter design, frequency domain analysis) |
| Bachelor's (Double Degree) | Financial Engineering | 2017-2021 | Economics, Financial Mathematics, Portfolio Theory (Markowitz MVO), Derivatives Pricing (Black-Scholes), Risk Management (VaR/CVaR), stochastic processes                                                                                     |
| Master's                   | Graduate Studies      | 2022-2024 | Enterprise Software Engineering (PHP/Laravel), Quantitative Trading Systems (first automated trading robot — precursor to Kokoro Alpha Lab)                                                                                                   |

> The Vehicle Engineering coursework is the direct academic origin of the signal processing pipeline. The Financial Engineering coursework is the direct academic origin of the quantitative finance implementations. This is formally trained expertise applied to a new domain — not self-study.

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

1. **242,466-line Rust monorepo** with Clean Integration Layer — 63 pure-logic crates, 3 I/O binaries, 1,074 tests, each crate an independently assignable unit of work designed for team-scale parallel development
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
Advanced:  Python, Go, PHP, Solidity, SQL
Competent: Shell/Bash, Java, C/C++
```

### Frameworks & Libraries

```
Backend:     Axum, Tokio, Tonic, Express, FastAPI, Gin, Anchor, Laravel
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
Containers:  Docker, Docker Compose, Kubernetes
Networking:  WireGuard, Caddy, Nginx, Cloudflare
Monitoring:  Prometheus, Grafana, OpenTelemetry, Uptime Kuma
CI/CD:       GitHub Actions, Jenkins
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
3. **AI-augmented development**: 115 MCP tools + Agent Orchestra enable a lean founder-led team to maintain 14 products with the velocity of an 8–12 person engineering team. This infrastructure persists as a competitive advantage as the team grows — it is not a workaround, it is the operating model
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
- Founder-led, AI-augmented team — architected for scaling to 20 people
- Architecture-first design: CIL, trait plugins, MCP tools, codified conventions enable parallel team growth

**Website**: https://tech.happykokoro.com
**GitHub**: github.com/happykokoro (organization), github.com/anescaper (personal)

---

## Scalability & Growth Architecture

The platform was not built to remain a one-person operation — it was architected from day one to scale from 1 to 20 people, with AI agents filling the gap until funding allows hiring. Every structural decision serves this goal.

### AI-Augmented Development Infrastructure

Not a hack, but a deliberate capability multiplier that persists as a competitive advantage even as the team grows:

- **Agent Orchestra**: Manages teams of AI coding agents with automated merge/build/test pipelines. A new engineer joining the team inherits this infrastructure immediately — their PRs enter the same review and integration pipeline that has been running since the codebase's inception.
- **115 MCP tools**: The entire platform is API-accessible for AI agents and human operators alike. Any team member can operate the system through structured tool interfaces without needing to understand every service boundary.
- **Claude Dev Pipeline**: Parallel development skill with atomic PRs and dependency-aware merging — encodes hard-won lessons about how to work on a large monorepo without producing conflicts.
- **Claude Init**: Auto-generates project configuration for new repos — zero onboarding friction when the team expands to new services.

### Codified Knowledge — The Codebase as Training Material

- **Clean Integration Layer (CIL)**: 63 pure-logic crates with zero I/O means any developer can understand and test business logic in isolation. A new hire given `factor-X` to implement needs to understand only the `AlphaFactor` trait interface, not the full pipeline.
- **Trait-based architecture**: New implementations plug into existing interfaces — add a new AlphaFactor, a new ExecutionBackend, a new ProtocolAdapter — without touching the rest of the system.
- **1,860+ tests as executable documentation**: The test suite defines correct behavior precisely. New contributors have a verifiable contract from day one.
- **constitution.md**: Defines 8 core architectural principles, anti-patterns, and a decision framework in the monorepo. Architectural intent is documented, not just code.

### Hiring Plan Architecture

The system is explicitly designed so each boundary becomes a hire boundary:

- **Each crate is an independently assignable unit**: A new Rust developer can own a single `factor-X` or `exec-Y` crate with a well-defined interface and complete test coverage.
- **Frontend developers work independently**: 200+ pages with stable API contracts — no coordination required with the backend team to ship UI features.
- **DevOps engineers own server boundaries**: Three servers with self-documenting Docker Compose files and full monitoring already in place.
- **MCP tool layer enables AI delegation**: Operational tasks can be handled by AI agents before hiring humans for them, extending the runway.

### Scalability Milestones

| Stage     | Team Size    | Focus                                                                                                            |
| --------- | ------------ | ---------------------------------------------------------------------------------------------------------------- |
| Current   | Founder + AI | Revenue from Kokoro MM and Alpha Lab. AI agents handle parallel development.                                     |
| Near-term | 3–5 people   | First hires: one Rust backend, one frontend, one DevOps. Each owns a server or service boundary.                 |
| Mid-term  | 5–10 people  | Domain specialists: quant researcher (factor development), blockchain specialist (multi-chain), product manager. |
| Growth    | 10–20 people | Team leads per product line. Agent Orchestra scales to coordinate multiple human+AI teams simultaneously.        |

---

## Market Timing

The Kokoro portfolio is positioned at the intersection of multiple simultaneously expanding markets, each reaching a critical inflection point as of early 2026.

- **Prediction markets: $200B+ annual run rate.** Polymarket hit $7B in monthly volume in February 2026, with a single-day record of $425M. Combined Polymarket and Kalshi volume runs at a $200B+ annual rate, with projections toward $325B. CNBC forecasts the sector reaching $1.1 trillion by 2030. DraftKings, FanDuel, and Robinhood launched prediction products for the 2026 FIFA World Cup. Tech and Science markets grew 1,637% YoY. Kokoro MM and the Polymarket trading bots are live in this market today.

- **DeFi lending: institutional adoption underway.** The DeFi market stands at $238.5B as of early 2026 (projected $770.6B by 2031, 26.4% CAGR). Aave holds $27.29B TVL, $83.3M monthly fees, 62.8% market share, and crossed $1 trillion in cumulative loans. $675M in liquidations occurred in the first nine months of 2026, including a record $429M in one week. Apollo Global Management and Société Générale are now deploying through DeFi. Each institutional dollar entering DeFi lending creates more liquidation opportunities — a direct revenue tailwind for the Kokoro Liquidation Bot.

- **Algorithmic trading: $25–33B market, 14.4% CAGR.** As of early 2026, the algorithmic trading market is valued at $25–33B and projected to reach $44B by 2030. Growth is driven by AI-driven algorithms, real-time execution optimization, and cross-asset expansion — all areas the Kokoro Alpha Lab addresses directly. Rust has become "non-negotiable for serious HFT" in 2026, with banks and trading firms migrating from C++ to Rust. Kokoro's 330,000+ lines of Rust is substantial even by institutional standards.

- **AI coding tools: $12.8B market with viral MCP adoption.** The AI coding tools market reached $12.8B in early 2026, projected to exceed $100B by 2030. 85% of developers regularly use AI tools. The Model Context Protocol hit 97 million monthly SDK downloads in March 2026 (up from 2M at November 2024 launch), with 6,400+ registered servers. Claude Code became the most-used AI coding tool in developer surveys within 10 months of launch. Kokoro's 115 MCP tools are one of the largest known domain-specific MCP implementations.

- **Founder-led AI-augmented era: Anthropic CEO's prediction is playing out.** Dario Amodei stated 70–80% odds of the first $1B founder-led company by 2026 or shortly after, specifically naming "proprietary trading" and "developer tools" as the most likely sectors. Solo-founded startups have risen from 23.7% of new companies in 2019 to 36.3% by mid-2025. Base44 (solo founder) sold to Wix for $80M in under six months. Kokoro builds exactly what Amodei described — the infrastructure proven at founder scale, architected to grow to team scale, with 10–50x capital efficiency versus a comparable team-based operation at the current stage.

This portfolio is not ahead of one trend — it is at the convergence of all five.

---

## Contact & Links

|                           |                                |
| ------------------------- | ------------------------------ |
| **GitHub (Organization)** | https://github.com/happykokoro |
| **GitHub (Personal)**     | https://github.com/anescaper   |
| **Company Website**       | https://tech.happykokoro.com   |
| **Portfolio**             | https://happykokoro.com        |

> Email and LinkedIn available upon request.
