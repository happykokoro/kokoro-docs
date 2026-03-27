# Technical Capabilities Overview

> Comprehensive technical profile of the Kokoro Tech platform — systems architecture, quantitative finance implementations, blockchain engineering, and infrastructure design. Architecture documented following ISO/IEC/IEEE 42010:2022 conventions.

---

## Core Competencies

### Systems Programming & Performance Engineering

- **Rust expertise at scale**: 330,000+ lines of production Rust across 100+ crates spanning trading engines, blockchain adapters, signal processing pipelines, API servers, and VPN infrastructure
- **Async architecture design**: Multi-service single-binary patterns (Tokio runtime — de facto async standard with 28K+ GitHub stars), per-entity async task management, lock-free concurrent state (DashMap, AtomicBool, AtomicI64), cooperative shutdown
- **Clean Integration Layer (CIL)**: Implemented at scale (242K lines, 63 pure-logic crates + 3 I/O binaries) — a monorepo architecture where business logic crates contain zero I/O, enabling pure-function testing and WASM portability
- **Trait-based plugin systems**: 21+ async trait hierarchies for pluggable factors, execution backends, protocol adapters, data sources, and risk gates
- **Axum 0.8 middleware composability**: tower::Service model for timeouts, tracing, compression, auth — composable without modifying handler signatures

### Quantitative Finance & Algorithmic Trading

- **Signal processing pipeline**: 11 production-grade filters implemented from mathematical foundations — H-infinity (4-state with innovation gating, minimax optimal under bounded disturbances per IEEE Transactions on Signal Processing), UKF (Cholesky sigma points, sigma point transform for nonlinear state estimation), particle filter (Sequential Monte Carlo with importance resampling), IMM (3-regime Kalman), RBPF, dual Kalman, wavelet CWT, Hilbert transform, Mellin transform, EWMA, Fourier
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

- **MCP Protocol mastery**: Built 2 MCP servers with 115 tools total, exposing full trading platform APIs to AI agents for autonomous research and execution
- **Agent orchestration**: Built `agent-orchestra` — Python platform managing AI coding agent agent teams with WebSocket dashboard, 7-phase automated lifecycle, worktree isolation, approval gates, critical error auto-kill
- **Development pipeline**: `claude-dev-pipeline` skill implementing 4-phase parallel execution (research → team → review → merge) with atomic PRs and dependency-aware merge order
- **AI coding agent tooling**: `claude-init` CLI (1,229 lines Python, zero deps) auto-generates `.claude/` config for any project by detecting language (9), framework (18), and project structure
- **Custom skills**: 7 domain-specific AI coding agent skills (dev-pipeline, signal-pipeline, risk-management, kalman-filter, polymarket-arbitrage, anchor-patterns, dex-integration)

---

## Service Capabilities

The technical competencies documented above translate directly into commercial service offerings for global clients. Kokoro Tech serves developers, enterprises, and FinTech companies internationally — not as a freelancer, but as a full-capability technology partner with production-proven systems and AI-augmented delivery.

### From Competency to Client Offering

**Systems Programming & Performance Engineering → Custom Software Development**
Expert-level Rust engineering at 330,000+ lines of production code means client systems are built for reliability from day one. The Clean Integration Layer methodology — 63 pure-logic crates with zero I/O, 3 I/O binaries — is applied to every engagement: client business logic is isolated, testable, and maintainable long after delivery. Clients receive production-quality, not prototype-quality code.

**Quantitative Finance & Algorithmic Trading → Quant System Design**
11 production DSP filters (H-infinity, UKF, particle filter, IMM, wavelet, and more), 24 alpha factor implementations, Avellaneda-Stoikov market making, VaR/CVaR risk management — all implemented from mathematical foundations, not library wrappers. Clients building trading systems, risk platforms, or signal processing pipelines get implementations that are mathematically sound and operationally hardened.

**Blockchain & DeFi Engineering → Blockchain Application Development**
20 Solana Anchor programs in production, a multi-chain liquidation bot running across 6 EVM chains, complete Polymarket SDK integration, Jupiter/Raydium/Orca DEX integrations. This is not tutorial-level blockchain work — it is production DeFi infrastructure covering every layer from smart contracts to execution to risk management.

**Full-Stack Web Development → End-to-End Product Delivery**
200+ API endpoints, 200+ frontend pages, 6 charting libraries, real-time SSE, Tauri desktop apps, Payload CMS — Kokoro Tech can own the complete product stack from database schema to deployed frontend without handoffs between specialists.

