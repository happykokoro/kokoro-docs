# The Kokoro Ecosystem: A Technical Deep Dive into Twenty Production Systems

> _This is the long-form article. For the structured reference, see [Projects Portfolio](../profile/projects-portfolio.md)._

> A comprehensive engineering analysis of the Kokoro project portfolio — covering quantitative trading infrastructure, DeFi automation, developer tooling, and supporting platforms. Written for senior engineers, CTOs, and technical investors evaluating the depth and cohesion of this technology stack.

---

## Prologue: A Distributed Architecture, Not a Collection

The projects described in this document are not independent experiments. They form a deliberate, interlocking distributed system built around a central thesis: that quantitative trading — across crypto, traditional equities, prediction markets, and DeFi — can be unified under a single coherent software architecture rather than scattered across siloed tools.

At the core sits Kokoro Alpha Lab, a 242,000-line Rust monorepo that defines the data types, traits, algorithms, and execution abstractions upon which nearly every other project depends. Surrounding it are execution-specialized derivatives — Kokoro MM for market making, the Polymarket Bot for directional trading, the Liquidation Bot for DeFi arbitrage — each consuming shared libraries from the monorepo's `shared-types` crate. The infrastructure layer includes a wallet monitor feeding on-chain intelligence upstream, a pricing service normalizing multi-DEX data, and an MCP tool server that exposes the entire research platform to AI-assisted workflows. The developer tooling — Agent Orchestra, Kokoro Pipeline, and claude-init — handles the engineering process itself, enabling a single developer to manage a codebase of this scale through automated multi-agent collaboration. Taken together, these projects represent a vertically integrated trading technology operation.

The platform covers six distinct technical domains, each with production-depth implementations. Quantitative signal processing implements 11 filter types from first principles — H-infinity, UKF, particle filter, IMM, RBPF, wavelet CWT, Hilbert transform, dual Kalman, and more — alongside 24 alpha factor implementations spanning crypto, equities, forex, and prediction markets. Market making is grounded in the Avellaneda-Stoikov model for inventory-adjusted optimal quoting. DeFi liquidation uses flash loan arbitrage across 6 EVM chains with zero capital required. Prediction market trading spans multiple strategy families including GARCH volatility modeling, Hurst exponent regime classification, and Brownian Bridge path conditioning. Multi-chain blockchain integration covers Solana (20 Anchor programs) and 6 EVM chains (Ethereum, Base, Arbitrum, Polygon, Optimism, Avalanche). Options pricing implements Black-Scholes with full Greeks and Monte Carlo simulation with variance reduction techniques.

### The Architecture of the Ecosystem

The ecosystem is structured as a federated architecture: a core monorepo provides shared domain types and infrastructure primitives, while satellite services are extracted into independent repositories when they reach operational maturity and have stable, proven interfaces. This extraction pattern is deliberate — start in the monorepo where iteration is fast and the interface is fluid, prove the interface under real workload, then extract to its own repository with a pinned `shared-types` dependency once the contract is stable. The wallet monitor, pricing service, and frontend all followed this path.

Inter-service boundaries are defined by message contracts rather than by organizational convention. Protobuf schemas define the wire format for all Redis Stream events and gRPC calls. Redis Stream message types establish the asynchronous contract between producers and consumers. REST API specifications define the synchronous contract at the boundary with external consumers. Each contract is versioned independently: proto files carry package names like `kokoro.lab.v1`, stream message types carry an `enc` field that enables format negotiation, and the shared-types crate uses semantic version tags (`shared-v0.x.x`) that satellite repositories pin to explicitly.

Cross-server service discovery is handled transparently by the WireGuard mesh. All services — whether running on the Singapore monorepo server, the Ireland market-making server, or the London copy-trader server — address each other by mesh IP in the 10.10.0.x range. A service does not know or care which physical server its dependency runs on. This makes the three-server deployment feel like a single datacenter from the application's perspective, without the overhead of a full service mesh framework.

---

## 1. Kokoro Alpha Lab

**Repository**: `happykokoro/kokoro-alpha-lab` (private)
**Language**: Rust | **Lines of Code**: 242,466 | **Tests**: 1,074
**Status**: Production — deployed on DigitalOcean Singapore

### Purpose and Scope

Kokoro Alpha Lab is a multi-asset quantitative trading research and execution platform built entirely in Rust. It implements the full pipeline from raw market data ingestion through signal processing, factor composition, portfolio construction, risk management, and order execution. The platform is deliberately multi-asset: it supports Solana decentralized exchanges, US equities via Alpaca, synthetic options, forex, and Polymarket prediction markets from a unified codebase. This breadth is not superficial — each asset class has dedicated factor implementations, data adapters, and execution backends.

The platform represents a deliberate architectural choice to invest deeply in correctness and performance at the foundation level, accepting a higher upfront engineering cost in exchange for a codebase where adding a new asset class or strategy is an additive operation rather than a cross-cutting concern.

### Architecture: The Clean Integration Layer

The most consequential architectural decision in Kokoro Alpha Lab is the Clean Integration Layer (CIL). All 63 pure-logic crates under the `crates/` directory contain zero I/O operations. There are no database calls, no HTTP requests, no file reads inside the core library. Every piece of logic that touches the outside world — network connections, database queries, filesystem access — is confined to three application binaries and four service crates.

This constraint has significant practical consequences. Pure crates are trivially unit-testable without mocking infrastructure. They compile faster because they carry fewer dependencies. They can be composed freely without worrying about side-effect ordering. The three application binaries — `apps/lab` on port 4100, `apps/engine` on port 4200, and `apps/platform` on port 4000 — each integrate the pure logic crates against real infrastructure in ways appropriate to their role. Lab is the research environment: it runs the full factor pipeline, exposes an HTTP API for human analysis, streams data via gRPC on port 50051, supports SSE for real-time frontend updates, and implements a replay mode for historical simulation. Engine is the execution environment: it runs a frozen (deployed, non-editable) strategy with real order execution and exposes gRPC on port 50052. Platform is the API gateway: it handles authentication, billing, tier-based access control, and proxies gRPC calls from the frontends as REST.

Inter-service communication uses four mechanisms simultaneously. Redis Streams carry asynchronous event data across ten active named streams, all encoded in a dual JSON/protobuf format that allows gradual migration without breaking consumers. gRPC via the tonic 0.13 library handles synchronous service-to-service calls between Lab and Engine. REST via the axum 0.8 framework serves the human-facing API. SSE (Server-Sent Events) pushes real-time data to browser frontends without requiring WebSocket upgrades.

### Crate Inventory: Sixty-Five Building Blocks

The 65-crate workspace is organized into seven functional layers. Understanding what each crate does and why it exists as a separate compilation unit reveals the platform's design philosophy.

**Signal Infrastructure (8 crates)**

The signal infrastructure layer defines the vocabulary of the entire system. `factor-core` establishes the root `AlphaFactor` trait along with the `AlphaSignal`, `ComposedSignal`, and `FactorInput` types that every other crate depends upon. This is the critical abstraction: anything that generates a trading signal implements `AlphaFactor`, and anything that consumes it works with `AlphaSignal`. `factor-registry` is the factory layer — it maps strategy name strings to boxed trait objects, enabling runtime strategy selection without requiring compile-time knowledge of all factor implementations. It is feature-gated across three profiles: `all-factors` (the full 65-crate build), `core-factors` (a curated subset for production), and `minimal` (the smallest possible compilation for CI speed).

`pipeline` is the sequential runner that executes a list of factors in order and collects their signals. `pipeline-runner` provides the higher-level `PipelineResult` orchestration that both Lab and Engine share, preventing duplication between the research and production binaries. `composer` implements the role-based signal composition logic: the Primary signal sets the baseline direction; Confirmation signals can boost confidence by up to 1.2x if they agree; Filter signals can veto a trade entirely; Observer signals are logged for paper mode analysis but never affect live orders. `signal-store` is a thread-safe `DashMap<(factor, token), AlphaSignal>` providing lock-free concurrent read/write access to the current signal state across pipeline stages. `blackboard` generalizes this pattern as a type-erased shared state store using `DashMap<String, Box<dyn Any>>`, allowing arbitrary data to pass between pipeline stages without tight coupling. `decision-trace` provides complete per-trade audit trails, capturing the full chain from individual factor signals through composition through risk gating through final execution — a critical feature for understanding and debugging strategy behavior after the fact.

**Digital Signal Processing (4 crates)**

