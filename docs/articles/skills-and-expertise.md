# Technical Capabilities Whitepaper: Skills & Domain Expertise

> This document provides a comprehensive account of technical skills, domain expertise, algorithmic knowledge, and engineering methodology demonstrated across the Kokoro project portfolio. Each capability is substantiated by concrete implementation evidence drawn from production systems.

---

## 1. Systems Programming in Rust

### Async Runtime Architecture

The ability to design and implement production-grade asynchronous systems from first principles is one of the most demanding competencies in modern systems programming. Across the Kokoro portfolio, async Rust is not merely used — it is architected with deliberate intent at every level of the stack.

The flagship example is kokoro-mm, a market-making platform that runs its gateway (HTTP server), engine (quoting pipeline), and datahub (market data aggregation) within a single shared Tokio runtime. Rather than decomposing these into separate networked services, they communicate via direct function calls across crate boundaries. This eliminates inter-service network overhead entirely while preserving strict logical separation. The architectural insight here is subtle: network isolation is a deployment concern, not a correctness concern, and collapsing the network boundary between tightly coupled services produces measurable latency improvements without sacrificing modularity.

Per-entity task management is another recurring pattern. In kokoro-wallet-monitor, each tracked wallet receives its own dedicated Tokio task, with per-task exponential-backoff WebSocket reconnection logic. When a connection drops, that wallet's task retries independently — a failure in one wallet's stream does not cascade to others. In kokoro-mm, each user account runs a `UserInstanceLoop` task that ticks at two-second intervals, managing the full lifecycle of quoting, inventory rebalancing, and order management for that user in an isolated execution context.