**Infrastructure & DevOps → Infrastructure as a Service**
3 production servers across 3 continents (Singapore, Ireland, London), connected by a self-built WireGuard mesh VPN. Docker Compose stacks, Prometheus/Grafana observability, Caddy auto-HTTPS, Cloudflare DDoS protection, SOPS secrets management. Client infrastructure deployments are modeled on what runs in production — not on textbook diagrams.

**AI Agent Systems → AI-Augmented Development & MCP Tooling**
115 MCP tools built across two production servers expose every platform capability to AI agents. Agent Orchestra manages multi-agent AI coding agent teams with automated pipelines. The result: development cycles that are measurably faster than traditional outsourcing with the same or higher quality bar. Clients can commission MCP server development, agent orchestration setup, or AI-augmented development workflow consulting as standalone services.

### The AI-Augmented Delivery Advantage

Traditional outsourcing delivers at the speed of human developer throughput. Kokoro Tech's AI-augmented workflow runs research, implementation, review, and testing phases in parallel — the same pipeline used to build the Kokoro platform. Phase 2 of the alpha-lab monorepo was built by 6 parallel AI agents coordinated through Agent Orchestra in a single session. This is not theoretical: it is the default delivery mode.

The practical outcome for clients: faster time-to-delivery, lower per-feature cost, higher consistency across the codebase, and a structured audit trail from the agent orchestration pipeline.

### Global Infrastructure as a Delivery Asset

Three production servers across three continents are not just platform infrastructure — they are evidence of operational capability. Clients requiring multi-region deployments, latency-optimized infrastructure, or self-hosted architecture get designs proven in production. The WireGuard mesh makes cross-server communication transparent and private. The self-hosted ecosystem (11 services) demonstrates that Kokoro Tech can own and operate infrastructure end-to-end, not just hand off deployment scripts.

---

## Architecture Standards Compliance

The platform architecture is documented following **ISO/IEC/IEEE 42010:2022 — Systems and Software Engineering: Architecture Description**. This international standard defines how architecture descriptions should be organized using viewpoints, stakeholder concerns, and architecture description languages.

### Architecture Viewpoints

Three primary viewpoints structure the architecture documentation:

**Signal Processing Viewpoint** — Addresses the concerns of quantitative analysts and strategy developers. Describes the filter cascade (H-infinity → UKF → particle filter), the `AlphaFactor` trait hierarchy, the factor composition pipeline, and the separation between signal generation and signal consumption. Pure-function crates with no I/O dependencies allow this viewpoint to be reasoned about independently.

**Execution Viewpoint** — Addresses the concerns of traders and operators. Describes the three-binary topology (Lab:4100 / Engine:4200 / Platform:4000), gRPC service definitions governing Lab↔Engine↔Platform communication, the risk gate chain architecture, and execution backend pluggability via the `ExecutionBackend` trait.

**Infrastructure Viewpoint** — Addresses the concerns of DevOps and operations. Describes the three-server WireGuard mesh, Docker Compose orchestration, Redis Streams topology (10 named streams, dual JSON/proto), service health and monitoring instrumentation, and secret management via SOPS.

### Stakeholder Concerns

Per ISO/IEC/IEEE 42010:2022, the architecture explicitly addresses:

| Stakeholder        | Primary Concern                                  | Architectural Response                                                |
| ------------------ | ------------------------------------------------ | --------------------------------------------------------------------- |
| Strategy developer | Testability of trading logic in isolation        | CIL: 63 pure-logic crates, zero I/O                                   |
| Platform operator  | Service reliability and observability            | Prometheus + Grafana on all services, health checks on all containers |
| Security engineer  | Secret exposure and network attack surface       | WireGuard mesh, SOPS, feature-gated live signing                      |
| API consumer       | Stable external contracts under internal change  | REST surface via Platform binary; internal gRPC evolves independently |
| AI agent operator  | Programmatic access to all platform capabilities | 115 MCP tools spanning all service boundaries                         |

### Architecture Description Language

The platform uses multiple architecture description languages suited to different viewpoints:

- **Proto3 schemas** (`services/proto/`) — formal contracts for gRPC service interfaces
- **Rust trait definitions** — formal contracts for plugin extension points (`AlphaFactor`, `ExecutionBackend`, `ProtocolAdapter`)
- **Docker Compose YAML** — formal descriptions of runtime topology per server
- **TOML strategy artifacts** — formal descriptions of deployed strategy configurations

---

## Signal Processing Methodology

The signal processing pipeline follows the minimax optimal estimation framework described in IEEE Transactions on Signal Processing. The pipeline is organized as a cascade of complementary estimators, each addressing different aspects of the state estimation problem.

