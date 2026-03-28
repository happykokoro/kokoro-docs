# Projects Portfolio — Complete Technical Catalog

> Exhaustive documentation of every project in the Kokoro ecosystem. Each entry includes purpose, architecture, technical specifications, algorithms, API surface, deployment details, and current status.

---

## Table of Contents

1. [Kokoro Alpha Lab](#1-kokoro-alpha-lab) — Quantitative Trading Research Platform
2. [Kokoro MM](#2-kokoro-mm) — Polymarket AMM SaaS
3. [Kokoro Polymarket Bot](#3-kokoro-polymarket-bot) — Multi-Strategy Trading Bot
4. [Kokoro Liquidation Bot](#4-kokoro-liquidation-bot) — Multi-Chain DeFi Liquidation Engine
5. [Kokoro Protocol](#5-kokoro-protocol) — On-Chain DeFi Platform (Solana)
6. [Kokoro Alpha Lab Frontend](#6-kokoro-alpha-lab-frontend) — Trading Dashboard
7. [Kokoro Staking](#7-kokoro-staking) — Multi-Chain Staking Aggregator
8. [Lab MCP](#8-lab-mcp) — MCP Tool Server
9. [Kokoro Pipeline](#9-kokoro-pipeline) — Automated Dev Pipeline Engine
10. [Agent Orchestra](#10-agent-orchestra) — Multi-Agent Orchestrator
11. [Kokoro VPN](#11-kokoro-vpn) — Self-Hosted VPN Infrastructure
12. [Kokoro Copy Trader](#12-kokoro-copy-trader) — Copy Trading Bot
13. [Kokoro Wallet Monitor](#13-kokoro-wallet-monitor) — Solana Wallet Monitor
14. [Kokoro Pricing Service](#14-kokoro-pricing-service) — Multi-DEX Price Aggregation
15. [Kokoro Pay](#15-kokoro-pay) — Crypto Payment Gateway
16. [Kokoro Tech](#16-kokoro-tech) — Company Website
17. [Claude Init](#17-claude-init) — CLI Configuration Generator
18. [Claude Dev Pipeline](#18-claude-dev-pipeline) — Parallel Development Skill
19. [Kokoro Services](#19-kokoro-services) — Self-Hosted Infrastructure
20. [HappyKokoro](#20-happykokoro) — Personal Portfolio Site

---

## 1. Kokoro Alpha Lab

**Repository**: `happykokoro/kokoro-alpha-lab` (private)
**Language**: Rust | **Lines of Code**: 242,466 | **Tests**: 1,074
**Status**: Production (deployed on DigitalOcean Singapore)

### Purpose

A multi-asset quantitative trading research and execution platform. The monorepo implements the full pipeline from raw market data ingestion through signal processing, factor composition, risk management, and order execution. Supports crypto (Solana DEX), equities (Alpaca), options (synthetic), forex, and prediction markets (Polymarket).

### Architecture

**Clean Integration Layer (CIL)**: 63 pure-logic crates under `crates/` contain zero I/O. All network, database, and filesystem operations are confined to 3 application binaries (`apps/lab`, `apps/engine`, `apps/platform`) and 4 service crates (`services/`).

```
apps/lab      (port 4100) — Research: factor pipeline, backtesting, HTTP API, gRPC :50051, SSE, replay mode
apps/engine   (port 4200) — Execution: frozen strategy, real execution, gRPC :50052
apps/platform (port 4000) — Gateway: auth, billing, tier gates, gRPC→REST proxy
```

**Inter-service communication**: Redis Streams (10 active streams with dual JSON/proto format), gRPC (tonic 0.13), REST (axum 0.8), SSE for real-time frontend streaming.

### Ecosystem Topology

Kokoro Alpha Lab is not a standalone application — it is the hub of a 7+ repository distributed system. The monorepo itself runs on the Singapore server, but the full platform spans multiple servers and multiple independently deployed repositories, all coordinated through defined contracts.

**Coordinated repositories (7+)**

| Repository                     | Role                                           | Communication                                            |
| ------------------------------ | ---------------------------------------------- | -------------------------------------------------------- |
| `kokoro-alpha-lab` (this repo) | Core monorepo: research, execution, gateway    | Exposes gRPC + REST; consumes Redis Streams              |
| `kokoro-alpha-lab-frontend`    | Next.js dashboard, extracted from monorepo     | REST API proxy → Platform (port 4000); SSE for real-time |
| `kokoro-wallet-monitor`        | Solana wallet tracking microservice, extracted | Publishes events → Redis Streams (upstream feed)         |
| `kokoro-pricing-service`       | Multi-DEX price aggregation, extracted         | Publishes events → Redis Streams (upstream feed)         |
| `lab-mcp`                      | TypeScript MCP server, 98 tool interfaces      | REST → Lab/Engine/Platform APIs                          |
| `kokoro-polymarket-bot`        | Polymarket trading bot, consumer               | Imports `shared-types`; reads Redis Streams              |
| `kokoro-copy-trader`           | Copy trading system, independent               | Runs on separate server; standalone deployment           |

**Three application binaries inside the monorepo**

- `apps/lab` (port 4100) — Research environment: full factor pipeline, backtesting, API, gRPC :50051, SSE, replay mode
- `apps/engine` (port 4200) — Execution environment: frozen strategy, real order execution, gRPC :50052
- `apps/platform` (port 4000) — API gateway: authentication, billing, tier-based access, gRPC→REST proxy for the frontend

**Two extracted microservices feeding data upstream**

- `kokoro-wallet-monitor` — Tracks on-chain wallet activity; publishes discovered wallets, cluster events, and coordination signals to Redis Streams, where the monorepo's Lab binary consumes them
- `kokoro-pricing-service` — Aggregates price data from multiple DEX sources; publishes normalized price events to Redis Streams consumed by the factor pipeline

**One extracted frontend consuming the REST API**

The Next.js frontend (`kokoro-alpha-lab-frontend`) was extracted from the monorepo as a separate repository. It communicates exclusively through the Platform binary's REST and SSE endpoints, never calling Lab or Engine directly. This maintains the API gateway contract between internal services and external consumers.

**One MCP server exposing 98 tool interfaces**

`lab-mcp` (TypeScript) exposes the full research platform as 98 structured MCP tools. AI agents can query live signal states, run backtests, inspect positions, manage strategies, and interact with the execution layer — all through tool calls that map to authenticated REST API endpoints.

**10 Redis Streams connecting all services**

All asynchronous events — price ticks, wallet alerts, factor inputs, signal outputs, execution confirmations, billing events — flow through named Redis Streams with consumer groups. Messages carry an `enc` field for auto-detected dual JSON/protobuf format, enabling rolling protocol migrations without downtime.

**gRPC for inter-app communication**

Lab, Engine, and Platform communicate synchronously via Tonic gRPC. Server-streaming RPCs handle continuous data flows (signals, positions, trades). Unary RPCs handle request-response operations (strategy deployment, backtest submission, factor queries).

**Payment service communicating via Redis Streams**

The payment service (`services/payment-service/`) lives inside the monorepo but communicates asynchronously with other services via Redis Streams — not direct function calls. This makes it independently deployable as a separate container within the same Docker Compose stack.

**Everything orchestrated by Docker Compose with 12+ containers on Singapore**

Services on the Singapore server run in a single Docker Compose stack: Redis, PostgreSQL, Lab, Engine, Platform, Frontend, Lab-MCP, Payment Service, Wallet Monitor, Pricing Service, Prometheus, and Grafana. Health checks gate startup ordering; `restart: unless-stopped` ensures recovery from transient failures.

**Shared type library versioned and tagged for cross-repo compatibility**

The `shared-types` crate defines the canonical types (signals, events, positions, tier enums) shared across all repositories. Satellite repositories pin to tagged releases (`shared-v0.x.x`) rather than floating on git HEAD, making dependency upgrades explicit and controllable.

### Quantitative Core Summary

The 65 crates implement a full quantitative trading stack. Signal processing: 11 DSP filters implemented from mathematical foundations — H-infinity (4-state with innovation gating; minimax optimal estimation under bounded noise per IEEE Transactions on Signal Processing), UKF (Cholesky sigma points; sigma point transform for nonlinear state propagation), particle filter (Sequential Monte Carlo with importance resampling), IMM (3-regime Kalman), RBPF, dual Kalman, wavelet CWT, Hilbert transform, Mellin transform, EWMA, and Fourier analysis. The prediction crate's expert aggregator and conformal prediction bounds approach the KalmanNet (IEEE 2021) frontier: neural network aided Kalman filtering for partially known dynamics. Factor implementations: 24 `AlphaFactor` implementations covering crypto, equities, options, forex, and prediction markets — including a Hawkes process factor for self-exciting event modeling and a DQN ensemble for adaptive signal generation. Quantitative modeling: GARCH(1,1) volatility estimation, Hurst exponent regime classification (R/S analysis), Gaussian/Student-t/Clayton copulas, conformal prediction, Brownian Bridge path conditioning, and ADF stationarity testing. Options pricing: Black-Scholes with full Greeks (delta, gamma, vega, theta, rho) and Monte Carlo simulation (GBM paths, importance sampling, antithetic variates). Portfolio optimization: Markowitz mean-variance optimization (analytical + projected gradient descent) and Kelly criterion sizing. Risk management: composable risk gate chains, VaR and CVaR (parametric + historical), drawdown circuit breakers, and adaptive position sizing.

### Crate Inventory (65 crates)

**Signal Infrastructure (8 crates)**:

- `factor-core` — Root `AlphaFactor` trait + `AlphaSignal` / `ComposedSignal` / `FactorInput` types
- `factor-registry` — Factory mapping strategy names → `Box<dyn AlphaFactor>`, feature-gated (`all-factors`, `core-factors`, `minimal`)
- `pipeline` — Sequential factor runner, collects signals
- `pipeline-runner` — Shared `PipelineResult` orchestration for Lab + Engine
- `composer` — Role-based signal composition: Primary → Confirmation (boost, capped 1.2x) → Filter (veto) → Observer (paper-only)
- `signal-store` — Thread-safe `DashMap<(factor, token), AlphaSignal>`
- `blackboard` — Type-erased shared state: `DashMap<String, Box<dyn Any>>`
- `decision-trace` — Full per-trade audit trail (factor signals → composition → risk → execution)

**Digital Signal Processing (4 crates)**:

- `dsp-filters` (89 tests) — H-infinity filter (4-state: position/velocity/acceleration/jerk with innovation gating; IEEE minimax optimal estimation), UKF (nalgebra Cholesky sigma points; IEEE sigma point transform), particle filter (Sequential Monte Carlo, importance resampling), Morlet wavelet CWT (20 log-spaced scales, multi-resolution time-frequency analysis), Hilbert transform (analytic signal via FFT), Mellin transform, Fourier, EWMA, rolling statistics
- `market-detectors` (49 tests) — Whale detector, cluster detector, OFI (Order Flow Imbalance), swap pressure, spectral event detector, reversal monitor
- `signal-generator` (50 tests) — `HierarchicalSignalGenerator`: orchestrates filters into regime-aware, confidence-scored signals
- `signal-core` — Facade re-exporting the above three

**Prediction & Autotune (1 crate, 51 tests)**:

- `prediction` — IMM filter (3-regime Kalman: Trending/Ranging/Volatile with Markov transition matrix), RBPF (Rao-Blackwellized particle filter: marginalizes continuous states analytically while sampling discrete regimes), stochastic-vol dual Kalman (price + log-vol coupled), expert aggregator (Hedge algorithm: multiplicative weights, exponential loss penalty η — approaches the KalmanNet IEEE 2021 frontier for partially known dynamics), conformal prediction (rolling calibration, 95% non-parametric coverage), Nelder-Mead simplex optimizer for autotune

**Factor Implementations (24 crates)**:

- `factor-swap-momentum` — Kalman-filtered swap momentum + safety checks
- `factor-price-trend` — EMA deviation threshold
- `factor-order-flow` — Normalized OFI thresholding (±0.5, ±2.0)
- `factor-cluster-activity` — Coordination score × volume
- `factor-depth-quality` — Depth score + slippage filter/veto
- `factor-enhanced` — 3× H-infinity cascade + microstructure
- `factor-hawkes` — Self-exciting Hawkes process: λ(t) = μ + Σ α·exp(-β·Δt)
- `factor-amm-state` — LP repositioning detection + liquidity density
- `factor-regime` — Cycle/regime classification
- `factor-ai` — DQN + trend/mean-reversion/risk-management agent ensemble (experience replay buffer, epsilon-greedy)
- `factor-whale-flow` — Exchange inflow/outflow net consensus with decay
- `factor-smart-money` — Tracked wallet consensus accumulator
- `factor-consensus` — Privacy-preserving community signal aggregation
- `factor-equity` — Momentum, MeanReversion, Pairs, SectorRotation
- `factor-options` — VolSurface, Skew, GammaScalping, CalendarSpread
- `factor-forex` — CarryFactor
- `factor-social` — SocialSentimentFactor (Twitter/Discord/Telegram)
- `factor-polymarket` — Polymarket-specific factors

**Quant Core (3 crates, 77 tests)**:

- `quant-core` — Black-Scholes pricing + Greeks, Monte Carlo (importance sampling, antithetic variates, GBM paths), Gaussian/Student-t/Clayton copulas, LMSR market scoring, Markowitz MVO (analytical Lagrangian + projected gradient descent via nalgebra DMatrix), GARCH(1,1) (grid search MLE), Hurst exponent (R/S analysis), ADF test, k-means clustering, Kelly criterion
- `amm-math` — UniswapV3-style tick math: slippage, price impact, fee models
- `backtest-engine` — BacktestRunner, ParameterOptimizer (grid/random search), WalkForwardAnalyzer, MonteCarloSimulator

**Execution Stack (5 crates)**:

- `execution` — Trait-based pipeline: `OrderSizer` → `SlippageEstimator` → `ProfitabilityFilter` → `ExecutionBackend` → `PostTradeValidator`
- `exec-paper` — PaperBackend with Fixed/Linear/AmmSim slippage models
- `exec-alpaca` — Alpaca equity REST+WS (paper + live)
- `exec-ib` — Interactive Brokers TWS adapter
- `exec-options` — Multi-leg options: strategies, `LegExecutor` trait, `OptionsRouter`, `ExerciseManager`

**Risk & Portfolio (6 crates, 36 tests)**:

- `risk` — `RiskManager`: confidence gate, per-asset-class limits, drawdown circuit breaker (`AtomicBool`), rate limiter, adaptive sizing, VaR/CVaR (parametric + historical), Sharpe ratio, options Greeks aggregation
- `portfolio` — `GlobalStance` (Aggressive/Normal/Defensive/Emergency), Kelly sizing, stance multipliers
- `portfolio-orchestrator` — `CorrelationMonitor`, `HeatManager` (circuit breakers), `PositionAggregator`
- `rebalance` — Drift computation, trade plan generation, target validation
- `positions` — In-memory position lifecycle store with metrics
- `attribution` — Per-factor P&L tracking

**Multi-Chain & On-Chain (4 crates)**:

- `chain-adapter` — `ChainAdapter` trait + `ChainRegistry`
- `evm-adapter` — Impls for Ethereum, Base, Arbitrum, Polygon
- `onchain-intel` — `SmartMoneyTracker`, `WhaleTracker`, `WalletClusterDetector`, `TokenFlowAnalyzer`
- `mev-strategies` — `MevStrategy` trait + arb, JIT liquidity, liquidation, sandwich impls

**Infrastructure (10 crates)**:

- `proto` — prost/tonic generated types for 6 proto packages
- `artifact` — Strategy artifact domain: TOML↔proto conversion, `ArtifactBuilder`, validation
- `data-source` — `DataSourceAdapter` + `EventBus` traits + `RedisEventBus`
- `db` — SQLx PostgreSQL repos
- `event-store` — Append-only JSONL event log
- `correlation` — Pairwise factor correlation via FFT (rustfft)
- `universe` — Token profile registry + lifecycle
- `tenant` — Tier-based resource limits (Free/Level1/Level2/ProMax)
- `copilot` — LLM-assisted factor advisor, risk explainer, strategy generator
- `factor-sdk` / `factor-wasm` — WASM factor plugin system with `kokoro_factor!` macro

### Key Metrics

- 65 Rust crates in workspace
- 242,466 lines of Rust
- 1,074 unit/integration tests
- 24 `AlphaFactor` implementations
- 21 public async traits
- 10 Redis Streams with dual JSON/proto format
- 3 application binaries
- Feature-gated builds: `all-factors` (65 crates) vs `minimal` (core only)

---

## 2. Kokoro MM

**Repository**: `happykokoro/kokoro-mm` (private)
**Language**: Rust + TypeScript | **Rust LOC**: 62,641 (126,873 total with tests) | **Frontend LOC**: ~80K TS
**Tests**: 690 (Rust) + frontend Vitest
**Status**: Production (deployed at https://mm.happykokoro.com, AWS Ireland)

### Purpose

A Polymarket Automated Market Maker (AMM) SaaS platform. Users become market makers on Polymarket's binary option rounds (5-min, 15-min, 4-hour crypto), minting CTF token pairs and profiting from the bid-ask spread. Tiered from free manual minting to fully autonomous AUTOPILOT mode.

### Architecture

**Single-binary MVP**: Gateway + Engine + DataHub run in one tokio process. Cross-service calls are direct function calls (no gRPC — deferred to Phase 8).

```
mm-bin (main.rs, 408 lines) → initializes all services, wires shared state
  ├── mm-gateway  — Axum HTTP (port 4000), 69 routes across 24 modules
  ├── mm-engine   — Quoting pipeline, order management, autopilot
  └── mm-datahub  — Data adapters (Pyth, Binance, CLOB WS), SSE broadcaster
```

### Crates (18 total, layered L0-L4)

**L0 — Domain Primitives**:

- `mm-types` — All domain types: `Round`, `Order`, `Fill`, `Strategy`, `MintOp`, `BookDiff`, `ResistanceLevel`
- `mm-proto` — API contract types (serialization boundary)
- `mm-traits` — Async traits: `MarketProvider`, `MmStrategy`, `OrderProvider`, `DataSource`, `NewsProvider`

**L1 — Domain Logic**:

- `mm-market` — Round lifecycle state machine (Discovered→OrdersOpen→Active→Settling→Settled), multi-venue router (Polymarket/Kalshi/Manifold), arbitrage scanner
- `mm-minting` — CTF splitPosition/mergePositions orchestrator with balance checks
- `mm-order` — Order lifecycle (paper + live), fill tracker, round-position accounting
- `mm-strategy` — Signal composer: `SpreadAdjustmentComposer`, `SignalClient`, `RegimeWeights`, `CopyTraderAsConfig`, `conformal_bounds`
- `mm-data` — Book manipulation (apply_diff, mid/spread/VWAP), order book imbalance, resistance level detection
- `mm-identity` — Auth (JWT + Argon2), TOTP 2FA (RFC 6238), API key management, tier gating, AES-256-GCM wallet encryption with HKDF-SHA256 per-user key derivation

**L2 — Infrastructure**:

- `mm-polymarket` — Complete Polymarket SDK: CLOB REST + WS, EIP-712/HMAC auth, order signing (alloy), Gamma API, fill detection, ACL anti-corruption layer
- `mm-polygon` — On-chain layer: splitPosition/mergePositions/redeem, USDC + CTF-1155 approvals, gas estimation, neg-risk adapter
- `mm-db` — SQLx PostgreSQL: 21 query modules, 58 migration pairs
- `mm-redis` — Redis pub/sub, streams, SSE event bus

**L3 — Services**:

- `mm-engine` — Core engine: quoting pipeline (FairValueEstimator → SpreadCalculator → InventoryTracker → QuoteGenerator → AdverseSelectionDetector → CancellationWave), order manager, lifecycle controller, strategies (SymmetricSpread, SignalSkewed, LadderedBreakout, Manual), risk (VaR/CVaR historical simulation), backtest harness, autopilot (5 risk gates), signal integration
- `mm-datahub` — Data hub: Pyth/Binance/CLOB adapters, book aggregation, SSE broadcaster, webhook, news, alert evaluation
- `mm-gateway` — Axum HTTP gateway: JWT/API-key middleware, tier middleware, rate limiting, Prometheus metrics

### Market Making Algorithms

**Avellaneda-Stoikov Model** (`mm-engine/quoting/spread.rs`):

- EWMA volatility estimate with configurable lambda
- Inventory skew shifts reservation price proportionally to net exposure
- Adverse selection premium added on top of base spread
- Components logged separately for telemetry and debugging

**Fair Value Estimation** (`mm-engine/quoting/fair_value.rs`):

- Multi-source fusion: CLOB mid + Binance spot + candle VWAP
- Sources carry exponential freshness decay and confidence weights
- EMA-filtered output with velocity tracking (price change/second) and uncertainty measure

**Strategy Types**:

1. `SymmetricSpread` — Baseline A-S model, symmetric quotes around fair value
2. `SignalSkewed` — Signal-driven mid-price shift: bullish → tighter ask / wider bid
3. `LadderedBreakout` — Tiered sell orders on both sides; breakout detected at fill → cancel opposite, place stop-loss
4. `Manual` — User-specified parameters, no quoting logic

**Adverse Selection Detection** (`mm-engine/quoting/adverse_selection.rs`, 365 lines):

- Monitors fill patterns to detect toxic flow
- Triggers `CancellationWave` (batch cancel) when threshold crossed

### API (69 routes)

Public: health, version, metrics, auth (register/login/refresh/forgot/reset), markets, book, tick/stream (SSE)
Protected (JWT): orders CRUD, mint/merge, strategies CRUD, billing, P&L
Tier-gated: wallets, configs, instances (start/stop), escrow
Signal tier: active signals
Billing: Stripe checkout/webhook/status
Marketplace: listings CRUD, subscribe, leaderboard (weekly/monthly)
Data: rounds/ticks/books/trades/signals, backtest
Phase 8 stubs: strikes, multi-venue, arbitrage scan, FIX protocol, WASM strategy plugins

### Frontend (36 pages)

Next.js 16, React 19, Tailwind v4, Zustand 5, SWR 2, Radix UI, lightweight-charts v5, recharts v3, @xyflow/react v12 (strategy builder canvas).

Key pages: dashboard (P&L chart, active rounds), markets browser, CTF minting wizard, order management, strategy builder canvas (React Flow), live tick stream with resistance levels, analytics, billing, leaderboard, onboarding wizard.

### MCP Tools (17)

Strategy (6), Market (3), Order (2), Status (2), Copilot (4: explain_round, suggest_spread, check_inventory, optimize).

---

## 3. Kokoro Polymarket Bot

**Repository**: `happykokoro/kokoro-polymarket-bot` (private)
**Language**: Rust + Python | **Rust LOC**: 15,491 | **Python LOC**: ~1,470
**Tests**: 72
**Status**: Stopped (strategy replacement needed — fair-value dislocation strategy failed live)

### Purpose

Multi-strategy Polymarket prediction market trading bot with 8-profile fleet architecture. Single Rust binary runs 8 parallel pipelines (each a different quantitative strategy profile), sharing one DataHub aggregating Binance spot/futures WebSocket, Polymarket CLOB WebSocket, and Deribit.

### Crate Structure (7 crates)

- `scanner` — CLOB market scanner, crypto round discovery (BTC/ETH/SOL/XRP × 5m/15m/1h), Binance + Pyth feeds
- `data` — Pluggable adapter system: `TickAdapter`/`RestAdapter` traits, `DataHub` orchestrator, candle builder, watchdog reconnect
- `data-hub` — Separate binary: candle store, round tracker, multi-timeframe intel
- `risk` — Composable `RiskGateChain`, Kelly sizing, VaR 95%, gates: MinEdge, MaxExposure, Drawdown, PositionCount, Volatility. Per-asset multipliers: SOL 1.4x, ETH 0.9x
- `executor` — EIP-712 + HMAC-SHA256 order signing, CLOB submission, paper vs live routing
- `api` — REST + WebSocket (axum port 4200), SQLite persistence, backtesting endpoint
- `bot` — Main binary: 8-pipeline orchestrator, 4 quant modules, 3 strategy tiers, bilateral MM, timeframe intel

### Quant Algorithms

- **GARCH(1,1)**: Grid search MLE over (alpha, beta) ∈ [0.015..0.300] × [0.025..1.0], n-step ahead variance forecast
- **Hurst Exponent**: R/S analysis on log-returns, OLS regression of log(R/S) vs log(n)
- **Jump Detection**: Return z-scores (threshold 3.0σ)
- **Brownian Bridge**: Path conditioning table from Q6 research (11,348 markets). Parent=UP + prior [DOWN, DOWN] → 95% p_up (100% historical accuracy n=18)
- **3 Strategy Tiers**: Rust baseline (6 static strategies), QuantCryptoComposer (GARCH-T/Hurst-Hinf/FullQuant profiles), Python service (GARCH MLE, Student-t CDF, PCA factor model, wavelets)

---

## 4. Kokoro Liquidation Bot

**Repository**: `happykokoro/kokoro-liquidation-bot` (private)
**Language**: Rust + Solidity | **Rust LOC**: 5,130
**Tests**: 24
**Status**: Production (deployed on DigitalOcean, paper mode, port 4400)

### Purpose

Multi-chain DeFi liquidation engine targeting undercollateralized lending positions. Pipeline: discover borrowers via historical event logs → poll health factors → evaluate profitability → risk-gate → execute via flash loan or absorb().

### Protocol Coverage

| Protocol    | Chains                                                 | Method                         |
| ----------- | ------------------------------------------------------ | ------------------------------ |
| Aave V3     | Ethereum, Base, Arbitrum, Polygon, Optimism, Avalanche | Flash loan + `liquidationCall` |
| Seamless    | Base                                                   | Flash loan + `liquidationCall` |
| Compound V3 | Ethereum, Base, Arbitrum, Polygon                      | `absorb()` (no flash loan)     |
| Moonwell    | Base                                                   | `liquidateBorrow()`            |

### Key Architecture

- `FlashLiquidator.sol` — On-chain contract: atomically flash-borrows debt, calls liquidation, swaps collateral via Uniswap V3, repays. Zero capital required
- `ProtocolAdapter` trait — Runtime dispatch via `Arc<dyn ProtocolAdapter>` for pluggable protocol support
- `LiquidationExecutor` trait — `FlashLoanExecutor`, `CompoundAbsorbExecutor`, `PaperExecutor` implementations
- `DashMap<Address, LendingPosition>` — Lock-free concurrent state shared across discovery/poller/API
- Risk engine: minimum profit threshold, per-tx/daily gas budget, circuit breaker (N consecutive reverts)
- Close factor logic: Aave V3 uses 50% when HF ≥ 0.95, 100% below; Compound always 100%
- Live: ~270 borrowers discovered, ~21 positions monitored, Ethereum primary

### REST API (port 4300/4400)

- GET /health — service health
- GET /api/positions — all monitored positions
- GET /api/positions/at-risk — positions with HF < threshold
- GET /api/opportunities — profitable liquidation opportunities
- GET /api/config — current configuration
- GET /api/history — execution history
- GET /api/pnl — profit & loss summary
- GET /api/chains — per-chain adapter status
- WebSocket /ws — real-time position updates
- Frontend workspace: `/liquidation` (6 pages, 13 API proxy routes)

---

## 5. Kokoro Protocol

**Repository**: `happykokoro/kokoro-protocol` (private)
**Language**: Rust (Anchor 0.30.1) + TypeScript (tests)
**Status**: Development (localnet/devnet)

### Purpose

On-chain DeFi platform on Solana with 20 Anchor programs spanning infrastructure, DeFi, gaming, prediction markets, and NFTs.

### Programs (20 total)

**Infrastructure (6)**: platform_treasury, platform_token (chip mint/redeem), user_vault, house_pool (LP deposits, circuit breaker, rebalance), reward_pool (rakeback, referrals, tier boost), governance (proposals, voting, execution)

**DeFi (5)**: dex_amm (constant product AMM: create pool, add/remove liquidity, swap), lending_protocol (create pool, supply, borrow, repay, liquidate, interest update), yield_vaults (create, deposit, withdraw, harvest, rebalance strategy), liquidation_engine (health check, loan liquidation, leverage liquidation, Dutch auction), leveraged_betting (open/add margin/close/force-close positions)

**Casino/Gaming (7)**: game_dice (place/resolve/cancel bet), game_crash (create round, place bet, cash out, resolve), game_coinflip, game_slots (spin/resolve/initialize), game_sports (create event, update odds, place bet, settle, cancel), game_d20 (battle: place/resolve/cancel), game_escrow (PvP: create/join/settle/force-refund)

**Prediction (1)**: prediction_market (create market, buy/sell shares, resolve, redeem winnings)

**NFT (1)**: nft_auction (create/place bid/settle/cancel)

---

## 6. Kokoro Alpha Lab Frontend

**Repository**: `happykokoro/kokoro-alpha-lab-frontend` (private)
**Language**: TypeScript (Next.js 15, React 19)
**Status**: Production

### Pages (107 total routes)

**Lab**: backtest (jobs/replay/results/scenarios), canvas, signals, factors, custom-factors, filters, correlation, consensus, copilot, predictions, rebalance, strategy (compare), workspace, microstructure, market, metrics, events, traces, universe, audit, reports (transparency), quant-tools, tradfi (equities/options/greeks/risk)

**Engine**: live, positions, execution, metrics, mev, controls, attribution, safety, services, wallets, polymarket (positions)

**Market**: crypto, stocks, forex, indices, bonds, etfs, commodities, crypto-futures, crypto-options, macro, technicals, movers, news, nft, calendar, metrics, intel

**Polymarket**: markets, bot (instances), risk, simulation, copula, arbitrage, depth, data-hub, calibration, particle-filter, formulas, agent-sim

**Liquidation**: positions, opportunities, config, history, pnl

**Marketplace**: listings, leaderboard, my-strategies, publish

**Charting**: lightweight-charts v5, recharts, chart.js, plotly.js, d3. Real-time via SSE with exponential backoff.

---

## 7. Kokoro Staking

**Repository**: `happykokoro/kokoro-staking` (private)
**Language**: Go 1.26 + TypeScript (Next.js 16 frontend)
**Status**: Plan/Development

### Purpose

Multi-chain validator staking aggregator supporting 17+ chains. Interface-segregated plugin architecture where each chain adapter implements only supported capabilities.

### Supported Chains (17)

Ethereum (EigenLayer restaking), Solana (Jito restaking), Cosmos, Avalanche, BNB Chain, Polkadot (Nominated PoS), Near, Cardano, Aptos, Sui, Tron, Tezos (Liquid PoS), Osmosis (LP incentives), Celestia, Injective, Sei, MultiversX.

### Architecture

- Interface-segregated: `StakingReader`, `TxBuilder`, `HealthChecker` — adapters implement only what they support
- Decorator layer: circuit breaker, rate limiter, cache, metrics applied uniformly
- Client-side signing only — backend builds unsigned transactions, never handles private keys
- `shopspring/decimal` for all financial math
- `errgroup` for partial-failure-tolerant cross-chain queries
- Prometheus metrics on every RPC call
- Modules: adapter/, api/, auth/, billing/, cache/, config/, eventbus/, model/, portfolio/, store/, worker/, services/mcp/

---

## 8. Lab MCP

**Repository**: `happykokoro/kokoro-alpha-lab` ecosystem
**Language**: TypeScript
**Status**: Production (98 tools)

### Tool Categories (98 tools across 13 files)

| Category      | Tools | Examples                                                                                                          |
| ------------- | ----- | ----------------------------------------------------------------------------------------------------------------- |
| Core Lab      | 36    | signals, predictions, backtesting, positions, candles, factors, metrics, traces, filter state, equity curve       |
| Quant Tools   | 8     | GBM simulation, Black-Scholes, option pricing, Markowitz, efficient frontier, Brier score, copula, t-dist fitting |
| Engine        | 7     | deploy/stop/status bots, cluster health, positions, trades                                                        |
| Backtest Jobs | 7     | submit, list, get, cancel, optimize, walk-forward, Monte Carlo, scenarios                                         |
| Alerts        | 7     | channels CRUD, test, history, preferences                                                                         |
| Admin         | 6     | list users, change tier, kill bot, system health, audit log                                                       |
| Polymarket    | 7     | markets, detail, positions, quotes, simulate, copula, arbitrage                                                   |
| Data Sources  | 5     | list, start/stop adapter, upload, status                                                                          |
| TradFi        | 4     | positions, Greeks, risk metrics, stress test                                                                      |
| Artifacts     | 4     | export, validate, load, list                                                                                      |
| Rebalance     | 3     | drift check, plan, targets                                                                                        |
| Consensus     | 3     | get, contribute, tokens                                                                                           |
| Universe      | 3     | stats, profiles, single profile                                                                                   |

Features: tier-gating per tool, service-availability guards, Zod schema validation, dual transport (stdio + HTTP).

---

## 9. Kokoro Pipeline

**Repository**: `anescaper/kokoro-pipeline` → migrating to TS
**Language**: TypeScript (Express + React/Vite)
**Status**: Active development (Rust→TS migration)

### Purpose

Full-featured automated development pipeline engine orchestrating AI agents through structured multi-phase workflows, with React web console, visual pipeline designer, and SaaS platform layer.

### Architecture

- Express API (port 5555) + PostgreSQL (Prisma, 30+ models) + React/Vite frontend (port 3000)
- PipelineEngine: 6-phase orchestrator (research → plan → execute → audit → assemble → report)
- Agent dispatcher interface: Local/OpenAI/Gemini backends
- WorktreeManager for git isolation
- React Flow visual designer with 40+ node types
- 19 skills: design-architect, implement-features, generate-tests, qa-validate, scaffold-project, production-adapt, contract-audit, financial-risk-review, codebase-ingest/map/analyze/document/evaluate/plan, tech-lead-audit, fullstack-pipeline, auto-dev-task
- Pipeline modes: Greenfield, Incremental, Hotfix, Reverse (analyze existing), Reverse-then-Forward
- SaaS: multi-tenant orgs, GitHub OAuth, Stripe billing, marketplace, SSO (SAML/OIDC), SCIM 2.0, audit log

---

## 10. Agent Orchestra

**Repository**: `anescaper/agent-orchestra`
**Language**: Python + Rust
**Status**: Production (used for parallel development)

### Purpose

Multi-agent orchestration platform managing AI agent teams through automated pipelines: launch → monitor → merge → build → test → report.

### Architecture

- FastAPI + WebSocket dashboard (`/ws/status`, `/ws/logs`, `/ws/teams`, `/ws/gm`)
- `GeneralManager`: 7-phase lifecycle (launching → waiting → analyzing → merging → building → testing → completed)
- `TeamLauncher`: spawns AI agent CLI subprocesses, monitors stdout, auto-kills on ENOSPC/OOM
- Git worktree isolation: each agent gets isolated branch, merge-on-completion
- Team templates: feature-dev (3 agents: architect/implementer/reviewer), build-fix (1 agent), code-review, debug, research
- Approval gate: pipeline pauses on merge conflicts, build failures, test failures
- Shared `CARGO_TARGET_DIR` across worktrees
- SQLite session persistence

---

## 11. Kokoro VPN

**Repository**: `happykokoro/kokoro-vpn` (private)
**Language**: Rust + TypeScript (Tauri v2)
**Status**: Production (3-node mesh deployed)

### Purpose

Self-hosted WireGuard VPN platform with two modes: client VPN (hub-and-spoke) and mesh VPN (full-mesh encrypted tunnels between servers).

### Architecture

- Two binaries: `kokoro-vpn-server` (REST API port 3000, WireGuard management, JWT auth, sandbox guest tunnels) and `kokoro-vpn` CLI (mesh management, ACL, health, firewall scripts)
- Client VPN: hub-and-spoke on `wg0` (10.8.0.0/24, UDP 51820)
- Mesh VPN: full-mesh on `wg1` (10.10.0.0/24, UDP 51821) — N\*(N-1)/2 tunnels
- Per-node firewall ACL system: generates iptables/nftables scripts with dedicated `KOKORO_MESH` chain
- Monitoring: `/api/mesh/health`, `/api/mesh/metrics` (Prometheus format)
- Desktop app: Tauri v2, React 19, Tailwind v4
- Terraform configs for DigitalOcean + AWS deployment
- Mesh IPs: sg-main 10.10.0.1, ie-poly 10.10.0.2, uk-pay 10.10.0.3

---

## 12. Kokoro Copy Trader

**Repository**: `happykokoro/kokoro-copy-trader`
**Language**: Python 3.12
**Status**: Paper testing (deployed on AWS London, port 4500)

### Purpose

Mirrors positions of high-win-rate Polymarket traders. Discovers traders (≥55% win rate, ≥20 trades, ≥$50 profit), polls for new positions, executes GTC limit buy orders, holds to resolution.

### Architecture

- `discovery.py` — High-performer discovery with configurable filters
- `monitor.py` — Position polling (30s interval)
- `copier.py` — GTC limit buy execution, hold-to-resolution
- `polymarket/` — CLOB client, REST API, Gamma API
- FastAPI REST API, SQLite persistence
- Paper mode, $100 bankroll, max 10% per position, max 10 positions

### Post-Deploy Audit

- 4 critical bugs found and fixed during paper testing session
- Issues #1-#6 created tracking all findings
- Fixes deployed via SCP but NOT committed to git (tracked in Issue #5)
- No automated tests — testing is manual via paper mode observation

---

## 13. Kokoro Wallet Monitor

**Repository**: `happykokoro/kokoro-wallet-monitor` (private)
**Language**: Rust | **Status**: Production (deployed on DigitalOcean)

### Purpose

Real-time Solana wallet monitoring via WebSocket logsSubscribe.

### Architecture

- Per-wallet tokio task with exponential-backoff reconnect
- `TransactionParser` for DEX swap detection (Jupiter V6, Raydium, Orca, Pump.fun)
- `GraphEngine` using petgraph for directed fund-flow analysis with Louvain community detection for Sybil/coordinated cluster identification
- Publishes `DetectedSwap` and `ClusterSignal` events to Redis Streams
- Uses `shared-types` from alpha-lab monorepo (tag `shared-v0.2.2`)

---

## 14. Kokoro Pricing Service

**Repository**: `happykokoro/kokoro-pricing-service` (private)
**Language**: Rust | **Status**: Production (deployed on DigitalOcean)

### Purpose

Multi-DEX price aggregation with signal processing.

### DEX Sources

Jupiter, Raydium, Orca, Jupiter Quote API, Pyth oracle.

### Signal Pipeline

Parallel `tokio::join!` across DEXes → VWAP/median aggregation → 2-state Kalman filter (price + velocity) → MomentumRanker (top/bottom 20%) → OFI calculator → candle construction.

### Output

REST + SSE endpoints and Redis Streams.

---

## 15. Kokoro Pay

**Repository**: `happykokoro/kokoro-pay` (private)
**Language**: Rust | **Status**: Standalone (not deployed)

### Purpose

B2B crypto payment gateway supporting USDC on Solana and Stripe.

### Crate Structure

- `server/` — Axum, SQLx, PostgreSQL, Redis

### API Modules

- **orders** — create, list, get, update status
- **merchant** — register, API keys, webhook config
- **codes** — generate gift codes, redeem, validate
- **admin** — dashboard stats, merchant management
- **webhooks** — payment confirmation, expiry notification

### Payment Methods

- **USDC on Solana** — vault address validation, on-chain confirmation
- **Stripe** — checkout sessions, subscription management, webhook events

### Event-Driven Processing

Background task worker for async settlement, payment expiry, webhook delivery.

### Frontend

- `dashboard/` — merchant management portal
- `widget/` — embeddable payment button for merchant websites

### Database

PostgreSQL with orders, merchants, codes, events, webhook_deliveries tables.

---

## 16-20. Supporting Projects

**Kokoro Tech** — Next.js 16, static export, Tailwind v4. Company marketing website at https://tech.happykokoro.com. 18 components, dark theme, scroll animations. Deployed via rsync.

**Claude Init** — Python single file (1,229 lines, zero dependencies). Detects language/framework from project files, generates complete `.claude/` config (CLAUDE.md, settings.json, agents, skills). Supports 9 languages, 18 frameworks.

**Claude Dev Pipeline** — Markdown skill (SKILL.md protocol). 4-phase parallel pipeline: research → team execution (1 agent = 1 worktree = 1 PR) → review + fix loops → dependency-aware merge. Single human approval gate.

**Kokoro Services** — Docker Compose config for 11 self-hosted services (Umami, Gitea, Shlink, Uptime Kuma, PrivateBin, Excalidraw, Linkding, Syncthing, Homepage).

**HappyKokoro** — Next.js 15, Payload CMS 3.77, SQLite. Company website and blog. CMS-driven: pages, posts, projects, search. Resend email adapter for contact form.

---

→ [Read the full article version](../articles/projects-portfolio.md)

---

**Next steps:** [Explore our services →](../services/overview.md) | [View technical profile →](../profile/resume.md) | [Contact us →](../services/contact.md)

---

_Kokoro Tech — [tech.happykokoro.com](https://tech.happykokoro.com) · [GitHub](https://github.com/happykokoro) · [Contact](../services/contact.md)_