The DSP layer is where raw market data is transformed into statistically meaningful signals. `dsp-filters` is the most algorithmically dense crate in the platform, with 89 tests. It implements an H-infinity filter with a four-state model tracking position, velocity, acceleration, and jerk simultaneously, with innovation gating to reject outlier measurements that would corrupt the filter state. The Unscented Kalman Filter uses nalgebra's Cholesky decomposition to compute sigma points, providing better nonlinear state estimation than the Extended Kalman Filter's first-order linearization. The particle filter uses importance resampling, maintaining a population of hypotheses about the true market state and resampling according to likelihood. The Morlet wavelet Continuous Wavelet Transform operates across 20 log-spaced scales, providing time-frequency decomposition that reveals periodicities at different timescales simultaneously. The Hilbert transform is computed via FFT to produce the analytic signal, enabling instantaneous amplitude and phase extraction from price series. Mellin, Fourier, EWMA, and rolling statistics complete the toolkit.

`market-detectors` applies these signal processing primitives to market microstructure detection, with 49 tests covering a whale detector, cluster detector, Order Flow Imbalance calculator, swap pressure monitor, spectral event detector, and reversal monitor. `signal-generator` provides the `HierarchicalSignalGenerator`, which orchestrates these detectors into regime-aware, confidence-scored composite signals with 50 tests validating its output. `signal-core` serves as a facade re-exporting all three crates, giving downstream consumers a single import point.

**Prediction and Autotune (1 crate, 51 tests)**

The `prediction` crate implements some of the most mathematically sophisticated components in the platform. The Interacting Multiple Model (IMM) filter maintains three simultaneous Kalman filter instances in parallel — one configured for trending markets with a higher velocity model, one for ranging markets with mean-reversion dynamics, and one for volatile markets with wider process noise — and maintains a probability distribution over which regime is currently active. At each timestep, the IMM blends the outputs of all three filters weighted by their regime probabilities, updating those probabilities based on measurement likelihood. This produces a single estimate that gracefully transitions between regimes without the hard switching artifacts of threshold-based approaches.

The Rao-Blackwellized Particle Filter extends this by maintaining a population of particles where each particle carries its own Kalman filter branch plus a regime label. This hybrid approach uses the particle filter to handle the discrete regime variable (which cannot be analytically integrated) while using exact Kalman filtering for the continuous state conditioned on each particle's regime hypothesis. The stochastic-volatility dual Kalman filter couples a price state equation with a log-volatility state equation, jointly estimating price level and volatility dynamics in a single filtering pass.

The expert aggregator implements the Hedge algorithm with multiplicative weight updates — a classical online learning method that combines multiple prediction sources by maintaining and updating relative weights based on each expert's recent accuracy. Conformal prediction wraps any of these estimators to produce statistically valid prediction intervals with guaranteed coverage: the rolling calibration procedure ensures that 95% coverage intervals truly contain the true value 95% of the time on held-out data. The Nelder-Mead simplex optimizer provides derivative-free parameter optimization for autotune, essential for filter parameters that have no analytical gradient.

**Factor Implementations (24 crates)**

Twenty-four distinct `AlphaFactor` implementations span crypto, traditional, and prediction market domains. `factor-swap-momentum` applies a Kalman filter to swap momentum signals to reduce noise before thresholding. `factor-price-trend` implements EMA deviation as a trend signal. `factor-order-flow` normalizes OFI values and applies asymmetric thresholds at ±0.5 (weak signal) and ±2.0 (strong signal). `factor-cluster-activity` combines a coordination score with volume to detect coordinated on-chain activity. `factor-depth-quality` scores order book depth and uses slippage as a filter/veto signal — if the market is too illiquid to execute at acceptable slippage, the signal is overridden. `factor-enhanced` cascades three H-infinity filters to progressively refine the signal while incorporating microstructure data.

`factor-hawkes` models self-exciting market events using the Hawkes process formulation: the intensity function λ(t) = μ + Σ α·exp(-β·Δt) captures the empirically observed clustering of large price moves, where each significant event increases the probability of subsequent events with exponential decay. `factor-amm-state` detects LP repositioning events and measures liquidity density around the current price in AMM pools. `factor-regime` classifies the current market cycle state.

`factor-ai` is particularly notable: it implements a Deep Q-Network (DQN) with an experience replay buffer and epsilon-greedy exploration, maintaining an ensemble of three agents specialized for trend-following, mean-reversion, and risk management respectively. The ensemble's combined output is the factor signal, allowing the system to adapt its emphasis between these three behavioral archetypes based on recent experience.

`factor-whale-flow` tracks exchange inflow/outflow with time decay to build a net consensus signal about institutional positioning. `factor-smart-money` maintains an accumulator of tracked wallet positions to synthesize a smart-money consensus. `factor-consensus` provides privacy-preserving community signal aggregation. The traditional markets factors cover `factor-equity` (momentum, mean-reversion, pairs trading, sector rotation), `factor-options` (volatility surface shape, skew, gamma scalping signals, calendar spread), `factor-forex` (carry factor), and `factor-social` (aggregating sentiment from Twitter, Discord, and Telegram). `factor-polymarket` is dedicated to prediction market signals.

**Quant Core (3 crates, 77 tests)**

`quant-core` provides the mathematical toolkit that factor implementations and risk management draw upon. Black-Scholes option pricing with full Greeks (delta, gamma, vega, theta, rho) supports the options factor and risk aggregation. Monte Carlo simulation uses three variance reduction techniques simultaneously: importance sampling to concentrate simulation effort in the tails, antithetic variates to enforce negative correlation between paired simulations, and Geometric Brownian Motion path generation. The copula library supports Gaussian, Student-t, and Clayton families, enabling joint distribution modeling of correlated assets for portfolio construction. LMSR market scoring provides a reference implementation for prediction market fair value. Markowitz Mean-Variance Optimization is implemented twice: analytically via Lagrangian multipliers when the closed-form solution is available, and via projected gradient descent using nalgebra's DMatrix for constrained optimization under inequality constraints. GARCH(1,1) is estimated via grid search maximum likelihood over the alpha and beta parameter space. The Hurst exponent is computed via R/S analysis to distinguish trending from mean-reverting time series. The ADF test provides unit root detection. K-means clustering segments assets or time periods. Kelly criterion computes optimal position sizing given edge and variance estimates.

`amm-math` implements UniswapV3-style tick mathematics: the precise fixed-point arithmetic for computing slippage, price impact, and fee models in concentrated liquidity AMMs. `backtest-engine` provides the simulation infrastructure: `BacktestRunner` executes strategies against historical data, `ParameterOptimizer` runs grid and random search over the strategy parameter space, `WalkForwardAnalyzer` implements walk-forward validation to detect overfitting, and `MonteCarloSimulator` generates alternative historical scenarios for robustness testing.

**Execution Stack (5 crates)**

The execution layer is built as a trait-based pipeline of composable stages. `execution` defines the core abstractions: `OrderSizer` computes position sizes, `SlippageEstimator` projects execution cost, `ProfitabilityFilter` gates orders that cannot achieve positive expected value after costs, `ExecutionBackend` dispatches to the appropriate venue, and `PostTradeValidator` confirms the execution matched expectations. `exec-paper` implements a paper trading backend with three slippage models: Fixed (constant percentage), Linear (proportional to size), and AmmSim (simulates AMM price impact). `exec-alpaca` connects to Alpaca's REST and WebSocket API for both paper and live US equity trading. `exec-ib` provides an Interactive Brokers TWS adapter for direct market access. `exec-options` handles multi-leg options strategies through a `LegExecutor` trait, `OptionsRouter` for venue selection, and `ExerciseManager` for expiry handling.

**Risk and Portfolio (6 crates, 36 tests)**

`risk` implements the `RiskManager`, which enforces a multi-layer safety model. A confidence gate rejects signals below a minimum confidence threshold. Per-asset-class position limits prevent over-concentration. A drawdown circuit breaker using an `AtomicBool` (for lock-free access from multiple threads) halts trading when cumulative drawdown exceeds a threshold. A rate limiter prevents order flooding. Adaptive sizing scales position sizes based on current market conditions. VaR and CVaR are computed both parametrically (assuming normality) and historically (empirical distribution of returns), with the more conservative estimate used for gating. Sharpe ratio tracking and options Greeks aggregation complete the risk reporting.

`portfolio` implements `GlobalStance` — a four-level regime that shifts the entire portfolio's risk appetite: Aggressive, Normal, Defensive, and Emergency. Kelly sizing is applied with stance-dependent multipliers. `portfolio-orchestrator` provides higher-level portfolio management: `CorrelationMonitor` tracks cross-asset correlation to detect diversification erosion, `HeatManager` implements circuit breakers based on portfolio-level metrics, and `PositionAggregator` maintains a consolidated view of all positions. `rebalance` computes drift from target allocations and generates trade plans to restore them. `positions` is the in-memory lifecycle store tracking position state and metrics. `attribution` attributes P&L to specific factors, enabling ongoing evaluation of which signals are adding value.