For hot-path concurrent state, `DashMap` is consistently preferred over `RwLock<HashMap>` to avoid contention on read-heavy workloads. Circuit breaker flags use `AtomicBool` for lock-free reads on every request path. Watchdog timestamps in data adapters use `Arc<AtomicI64>` so that health-checking threads can update timestamps without blocking the data path. In polymarket-bot specifically, `std::sync::RwLock` (not Tokio's async equivalent) is deliberately chosen to avoid the overhead of async lock contention — a nuanced decision that reflects a deep understanding of when async synchronization primitives are counterproductive.

Across all services, graceful shutdown is implemented via cooperative cancellation: `tokio::select!` statements on shutdown channels combined with OS signal handlers ensure that in-flight work completes before process exit, and that database connections, WebSocket connections, and Redis consumers are properly closed.

### Trait-Based Abstraction Design

Extensible trait hierarchies are the primary tool for building pluggable architectures throughout this codebase. The approach is neither over-abstracted nor under-engineered — traits are introduced precisely where runtime composability or multiple implementations are genuinely required.

In the alpha-lab platform, 24 distinct `AlphaFactor` implementations all conform to a single `trait AlphaFactor: Send + Sync`. The signal pipeline operates on a `Vec<Box<dyn AlphaFactor>>`, choosing dynamic dispatch deliberately to support runtime factor composition — users can assemble arbitrary combinations of alpha factors without recompilation. This is a real-world application of the Open/Closed Principle: the pipeline is closed to modification but open to extension through new trait implementations.

The execution pipeline in the liquidation and trading systems composes multiple trait-gated stages: `OrderSizer` determines position size, `SlippageEstimator` models market impact, `ProfitabilityFilter` gates execution on expected P&L, `ExecutionBackend` handles order routing, and `PostTradeValidator` confirms fills. Each stage has multiple interchangeable implementations, and the pipeline can be reconfigured without touching any stage-level code.

The liquidation-bot demonstrates the Protocol Adapter pattern at its most direct: a `ProtocolAdapter` trait enables runtime dispatch across Aave V3, Compound V3, Seamless, and Moonwell — four DeFi lending protocols with meaningfully different on-chain interfaces — through a single calling convention. A separate `LiquidationExecutor` trait cleanly separates execution strategies: flash loan execution, absorb-based execution, and paper (simulation) execution are all interchangeable behind the same interface.

In polymarket-bot, `TickAdapter` and `RestAdapter` traits standardize the interface for real-time and historical data sources with a four-method contract: `connect`, `subscribe`, `poll_next`, and `is_healthy`. The `DataHub` uses a builder pattern to compose adapters before starting the data pipeline, allowing different adapter combinations in test versus production environments.

### Memory Safety and Concurrency Patterns

The codebase applies several advanced Rust patterns to enforce correctness at compile time rather than relying on runtime checks.

The separation between `mm-types` and `mm-proto` crates enforces zero-copy serialization boundaries: domain types remain internal to the system and never carry serde annotations, while API types handle serialization at the boundary. This prevents accidental exposure of internal representations through external interfaces.

Feature-gated compilation is used extensively. In `factor-registry`, `#[cfg(feature = "factor-X")]` conditional compilation allows different build profiles — `all-factors`, `core-factors`, and `minimal` — to control binary size and compile time without maintaining separate codebases. Most significantly, in both polymarket-bot and liquidation-bot, all live-trading code paths are gated behind `#[cfg(feature = "live-signing")]`. This means paper-mode binaries are physically incapable of executing live transactions — the code doesn't exist in the compiled binary. This is a stronger safety guarantee than any runtime flag could provide.

The type-state pattern is applied to the round lifecycle in kokoro-mm, where a round progresses through `Discovered → OrdersOpen → Active → Settling → Settled` as explicit enum variants. State machine transitions are encoded in the type system: operations that are only valid in certain states are simply not callable in others, because the relevant methods exist only on the corresponding variants.

The `factor-registry` implements a thread-safe factory registry that maps string names to `Box<dyn Fn() -> Box<dyn AlphaFactor>>` factory functions. This is populated at startup via feature-gated blocks, allowing the factory to be assembled from whatever set of factors are compiled into the current binary.

### Macro and Metaprogramming

The `factor-sdk` crate provides a `kokoro_factor!` procedural-style macro that generates WASM export boilerplate for user-compiled strategy factors. This enables end users to write custom alpha factors that load at runtime without any manual FFI wiring — the macro handles all the unsafe boundary code automatically.

In the liquidation-bot, `alloy::sol!` is used for inline ABI definition, embedding Solidity contract ABIs directly in Rust source. This eliminates the separate ABI JSON files that traditional EVM development requires, keeping the contract interface co-located with the Rust code that calls it and ensuring they cannot drift out of sync.

The Python strategy service in polymarket-bot uses a `@register_strategy` decorator pattern that automatically registers strategy classes into a `StrategyRegistry` on import. This provides the same discoverability as explicit registration without requiring any registration boilerplate in each strategy file.

Across all domain types in every crate, `#[derive(Debug, Clone, Serialize, Deserialize)]` is standard. `#[serde(default = "fn_name")]` attributes are used consistently for backward-compatible config deserialization, ensuring that configuration files from older versions continue to work as new fields are added.

---

## 2. Quantitative Finance

### Signal Processing and Filtering

The signal processing implementations across this portfolio go well beyond commodity technical indicators. These are mathematically rigorous DSP algorithms implemented from first principles in production Rust, applied to financial time series where noise suppression, latency, and robustness to non-Gaussian distributions are all simultaneously important.

The H-infinity filter is the most advanced estimator in the stack. Unlike the Kalman filter, which minimizes mean-squared error under Gaussian assumptions, the H-infinity filter is minimax optimal under bounded noise — it minimizes the worst-case estimation error regardless of the noise distribution. The implementation uses four states (position, velocity, acceleration, and jerk), applies innovation gating to reject outlier measurements, scales the measurement noise matrix R adaptively with tick rate, and inflates state covariance to handle non-stationarity. In the `factor-enhanced` crate, three H-infinity filters are cascaded, each operating on the output of the previous, providing progressively cleaner signal with controlled latency.

The Unscented Kalman Filter (UKF) addresses a fundamental limitation of the classical Kalman filter: it assumes linear dynamics. For nonlinear price processes, the UKF uses the sigma point transform — a deterministic sampling scheme that propagates a set of carefully chosen points through the nonlinear dynamics and recovers a Gaussian approximation to the posterior. The implementation uses nalgebra's Cholesky decomposition for sigma point generation and models price dynamics with a mean-reversion velocity and acceleration decay term.

The particle filter provides a fully nonparametric approach, making no Gaussian assumption on either the state distribution or the noise. Implemented in both `dsp-filters` (general purpose) and `prediction` (as a Rao-Blackwellized Particle Filter variant), it uses sequential Monte Carlo with importance resampling. The RBPF variant is particularly sophisticated: it marginalizes the continuous (linear) states analytically using a per-particle Kalman filter, while sampling only the discrete regime labels with particles. This dramatically reduces the variance of the Monte Carlo estimate compared to a plain particle filter on the full state space.

The Interacting Multiple Models (IMM) filter operates three simultaneous regime models: a Trending model with persistent velocity, a Ranging model with mean-reverting dynamics, and a Volatile model with random walk dynamics. A Markov transition matrix governs the probability of switching between regimes at each timestep. The filter maintains probability weights over these models and mixes their predictions accordingly. This is the appropriate architecture for financial time series because markets genuinely switch between regimes — a filter that assumes a single fixed dynamic model will necessarily be misspecified for extended periods.

The Dual Kalman filter runs coupled estimations for price and log-volatility simultaneously. The volatility estimate feeds back into the process noise matrix Q of the price Kalman filter, creating a system where the price smoother adapts its confidence in its own model based on a separate volatility signal. This is a principled way to handle heteroscedasticity without requiring a full stochastic volatility model.

For frequency-domain analysis, the Morlet Wavelet Continuous Wavelet Transform (CWT) is implemented using 20 log-spaced scales. Unlike the Fourier transform, which provides global frequency information, the CWT provides multi-resolution time-frequency decomposition — it can identify which frequencies are active at which moments in time. This is directly useful for detecting regime-specific periodicity in market microstructure.

The Hilbert transform is implemented via FFT: the negative frequency components are zeroed, and the inverse FFT yields the analytic signal, from which instantaneous amplitude, instantaneous phase, and instantaneous frequency can be extracted. This provides a way to characterize the local oscillatory behavior of a signal without committing to a global frequency model. The Mellin transform, which provides scale-invariant spectral analysis, is also implemented for financial time series, enabling analysis that is robust to changes in market tempo.

For baseline noise smoothing in the pricing-service, a classical two-state Kalman filter tracks price and velocity. Exponentially Weighted Moving Average (EWMA) with configurable lambda is used for volatility estimation in the kokoro-mm spread calculator, providing a computationally lightweight alternative where the latency of more sophisticated filters cannot be tolerated.

### Statistical Modeling

GARCH(1,1) — the Generalized Autoregressive Conditional Heteroscedasticity model — is implemented twice: once in Rust using grid search maximum likelihood estimation over the (alpha, beta) parameter space with variance targeting, and once in Python using the `arch` library. GARCH models the empirical fact that financial volatility is not constant but clusters in time — periods of high volatility tend to persist. The Rust implementation supports n-step ahead forecasting with explicit mean-reversion to long-run variance, which is essential for options pricing and risk management over multi-day horizons.

The Hurst exponent, estimated via R/S (rescaled range) analysis on log-returns, is used to characterize long-range dependence in time series. Chunk sizes start at 8 and multiply by 1.5 across the range, and OLS regression of log(R/S) against log(n) yields the exponent. A Hurst exponent below 0.5 indicates mean-reverting dynamics (useful for knowing when spread-trading is appropriate), while values above 0.5 indicate trending dynamics that favor momentum strategies.

Probability estimation for tail events uses the Student-t distribution rather than the normal distribution, reflecting the well-documented fat-tailed nature of financial returns. CDF computation is implemented directly for use in risk modeling and signal confidence scoring.

Stationarity testing via the Augmented Dickey-Fuller (ADF) test is applied to time series before treating them as mean-reverting. This guards against the common mistake of building a mean-reversion strategy on a non-stationary process.

Conformal prediction provides non-parametric uncertainty quantification without any distributional assumptions. A rolling calibration set is maintained, and quantile-based coverage bounds are computed targeting 95% empirical coverage. This framework is valuable precisely because it provides valid uncertainty intervals even when the underlying signal distribution is unknown or changing.

Expert aggregation using the Hedge algorithm implements multiplicative weights update with exponential loss penalty eta (η). This is a theoretically grounded approach to combining multiple prediction experts in an online setting: experts that have historically been accurate receive higher weight, while experts that have been wrong are downweighted exponentially. The regret bounds from online learning theory guarantee that performance approaches the best single expert in hindsight.

Copula models capture dependency structure between correlated assets without assuming a multivariate normal distribution. Three families are implemented: Gaussian copulas (Cholesky sampling from the correlation matrix), Student-t copulas (which introduce tail dependence controlled by the degrees-of-freedom parameter ν), and Clayton copulas (an Archimedean family with lower-tail dependence). This is applied to portfolio risk modeling where the assumption that asset returns are jointly normal significantly understates correlated crash risk.

Autocorrelation analysis for serial dependence detection is used in signal validation to ensure that proposed alpha factors are not simply exploiting spurious autocorrelation in the training data. Jump detection via return z-scores with a 3.0σ threshold identifies regime breaks — periods where the time series process changes character — which serves as input to downstream regime-aware models.

The Brownian Bridge research represents one of the most substantive original research contributions in the portfolio. Path conditioning on prediction market outcomes was studied across 11,348 historical Polymarket markets. The key finding is that the conditional probability of an outcome is not captured adequately by the current market price — it depends on the realized price path over multiple timeframes. Specifically, a parent-level Up signal combined with a recent [Down, Down] sub-path predicts Up with 95% probability, validated at 100% accuracy on 18 out-of-sample cases. This exploits a hierarchical timeframe cascade structure: three 5-minute periods are nested inside each 15-minute period, and four 15-minute periods are nested inside each 1-hour period. The theoretical foundation is the Brownian Bridge — a stochastic process conditioned on both its starting value and its terminal value — applied to the prediction market price path conditional on the known terminal outcome boundary.

### Options Pricing and Greeks

Black-Scholes analytical closed-form pricing for European options is implemented in the `quant-core` crate, including all first-order Greeks: delta (sensitivity to underlying price), gamma (convexity of delta), vega (sensitivity to volatility), theta (time decay), and rho (sensitivity to interest rates). Having all Greeks available is essential for portfolio risk aggregation, not just individual option pricing.

Monte Carlo options pricing is implemented with two variance reduction techniques applied simultaneously. Importance sampling reweights paths from a proposal distribution that concentrates more samples in the region of interest (e.g., in-the-money outcomes for out-of-the-money options), dramatically improving estimator efficiency for rare events. Antithetic variates pairs each simulated path with its mirror path (where each random increment is negated), ensuring that the two paths are negatively correlated and thus their average has lower variance than either path individually. Path simulation follows Geometric Brownian Motion with configurable path count and time steps.

For assets without listed options markets, a synthetic options chain generation facility exists in the `options-data` crate. It applies Black-Scholes across a range of strikes and synthetic expiration slices to produce a complete options chain, enabling options-style risk analysis on non-standard assets.

### Portfolio Optimization and Risk Management

Mean-Variance Optimization (MVO) follows Markowitz's framework for computing optimal portfolio weights given expected returns and a covariance matrix. Two solution methods are implemented: an analytical two-constraint Lagrangian solution for the unconstrained case, and projected gradient descent for the constrained case. Operations on the covariance matrix use nalgebra's `DMatrix` type. Full efficient frontier computation is supported, generating the complete set of Pareto-optimal return/risk tradeoff portfolios.

The Kelly criterion for position sizing is implemented in the alpha-lab portfolio module. In polymarket-bot, it is present but deliberately disabled pending proper probability calibration — a principled decision reflecting understanding that Kelly requires true probabilities, not just model predictions that may be overconfident.

Value at Risk (VaR) is implemented under two assumptions: parametric (Gaussian) and historical (quantile from empirical return distribution). Both at 95% confidence. Conditional VaR (CVaR), also known as Expected Shortfall, computes the expected loss conditional on exceeding the VaR threshold — a coherent risk measure that properly captures tail risk where VaR does not.

Drawdown management in live systems uses an `AtomicBool` circuit breaker flag that trading-path code checks on every operation without acquiring a lock. Daily loss limits and maximum drawdown gates are enforced through this mechanism. Portfolio-level Greeks aggregation — summing delta, gamma, vega, and theta across all positions — provides a single risk picture for the options portfolio.

Historical simulation for kokoro-mm's VaR/CVaR computation generates 21 price-move scenarios spanning ±20% range, providing a stress-test-style risk estimate grounded in realistic market dislocations rather than purely statistical extrapolation.

### Market Making

The Avellaneda-Stoikov (A-S) market making model provides the theoretical foundation for kokoro-mm's spread calculator. The model computes a reservation price — the price at which the market maker is indifferent between buying and selling — by adjusting the fair value based on current inventory. The spread around the reservation price is set proportional to volatility and a risk aversion parameter, with an adverse selection premium added to compensate for the risk of trading against informed flow. The implementation uses EWMA volatility and tracks net token exposure per side to feed the inventory skew signal back into the A-S model's reservation price computation.

Fair value estimation fuses multiple data sources using exponential freshness decay (newer sources get exponentially higher weight), confidence weights per source, EMA filtering to smooth out noise, and velocity tracking to detect trend. This multi-source fusion approach is more robust than any single data source, particularly in markets where individual price feeds can be stale or temporarily dislocated.

Adverse selection detection monitors fill patterns to identify toxic order flow — situations where the counterparties consistently hold profitable positions, suggesting they have information advantage. When toxic flow is detected, the system triggers batch cancellation waves to exit the adverse exposure before it compounds.

The quote generation module, a 392-line `QuoteGenerator`, produces a full bid/ask ladder from the spread calculator's output. It implements laddered quoting with tiered levels, breakout detection at fill (indicating that the market has moved decisively and the current quotes are stale), and automatic stop-loss placement to bound inventory risk.

### Backtesting Infrastructure

The backtesting system is built around a `BacktestRunner` that makes a single pass over `PriceBar` slices with configurable stop-loss and take-profit parameters. Deterministic replay is a first-class requirement: the same `HistoricalTick` input always produces the same output. This is not accidental — it is enforced by design, ensuring that backtests are reproducible and that observed improvements from parameter changes are real, not an artifact of randomness.

Parameter optimization supports both grid search (exhaustive enumeration of `ParameterRange` combinations) and random search (Monte Carlo sampling for high-dimensional parameter spaces). `WalkForwardAnalyzer` implements rolling train/test windows for out-of-sample validation — the gold standard for detecting overfitting in quantitative strategies. `MonteCarloSimulator` adds path randomization to generate confidence intervals around backtest performance metrics.

For synthetic scenario testing, crash, ramp, and sideways market scenarios can be generated as JSONL files for offline replay. This enables stress testing against market conditions that may not appear in historical data.

### Market Microstructure

The Hawkes process models self-exciting point processes — events that increase the probability of subsequent events. For order flow, the intensity function is λ(t) = μ + Σ α·exp(-β·(t−tᵢ)), where each past event contributes a decaying excitation to the current intensity. The `factor-hawkes` crate uses cascade threshold detection to identify when order flow is exhibiting self-exciting dynamics characteristic of institutional accumulation or distribution.

Order Flow Imbalance (OFI) — the normalized difference between buy and sell order flow — is computed with thresholds at ±0.5 (signal) and ±2.0 (strong signal). A dedicated crate handles this computation in the pricing-service, reflecting the importance of OFI as a leading indicator of short-term price pressure.

UniswapV3-style tick space analysis detects LP repositioning events, which signal upcoming changes in AMM liquidity depth. Liquidity density scoring identifies thin liquidity zones ahead of the current price, where a given order size would cause disproportionately large price impact — useful for predicting high-volatility micro-events. Whale detection combines exchange inflow/outflow metrics with exponential time decay and consensus signals from tracked wallets. Order book imbalance analysis covers mid-price, spread, and VWAP calculations, with book manipulation detection. DEX swap pressure analysis processes swap volume and direction to infer directional pressure from on-chain activity.

### Monte Carlo Methods

The Monte Carlo toolkit covers the full spectrum from basic probability estimation (simple binary simulation) to sophisticated variance reduction techniques. Importance sampling uses a proposal distribution to oversample the region of interest, then reweights the samples by the likelihood ratio between the proposal and target distributions — this is essential for accurately estimating probabilities of rare events where naive simulation would require impractically many samples. Antithetic variates ensures that each simulation generates two negatively correlated paths, cutting variance roughly in half for no additional model evaluations. Geometric Brownian Motion path simulation is the standard model for asset price evolution under the risk-neutral measure. The Logarithmic Market Scoring Rule (LMSR) — the cost function used by prediction market automated market makers — is implemented along with its Bregman divergence interpretation, which provides the theoretical link between market scoring rules and proper scoring rules from statistical decision theory.

---

## 3. Blockchain and DeFi

### Solana Development

The Solana development experience spans 20 Anchor programs with complete instruction handler implementations. The application domains covered are unusually broad: DeFi (AMM, lending, yield vaults, liquidation engine, leveraged betting), gaming (six distinct casino game types with proper probability fairness), prediction markets, NFT auctions, and on-chain governance. Each of these domains has its own characteristic on-chain data model, account structure, and security requirements.

SPL Token integration covers the full lifecycle: minting and redeeming chip tokens for the gaming protocols, managing associated token accounts for users, and handling token approvals for protocol interactions. The house pool architecture implements LP deposits with pro-rata share accounting, game locks that reserve funds during active rounds, settlement mechanics that distribute winnings, and circuit breakers that halt new games when reserves fall below minimum thresholds.

The reward system implements rakeback accrual (a percentage of fees returned to active players), claim mechanics with on-chain proof of accrued rewards, a referral system that tracks relationships between accounts and distributes referral bonuses, and a tier boosting system that modifies reward rates based on activity levels.

DEX integrations cover the three major Solana AMMs: Jupiter V6 for swap routing (using the quote API to find optimal routes across multiple pools), Raydium AMM for pool state reading, and Orca Whirlpool for concentrated liquidity position tracking. Pump.fun detection identifies newly launched tokens from the memecoin launchpad.

Real-time wallet monitoring uses WebSocket `logsSubscribe` subscriptions to receive program log events as they occur on-chain. Transaction parsing fetches full transaction data via RPC, identifies relevant program IDs, and extracts structured `DetectedSwap` events from the instruction data.

### EVM Development

The EVM development work centers on a multi-chain liquidation engine covering six chains simultaneously: Ethereum, Base, Arbitrum, Polygon, Optimism, and Avalanche. Each chain has its own gas dynamics, block time, and protocol deployment addresses, requiring protocol-specific adapter logic behind a unified `ProtocolAdapter` trait.

Flash loan execution is implemented in `FlashLiquidator.sol`, a Solidity contract that atomically: flash-borrows the required amount, liquidates the undercollateralized position, swaps the collateral received to the borrowed asset via Uniswap V3, and repays the flash loan — all within a single transaction that either succeeds in its entirety or reverts. This atomic composition is essential because any partial execution would leave the protocol in an exploitable intermediate state.

The Rust-side EVM interaction uses the `alloy` framework with `sol!` macro for inline ABI definition. This approach keeps contract interface definitions co-located with the calling code and eliminates the build-time JSON ABI file dependency.

EIP-712 typed structured data signing is implemented for Polymarket CLOB orders with manual Keccak256 digest computation — the domain separator, type hash, and struct hash are computed explicitly rather than delegated to a library. This level of control is necessary when building against novel contract interfaces that pre-date comprehensive library support.

Flashbots integration enables MEV-protected transaction submission on Ethereum mainnet via `eth_sendBundle`. For liquidation bots, this is critical: without MEV protection, profitable liquidation transactions are routinely front-run by searchers monitoring the mempool.

On-chain CTF (Conditional Token Framework) operations — `splitPosition`, `mergePositions`, and `redeem` — are implemented for the Polymarket position settlement flow. USDC and ERC-1155 approvals are managed through the same interaction layer.

Uniswap V3 fee tier selection logic classifies pairs as: stable-stable (0.05% fee tier), WETH-stable (0.05% fee tier), or default (0.3% fee tier). The liquidation close factor logic is protocol-specific: Aave V3 uses 50% when Health Factor > 0.95 and 100% when HF falls below that threshold, while Compound V3 always allows 100% liquidation.

### Prediction Markets

A complete Polymarket SDK has been built from scratch, covering the CLOB REST API, WebSocket order book feed, Gamma metadata API, EIP-712 order signing, HMAC-SHA256 L2 authentication, and fill detection via polling. This covers the complete operational surface of the Polymarket protocol.

The CTF integration handles the full position lifecycle on Polygon: splitting USDC into conditional token positions, merging positions back into USDC when taking the other side, and redeeming resolved positions for their settlement value.

Multi-venue routing in kokoro-mm abstracts over Polymarket, Kalshi, and Manifold through unified market provider adapters, allowing the market-making engine to operate across prediction market venues without venue-specific logic in the quoting pipeline.

The copy-trading system implements trader discovery (identifying traders with strong track records), position mirroring with size normalization, and hold-to-resolution logic that maintains positions through contract settlement rather than exiting early.

---

## 4. Full-Stack Web Development

### Backend Architecture

All Rust HTTP services in the portfolio use Axum 0.8 with Tower middleware for cross-cutting concerns: CORS, rate limiting, distributed tracing, and Prometheus metrics exposition. Kokoro-mm's API layer spans 69 routes across 24 modules, covering market data, order management, user accounts, strategy configuration, backtesting, and administration.

The Node.js/Express backend for kokoro-pipeline implements 50+ route modules using Prisma ORM against a schema with 30+ models. The Python FastAPI services — polymarket-bot's strategy service on port 8100 and kokoro-copy-trader on port 4500 — provide lightweight high-throughput endpoints for latency-sensitive operations. The kokoro-staking backend uses Gin (Go) with interface-segregated adapters following the same plugin architecture patterns used in Rust.

The happykokoro.com website uses Payload CMS with SQLite persistence, a lexical rich-text editor, form builder, and SEO tooling — demonstrating practical knowledge of production CMS deployment alongside more complex distributed systems.

Authentication implementations span the full modern security stack: JWT sessions (RS256 and HS256), API key authentication via HMAC-SHA256, TOTP two-factor authentication per RFC 6238, Argon2 password hashing, AES-256-GCM wallet encryption at rest, HKDF key derivation for per-user key material, GitHub OAuth, and SAML/OIDC SSO for enterprise integrations.

Tier-gated middleware enforces subscription level authorization at the request level. In kokoro-mm, this maps to FREE/MANUAL/SIGNAL/AUTOPILOT tiers; in alpha-lab, to Free/Level1/Level2/ProMax. This allows the same API codebase to serve users at different subscription levels without duplicating route handlers.

### Frontend Development

Production frontends are built with Next.js 15/16 using the App Router paradigm with server components for data-heavy pages and static export for deploy simplicity where appropriate. React 19's latest features are used across all frontends. Tailwind v4 uses the PostCSS plugin model, departing from the JIT configuration model of earlier versions.

Component architecture relies on Radix UI primitives for accessibility-correct unstyled components, assembled into styled shadcn/ui components. State management splits cleanly between Zustand 5 for client state stores and SWR 2 for server data fetching with automatic caching and revalidation.

Real-time updates to the frontend use SSE (Server-Sent Events) with a custom `useSSE` React hook that implements exponential backoff reconnection from 1 second to a 30-second cap, automatic event parsing, and state hydration from the event stream. WebSocket connections are used for exchange order book feeds where bi-directional communication is required.

Six distinct charting libraries are in active use, each selected for specific visualization tasks: lightweight-charts v5 for financial OHLC candlestick charts, recharts for dashboard summary visualizations, chart.js for configurable chart types, plotly.js for scientific and statistical plots, d3 for custom algorithmic visualizations, and React Flow for node-graph editors.

The strategy builder canvas in kokoro-mm uses React Flow (@xyflow/react v12) with six custom node types: cancel-node, inventory-node, mint-node, quote-node, round-lifecycle-node, and spread-visualizer-node. This provides a visual drag-and-drop interface for constructing market making strategies without code.

Tauri v2 was used for the kokoro-vpn desktop client, demonstrating cross-platform desktop application development with a Rust backend and web frontend.

### Database Design

PostgreSQL is used for production persistence across the most complex services. Kokoro-mm has 21 query modules organized around the repository pattern, with async trait abstractions and in-memory repository implementations that allow the full business logic layer to be tested without a database. Kokoro-pipeline has 30+ Prisma models with full migration history.

Redis Streams serve as the backbone for all inter-service event passing: 10 active streams with consumer groups, XREADGROUP plus ACK for reliable at-least-once delivery semantics, XPENDING monitoring for consumer lag detection, and a dual JSON/proto format that allows zero-downtime rolling upgrades. SQLite is used for lightweight persistence in polymarket-bot, the VPN client, the copy-trader, and the CMS.

Database schema evolution is managed through multiple mechanisms: SQLx migration pairs (58 pairs in kokoro-mm), Prisma migrations for the Node.js service, and JSONL append-only event logs for audit trail data that must be immutable.

---

## 5. Infrastructure and DevOps

### Container Orchestration

All production services are containerized using multi-stage Docker builds. For Rust binaries, the build stage uses a full Rust toolchain image to compile the release binary; the runtime stage is a minimal image containing only the compiled binary and its dynamic dependencies. This produces container images that are orders of magnitude smaller than single-stage builds.

Docker Compose orchestrates the full-stack deployment across three production servers, including health checks, named volumes for persistent data, and network isolation between service groups.

Beyond the core trading infrastructure, 11 self-hosted services run in the same infrastructure: Umami for web analytics, Gitea for private git hosting, Uptime Kuma for uptime monitoring, Excalidraw for collaborative diagramming, Shlink for URL shortening, PrivateBin for encrypted paste sharing, Linkding for bookmark management, Syncthing for file synchronization, and Homepage for service dashboarding. Operating this breadth of self-hosted infrastructure demonstrates practical DevOps competency beyond what is needed for any single application.

### Networking and Security

A custom WireGuard VPN infrastructure provides two operating modes: client VPN (hub-and-spoke topology for end-user clients) and mesh VPN (full-mesh topology for inter-server communication). An ACL firewall rule system generates iptables and nftables scripts from a declarative access control specification. The mesh spans three nodes across Singapore, Ireland, and London, providing encrypted private networking for all inter-server service calls.

Public-facing services use Caddy for automatic HTTPS certificate provisioning and renewal, with Nginx handling specific services that require more flexible configuration. All public domains are fronted by Cloudflare for DNS, CDN caching, and DDoS protection.

SOPS (Secrets OPerationS) provides encrypted secrets management for deployment configurations, ensuring that secret values are never stored in plaintext in version control. Private keys are never transmitted via API (enforced through a placeholder pattern), encrypted at rest using AES-256-GCM, and derived per-user using HKDF to prevent key reuse.

### Monitoring and Observability

Prometheus metrics are exported from all Rust services via Tower-HTTP middleware, providing uniform metric collection without service-specific instrumentation code. Grafana provides dashboard visualization for operational monitoring. OpenTelemetry enables distributed tracing across service boundaries.

Structured logging uses the `tracing` crate with `tracing-subscriber` for log collection, maintaining span context that allows log lines to be correlated with the request or background task that generated them. Every service exposes both `/health` and `/metrics` endpoints as a first-class operational requirement.

### Multi-Server Management

The production infrastructure spans three servers: sg-main on DigitalOcean Singapore hosting the Alpha-lab platform, trading bots, monitoring infrastructure, and self-hosted services; ie-poly on AWS EC2 Ireland hosting Kokoro MM and the Polymarket bot; and uk-pay on AWS EC2 London hosting the copy trader and market data services. All three are connected via a WireGuard mesh on the 10.10.0.0/24 private subnet, enabling inter-server API calls that never traverse the public internet.

---

## 6. AI and Agent Systems

### Claude Code Mastery

Two MCP (Model Context Protocol) servers have been built from scratch, exposing 115 total tools that provide Claude with programmatic access to the trading platform's full API surface. This enables Claude to autonomously inspect live market data, query signal states, examine positions, and reason about trading decisions without requiring human intermediation for data access.

Custom Claude Code skills have been developed for structured workflow automation in trading-specific domains: `dev-pipeline`, `signal-pipeline`, `risk-management`, `kalman-filter`, `polymarket-arbitrage`, `anchor-patterns`, and `dex-integration`. These skills encode domain-specific patterns that would otherwise require lengthy prompting to communicate.

The agent-orchestra project is a ground-up Python implementation of a Claude subagent orchestration dashboard. It manages Claude CLI subprocesses with WebSocket-based real-time monitoring of each agent's output. The system supports configurable team templates — feature-dev (three agents: architect, implementer, reviewer), build-fix (single focused agent), code-review, debug, and research — with approval gates that pause the pipeline for human review on merge conflicts, build failures, and test failures. Each agent works in an isolated git worktree on its own branch, and completions trigger automatic merge with dependency-aware ordering. A shared `CARGO_TARGET_DIR` prevents redundant compilation across concurrent agents, and critical error detection (ENOSPC and OOM) triggers automatic process termination before the server runs out of disk or memory.

The `claude-dev-pipeline` skill implements a four-phase parallel execution model with atomic PR creation and dependency-aware merge ordering, enabling complex multi-crate feature development to be orchestrated through a single command.

### ML and AI Implementations

A Deep Q-Network (DQN) implementation in the `factor-ai` crate of alpha-lab uses an experience replay buffer to break temporal correlations in the training data, a Q-network for function approximation of the action-value function, and epsilon-greedy exploration with annealing. This provides a reinforcement learning foundation for factor selection and portfolio management under non-stationary market conditions.

The copilot crate in alpha-lab integrates LLM capabilities for four distinct use cases: factor advisor (explaining the current factor composition to users), risk explainer (narrating the current risk exposure in plain language), strategy generator (proposing new strategy configurations from natural language descriptions), and trace analyzer (diagnosing why a particular signal or trade behaved unexpectedly).

The `factor-sdk` WASM plugin system allows users to write custom alpha factors in Rust, compile them to WASM using the `kokoro_factor!` macro for FFI boilerplate, and load them at runtime without access to the platform source code. This is a complete plugin architecture that maintains both performance (WASM near-native throughput) and security (sandboxed execution).

PCA (Principal Component Analysis) factor decomposition is implemented in scikit-learn within the Python strategy service, used to identify orthogonal dimensions of market variation and reduce correlated factor signals to a smaller set of uncorrelated predictors.

---

## 7. Cryptography and Security

The cryptographic implementations span both traditional web security and blockchain-specific protocols, reflecting the dual nature of the systems being built.

EIP-712 typed structured data signing — used for Polymarket CLOB orders — is implemented with manual Keccak256 digest computation. This means the domain separator, type hash, and encoding of each struct field are computed explicitly in Rust code, providing complete auditability of the signing process. ECDSA signing uses the `ethers` and `k256` libraries for live transaction signing, with private keys held only in memory during the signing operation.

HMAC-SHA256 provides API authentication for both Polymarket's L2 CLOB authentication and kokoro-mm's API key system. AES-256-GCM encrypts wallet keys at rest, providing authenticated encryption that detects any tampering with the stored ciphertext. HKDF-SHA256 derives per-user cryptographic keys from a master key, ensuring that a compromise of one user's derived key does not expose the master key or other users' keys.

Argon2 password hashing is the current state-of-the-art for password storage, providing memory-hard hashing that resists GPU-accelerated cracking attempts. JWT session management is implemented in both RS256 (asymmetric, suitable for multi-service verification) and HS256 (symmetric, for single-service use). TOTP per RFC 6238 provides time-based one-time password generation and verification for two-factor authentication.

WireGuard's underlying cryptography — Curve25519 elliptic curve key exchange, ChaCha20-Poly1305 symmetric encryption — is used for all VPN tunnel encryption. SOPS uses age or PGP encryption for secrets at rest in configuration files. The flash loan smart contract provides atomicity as a security property: the borrow, liquidate, swap, and repay operations either all succeed or all revert, preventing partial execution that could drain pool reserves.

---

## 8. Testing and Quality Assurance

### Test Philosophy

The testing philosophy prioritizes correctness verification over coverage metrics. Strategies and quantitative algorithms are pure functions — they take inputs and return outputs without side effects — and are tested deterministically with synthetic data generated inline. There are no external fixture files and no mock frameworks anywhere in the codebase. Tests use real logic against synthetic data, which means that passing tests provide genuine evidence of algorithmic correctness rather than just evidence that mocks return the expected values.

Computationally expensive tests — filter convergence tests, Monte Carlo simulations — are gated behind a `slow-tests` feature flag so they can be run deliberately rather than on every build cycle. Tests are co-located with the source code they verify (`#[cfg(test)] mod tests` within each source file), keeping test maintenance friction low. The repository pattern's dual implementation strategy — PostgreSQL for production, in-memory for tests — means the full business logic layer can be exercised without database setup.

### Test Coverage

The test suite totals 1,860 tests across the four primary repositories. Kokoro-alpha-lab has 1,074 tests covering filter convergence (verifying that state estimators actually converge to the correct values on synthetic data), quantitative algorithms (GARCH fitting and forecasting, copula sampling, VaR computation), signal composition (verifying that factor signals combine correctly), risk gate chains, and individual factor implementations. Kokoro-mm has 690 tests covering the quoting pipeline, symmetric and laddered breakout strategies, order management state machines, spread calculation, round controller lifecycle, and live order management. Kokoro-polymarket-bot has 72 tests focused on the statistical models: GARCH fitting and forecasting, Hurst exponent calculation, jump detection, Student-t CDF computation, risk gate chain execution, and candle aggregation. Kokoro-liquidation-bot has 24 tests covering profitability calculation, risk gate logic, circuit breaker behavior, health factor mathematics, and gas estimation.

### CI/CD Gates

The continuous integration pipeline enforces strict quality gates at every pull request. `cargo build --release` must produce zero warnings — warnings are treated as potential bugs. `cargo clippy -D warnings` converts all Clippy lint violations into errors, enforcing idiomatic Rust patterns. `cargo fmt --check` enforces consistent code formatting without exceptions. `cargo deny check` audits all dependencies for license compatibility and known security vulnerabilities. `npm run build` verifies that frontend builds succeed. The full test suite runs on every PR, ensuring that no change can merge while tests are failing.

---

## 9. Software Architecture Patterns

The architecture patterns applied across this portfolio reflect a coherent design philosophy rather than ad-hoc decisions. The Clean Integration Layer (CIL) pattern organizes alpha-lab as 63 pure-logic crates plus 3 app binaries, with I/O confined strictly to the boundary layer. Pure crates have no database access, no network calls, and no filesystem I/O — they are pure transformations of data. This makes them independently testable and trivially parallelizable.

The trait-object pipeline pattern (`Vec<Box<dyn AlphaFactor>>`) enables dynamic factor composition: new factors can be added at runtime without modifying pipeline code. The builder pattern provides fluent construction of complex domain objects: `AlphaSignal::new().with_metadata().with_prediction()`, `ArtifactBuilder`, and `DataHub::new().add_tick_adapter()` all follow this convention. The factory registry maps string names to factory functions, enabling dynamic instantiation of named implementations at runtime.

Role-based composition gives signals explicit roles — Primary, Confirmation, Filter, Observer — with different composition rules per role. Primary signals drive decisions; Confirmation signals must agree before execution; Filter signals can only veto; Observer signals only log. The composable risk gate architecture implements `RiskGateChain`, which runs a sorted list of gates where each gate can Pass, Reject, or Resize a trade, with resizing multipliers accumulating across the chain.

The Anti-Corruption Layer pattern in `mm-polymarket` wraps the external Polymarket API with a domain-typed interface, ensuring that Polymarket-specific data structures (market IDs, outcome token representations, CLOB order formats) never leak into the market-making engine's domain model.

The Go staking adapters use decorator layering: a raw chain adapter is wrapped with a circuit breaker decorator, then a rate limiter decorator, then a cache decorator, then a metrics decorator. Each decorator implements the same interface and adds exactly one cross-cutting concern.

Dual-format Redis Streams messaging provides backward-compatible migration from JSON to Protocol Buffers: consumers inspect the first byte of each message to determine its format and decode accordingly. This enables zero-downtime rolling upgrades where producers and consumers can be upgraded independently.

---

## 10. Data Pipeline and Streaming Architecture

### Redis Streams

Ten active Redis Streams with consumer groups form the backbone of inter-service event passing. XREADGROUP with ACK provides reliable at-least-once delivery: a message is only removed from the pending-entries list after the consumer explicitly acknowledges successful processing. XPENDING monitoring enables detection of consumer lag and identification of dead-letter messages that are stuck in the pending list without acknowledgment.

The dual-format JSON/proto migration is a canonical example of backward-compatible protocol evolution. During the transition period, producers publish both formats or the new format only, while consumers detect the format by inspecting the first byte and decode appropriately. This allows producers and consumers to be upgraded on independent schedules without a coordinated cutover, which would require simultaneous downtime across multiple services.

The stream topology follows the data pipeline: wallet-monitor publishes discovered swap events → pricing-service aggregates price data → alpha-lab engine receives aggregated signals → execution layer receives approved orders. Each stage is a consumer group on the upstream stream and a producer on its downstream stream.

### Real-Time Communication

The SSE (Server-Sent Events) pattern for frontend real-time updates is implemented with a custom `useSSE` React hook that handles exponential backoff reconnection (starting at 1 second, capped at 30 seconds), automatic event type parsing, and state hydration from the full event stream on reconnection. This is more lightweight than WebSocket for unidirectional server-to-client streams and requires no special infrastructure beyond standard HTTP.

gRPC streaming uses tonic 0.13 for server-streaming RPCs (signals, positions, trades) and bi-directional streaming for inter-service communication. Server-streaming RPCs allow a single RPC call to produce an ongoing stream of responses, which is the natural fit for live market data feeds. WebSocket connections for exchange data adapters (Binance, Coinbase, Polymarket) implement per-connection heartbeat and automatic reconnection with per-connection state management.

### Event Sourcing and Audit

A JSONL append-only event log records every decision in the signal evaluation pipeline: each signal evaluation, each risk gate decision, and each order placement is logged with a timestamp and full causal chain. This provides a complete audit trail that can be used for regulatory compliance, post-hoc debugging, and backtesting by replaying the log through an updated pipeline.

Deterministic replay of historical event logs through the full pipeline is a first-class capability, enabling reproducible debugging of production incidents and validation that bug fixes actually change behavior on the cases that exposed the bug.

---

## 11. Payment Processing

### Stripe Integration

The Stripe integration covers the complete subscription commerce lifecycle. Server-side checkout session creation handles the redirect flow with success and cancel URL configuration. Subscription lifecycle management covers plan creation, pro-rata upgrade and downgrade handling, cancellation with end-of-period access, and webhook-driven state updates. Webhook event processing uses Stripe's signature verification to authenticate webhook calls and implements idempotent event handling for `payment_intent.succeeded`, `subscription.updated`, and `invoice.paid` events. The kokoro-pipeline creator marketplace implements revenue split logic and Stripe Connect-based creator payout processing.

### Crypto Payments

USDC on Solana is accepted for subscription payments in kokoro-pay, with on-chain vault address validation and transaction confirmation polling. A gift code system handles generation, redemption, and validation with expiry tracking.

### Platform Payment Service

Within the alpha-lab monorepo, the payment service (`services/payment-service`) integrates payment event processing into the same Redis Streams infrastructure used for trading signals. Payment events (new subscription, upgrade, cancellation) flow through the streaming pipeline, triggering access control changes in the platform in near-real-time. A unified multi-provider abstraction layer sits over both Stripe and crypto payment rails, allowing the payment service's business logic to be written once and applied to either payment method.

---

_This whitepaper documents technical capabilities as demonstrated across production implementations. All claims are grounded in specific codebases and implementation artifacts within the Kokoro project portfolio._