### Filter Cascade Architecture

The core insight is that financial price series exhibit the same mathematical properties as physical dynamical systems: they have hidden state (true price, trend velocity), observable outputs (tick prices with noise), and disturbance inputs (market impact, news events). State estimation theory — originally developed for aerospace and control systems — applies directly.

| Estimator                   | IEEE Framework                                                                 | Role in Pipeline                                                                                                                                                   |
| --------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **H-infinity filter**       | Minimax optimal estimation under bounded noise (IEEE Trans. Signal Processing) | Primary price tracker; robust to non-Gaussian disturbances via minimax formulation                                                                                 |
| **Unscented Kalman Filter** | Sigma point transform for nonlinear state propagation                          | Handles nonlinear price dynamics; Cholesky sigma point generation for numerical stability                                                                          |
| **Particle filter**         | Sequential Monte Carlo with importance resampling                              | Multi-modal posterior estimation; used where regime uncertainty requires full distribution tracking                                                                |
| **IMM filter**              | Interacting Multiple Models (multi-regime Kalman)                              | 3-regime transitions: Trending (persistent velocity), Ranging (mean-reverting), Volatile (random walk)                                                             |
| **RBPF**                    | Rao-Blackwellized Particle Filter                                              | Marginalizes continuous states analytically (Kalman) while sampling discrete regime labels                                                                         |
| **KalmanNet direction**     | Neural network aided Kalman filtering (IEEE 2021)                              | The expert aggregator and conformal prediction in `prediction` crate approaches this frontier: combining learned model corrections with classical state estimation |

### Decentralized H-infinity UKF Design

The H-infinity implementation uses a 4-state model (position, velocity, acceleration, jerk) with innovation gating and tick-rate adaptive R matrix scaling. The minimax formulation finds the estimator that minimizes the worst-case ratio of estimation error energy to disturbance energy — this is the key property that makes H-infinity filters robust where Kalman filters degrade under non-Gaussian noise conditions.

A 3× cascade of H-infinity filters appears in `factor-enhanced`: three successive filter stages produce progressively smoother state estimates at different temporal scales, analogous to multi-scale signal analysis in wavelet decomposition.

### Multi-Resolution Time-Frequency Analysis

The wavelet Continuous Wavelet Transform (Morlet wavelet, 20 log-spaced scales) provides simultaneous time and frequency localization — the foundational property of multi-resolution signal analysis. The Hilbert transform constructs the analytic signal (zero negative-frequency components via FFT → inverse FFT), yielding instantaneous amplitude, phase, and frequency at each point in the series. The Mellin transform provides scale-invariant analysis for price series where multiplicative structure dominates additive structure.

---

## Distributed Systems Architecture

The platform implements cloud-native architecture patterns following 2026 CNCF best practices (89% organizational adoption rate, 80% running Kubernetes in production).

### Pattern Implementations

| Pattern                       | Implementation                                                                                 | Location                                          |
| ----------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| **Event-Driven Architecture** | Redis Streams: 10 named streams, persistence + consumer groups + ordering                      | All inter-service async communication             |
| **API Gateway**               | Platform binary (port 4000): auth, billing, tier gates, gRPC→REST translation                  | External boundary for all frontend/client traffic |
| **Circuit Breaker**           | `AtomicBool` flag trips after N consecutive failures; hot-path reads without locking           | Risk module (all trading systems)                 |
| **CQRS**                      | Separate read path (Lab signal pipeline) from write path (Engine execution)                    | Lab:4100 / Engine:4200 topology                   |
| **Service Mesh**              | WireGuard mesh VPN on 10.10.0.0/24 subnet — all cross-server traffic encrypted and transparent | 3-server topology (Singapore / Ireland / London)  |
| **Saga Pattern**              | Flash loan execution: atomic borrow → liquidate → swap → repay via Solidity contract           | Liquidation bot                                   |

### Redis Streams Architecture (10-Stream Topology)

The platform's inter-service messaging follows Redis Streams best practices: persistence (messages survive restart), consumer groups (parallel processing with acknowledgment), and ordering (within-stream sequential delivery).

```
Stream topology (dual JSON/proto format):
  price_updates        → pricing-service publishes, Lab consumes (factor pipeline)
  wallet_events        → wallet-monitor publishes, Lab consumes (whale/cluster factors)
  alpha_signals        → Lab publishes, Engine consumes (execution decisions)
  execution_events     → Engine publishes, Platform consumes (position updates)
  billing_events       → Platform publishes, Engine consumes (tier enforcement)
  [+ 5 additional streams for coordination, monitoring, and audit]
```