**Multi-Chain and On-Chain (4 crates)**

`chain-adapter` defines the `ChainAdapter` trait and a `ChainRegistry` for runtime chain selection. `evm-adapter` provides implementations for Ethereum, Base, Arbitrum, and Polygon. `onchain-intel` is the intelligence layer: `SmartMoneyTracker` monitors wallets identified as sophisticated, `WhaleTracker` monitors large-balance addresses, `WalletClusterDetector` identifies groups of coordinated wallets, and `TokenFlowAnalyzer` tracks net token movement to measure accumulation and distribution. `mev-strategies` defines a `MevStrategy` trait with implementations for arbitrage, just-in-time liquidity provision, liquidation, and sandwich detection.

**Infrastructure (10 crates)**

`proto` contains prost/tonic generated Rust types from six protobuf packages. `artifact` handles the strategy artifact domain: converting between TOML configuration and protobuf binary formats, building artifacts via `ArtifactBuilder`, and validating them before deployment. `data-source` defines `DataSourceAdapter` and `EventBus` traits with `RedisEventBus` as the concrete implementation. `db` provides SQLx PostgreSQL repository implementations. `event-store` is an append-only JSONL event log for immutable audit history. `correlation` computes pairwise factor correlations via FFT using the rustfft crate — significantly faster than naive O(n²) correlation computation for large factor sets. `universe` maintains the token profile registry and its lifecycle. `tenant` enforces tier-based resource limits across four tiers: Free, Level1, Level2, and ProMax. `copilot` is the LLM-assisted component: a factor advisor, risk explainer, and strategy generator that uses a language model to interpret quantitative outputs in natural language. `factor-sdk` and `factor-wasm` provide a WASM plugin system with a `kokoro_factor!` procedural macro, allowing external factor implementations to be loaded at runtime without recompiling the core binary.

### Scale and Engineering Significance

The platform's metrics are worth stating plainly: 65 Rust crates, 242,466 lines of Rust code, 1,074 tests, 24 `AlphaFactor` implementations, 21 public async traits, 10 Redis Streams with dual encoding, 3 application binaries, and feature-gated compilation profiles spanning from minimal to full. This is not a prototype or a research notebook — it is a production trading system with a software architecture that could support a team of engineers without significant refactoring.

---

## 2. Kokoro MM

**Repository**: `happykokoro/kokoro-mm` (private)
**Language**: Rust + TypeScript | **Rust LOC**: 62,641 (126,873 including tests) | **Frontend LOC**: ~80,000 TS
**Tests**: 690 (Rust) + frontend Vitest suite
**Status**: Production — deployed at https://mm.happykokoro.com, AWS Ireland

### Purpose and Market Context

Kokoro MM is a Polymarket Automated Market Maker SaaS platform. Polymarket operates binary option prediction markets on crypto price outcomes — whether BTC will be above or below a target price at the close of a 5-minute, 15-minute, or 4-hour round. For each such round, there exists a Central Limit Order Book (CLOB) where traders post and fill bids and asks on outcome tokens.

Market makers on Polymarket play the same role they do in traditional markets: they provide continuous two-sided liquidity by simultaneously quoting bids and asks, profiting from the spread while bearing inventory risk. The mechanics are crypto-native: users must mint CTF (Conditional Token Framework) token pairs on-chain by calling the `splitPosition` function, depositing USDC as collateral and receiving equal quantities of YES and NO tokens. After a round resolves, the winning token redeems 1:1 for USDC and the losing token expires worthless. Kokoro MM automates this entire lifecycle — from token minting through quote generation through order management through post-resolution redemption — and provides it as a tiered SaaS, from free manual minting up to fully autonomous AUTOPILOT mode.

### Architecture: Single-Binary MVP

The core architectural decision for Kokoro MM was to ship a production-quality single binary rather than a microservice architecture. The Gateway, Engine, and DataHub run as separate modules within a single tokio process, communicating via direct function calls rather than network hops. The main binary (`mm-bin/main.rs`, 408 lines) initializes all services and wires their shared state. gRPC between services — deferred to Phase 8 — would add latency and operational complexity without benefit at current scale. This is a deliberate pragmatism: build the right abstractions (the module boundaries exist and are clean), deploy as a monolith until the operational need for distribution is demonstrated.

The three major service modules are `mm-gateway` (Axum HTTP server on port 4000 with 69 routes across 24 modules), `mm-engine` (the core quoting pipeline and order management system), and `mm-datahub` (data adapters for Pyth price oracle, Binance WebSocket, and Polymarket CLOB WebSocket, plus the SSE broadcast infrastructure).

### Crate Architecture: Eighteen Crates in Four Layers

The crate layering provides compile-time enforcement of dependency direction. L0 contains pure domain primitives that nothing else in the system constrains. L1 builds domain logic on top of L0 types. L2 adds infrastructure implementations. L3 assembles everything into runnable services.

**L0 — Domain Primitives**

`mm-types` is the bedrock: it defines every significant domain concept — `Round` (a prediction market round with its lifecycle state), `Order` (a limit order in the CLOB), `Fill` (an executed trade), `Strategy` (a named set of quoting parameters), `MintOp` (a pending on-chain mint operation), `BookDiff` (an incremental order book update), and `ResistanceLevel` (a detected price level of significant order concentration). Centralizing all types here prevents the circular dependency problems that plague larger systems where types are defined alongside logic. `mm-proto` provides the API contract types that form the serialization boundary between the service and its clients. `mm-traits` defines five async traits — `MarketProvider`, `MmStrategy`, `OrderProvider`, `DataSource`, and `NewsProvider` — establishing the interfaces that all implementations must satisfy.

**L1 — Domain Logic**

`mm-market` implements the round lifecycle state machine: a round progresses through Discovered, OrdersOpen, Active, Settling, and Settled states, with transitions governed by time and on-chain events. It also implements a multi-venue router supporting Polymarket, Kalshi, and Manifold simultaneously, and includes an arbitrage scanner to detect mispricing across venues. `mm-minting` orchestrates the CTF `splitPosition` and `mergePositions` contract calls, including balance checks to prevent failed transactions from wasting gas. `mm-order` manages the full order lifecycle in both paper and live modes, tracking fills and maintaining per-round position accounting. `mm-strategy` is the signal composition layer: `SpreadAdjustmentComposer` combines multiple adjustment signals into a final spread parameter, `SignalClient` interfaces with the external signal feed, `RegimeWeights` applies different strategy emphases based on market regime, `CopyTraderAsConfig` converts copy-trading signals into strategy parameters, and `conformal_bounds` applies conformal prediction to strategy signals for calibrated uncertainty intervals.

`mm-data` provides order book manipulation utilities: `apply_diff` incrementally updates a book snapshot from a stream of diffs, `mid/spread/VWAP` compute standard book metrics, and order book imbalance and resistance level detection give the quoting engine insight into near-term price dynamics. `mm-identity` handles all security-sensitive operations: JWT generation and validation, Argon2 password hashing, TOTP two-factor authentication per RFC 6238, API key management, tier-based feature gating, and wallet encryption using AES-256-GCM with per-user key derivation via HKDF-SHA256. The HKDF derivation is notable: rather than sharing one encryption key across all users' stored wallets, each user gets a key derived from both a server secret and their user identifier, limiting the blast radius of a key compromise.

**L2 — Infrastructure**

`mm-polymarket` is a complete Polymarket SDK: it implements the full CLOB REST API plus WebSocket subscription, handles EIP-712 and HMAC authentication, performs order signing using the alloy crate, integrates with the Gamma metadata API, implements fill detection, and wraps the external Polymarket API behind an ACL (Anti-Corruption Layer) to prevent Polymarket's data model from leaking into the domain layer. `mm-polygon` is the on-chain interaction layer: it calls `splitPosition`, `mergePositions`, and `redeem` on the CTF contract, manages USDC and CTF-1155 token approvals, estimates gas before submission, and handles the neg-risk adapter that Polymarket uses for complementary YES/NO token pairs. `mm-db` provides SQLx-based PostgreSQL access with 21 query modules and 58 migration pairs. `mm-redis` provides Redis pub/sub, streams, and the SSE event bus.

**L3 — Services**

