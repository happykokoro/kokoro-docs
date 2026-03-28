# Skills & Domain Expertise — Comprehensive Profile

> Detailed breakdown of every technical skill, domain expertise, algorithm knowledge, and methodology demonstrated across the Kokoro project portfolio. Each skill includes evidence from specific projects and implementations.

---

## Scope of Services

The technical capabilities documented in this profile are available as commercial services for global clients. Kokoro Tech provides software outsourcing and custom development, AI consulting and MCP tooling, hardware and network infrastructure design, DevOps and operations consulting, and quantitative finance system development — delivered to enterprises, FinTech companies, and development teams across Asia-Pacific, Europe, and the Americas. Every skill listed here has been exercised in production systems, not in academic or demonstration contexts. Clients commissioning services from Kokoro Tech receive implementations drawn from the same engineering standards that govern the company's own platform.

---

## 1. Systems Programming (Rust)

### Async Runtime Architecture

**Expertise Level**: Expert — designs and implements production async systems from scratch.

- **Multi-service single-binary architecture**: kokoro-mm runs gateway (HTTP server), engine (quoting pipeline), and datahub (market data aggregation) in a single tokio runtime with direct function call IPC. This eliminates network overhead between services while maintaining logical separation through crate boundaries.
- **Per-entity async task management**: kokoro-wallet-monitor spawns one tokio task per tracked wallet with per-task exponential-backoff WebSocket reconnection. kokoro-mm spawns per-user `UserInstanceLoop` tasks ticking at 2-second intervals.
- **Lock-free concurrent state**: Extensive use of `DashMap` over `RwLock<HashMap>` for hot paths. `AtomicBool` for circuit breaker flags. `Arc<AtomicI64>` for lock-free watchdog timestamps in data adapters. Deliberate use of `std::sync::RwLock` (not tokio's) in polymarket-bot to avoid async lock contention overhead.
- **Graceful shutdown**: Cooperative cancellation via `tokio::select!` + signal handlers across all services.

### Trait-Based Abstraction Design

**Expertise Level**: Expert — designs extensible trait hierarchies for pluggable architectures.

- **24 `AlphaFactor` implementations** behind a single `trait AlphaFactor: Send + Sync` in alpha-lab. Pipeline operates on `Vec<Box<dyn AlphaFactor>>` — dynamic dispatch chosen deliberately for runtime composability.
- **Composable execution pipeline**: `OrderSizer` → `SlippageEstimator` → `ProfitabilityFilter` → `ExecutionBackend` → `PostTradeValidator` — each step is a trait with multiple implementations.
- **Protocol adapter pattern**: `ProtocolAdapter` trait in liquidation-bot allows runtime dispatch across Aave V3, Compound V3, Seamless, Moonwell. `LiquidationExecutor` trait separates flash loan vs absorb vs paper execution.
- **Data adapter pattern**: `TickAdapter` and `RestAdapter` traits in polymarket-bot with `connect`, `subscribe`, `poll_next`, `is_healthy` interface. `DataHub` builder pattern adds adapters before start.
- **Interface segregation**: kokoro-staking Go adapters implement only `StakingReader`, `TxBuilder`, `HealthChecker` as applicable per chain.

### Memory Safety & Concurrency Patterns

- **Zero-copy serialization boundaries**: `mm-types` / `mm-proto` separation ensures domain types stay internal while API types handle serde.
- **Feature-gated compilation**: `factor-registry` uses `#[cfg(feature = "factor-X")]` conditional compilation. `all-factors` vs `core-factors` vs `minimal` feature sets control binary size and compile time.
- **`#[cfg(feature = "live-signing")]`**: Live trading code is completely excluded from paper-mode binaries at compile time (polymarket-bot, liquidation-bot).
- **Type-state pattern**: Round lifecycle in kokoro-mm: `Discovered → OrdersOpen → Active → Settling → Settled` as explicit enum variants driving state machine transitions.
- **Thread-safe factory registry**: `factor-registry` maps string names to `Box<dyn Fn() -> Box<dyn AlphaFactor>>` factory functions, populated at startup via feature-gated blocks.

### Macro & Metaprogramming

- **`kokoro_factor!` proc-style macro**: Generates WASM export boilerplate for user-compiled strategy factors in `factor-sdk`.
- **`alloy::sol!` inline ABI generation**: Defines Solidity ABIs inline in Rust (liquidation-bot), eliminating separate ABI JSON files.
- **`@register_strategy` decorator pattern**: Python strategy service auto-registers strategies into `StrategyRegistry` on import via decorator.
- **Extensive derive usage**: `#[derive(Debug, Clone, Serialize, Deserialize)]` as standard on all domain types. `#[serde(default = "fn_name")]` for backward-compatible config deserialization.

---

## 2. Quantitative Finance

### Signal Processing & Filtering

**Expertise Level**: Expert — implements production-grade DSP filters from mathematical foundations.

The H-infinity filter implementation follows the minimax optimal estimation framework (IEEE Transactions on Signal Processing): the estimator minimizes the worst-case ratio of estimation error energy to disturbance energy over all bounded disturbance sequences — making it robust to non-Gaussian noise conditions where classical Kalman filtering degrades. The UKF implementation uses the sigma point transform for nonlinear state propagation. The prediction crate's expert aggregator with conformal prediction bounds approaches the KalmanNet frontier (IEEE 2021): neural network aided Kalman filtering for partially known dynamics.

| Filter/Algorithm                  | Mathematical Foundation                                         | Implementation Details                                                                                                                                             |
| --------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **H-infinity filter**             | Minimax optimal estimation under bounded noise (IEEE Trans. SP) | 4-state (position/velocity/acceleration/jerk), innovation gating, tick-rate adaptive R matrix scaling, state covariance inflation. 3× cascade in `factor-enhanced` |
| **Unscented Kalman Filter (UKF)** | Sigma point transform for nonlinear systems                     | nalgebra Cholesky decomposition for sigma point generation, mean-reversion velocity model, acceleration decay                                                      |
| **Particle filter**               | Sequential Monte Carlo with importance resampling               | Used in both `dsp-filters` (general purpose) and `prediction` (RBPF variant with per-particle regime labels)                                                       |
| **IMM filter**                    | Interacting Multiple Models                                     | 3 regimes (Trending: persistent velocity, Ranging: mean-reverting, Volatile: random walk). Markov transition matrix, model probability mixing                      |
| **RBPF**                          | Rao-Blackwellized Particle Filter                               | Marginalizes linear states analytically (Kalman), samples discrete regime labels with particles                                                                    |
| **Dual Kalman**                   | Coupled state estimation                                        | Price + log-volatility: vol estimate feeds back into Q matrix of price Kalman                                                                                      |
| **Morlet wavelet CWT**            | Continuous wavelet transform                                    | 20 log-spaced scales for multi-resolution time-frequency analysis                                                                                                  |
| **Hilbert transform**             | Analytic signal construction                                    | Via FFT: zero negative frequencies, inverse FFT → instantaneous amplitude/phase/frequency                                                                          |
| **Mellin transform**              | Scale-invariant analysis                                        | Implemented for financial time series                                                                                                                              |
| **2-state Kalman**                | Classical Kalman filter                                         | Price + velocity states for noise smoothing (pricing-service)                                                                                                      |
| **EWMA**                          | Exponentially Weighted Moving Average                           | Configurable lambda for volatility estimation (kokoro-mm spread calculator)                                                                                        |

### Statistical Modeling

| Technique                  | Application                                                                                                                                                                                                                                  |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **GARCH(1,1)**             | Volatility modeling. Two implementations: Rust (grid search MLE over (α,β) space, variance targeting) and Python (arch library). n-step ahead forecasting with mean-reversion to long-run variance                                           |
| **Hurst exponent**         | R/S analysis on log-returns with chunk sizes starting at 8, multiplying by 1.5. OLS regression of log(R/S) vs log(n). H < 0.5 = mean-reverting, H > 0.5 = trending                                                                           |
| **Student-t distribution** | Fat-tail probability estimation via CDF computation. Used for risk modeling and signal confidence                                                                                                                                            |
| **ADF test**               | Augmented Dickey-Fuller stationarity test for time series                                                                                                                                                                                    |
| **Conformal prediction**   | Rolling calibration set, quantile-based coverage bounds (95% target). Non-parametric uncertainty quantification                                                                                                                              |
| **Expert aggregator**      | Multiplicative weights update (Hedge algorithm) with exponential loss penalty η. Online learning for combining expert predictions                                                                                                            |
| **Copulas**                | Gaussian (Cholesky sampling), Student-t (with ν DoF), Clayton (Archimedean). Dependency modeling between correlated assets                                                                                                                   |
| **Autocorrelation**        | Serial dependence analysis for signal validation                                                                                                                                                                                             |
| **Jump detection**         | Return z-scores with 3.0σ threshold for identifying regime breaks                                                                                                                                                                            |
| **Brownian Bridge**        | Path conditioning on prediction market outcomes. Research on 11,348 historical Polymarket markets. Parent=UP + prior [DOWN,DOWN] → 95% p_up (100% accuracy n=18). Exploits hierarchical timeframe cascade (3×5m inside 15m, 4×15m inside 1h) |

### Options Pricing & Greeks

| Technique                   | Implementation                                                                                                                                           |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Black-Scholes**           | Analytical closed-form pricing for European options + Greeks (delta, gamma, vega, theta, rho). Implemented in quant-core                                 |
| **Monte Carlo options**     | GBM path simulation with importance sampling (proposal reweighting) and antithetic variates (variance reduction). Configurable path count and time steps |
| **Synthetic options chain** | Options chain generation via Black-Scholes for assets without listed options markets. Synthetic expiration slices (options-data crate)                   |

### Portfolio Optimization & Risk Management

| Technique                      | Implementation                                                                                                                                      |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Markowitz MVO**              | Analytical (2-constraint Lagrangian) + projected gradient descent for constrained case. nalgebra DMatrix operations                                 |
| **Efficient frontier**         | Full frontier computation with target return constraints                                                                                            |
| **Kelly criterion**            | Position sizing (alpha-lab portfolio). Conviction-based flat sizing in polymarket-bot (Kelly present but disabled — "not calibrated probabilities") |
| **VaR (Value at Risk)**        | Parametric (normal assumption) and historical (quantile) implementations. 95% confidence level                                                      |
| **CVaR / Expected Shortfall**  | Expected loss beyond VaR threshold                                                                                                                  |
| **Sharpe ratio**               | Risk-adjusted return metric                                                                                                                         |
| **Drawdown management**        | Circuit breaker with `AtomicBool` flag for hot-path reading. Daily loss limits. Max drawdown gates                                                  |
| **Options Greeks aggregation** | Portfolio-level delta, gamma, vega, theta risk                                                                                                      |
| **Historical simulation**      | 21 price-move scenarios (±20% range) for kokoro-mm VaR/CVaR                                                                                         |

### Market Making

| Concept                         | Implementation                                                                                                                         |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Avellaneda-Stoikov model**    | Reservation price with inventory skew, EWMA volatility, adverse selection premium. Full implementation in kokoro-mm `SpreadCalculator` |
| **Fair value estimation**       | Multi-source fusion with exponential freshness decay, confidence weights, EMA filtering, velocity tracking                             |
| **Inventory management**        | Net token exposure tracking per side, feeding skew into spread calculator                                                              |
| **Adverse selection detection** | Fill pattern monitoring to detect toxic flow, triggering batch cancellation waves                                                      |
| **Laddered quoting**            | Tiered bid/ask levels from spread output, breakout detection at fill, automatic stop-loss placement                                    |
| **Quote generation**            | 392-line `QuoteGenerator` producing full bid/ask ladder from spread output                                                             |

### Backtesting

| Feature                  | Details                                                                      |
| ------------------------ | ---------------------------------------------------------------------------- |
| **BacktestRunner**       | Single-pass over `PriceBar` slices with configurable SL/TP                   |
| **ParameterOptimizer**   | Grid search + random search over `ParameterRange`                            |
| **WalkForwardAnalyzer**  | Rolling train/test windows for out-of-sample validation                      |
| **MonteCarloSimulator**  | Path randomization for confidence intervals                                  |
| **Synthetic scenarios**  | Crash, ramp, sideways JSONL generation for offline replay                    |
| **Deterministic replay** | Same `HistoricalTick` input always produces same output (kokoro-mm backtest) |

### Market Microstructure

| Concept                        | Implementation                                                                                            |
| ------------------------------ | --------------------------------------------------------------------------------------------------------- |
| **Hawkes process**             | Self-exciting point process: λ(t) = μ + Σ α·exp(-β·(t−tᵢ)). Cascade threshold detection for factor-hawkes |
| **Order flow imbalance (OFI)** | Normalized thresholding at ±0.5 (signal) and ±2.0 (strong signal). Dedicated crate in pricing-service     |
| **LP repositioning detection** | UniswapV3-style tick space analysis for AMM state factor                                                  |
| **Liquidity density scoring**  | Thin zones ahead → large move potential                                                                   |
| **Whale detection**            | Exchange inflow/outflow with decay, tracked wallet consensus                                              |
| **Order book imbalance**       | Book manipulation analysis: mid/spread/VWAP calculation                                                   |
| **Resistance level detection** | Price level identification from tick data (kokoro-mm)                                                     |
| **Swap pressure**              | DEX swap volume and direction analysis                                                                    |

### Monte Carlo Methods

| Method                                     | Application                                                     |
| ------------------------------------------ | --------------------------------------------------------------- |
| **Simple binary**                          | Basic probability estimation                                    |
| **Importance sampling**                    | Proposal distribution reweighting for rare event estimation     |
| **Antithetic variates**                    | Variance reduction by pairing paths                             |
| **GBM (Geometric Brownian Motion)**        | Asset price path simulation                                     |
| **LMSR (Logarithmic Market Scoring Rule)** | Cost function for prediction market making + Bregman divergence |

---

## 3. Blockchain & DeFi

### Solana Development

- **20 Anchor programs** with full instruction handler implementations spanning DeFi (AMM, lending, yield vaults, liquidation engine, leveraged betting), gaming (6 casino game types), prediction markets, NFT auctions, governance
- **SPL Token integration**: mint/redeem chip tokens, associated token account management
- **House pool architecture**: LP deposits, game locks, settlement, circuit breaker, rebalance
- **Reward system**: Rakeback accrual, claim mechanics, referral system, tier boosting
- **DEX integrations**: Jupiter V6 (swap routing, quote API), Raydium AMM (pool state), Orca Whirlpool (position tracking), Pump.fun (detection)
- **WebSocket subscription**: `logsSubscribe` for real-time wallet monitoring
- **Transaction parsing**: Full tx fetch via RPC, program ID identification, `DetectedSwap` extraction

### EVM Development

- **Multi-chain liquidation**: 6 chains (Ethereum, Base, Arbitrum, Polygon, Optimism, Avalanche) with protocol-specific adapters
- **Flash loan execution**: Solidity `FlashLiquidator.sol` — atomically flash-borrow, liquidate, swap via Uniswap V3, repay
- **`alloy` framework**: Contract interaction via `sol!` macro for inline ABI definition, transaction building, gas estimation
- **EIP-712 signing**: Typed structured data signing for Polymarket CLOB orders (manual Keccak256 digest computation)
- **Flashbots integration**: MEV-protected transaction submission via `eth_sendBundle` on Ethereum mainnet
- **On-chain operations**: CTF splitPosition/mergePositions/redeem, USDC + ERC-1155 approvals (kokoro-mm)
- **Fee tier selection**: Uniswap V3 fee classification (stable-stable 0.05%, WETH-stable 0.05%, default 0.3%)
- **Close factor logic**: Protocol-specific (Aave V3: 50%/100% based on HF threshold; Compound: always 100%)

### Prediction Markets

- **Complete Polymarket SDK**: CLOB REST + WebSocket, Gamma API, EIP-712 order signing, HMAC-SHA256 L2 auth, fill detection via polling
- **CTF (Conditional Token Framework)**: splitPosition/mergePositions/redeem operations on Polygon
- **Multi-venue routing**: Polymarket + Kalshi + Manifold market provider adapters (kokoro-mm)
- **Brownian Bridge strategy**: Path conditioning research on 11,348 historical markets, hierarchical timeframe cascade
- **8-profile fleet**: 8 parallel strategy pipelines sharing single data feed (polymarket-bot)
- **Copy trading**: Trader discovery, position mirroring, hold-to-resolution (copy-trader)

---

## 4. Full-Stack Web Development

### Backend Architecture

Aligned with 2026 cloud-native best practices (CNCF: 89% organizational adoption, 80% running Kubernetes in production), the backend architecture implements the standard cloud-native patterns: API Gateway (Platform binary), Event-Driven Architecture (Redis Streams), Circuit Breaker (`AtomicBool` flags), and CQRS-like read/write separation (Lab vs Engine binaries).

- **Axum 0.8 expertise**: All Rust HTTP services use Axum 0.8 with tower::Service middleware composability (CORS, rate limiting, tracing, compression, auth) — timeouts and auth added without modifying handler signatures. kokoro-mm has 69 routes across 24 modules.
- **Express/Node.js**: kokoro-pipeline console (50+ route modules, Prisma ORM, 30+ models)
- **FastAPI**: polymarket-bot strategy service (port 8100), kokoro-copy-trader (port 4500)
- **Gin (Go)**: kokoro-staking backend with interface-segregated adapters
- **Payload CMS**: happykokoro.com website with SQLite, lexical editor, form-builder, SEO
- **Authentication**: JWT sessions, API key (HMAC-SHA256), TOTP 2FA (RFC 6238), Argon2 password hashing, AES-256-GCM wallet encryption, HKDF key derivation, GitHub OAuth, SAML/OIDC SSO
- **Tier-gated middleware**: Request-level authorization by subscription level (FREE/MANUAL/SIGNAL/AUTOPILOT in kokoro-mm; Free/Level1/Level2/ProMax in alpha-lab)

### Frontend Development

- **Next.js 15/16**: Production frontends with App Router, server components, static export
- **React 19**: Latest features across all frontends
- **Tailwind v4**: PostCSS plugin model (not JIT config)
- **Component libraries**: Radix UI primitives, shadcn/ui styled components
- **State management**: Zustand 5 (client stores), SWR 2 (data fetching with caching)
- **Real-time**: SSE with exponential backoff reconnection (custom `useSSE` hook), WebSocket for exchange feeds
- **Charting**: 6 libraries (lightweight-charts v5 for OHLC, recharts for dashboards, chart.js, plotly.js for scientific plots, d3 for custom vis, React Flow for node-graph editors)
- **Visual editors**: React Flow (@xyflow/react v12) strategy builder canvas with custom nodes (cancel, inventory, mint, quote, round-lifecycle, spread-visualizer)
- **Desktop apps**: Tauri v2 (kokoro-vpn desktop client)

### Database Design

- **PostgreSQL**: Complex schemas with 21 query modules (kokoro-mm), 30+ Prisma models (kokoro-pipeline), repository pattern with async traits and in-memory stubs for testing
- **Redis Streams**: 10 active streams with consumer groups, dual JSON/proto format, XREADGROUP + ACK, XPENDING monitoring. The persistence + consumer group + ordering properties of Redis Streams (vs simple Pub/Sub) follow 2026 real-time streaming best practices. The dual-format JSON→proto migration pattern was executed across all 10 streams as a zero-downtime protocol evolution.
- **SQLite**: Lightweight persistence where appropriate (polymarket-bot, VPN, copy-trader, CMS)
- **Migration management**: SQLx migrations (58 pairs in kokoro-mm), Prisma migrations, JSONL append-only event logs

---

## 5. Infrastructure & DevOps

### Container Orchestration

- **Docker**: Multi-stage builds for Rust binaries (builder → runtime), all production services containerized
- **Docker Compose**: Full-stack service orchestration across 3 servers with health checks, volume management, network isolation
- **11 self-hosted services**: Analytics (Umami), git (Gitea), monitoring (Uptime Kuma), whiteboard (Excalidraw), URL shortener (Shlink), paste bin (PrivateBin), bookmarks (Linkding), file sync (Syncthing), dashboard (Homepage)

### Networking & Security

- **WireGuard VPN**: Dual-mode infrastructure — client VPN (hub-and-spoke) and mesh VPN (full-mesh). ACL firewall rule system generating iptables/nftables scripts. 3-node mesh across Singapore, Ireland, London.
- **Reverse proxying**: Caddy (automatic HTTPS) + Nginx for different services
- **Cloudflare**: DNS, CDN, DDoS protection for all public services
- **SOPS**: Encrypted secrets management
- **Flashbots**: MEV-protected transaction submission
- **Private key security**: Never transmitted via API (placeholder pattern), encrypted at rest (AES-256-GCM), per-user derivation (HKDF)

### Monitoring & Observability

- **Prometheus**: Metrics from all Rust services via tower-http middleware
- **Grafana**: Dashboard visualization for oncall monitoring
- **OpenTelemetry**: Distributed tracing
- **Structured logging**: `tracing` + `tracing-subscriber` with span context across all Rust services
- **Health endpoints**: Every service exposes `/health` and `/metrics`
- **Uptime Kuma**: Self-hosted uptime monitoring
- **Umami**: Self-hosted web analytics

### Multi-Server Management

| Server  | Provider     | Location  | Services                                                           |
| ------- | ------------ | --------- | ------------------------------------------------------------------ |
| sg-main | DigitalOcean | Singapore | Alpha-lab platform, trading bots, monitoring, self-hosted services |
| ie-poly | AWS EC2      | Ireland   | Kokoro MM, Polymarket bot                                          |
| uk-pay  | AWS EC2      | London    | Copy trader, market data                                           |

Connected via WireGuard mesh (10.10.0.0/24) for private inter-server communication.

### Server Scheduling & Maintenance

**Professional foundation**: The infrastructure practice is grounded in professional experience with Jenkins CI/CD, Kubernetes orchestration, and production server management. This hands-on operational discipline forms the foundation of the current AI-augmented infrastructure practice.

- Production server administration across 3 servers (DigitalOcean, 2x AWS)
- systemd service management for all backend processes
- Docker container orchestration with health checks and restart policies
- Cron job scheduling for periodic tasks (price feeds, graph reclustering, P&L aggregation)
- Log management and rotation
- SSL certificate management via Caddy auto-HTTPS and Cloudflare
- Database backup and maintenance (PostgreSQL, Redis persistence)
- Process monitoring: PM2 for Node.js, systemd for Rust binaries, Docker for containerized services
- Disk space management and resource monitoring
- Remote server access via SSH with key-based authentication
- Multi-server coordination via WireGuard mesh VPN

---

## 6. AI & Agent Systems

### AI coding agent Mastery

- **MCP Protocol**: Built 2 MCP servers (115 total tools) exposing trading platform APIs to AI agents for autonomous operation
- **Custom skills**: Built production skills for AI coding agent (dev-pipeline, signal-pipeline, risk-management, kalman-filter, polymarket-arbitrage, anchor-patterns, dex-integration)
- **Agent orchestration**: Built agent-orchestra from scratch — Python dashboard managing AI agent CLI subprocesses with WebSocket real-time monitoring
- **Team patterns**: Designed team templates (feature-dev: 3 agents, build-fix: 1 agent, code-review, debug, research) with approval gates
- **Worktree isolation**: Each agent gets isolated git branch, merge-on-completion, shared CARGO_TARGET_DIR
- **Production pipeline**: `claude-dev-pipeline` skill implements 4-phase parallel execution with atomic PRs and dependency-aware merge order

### ML / AI Implementations

- **DQN (Deep Q-Network)**: Experience replay buffer, Q-network approximation, epsilon-greedy exploration (alpha-lab factor-ai crate)
- **LLM copilot integration**: Factor advisor, risk explainer, strategy generator, trace analyzer (alpha-lab copilot crate)
- **WASM plugin system**: `factor-sdk` with compile-time macro generation for user-written strategy factors loaded at runtime
- **Expert aggregation**: Hedge algorithm with multiplicative weights for online learning
- **PCA factor model**: scikit-learn PCA for factor decomposition (polymarket-bot Python service)
- **Conformal prediction**: Non-parametric uncertainty bounds for signal confidence

---

## 7. Cryptography & Security

| Area                      | Implementation                                                               |
| ------------------------- | ---------------------------------------------------------------------------- |
| **EIP-712 typed signing** | Manual Keccak256 digest computation for Polymarket orders                    |
| **ECDSA**                 | ethers/k256 for live transaction signing                                     |
| **HMAC-SHA256**           | API authentication (Polymarket CLOB L2 auth, kokoro-mm API keys)             |
| **AES-256-GCM**           | Wallet key encryption at rest                                                |
| **HKDF-SHA256**           | Per-user cryptographic key derivation from master key                        |
| **Argon2**                | Password hashing                                                             |
| **JWT (RS256/HS256)**     | Session token management across all API servers                              |
| **TOTP (RFC 6238)**       | Time-based one-time passwords for 2FA                                        |
| **WireGuard**             | VPN tunnel encryption (Curve25519 key exchange)                              |
| **Flash loan atomicity**  | Solidity contract ensuring borrow-liquidate-swap-repay in single transaction |
| **SOPS**                  | Encrypted secrets management for deployment configs                          |

---

## 8. Testing & Quality Assurance

### Test Philosophy

- **Pure-function testing**: Strategies and quant algorithms are pure functions tested deterministically without I/O or mocking
- **No mock frameworks**: All tests use real logic with synthetic data, no external mocking libraries
- **Feature-gated slow tests**: Expensive tests (convergence, Monte Carlo) behind `slow-tests` feature flag
- **Co-located test modules**: `#[cfg(test)] mod tests` within each source file
- **Repository pattern**: Database repos have both `Pg*` (real) and in-memory implementations for testing
- **Synthetic data generation**: Tests generate their own input data inline — no fixture files

### Test Coverage

| Project                | Tests | Focus Areas                                                                                                                                |
| ---------------------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| kokoro-alpha-lab       | 1,074 | Filter convergence, quant algorithms (GARCH, copulas, VaR), signal composition, risk gates, factor implementations                         |
| kokoro-mm              | 690   | Quoting pipeline, strategies (symmetric, laddered breakout), order management, spread calculation, round controller, live order management |
| kokoro-polymarket-bot  | 72    | GARCH fitting/forecasting, Hurst exponent, jump detection, Student-t CDF, risk gate chain, candle aggregation                              |
| kokoro-liquidation-bot | 24    | Profitability calculation, risk gates, circuit breaker, health factor math, gas estimation                                                 |

### CI/CD Gates

- `cargo build --release` — zero warnings
- `cargo clippy -D warnings` — all lint violations are errors
- `cargo fmt --check` — enforced formatting
- `cargo deny check` — dependency license and vulnerability audit
- `npm run build` — frontend build verification
- Full test suite per PR

---

## 9. Software Architecture Patterns

| Pattern                           | Application                                                                                            |
| --------------------------------- | ------------------------------------------------------------------------------------------------------ |
| **Clean Integration Layer (CIL)** | Pure-logic crates with I/O at boundaries only (alpha-lab: 63 pure crates + 3 app binaries)             |
| **Trait-object pipeline**         | `Vec<Box<dyn AlphaFactor>>` for dynamic factor composition                                             |
| **Builder pattern**               | `AlphaSignal::new().with_metadata().with_prediction()`, `ArtifactBuilder`, `DataHub::new().add_tick()` |
| **Factory registry**              | String → factory function mapping with feature-gated population                                        |
| **Role-based composition**        | Primary → Confirmation → Filter → Observer signal roles with different composition rules               |
| **State machine**                 | Explicit enum variants for round lifecycle, order lifecycle                                            |
| **Repository pattern**            | Async trait repos with PostgreSQL + in-memory implementations                                          |
| **Anti-corruption layer**         | `mm-polymarket` ACL wrapping external Polymarket API with domain-typed interface                       |
| **Composable risk gates**         | `RiskGateChain` running gates sorted by priority: Pass/Reject/Resize with accumulating multipliers     |
| **Decorator pattern**             | Go staking adapters: circuit breaker, rate limiter, cache, metrics layered uniformly                   |
| **Interface segregation**         | Chain adapters implement only supported capabilities                                                   |
| **Feature-gated compilation**     | Conditional inclusion of crates at compile time for different build profiles                           |
| **Worktree isolation**            | Each agent gets isolated git branch for conflict-free parallel development                             |
| **Single-binary MVP**             | Multiple logical services in one process with direct function calls (kokoro-mm)                        |
| **Dual-format messaging**         | Redis Streams with automatic JSON/proto detection for backward-compatible migration                    |

---

## 10. Data Pipeline & Streaming Architecture

### Redis Streams

- **10 active streams** with consumer groups, XREADGROUP + ACK pattern for reliable at-least-once delivery
- **XPENDING monitoring** for consumer lag detection and dead-letter identification
- **Dual-format migration**: JSON→proto transition with auto-detection at consumer level — consumers inspect first byte to determine format, enabling zero-downtime rolling upgrades without coordinated deployment
- **Stream topology**: wallet-monitor → pricing-service → alpha-lab engine (discovery → aggregation → signal pipeline → execution)

### Real-Time Communication

- **SSE (Server-Sent Events)** for frontend real-time updates: custom `useSSE` React hook with exponential backoff reconnection (1s → 30s cap), automatic event parsing and state hydration
- **gRPC streaming**: Server-streaming RPCs for signals, positions, and trades using tonic 0.13. Bi-directional streaming for inter-service communication
- **WebSocket feeds**: Exchange data adapters (Binance, Coinbase, Polymarket) with per-connection heartbeat and automatic reconnection

### Event Sourcing & Audit

- **JSONL append-only event log** for decision trace audit trails — every signal evaluation, risk gate decision, and order placement is logged with timestamp and causal chain
- **Deterministic replay**: Historical event logs can be replayed through the pipeline for backtesting and debugging

---

## 11. Payment Processing

### Stripe Integration

- **Checkout sessions**: Server-side session creation with success/cancel URL handling
- **Subscription lifecycle management**: Plan creation, upgrade/downgrade, cancellation, proration handling
- **Webhook event processing**: Signature verification, idempotent event handling for payment_intent.succeeded, subscription.updated, invoice.paid
- **Creator payouts**: Marketplace revenue split and creator payout processing (kokoro-pipeline)

### Crypto Payments

- **USDC on Solana**: On-chain vault address validation and transaction confirmation (kokoro-pay)
- **Gift code system**: Generation, redemption, validation with expiry tracking (kokoro-pay)

### Platform Payment Service

- **Redis Streams-based payment lifecycle**: Payment events flow through the same streaming infrastructure as trading signals (services/payment-service in alpha-lab monorepo)
- **Multi-provider abstraction**: Unified interface across Stripe and crypto payment rails

---

## 12. PHP & Enterprise Web Development

- Laravel MVC architecture: Models, Controllers, Migrations, Seeders, Blade views
- Eloquent ORM with relationships, mass assignment protection, query scoping
- Authentication: Laravel Breeze (register, login, password reset, profile management)
- Database design: MySQL schemas with foreign key constraints, cascading deletes, index optimization
- File handling: Image upload to storage with public disk linking
- Form validation: inline and FormRequest-based validation
- Server-side rendering: Blade templating with Bootstrap 5 integration
- Testing: Pest framework for feature and unit testing
- Production experience with Laravel 11 enterprise web applications: MVC architecture, Eloquent ORM, Pest testing, Blade templates, enterprise authentication patterns

---

→ [Read the full article version](../articles/skills-and-expertise.md)

---

**Next steps:** [Explore our services →](../services/overview.md) | [View technical profile →](../profile/resume.md) | [Contact us →](../services/contact.md)

---

_Kokoro Tech — [tech.happykokoro.com](https://tech.happykokoro.com) · [GitHub](https://github.com/happykokoro) · [Contact](../services/contact.md)_