The dual JSON/protobuf migration pattern was executed across all 10 streams simultaneously: the `enc` field signals encoding in use, and all consumers auto-detect. This zero-downtime protocol evolution technique allows old and new service versions to coexist during rolling deployments — an instance of the recognized pattern for gradual protocol migration without service coordination.

### gRPC Service Topology

Three service pairs use Tonic gRPC for synchronous inter-service communication:

```
Lab (:50051) ←→ Engine (:50052)   — signal submission, execution confirmation
Engine       ←→ Platform (:4000)  — tier enforcement, billing events
Platform     ←→ Frontend          — authenticated, rate-limited REST surface
```

Proto `.proto` files in `services/proto/` are the source of truth; generated Rust types are checked in. The REST surface of the Platform binary is the stable external contract — internal gRPC bindings evolve behind it.

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
| **Kokoro Tech**            | Next.js 16, static export                         | Company website at tech.happykokoro.com                                                                                                        |
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
| **Agent Orchestra**     | Python + Rust               | Multi-agent AI coding agent orchestration with WebSocket dashboard           |
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

### Notable Engineering Implementations

1. **242,466-line Rust monorepo** with Clean Integration Layer — 63 pure-logic crates, 3 I/O binaries, 1,074 tests, each crate independently testable as a pure function
2. **11 DSP filters from mathematical foundations** — direct implementations of H-infinity (IEEE minimax optimal), UKF (sigma point transform), particle filter (Sequential Monte Carlo), IMM, RBPF, wavelet CWT, Hilbert transform
3. **Flash loan liquidation** across 6 EVM chains simultaneously — zero capital required, custom Solidity contract for atomic borrow-liquidate-swap-repay sequence
4. **20 Solana Anchor programs** spanning DeFi (AMM, lending, yield, liquidation, leverage), gaming (6 types), prediction markets, NFT, and governance
5. **Multi-agent development orchestration** — Agent Orchestra manages AI coding agent agent teams with automated merge, build, test pipeline; used to build Phase 2 of alpha-lab with 6 parallel agents
6. **Dual-format Redis Streams migration** — zero-downtime JSON→proto transition across 10 streams with auto-detection at consumer level
7. **Self-built WireGuard mesh VPN** connecting 3 servers across 3 cloud providers (DigitalOcean Singapore, AWS Ireland, AWS London) with per-node ACL firewall generation
8. **8-profile trading bot fleet** — single binary running 8 parallel strategy pipelines sharing one data feed, each with different quant models (GARCH, Hurst, Brownian Bridge, bilateral MM)

### Open Source Contributions

- **claude-init** — Auto-generate .claude/ configuration for any project (public, GitHub)
- **claude-dev-pipeline** — Parallel development pipeline skill for AI coding agent (public, MIT license)
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
Backend:     Axum 0.8 (tower middleware), Tokio 1.x, Tonic, Express, FastAPI, Gin, Anchor, Laravel
Frontend:    Next.js 15/16, React 19, Tailwind v4, Radix UI, Zustand, SWR
Desktop:     Tauri v2
Database:    PostgreSQL (SQLx/Prisma), Redis Streams, SQLite
Blockchain:  Solana SDK, Anchor, Alloy (EVM), Jupiter, Raydium, Orca
Charting:    TradingView, Recharts, Plotly, D3, React Flow
AI/ML:       MCP Protocol, LLM API, DQN, WASM plugins
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
Quantitative Finance:  Signal processing (IEEE filter theory), factor models, market making
                       (Avellaneda-Stoikov), backtesting, risk management (VaR/CVaR/Kelly),
                       portfolio optimization (Markowitz MVO)
Blockchain/DeFi:       Solana programs, EVM contracts, flash loans, DEX integration,
                       prediction markets, NFTs, lending protocols, liquidation engines
Market Microstructure: Order flow imbalance, Hawkes processes, adverse selection,
                       liquidity density, whale detection, Louvain cluster analysis
Cryptography:          EIP-712, ECDSA, AES-GCM, HKDF, Argon2, TOTP, WireGuard
AI Agent Systems:      MCP servers, agent orchestration, skill protocols, WASM plugins
```

---

## Contact & Links

|                           |                                |
| ------------------------- | ------------------------------ |
| **GitHub (Organization)** | https://github.com/happykokoro |
| **GitHub (Personal)**     | https://github.com/anescaper   |
| **Company Website**       | https://tech.happykokoro.com   |
| **Portfolio**             | https://happykokoro.com        |