`mm-engine` is the central piece. Its quoting pipeline consists of six sequential stages: `FairValueEstimator` produces a calibrated price belief, `SpreadCalculator` determines the appropriate bid-ask spread, `InventoryTracker` monitors the current YES/NO token inventory imbalance, `QuoteGenerator` produces actual bid and ask prices, `AdverseSelectionDetector` monitors fill patterns for signs of informed trading, and `CancellationWave` executes batch order cancellations when adverse selection is detected. On top of this pipeline sits the order manager (tracking the full lifecycle of every order placed), the lifecycle controller (orchestrating round start/end transitions), four named strategies, a risk module computing VaR and CVaR via historical simulation, a backtest harness, the AUTOPILOT mode with five sequential risk gates, and external signal integration.

`mm-datahub` aggregates price data from Pyth, Binance, and Polymarket CLOB, broadcasts updates to connected clients via SSE, evaluates alert conditions, and processes webhooks. `mm-gateway` is the Axum HTTP server with JWT and API-key authentication middleware, tier enforcement middleware, per-endpoint rate limiting, and Prometheus metrics emission.

### Market Making Algorithms

The quoting logic is grounded in established academic market microstructure theory, adapted for the specifics of Polymarket's binary rounds.

The **Avellaneda-Stoikov model** is the mathematical foundation. It models the market maker's optimization problem: choose bid and ask quotes to maximize expected utility while managing inventory risk. The key insight is that a market maker with a net long inventory in YES tokens should shift their quotes downward (lower bid and ask) to reduce further buying and encourage selling that reduces their inventory. In the implementation, an EWMA volatility estimate with a configurable lambda provides the volatility input; inventory skew is computed proportionally to net exposure and shifts the reservation price; an adverse selection premium is added to the base spread to compensate for the risk of trading against informed counterparties. All components are logged separately, providing full telemetry decomposition of every quoted spread.

**Fair Value Estimation** fuses three independent price signals. The CLOB mid-price reflects the current market consensus on Polymarket. The Binance spot price for the underlying crypto asset provides an external anchor. The candle VWAP provides a time-weighted average that smooths short-term noise. Each source is weighted by a freshness decay factor (older observations receive exponentially less weight) and a confidence score based on data availability and recent accuracy. The fused estimate is EMA-filtered to smooth inter-update noise, and velocity (price change per second) plus an uncertainty measure are tracked alongside the price estimate itself.

The four named strategies operationalize different market making philosophies. `SymmetricSpread` is the pure Avellaneda-Stoikov baseline: symmetric quotes around the fair value with inventory-adjusted spread. `SignalSkewed` incorporates external directional signals: a bullish signal shifts the mid-price upward, resulting in a tighter ask (better price for buyers) and wider bid (worse price for sellers), allowing the market maker to accumulate YES tokens when they expect upward moves. `LadderedBreakout` places tiered sell orders on both sides of the book; when a fill is detected at a breakout level, it cancels orders on the opposite side and places a stop-loss — a directional strategy dressed as market making. `Manual` gives users direct control over all parameters without algorithmic intervention.

The **Adverse Selection Detection** module (`mm-engine/quoting/adverse_selection.rs`, 365 lines) solves one of the core challenges in market making: distinguishing uninformed flow (retail traders acting on noise, providing spread income) from informed flow (traders who know something the market maker doesn't, creating inventory losses that exceed spread income). It monitors fill patterns — the sequence, direction, and timing of trades — and computes a running toxicity score. When the score crosses a threshold, it triggers a `CancellationWave`, pulling all quotes from the book until the situation clarifies.

### API Surface (69 Routes)

The 69-route API spans several access tiers. Public endpoints handle health, versioning, Prometheus metrics, and authentication (registration, login, token refresh, password reset). JWT-protected endpoints provide order CRUD, mint/merge operations, strategy management, billing information, and P&L reporting. Tier-gated endpoints control wallet management, strategy configuration, instance lifecycle (start/stop), and escrow operations. A dedicated signal tier exposes active strategy signals. Billing endpoints interface with Stripe for checkout sessions and webhooks. Marketplace endpoints handle strategy listing, subscription, and leaderboard rankings at weekly and monthly granularity. Data endpoints provide access to rounds, tick history, order books, trades, signals, and backtests. Phase 8 stub endpoints are already defined for strike management, multi-venue trading, arbitrage scanning, FIX protocol, and WASM strategy plugins — capturing the intended future API surface before implementation.

### Frontend (36 Pages)

The Next.js 16 frontend uses React 19, Tailwind v4, Zustand 5 for state management, SWR 2 for data fetching, and Radix UI for accessible component primitives. Charting uses lightweight-charts v5 for the performance-critical price and P&L displays, recharts v3 for analytics, and `@xyflow/react` v12 (React Flow) for the strategy builder canvas. The canvas is a particular engineering achievement: it allows users to visually compose strategy logic by connecting nodes in a directed graph, with the result serialized to the strategy configuration format. Key pages include the P&L dashboard with real-time charting, the markets browser for round discovery, the CTF minting wizard that walks users through the on-chain token creation process, the order management interface, the live tick stream with resistance level overlays, analytics, billing, leaderboard, and an onboarding wizard.

### MCP Tools (17)

Seventeen MCP tools expose Kokoro MM's capabilities to AI-assisted workflows. Six strategy tools manage strategy creation and configuration. Three market tools provide round and book data. Two order tools handle order submission and status. Two status tools report service and engine health. Four copilot tools — `explain_round`, `suggest_spread`, `check_inventory`, and `optimize` — provide natural language interfaces for interpreting market conditions and getting tuning recommendations.

---

## 3. Kokoro Polymarket Bot

**Repository**: `happykokoro/kokoro-polymarket-bot` (private)
**Language**: Rust + Python | **Rust LOC**: 15,491 | **Python LOC**: ~1,470
**Tests**: 72
**Status**: Stopped — strategy replacement required

### Purpose and Architecture

The Polymarket Bot is a multi-strategy directional trading system for Polymarket prediction markets, distinct from Kokoro MM's market-making approach. Where MM profits from the spread by providing liquidity to both sides, the Bot takes directional positions, betting on specific outcome probabilities. It runs 8 parallel pipelines within a single Rust binary, each implementing a different quantitative strategy profile but sharing one DataHub that aggregates Binance spot WebSocket, Binance futures WebSocket, Polymarket CLOB WebSocket, and Deribit data.

The codebase is organized into seven crates, each with a clear responsibility. `scanner` discovers tradable markets: it identifies BTC, ETH, SOL, and XRP rounds across 5-minute, 15-minute, and 1-hour timeframes, pulling data from Binance and Pyth feeds. `data` provides the pluggable adapter system: `TickAdapter` and `RestAdapter` traits with a `DataHub` orchestrator that coordinates them, a candle builder that converts tick streams into OHLCV bars, and a watchdog mechanism that reconnects dropped WebSocket connections. `data-hub` is a separate binary providing the candle store, round tracker, and multi-timeframe intelligence aggregation. `risk` implements composable risk gating: `RiskGateChain` sequences multiple gates so any veto stops the order, Kelly sizing computes optimal position sizes, VaR at 95% confidence is computed from recent P&L history, and named gates (MinEdge, MaxExposure, Drawdown, PositionCount, Volatility) apply thresholds with configured limits. Per-asset multipliers — SOL at 1.4x and ETH at 0.9x — encode empirical observations about each asset's typical edge characteristics. `executor` handles the order submission details: EIP-712 and HMAC-SHA256 order signing required by Polymarket's API, CLOB order submission, and routing between paper and live execution backends. `api` provides a REST and WebSocket server on port 4200 using axum, SQLite persistence for position tracking, and a backtesting endpoint. `bot` is the main binary: the 8-pipeline orchestrator, four quant modules, three strategy tiers, bilateral market making logic, and timeframe intelligence integration.

### Quantitative Algorithms

The quantitative sophistication of the Bot's strategy implementations reflects serious engagement with market microstructure research.

**GARCH(1,1)** models time-varying volatility — the empirically observed tendency of volatility to cluster. The (1,1) specification models tomorrow's variance as a weighted combination of yesterday's squared return and yesterday's variance estimate, with weights alpha and beta constrained to sum below 1.0 to ensure stationarity. The grid search MLE estimation sweeps alpha ∈ [0.015, 0.300] and beta ∈ [0.025, 1.0] to find parameters that maximize the log-likelihood of the observed return sequence, then uses the fitted model to generate n-step-ahead variance forecasts.

**Hurst Exponent** analysis via Rescaled Range (R/S) distinguishes three market regimes. An exponent near 0.5 indicates a random walk where past returns carry no predictive information. An exponent above 0.5 (say, 0.65-0.80) indicates persistence — recent trends are likely to continue. An exponent below 0.5 indicates anti-persistence — recent moves are likely to reverse. The computation divides the time series into segments of varying lengths n, computes the ratio of the range to the standard deviation (R/S) for each length, then fits log(R/S) = H·log(n) + constant via OLS regression. The slope H is the Hurst exponent.

**Jump Detection** identifies price discontinuities by computing standardized return z-scores and flagging observations where |z| > 3.0σ, signaling abnormal price movements that may indicate news events or significant order flow.

**Brownian Bridge** path conditioning is the most research-grounded technique in the bot. A Brownian Bridge conditions a stochastic process on both its start and end points, allowing the analyst to compute conditional probabilities given partial path information. The implementation uses a path conditioning table derived from Q6 research covering 11,348 historical Polymarket markets. The key empirical finding: when the parent-timeframe direction is UP and the two most recent lower-timeframe moves were both DOWN (suggesting a consolidation pullback), the probability of an UP resolution is 95% — validated at 100% historical accuracy on an 18-sample holdout set. This is not a theoretical model but an empirical regularity extracted from a large historical dataset.

The three strategy tiers implement progressively sophisticated approaches. The Rust baseline runs six static strategies with deterministic logic. The QuantCryptoComposer layer combines three profiles: GARCH-T (GARCH volatility with Student-t tail distribution for heavy tails), Hurst-Hinf (Hurst-conditioned entry with H-infinity filter for signal smoothing), and FullQuant (all modules active). The Python service layer — running as a sidecar process — provides GARCH maximum likelihood estimation via scipy, Student-t cumulative distribution function evaluation for probability transformation, PCA factor model for cross-asset signal decomposition, and wavelet decomposition for multi-scale trend extraction.

### Strategic Status

The fair-value dislocation strategy that was initially deployed failed in live trading, losing $55 in 12 minutes. Post-mortem analysis identified a structural down bias in the strategy's signal generation, and a fundamental issue with paper validation: validating on the same data distribution used to construct the fair-value model creates a tautological test that cannot detect structural bias. The 3 infra fixes (GTC order exposure in risk gates, hold-to-resolution logic, and round-ended skip for SELL orders) are implemented but uncommitted. Three issues are identified as must-implement before any future live trading: Issue #69 (Brownian Bridge path conditioning), Issue #73 (per-asset parameter profiles), and Issue #63 (dual-side architecture that treats UP and DOWN predictions as independent strategies rather than inverse positions).

---

## 4. Kokoro Liquidation Bot

**Repository**: `happykokoro/kokoro-liquidation-bot` (private)
**Language**: Rust + Solidity | **Rust LOC**: 5,130
**Tests**: 24
**Status**: Production — deployed on DigitalOcean, paper mode, port 4400

### Purpose and Economic Model

DeFi liquidation bots are among the most mechanically constrained forms of on-chain arbitrage. When a borrower's collateral value drops below the threshold required by a lending protocol's health factor formula, the protocol permits any external party to repay part of the borrower's debt in exchange for receiving the collateral at a discount (the liquidation bonus, typically 5–15%). The liquidation bot's job is to discover these opportunities before competitors, compute profitability after gas, flash loan fees, and DEX swap costs, and execute atomically.

The system targets four protocols across multiple chains: Aave V3 on Ethereum, Base, Arbitrum, Polygon, Optimism, and Avalanche via flash loan plus `liquidationCall`; Seamless Protocol on Base via the same mechanism; Compound V3 on Ethereum, Base, Arbitrum, and Polygon via the `absorb()` function (which does not require a flash loan because Compound's mechanism works differently); and Moonwell on Base via `liquidateBorrow()`.

### Architecture

The discovery pipeline proceeds in three phases. First, the indexer crate replays historical `Borrow` events from protocol contracts to build a comprehensive list of all current borrowers — approximately 270 borrowers discovered in the Ethereum deployment. Second, the evaluator crate polls health factors for each known borrower at configurable intervals, identifying which positions have dropped below the liquidation threshold. Third, the executor crate evaluates profitability for each at-risk position and, if profitable, submits the transaction.

The `FlashLiquidator.sol` contract is the on-chain component that makes flash loan liquidation possible. Its execution is atomic and requires zero upfront capital: it borrows the debt token from Aave's flash loan facility, calls `liquidationCall` on the lending protocol to repay the borrower's debt and receive the discounted collateral, swaps the collateral back to the debt token via Uniswap V3 on-chain, repays the flash loan plus fee, and pockets the difference. All of this happens in a single transaction that reverts entirely if any step fails.

The `ProtocolAdapter` trait enables runtime dispatch: each protocol (Aave V3, Seamless, Compound V3, Moonwell) is wrapped in an adapter that implements a uniform interface, registered in the adapter registry, and selected at runtime based on the position's protocol field. `Arc<dyn ProtocolAdapter>` provides thread-safe shared access. The same pattern applies to the `LiquidationExecutor` trait: `FlashLoanExecutor` handles the flash-loan-based liquidation flow, `CompoundAbsorbExecutor` handles Compound's native `absorb()` call, and `PaperExecutor` simulates execution without submitting transactions, enabling paper mode testing with real market data.

The shared state is a `DashMap<Address, LendingPosition>` — a lock-free concurrent hash map from the dashmap crate — populated by the indexer and read simultaneously by the poller, evaluator, and API without requiring mutex locks. This is a meaningful performance consideration: a traditional `Mutex<HashMap<>>` would serialize all access, creating contention when discovery is running concurrently with health factor polling.

Risk management operates at two levels. The per-transaction minimum profit threshold filters out positions where the liquidation bonus, after gas costs and DEX slippage, doesn't exceed a configured floor. Per-transaction and daily gas budgets prevent runaway spending during periods of high gas prices. The circuit breaker triggers after N consecutive revert transactions — indicating something is systematically wrong, such as a competing bot front-running every submission — and pauses execution until manually reviewed.

Close factor logic adapts to position health: for Aave V3, when the health factor is above 0.95 (the position is slightly undercollateralized), only 50% of the debt can be repaid in a single liquidation; below 0.95, the full 100% can be liquidated. For Compound, 100% is always allowed. This boundary affects the profitability calculation and must be correctly modeled to avoid submitting transactions with unexpected close amounts.

### REST API

The API on port 4300/4400 exposes nine endpoints: `GET /health` for service status; `GET /api/positions` for all monitored borrower positions; `GET /api/positions/at-risk` filtered to positions below the health factor threshold; `GET /api/opportunities` for positions that would currently be profitable to liquidate; `GET /api/config` for the current configuration; `GET /api/history` for past execution attempts; `GET /api/pnl` for cumulative P&L; `GET /api/chains` for per-chain adapter status; and a WebSocket at `/ws` for real-time position updates. Six frontend pages and 13 API proxy routes provide a monitoring dashboard.

---

## 5. Kokoro Protocol

**Repository**: `happykokoro/kokoro-protocol` (private)
**Language**: Rust (Anchor 0.30.1) + TypeScript (test suite)
**Status**: Development — localnet and devnet

### Purpose and Scope

Kokoro Protocol is an on-chain DeFi platform built on Solana using the Anchor 0.30.1 framework. It spans 20 programs across five categories: infrastructure, DeFi, gaming, prediction markets, and NFTs. The scope is deliberately comprehensive — rather than building a single-purpose protocol, the design intent is a unified financial platform where users can interact with all components under a single account and identity.

### Infrastructure Programs (6)

`platform_treasury` manages protocol-level funds. `platform_token` implements a chip mint/redeem system, likely providing an intermediate token for cross-program accounting. `user_vault` provides each user with a personal on-chain vault for secure fund management. `house_pool` implements LP deposit mechanics with a circuit breaker and automatic rebalancing strategy, functioning as the protocol's liquidity foundation. `reward_pool` manages rakeback calculations, referral commissions, and tier-based rewards, providing the incentive layer that drives user retention. `governance` implements on-chain governance with proposal creation, token-weighted voting, and on-chain execution of approved proposals.

### DeFi Programs (5)

`dex_amm` is a constant-product AMM supporting pool creation, liquidity addition and removal, and token swapping with the standard x\*y=k invariant. `lending_protocol` is a full lending market: it supports pool creation, asset supply, borrowing, repayment, liquidation, and interest rate updates. `yield_vaults` implements ERC-4626-style yield strategies on Solana: users deposit assets, the vault deploys them according to a configurable strategy, and users can withdraw plus accrued yield. `liquidation_engine` is the on-chain liquidation orchestration layer: it performs health checks, orchestrates loan liquidations and leverage position liquidations, and implements Dutch auction mechanics for collateral disposal. `leveraged_betting` allows users to open leveraged positions on prediction outcomes, with margin management (open, add, close), forced liquidation for undercollateralized positions, and integration with the `liquidation_engine`.

### Gaming and Casino Programs (7)

Seven programs implement casino and gaming mechanics. `game_dice` is a basic over/under dice game with bet placement, random resolution, and cancellation. `game_crash` is a multiplier crash game: rounds are created, players place bets, they can cash out before the multiplier crashes, and the round resolves at a pseudo-random crash point. `game_coinflip` provides a binary 50/50 wager. `game_slots` implements a slot machine with spin, resolve, and initialization. `game_sports` is the most complex gaming program: it supports event creation with initial odds, real-time odds updates, bet placement, event settlement, and bet cancellation. `game_d20` implements a PvP battle mechanic with a 20-sided die. `game_escrow` provides a general PvP escrow: two parties create and join a game, and the outcome triggers settlement via the escrow; a force-refund mechanism handles abandoned games.

### Prediction Market (1)

`prediction_market` provides on-chain prediction market mechanics: market creation with outcome definitions, binary share buying and selling, market resolution by an authorized resolver, and winning share redemption for USDC.

### NFT (1)

`nft_auction` implements English-style auctions for NFTs: creation with reserve price, competitive bidding, settlement to the highest bidder, and cancellation if the reserve is not met.

---

## 6. Kokoro Alpha Lab Frontend

**Repository**: `happykokoro/kokoro-alpha-lab-frontend` (private)
**Language**: TypeScript (Next.js 15, React 19)
**Status**: Production

### Scale and Organization

The frontend for Kokoro Alpha Lab is a 107-route Next.js 15 application providing a complete trading research and execution interface. The route count alone signals the breadth of the backend it exposes. Routes are organized into six major sections.

The **Lab** section covers the full research workflow: backtesting (with sub-routes for jobs, replay, results, and scenario analysis), a visual strategy composition canvas, signal inspection, factor analysis, custom factor development, filter state monitoring, correlation analysis, consensus signals, the AI copilot interface, prediction model results, portfolio rebalancing, strategy comparison, workspace management, microstructure analysis, market data, metrics, event streams, execution traces, universe management, audit logs, transparency reports, quantitative tools, and traditional finance views (equities, options, Greeks, risk).

The **Engine** section mirrors the live execution environment: live positions, execution history, engine metrics, MEV opportunity tracking, control panel, P&L attribution, safety status, service health, wallet management, and Polymarket position monitoring.

The **Market** section provides broad market data coverage: crypto spot, stocks, forex, indices, bonds, ETFs, commodities, crypto futures, crypto options, macro indicators, technicals, market movers, news feed, NFT market data, economic calendar, cross-market metrics, and on-chain intelligence.

The **Polymarket** section serves the prediction market workflows: market browser, bot instance management, risk dashboard, simulation interface, copula correlation analysis, arbitrage scanner, order depth visualization, data hub inspection, filter calibration, particle filter visualization, formula reference, and agent simulation.

The **Liquidation** section provides the monitoring interface for the Liquidation Bot: position browser, opportunity identification, configuration, execution history, and P&L.

The **Marketplace** section enables strategy sharing: listings browser, leaderboard, personal strategy management, and strategy publishing.

The charting infrastructure uses five libraries depending on use case: lightweight-charts v5 for the most performance-sensitive real-time price displays, recharts for composable chart components, chart.js for canvas-based rendering, plotly.js for statistical and scientific visualizations, and d3 for custom data visualizations. Real-time data is delivered via SSE with exponential backoff reconnection — a deliberate choice over WebSockets that simplifies server state management while providing adequate latency for research-oriented displays.

---

## 7. Kokoro Staking

**Repository**: `happykokoro/kokoro-staking` (private)
**Language**: Go 1.26 + TypeScript (Next.js 16 frontend)
**Status**: Plan/Development

### Purpose

Kokoro Staking is a multi-chain validator staking aggregator supporting 17 blockchain networks. The platform abstracts the significant protocol-specific complexity of staking — each chain has different validator selection mechanics, slashing conditions, unbonding periods, and reward claim procedures — behind a unified interface.

### Supported Chains

The 17 supported chains span the major proof-of-stake ecosystems. Ethereum (with EigenLayer restaking for additional yield layers), Solana (with Jito restaking), Cosmos, Avalanche, BNB Chain, Polkadot (Nominated PoS where nominators stake behind validators), Near, Cardano, Aptos, Sui, Tron, Tezos (Liquid Proof of Stake), Osmosis (LP incentives integrated with staking), Celestia, Injective, Sei, and MultiversX.

### Architecture

The architecture makes two important design choices that reflect Go idioms and financial software best practices. Interface segregation means that each chain adapter only implements the capabilities it actually supports: `StakingReader` for querying staking state, `TxBuilder` for constructing unsigned transactions, and `HealthChecker` for monitoring validator and node health. A chain that supports reading but not programmatic transaction building simply does not implement `TxBuilder`. This is cleaner than forcing every adapter to implement a full interface and returning errors for unsupported operations.

Client-side signing is a security-critical design choice: the backend builds unsigned transactions and returns them to the frontend, which signs them locally in the user's wallet. The server never has access to private keys, eliminating the most severe category of custody risk. The `shopspring/decimal` library provides arbitrary-precision decimal arithmetic throughout — essential for staking reward calculations where floating-point rounding errors could silently misrepresent positions. The `errgroup` package handles cross-chain queries with partial-failure tolerance: if three chains respond and two fail, the successful results are returned rather than returning a failure for the entire request. Prometheus metrics instrument every RPC call, providing observability into chain connectivity and latency. The module structure (adapter, api, auth, billing, cache, config, eventbus, model, portfolio, store, worker, services/mcp) reflects the standard Go project layout with clear separation between domain and infrastructure layers. A decorator layer uniformly applies circuit breaking, rate limiting, caching, and metrics to all chain adapters without modifying their core logic.

---

## 8. Lab MCP

**Repository**: Part of the `happykokoro/kokoro-alpha-lab` ecosystem
**Language**: TypeScript
**Status**: Production — 98 tools across 13 files

### Purpose and Significance

The Lab MCP (Model Context Protocol) server exposes the entire Kokoro Alpha Lab platform as a structured set of tools callable by AI assistants. This is a deliberate architectural choice to make the trading research platform AI-native: rather than requiring a human to navigate 107 frontend pages to check signals, analyze factors, and inspect risk, an AI agent can invoke the appropriate tool directly.

### Tool Inventory (98 Tools)

The 98 tools are organized into 13 categories. Core Lab provides 36 tools covering signals, predictions, backtesting, positions, candles, factor analysis, metrics, execution traces, filter state inspection, and equity curve retrieval — the full research workflow accessible programmatically. Quant Tools provides 8 tools: GBM simulation, Black-Scholes pricing, option pricing, Markowitz optimization, efficient frontier generation, Brier score computation, copula fitting, and Student-t distribution fitting. Engine tools (7) manage bot deployment and inspection: deploy and stop bots, check bot status, inspect cluster health, retrieve positions and trade history. Backtest Jobs (7) provide a complete job management interface: submit, list, retrieve, cancel, optimize, walk-forward validation, Monte Carlo simulation, and scenario analysis. Alerts (7) manage notification channels: CRUD operations, test delivery, history inspection, and preference management. Admin (6) exposes privileged operations: list users, change tier assignments, kill misbehaving bots, inspect system health, and audit log retrieval. Polymarket (7) covers prediction market operations: market discovery, position details, quote retrieval, simulation, copula analysis, and arbitrage scanning. Data Sources (5) manage data adapter lifecycle: list, start, stop, upload data, and check adapter status. TradFi (4) exposes traditional finance capabilities: position inspection, Greeks computation, risk metrics, and stress testing. Artifacts (4) handle strategy packaging: export, validate, load, and list. Rebalance (3) provides portfolio rebalancing utilities: drift computation, plan generation, and target management. Consensus (3) exposes the community signal layer: get, contribute, and token listing. Universe (3) provides token intelligence: aggregate statistics, profile lists, and individual profiles.

The implementation includes tier gating per tool (some tools require Level2 or ProMax tiers), service-availability guards that return informative errors when required services are offline rather than hanging, Zod schema validation for all inputs, and dual transport support (both stdio for CLI use and HTTP for server-based MCP deployment).

---

## 9. Kokoro Pipeline

**Repository**: `anescaper/kokoro-pipeline` (migrating to TypeScript)
**Language**: TypeScript (Express + React/Vite)
**Status**: Active development — Rust-to-TypeScript migration in progress

### Purpose

Kokoro Pipeline is a full-featured automated development pipeline engine that orchestrates AI agents through structured multi-phase software development workflows. It provides a React web console with a visual pipeline designer and a SaaS platform layer for multi-tenant deployment.

### Architecture

The backend is an Express API on port 5555, backed by PostgreSQL with a Prisma ORM schema of 30+ models. The React/Vite frontend runs on port 3000. The central component is the `PipelineEngine`: a six-phase orchestrator that takes a development task from specification to completion. The phases are: research (understanding the codebase and requirements), plan (generating a structured implementation plan), execute (running agents to implement the plan), audit (reviewing what was built), assemble (integrating changes), and report (summarizing what was accomplished and what remains). Each phase can be retried independently, and the pipeline supports branching on audit failures with automated fix loops.

The agent dispatcher interface abstracts over different AI backends: local AI coding agent instances, OpenAI API agents, and Gemini API agents can all be used interchangeably or in combination. The `WorktreeManager` creates isolated git worktrees for each agent, preventing concurrent modifications from conflicting and making each agent's changes reviewable as a discrete unit.

The React Flow visual designer provides 40+ node types, allowing users to design pipeline topologies graphically. Rather than hand-writing JSON pipeline configurations, users connect nodes representing research tasks, implementation phases, audit checks, and merge operations into a directed acyclic graph.

Nineteen skills codify specialized development capabilities: `design-architect` for system design, `implement-features` for code generation, `generate-tests` for test authoring, `qa-validate` for quality validation, `scaffold-project` for project bootstrapping, `production-adapt` for deploying changes to production, `contract-audit` for smart contract security review, `financial-risk-review` for risk assessment, five codebase analysis skills (ingest, map, analyze, document, evaluate, plan), `tech-lead-audit` for architectural review, `fullstack-pipeline` for end-to-end feature development, and `auto-dev-task` for autonomous task completion.

Pipeline modes address different development scenarios. Greenfield creates new projects from scratch. Incremental adds features to existing codebases. Hotfix focuses on targeted bug resolution. Reverse analyzes an existing codebase to generate documentation and a model of its structure. Reverse-then-Forward first analyzes the existing system and then plans and executes forward changes, grounding the implementation plan in the discovered reality rather than assumptions.

The SaaS layer includes multi-tenant organization support, GitHub OAuth for authentication, Stripe billing integration, a strategy marketplace, SSO via SAML/OIDC for enterprise customers, SCIM 2.0 for automated user provisioning, and audit logs for compliance.

---

## 10. Agent Orchestra

**Repository**: `anescaper/agent-orchestra`
**Language**: Python + Rust
**Status**: Production — actively used for parallel development

### Purpose

Agent Orchestra is the multi-agent orchestration platform that enables a single developer to manage parallel implementation efforts across multiple git worktrees. It was built to support the development of the Kokoro Alpha Lab monorepo, where multiple independent crates could be developed simultaneously by separate agent instances.

### Architecture

The system runs as a FastAPI server with a WebSocket dashboard providing four real-time event streams: `/ws/status` for overall system state, `/ws/logs` for agent output, `/ws/teams` for team activity, and `/ws/gm` for General Manager decisions and approval requests.

The `GeneralManager` is the central automation engine. It orchestrates a seven-phase lifecycle: launching (spawning agent subprocesses), waiting (monitoring for completion), analyzing (reviewing each agent's output for success or failure), merging (integrating agent branches into the main branch), building (compiling the result), testing (running the test suite), and completing (archiving the session). The GM pauses at an approval gate whenever it encounters merge conflicts, build failures, or test failures, broadcasting a decision card via `/ws/gm` and waiting for human input before proceeding.

The `TeamLauncher` spawns AI agent CLI subprocesses with configurable flags, including `--dangerously-skip-permissions` for fully autonomous operation. It monitors stdout for progress and auto-kills processes that emit out-of-disk (ENOSPC) or out-of-memory (OOM) error messages. Git worktree isolation gives each agent a separate branch and filesystem location, preventing concurrent write conflicts. Upon completion, each agent's worktree branch is merged back. A shared `CARGO_TARGET_DIR` across all worktrees prevents N×disk-size compilation artifacts — without this, a 6-agent Rust build would produce 6 copies of the target directory, exhausting disk rapidly. SQLite provides session persistence.

Five team templates define common collaboration patterns. `feature-dev` uses three agents in a hierarchical pattern: an architect agent designs the implementation approach, an implementer agent writes the code, and a reviewer agent audits the result. `build-fix` uses a single focused agent tasked purely with making the code compile — the empirical finding is that the three-agent architecture is overkill for compiler error resolution. `code-review`, `debug`, and `research` templates support their respective tasks. The team template selection is context-dependent: a new feature benefits from the architect/implementer/reviewer hierarchy, while a compilation failure just needs one agent reading the error messages.

---

## 11. Kokoro VPN

**Repository**: `happykokoro/kokoro-vpn` (private)
**Language**: Rust + TypeScript (Tauri v2)
**Status**: Production — 3-node mesh deployed

### Purpose

Kokoro VPN is a self-hosted WireGuard VPN platform that provides two network topologies: a hub-and-spoke client VPN for secure remote access, and a full-mesh encrypted overlay network connecting multiple server nodes. Unlike commercial VPN services, it is entirely self-hosted, giving full control over keys, policies, and audit logs.

### Architecture

Two binaries handle the two deployment roles. `kokoro-vpn-server` is the API server: it runs on port 3000, manages WireGuard key generation and configuration, handles JWT authentication, and provides sandbox guest tunnels for temporary access without full credentials. `kokoro-vpn` is the CLI management tool: it controls mesh configuration, ACL policies, health monitoring, and firewall script generation.

The client VPN uses hub-and-spoke topology on the `wg0` interface, with the 10.8.0.0/24 network and UDP port 51820. All client traffic routes through the hub node. The mesh VPN uses a separate `wg1` interface on 10.10.0.0/24 and UDP port 51821, creating direct encrypted tunnels between every pair of nodes: for N nodes, this produces N\*(N-1)/2 tunnels. The three deployed nodes occupy 10.10.0.1 (sg-main, Singapore), 10.10.0.2 (ie-poly, Ireland), and 10.10.0.3 (uk-pay, London).

The per-node firewall ACL system generates iptables and nftables scripts with a dedicated `KOKORO_MESH` chain, providing precise traffic control between mesh nodes without relying on WireGuard's built-in AllowedIPs mechanism for enforcement. This allows more expressive ACL policies (allowing specific ports between specific node pairs) than WireGuard's peer-level configuration permits. Two monitoring endpoints — `/api/mesh/health` and `/api/mesh/metrics` (in Prometheus format) — provide observability into mesh tunnel status and traffic. Terraform configurations for both DigitalOcean and AWS provide infrastructure-as-code for deploying new nodes. The desktop app uses Tauri v2 with React 19 and Tailwind v4, providing a native application experience for VPN management without requiring users to interact with the CLI.

---

## 12. Kokoro Copy Trader

**Repository**: `happykokoro/kokoro-copy-trader`
**Language**: Python 3.12
**Status**: Paper testing — deployed on AWS London, port 4500

### Purpose and Strategy

The Copy Trader implements a simple but empirically grounded strategy: identify Polymarket traders with demonstrated positive performance and mirror their positions. The hypothesis is that some traders possess persistent edge — better information, superior calibration, or systematic research — that makes their positions worth following. Rather than developing an independent predictive signal, the Copy Trader parasitically benefits from others' edge.

### Architecture

Discovery uses configurable filters: a trader must have a win rate of at least 55%, a minimum of 20 completed trades for statistical significance, and at least $50 in net profit to filter out lucky beginners. `monitor.py` polls Polymarket's API at 30-second intervals to detect when tracked traders open new positions. `copier.py` executes GTC (Good Till Cancelled) limit buy orders when a position is detected and holds through to resolution — avoiding the temptation to exit early and thereby capturing the full edge of the original trader's conviction. The `polymarket/` module provides clients for the CLOB order book API, REST API, and Gamma metadata API. FastAPI serves the REST API; SQLite stores position history. The $100 bankroll operates under two concentration limits: no more than 10% per position and no more than 10 simultaneous positions, controlling both single-position and portfolio-level risk.

### Post-Deploy Audit

Paper testing during the first deployment session discovered 4 critical bugs in the implementation, leading to creation of 6 tracking issues. The fixes were deployed via SCP without committing to git — a technical debt item tracked as Issue #5. The absence of automated tests means all validation is done by manual observation of paper mode behavior, which is acknowledged as a gap.

---

## 13. Kokoro Wallet Monitor

**Repository**: `happykokoro/kokoro-wallet-monitor` (private)
**Language**: Rust
**Status**: Production — deployed on DigitalOcean

### Purpose

Kokoro Wallet Monitor provides real-time Solana wallet surveillance via the WebSocket `logsSubscribe` RPC method. It detects DEX swap activity for tracked wallets and performs graph-theoretic analysis of fund flows to identify coordinated trading clusters.

### Architecture

Each tracked wallet runs in its own tokio task with an independent WebSocket connection, reconnecting on failure with exponential backoff. The `TransactionParser` decodes transaction logs for swap detection across four DEX protocols: Jupiter V6 (the dominant Solana aggregator), Raydium (concentrated liquidity AMM), Orca (whirlpool CLMM), and Pump.fun (meme token launchpad). The `GraphEngine` uses the petgraph crate to maintain a directed fund-flow graph: each detected swap or transfer creates a weighted edge from source to destination wallet. Louvain community detection — a modularity-maximizing graph clustering algorithm — runs over this graph to identify groups of wallets that show statistically unlikely levels of interconnection, flagging potential Sybil clusters or coordinated traders. Detected swap events and cluster signals are published to Redis Streams using the shared-types crate from the Alpha Lab monorepo (pinned to tag `shared-v0.2.2`), making wallet intelligence available to the broader signal pipeline.

---

## 14. Kokoro Pricing Service

**Repository**: `happykokoro/kokoro-pricing-service` (private)
**Language**: Rust
**Status**: Production — deployed on DigitalOcean

### Purpose

The Pricing Service aggregates price data from multiple Solana DEX sources, applies signal processing to produce high-quality price estimates, and distributes them to downstream consumers.

### Signal Pipeline

Data collection runs in parallel across five sources using `tokio::join!`: Jupiter aggregated quotes, Raydium AMM prices, Orca pool prices, Jupiter's Quote API for cross-token pricing, and the Pyth oracle for reference prices. Parallel collection via `tokio::join!` rather than sequential polling keeps latency at the maximum of any single source rather than the sum.

Aggregation applies VWAP (Volume-Weighted Average Price) and median aggregation to the parallel price observations, inherently filtering outliers from any single source. The 2-state Kalman filter — tracking price level and price velocity (first derivative) as a state vector — smooths the aggregated price while tracking trend momentum. This is a continuous-time adaptation of the standard discrete Kalman filter, appropriate for the non-uniform sampling intervals of DEX price updates. The MomentumRanker identifies the top and bottom 20% of tokens by recent momentum, providing a relative ranking signal. The OFI (Order Flow Imbalance) calculator measures buying versus selling pressure across the DEX pool data. A candle builder converts the tick stream into OHLCV bars at configurable timeframes. Processed prices are distributed via REST endpoints, Server-Sent Events for real-time streaming, and Redis Streams for system-internal consumers.

---

## 15. Kokoro Pay

**Repository**: `happykokoro/kokoro-pay` (private)
**Language**: Rust
**Status**: Standalone — not deployed

### Purpose

Kokoro Pay is a B2B crypto payment gateway supporting USDC on Solana alongside Stripe, providing merchants with a single integration point for both crypto and fiat payment acceptance.

### Architecture

The Rust backend uses Axum for HTTP routing, SQLx for PostgreSQL interaction, and Redis for event queuing. The API is organized into five modules. `orders` manages payment lifecycle: create, list, get by ID, and update status. `merchant` handles onboarding: registration, API key issuance and rotation, and webhook configuration. `codes` implements gift code mechanics: generate codes tied to specific amounts, redeem codes against orders, and validate before use. `admin` provides the operator dashboard: aggregate stats, merchant management, and dispute resolution. `webhooks` handles event notifications to merchant systems: payment confirmation, expiry notification, and delivery retry.

USDC on Solana payments use on-chain vault addresses: the gateway generates a unique vault address per order, monitors for on-chain confirmation of the expected USDC transfer, and marks the order paid upon confirmation. Stripe integration handles checkout session creation (for hosted payment pages), subscription lifecycle management, and Stripe webhook event processing. A background task worker handles async settlement, payment expiry (cancelling unpaid orders after a timeout), and webhook delivery with retry logic. The frontend split between a merchant dashboard and an embeddable widget enables Kokoro Pay to be used both as a standalone portal and as an embedded checkout in merchant websites.

---

## 16–20. Supporting Infrastructure and Developer Tools

### Kokoro Tech

The company marketing website at https://tech.happykokoro.com is built with Next.js 16 as a static export, Tailwind v4, and a dark theme. It contains 18 components with scroll animations. Two primary pages cover the 9 Kokoro products with a vision roadmap and a 250+ item technology stack inventory, plus a services catalog with 28 categories. Deployment is handled via rsync to the DigitalOcean server.

### Claude Init

Claude Init is a Python single-file CLI (1,229 lines, zero dependencies beyond the standard library) that bootstraps a complete AI coding agent configuration for any project. It inspects project files — `Cargo.toml`, `package.json`, `go.mod`, `pyproject.toml`, and framework-specific indicators — to detect the language and framework, then generates a `.claude/` directory containing a CLAUDE.md with project-specific instructions, a `settings.json` with appropriate tool permissions, agent configurations, and skill definitions. The zero-dependency design means it runs anywhere Python runs without requiring a virtualenv or pip install. Supported languages are 9 (Rust, Python, TypeScript, JavaScript, Go, Java, Ruby, Elixir, Dart, Solana) and 18 frameworks (Next.js, React, Vue, Angular, Express, Fastify, FastAPI, Django, Flask, Axum, Actix, Anchor, Bevy, Leptos, Svelte, Astro, Remix).

### Claude Dev Pipeline

Claude Dev Pipeline is a Markdown skill file implementing the SKILL.md protocol. It defines a four-phase parallel development workflow: a research phase where an agent ingests the codebase and requirements, a team execution phase where each agent operates in its own git worktree and produces its own PR, review-and-fix loops where agent output is audited and corrected, and a dependency-aware merge phase that orders PR merges according to the dependency graph of the changes. A single human approval gate at the end of the review phase is the only required human intervention. This skill serves as the high-level orchestration protocol that Agent Orchestra implements at the tooling level.

### Kokoro Services

Kokoro Services is a Docker Compose configuration for self-hosted infrastructure replacing commercial SaaS dependencies. The 11 services managed include Umami (privacy-first analytics), Gitea (self-hosted git), Shlink (URL shortener), Uptime Kuma (uptime monitoring), PrivateBin (encrypted paste service), Excalidraw (collaborative whiteboarding), Linkding (bookmark manager), Syncthing (file synchronization), and Homepage (service dashboard). Running these services privately eliminates recurring SaaS fees, retains data control, and removes external service availability dependencies from internal tooling.

### HappyKokoro

The company website is built on Next.js 15 with Payload CMS 3.77 backed by SQLite. The CMS-driven architecture manages pages, blog posts, project showcases, and site search. The Resend email adapter (configured with the `happykokoro.com` domain on Resend's Tokyo region) handles the contact form, routing submissions to the configured address.

---

## Conclusion: Engineering Coherence at Scale

Twenty projects built by a single developer over a focused period represent an unusual technical achievement. What makes this portfolio notable is not any individual project but the deliberate coherence between them. The Alpha Lab monorepo defines shared types and traits that are consumed by the Wallet Monitor and Pricing Service via `shared-types`. The quantitative algorithms in `quant-core` appear in both the Polymarket Bot and Kokoro MM. The EIP-712 signing logic in `mm-polymarket` is the same signing logic used in the Polymarket Bot's `executor` crate. The Avellaneda-Stoikov spread calculation in Kokoro MM draws on the same Kalman filtering primitives as the broader DSP infrastructure.

This coherence is the product of upfront architectural investment: defining clean abstractions, enforcing dependency boundaries, and resisting the temptation to copy-paste logic across projects. The result is a codebase that, despite its scale — over 300,000 lines of Rust across the primary projects, plus tens of thousands of lines of TypeScript and Python — remains navigable and extensible. New asset classes, strategies, and execution venues can be added as additive operations rather than requiring cross-cutting refactors. The Clean Integration Layer in Alpha Lab, the trait-based adapter pattern in the Liquidation Bot, the interface-segregated plugin architecture in Kokoro Staking — these are not incidental design choices but consistent applications of the same architectural principles across every project in the portfolio.

For senior engineers evaluating this work, the signal is in the architectural decisions: zero I/O in pure crates, trait-based dispatch everywhere that runtime flexibility is needed, lock-free concurrent data structures at performance boundaries, dual JSON/protobuf encoding for migration safety, and client-side signing as a security-first default. These are the decisions of an engineer who has thought carefully about the problems that arise at scale and built ahead of them.

---

**Next steps:** [Explore our services →](../services/overview.md) | [View technical profile →](../profile/resume.md) | [Contact us →](../services/contact.md)

---

_Kokoro Tech — [tech.happykokoro.com](https://tech.happykokoro.com) · [GitHub](https://github.com/happykokoro) · [Contact](../services/contact.md)_
