# Kokoro Tech: Architecture Overview

## A Distributed Quantitative Trading and Blockchain Infrastructure Platform

Kokoro Tech is a distributed quantitative trading and blockchain infrastructure platform spanning 530,000+ lines of production code across 7+ coordinated repositories, 3 cloud regions, and 14 independently deployable products. This document describes how the system is architected, why specific engineering decisions were made, and how the platform aligns with contemporary standards in distributed systems, signal processing, and cloud-native operations.

Architecture documented following ISO/IEC/IEEE 42010:2022 conventions. Technical content at the level of engineering review, not product marketing.

---

## System Architecture: One Logical Platform Across Seven Repositories

What appears at first glance to be a portfolio of fourteen separate products is, in practice, one interconnected distributed system with fourteen independently deployable nodes. The architecture was designed around this distinction from the beginning — the question was never "how do we build fourteen things" but "how do we build one coherent system that happens to have fourteen deployment units."

### The Repository Federation Pattern

The core of the platform is a Rust monorepo (`kokoro-alpha-lab`, 242,466 lines, 65 crates, 1,074 tests) organized around a principle called the Clean Integration Layer (CIL). The CIL separates all business logic from all I/O: 63 crates under `crates/` contain pure trading logic with zero I/O dependencies, while only 3 application binaries in `apps/` interact with the outside world.

```
apps/lab      (port 4100) — Research: factor pipeline, backtesting, HTTP API, gRPC :50051, SSE
apps/engine   (port 4200) — Execution: frozen strategy, real order execution, gRPC :50052
apps/platform (port 4000) — Gateway: auth, billing, tier gates, gRPC→REST proxy
```

Satellite repositories were extracted from the core monorepo as they reached operational maturity: `kokoro-alpha-lab-frontend` (Next.js trading dashboard), `kokoro-wallet-monitor` (Solana on-chain intelligence), `kokoro-pricing-service` (multi-DEX price aggregation), `lab-mcp` (TypeScript MCP tool server), `kokoro-polymarket-bot`, and `kokoro-copy-trader`. Each extraction was defined by a stable interface contract — not by arbitrary project boundaries.

### Coordination Mechanisms

Seven or more repositories coordinate as one logical system through four explicit mechanisms:

**Versioned type contracts.** A single `shared-types` crate defines canonical domain types used across all repositories: signal shapes, event schemas, position structs, billing tier enums. Satellite repositories pin to tagged semantic releases (`shared-v0.x.x`) rather than git SHAs, enforcing a deliberate upgrade process. When a type changes, the change propagates through a controlled dependency bump.

**Redis Streams as the inter-service message bus (10 named streams).** Asynchronous events between services are carried over Redis Streams rather than simple Pub/Sub — the critical difference being persistence, consumer groups, and ordering guarantees. All 10 streams carry messages in dual JSON/protobuf format: the `enc` field signals the encoding in use, and all consumers auto-detect. This allows old and new service versions to coexist during rolling deployments without coordination — an instance of the zero-downtime protocol evolution pattern now recognized as best practice.

**gRPC for synchronous service-to-service calls.** Three service pairs use Tonic gRPC for request-response and server-streaming interactions: Lab↔Engine (signal submission, execution confirmation), Engine↔Platform (tier enforcement, billing events), and Platform↔external clients (authenticated, rate-limited API surface). Proto `.proto` files in `services/proto/` are the source of truth.

**WireGuard mesh making cross-server communication transparent.** All three production servers (DigitalOcean Singapore, AWS Ireland, AWS London) participate in a WireGuard mesh on the 10.10.0.0/24 subnet. Services address each other by mesh IP. A service on the Singapore server communicates with a service on the Ireland server exactly as if co-located — no public internet exposure, no external load balancer, no service discovery overhead.

---

## Cloud-Native Architecture Patterns

The platform implements the full set of cloud-native patterns that 89% of organizations now use (CNCF Annual Survey 2026), with 80% running Kubernetes in production. The patterns were adopted because they solve real architectural problems at scale — not as theoretical compliance.

### Implemented Patterns

**Event-Driven Architecture (EDA)** via Redis Streams. The 10-stream topology decouples producers from consumers across server and repository boundaries. The pricing service publishes price events without knowing which downstream factors will consume them. The wallet monitor publishes cluster events without knowing which strategy will use them. Services can be added, removed, or scaled independently.

**API Gateway pattern** via the Platform binary (port 4000). All external traffic — frontend, third-party integrators, API clients — enters through the Platform binary. Authentication, billing enforcement, tier-based rate limiting, and gRPC→REST translation are handled at this boundary. Internal gRPC bindings between Lab, Engine, and Platform can evolve without breaking external contracts.

**Circuit Breaker pattern** via `AtomicBool` flags. Every trading system implements circuit breakers that trip after configurable failure thresholds. The liquidation bot trips after 5 consecutive on-chain reverts. The market-making engine trips on adverse selection detection. Hot-path circuit breaker reads use `AtomicBool` — no lock acquisition, no async overhead, microsecond read latency.

**CQRS-like separation** between signal generation and execution. The Lab binary (port 4100) handles all read-path operations: factor computation, signal aggregation, backtesting, research queries. The Engine binary (port 4200) handles the write path: order submission, position management, execution state. These concerns are physically separated into different binaries with explicit gRPC contracts between them.

**Saga Pattern** in the liquidation bot. The flash loan liquidation sequence — borrow from Aave, liquidate undercollateralized position, swap collateral to repayment token, repay loan — must execute atomically or not at all. This is implemented as a Solidity `FlashLiquidator.sol` contract that performs the complete sequence within a single Ethereum transaction, ensuring atomicity at the protocol level.

### Real-Time Streaming Architecture

The SSE (Server-Sent Events) pattern for real-time frontend updates follows 2026 streaming best practices: persistent HTTP connection, server-pushed events, exponential backoff reconnection (1s → 2s → 4s → ... → 30s max). The frontend maintains an `EventSource` connection to the Platform binary; the Platform proxies gRPC server-streaming from the Lab and Engine binaries.

For cross-service streaming, gRPC server-streaming handles low-latency point-to-point communication (Lab→Engine signal feeds). Redis Streams handles high-durability fan-out (pricing service → all downstream consumers). The distinction follows the pattern: gRPC for latency-critical service pairs, Streams for durable multi-consumer delivery.

---

## Signal Processing Methodology

The quantitative signal processing pipeline applies state estimation theory — developed originally for control systems — to financial time series. This is not a surface-level analogy: the mathematical framework is identical.

### The State Estimation Problem in Finance

A financial price series presents the same structure as a physical dynamical system: hidden state (true price, trend velocity, market regime), observable outputs (tick prices, corrupted by microstructure noise), and disturbance inputs (order flow imbalance, news events, liquidity shocks). State estimation theory addresses precisely this problem: given a sequence of noisy observations, maintain the best estimate of hidden state and its uncertainty.

The Kalman filter, in its original derivation, assumes Gaussian noise and linear dynamics. This assumption is violated by financial prices on both counts: price distributions have fat tails (non-Gaussian), and the relationship between state and observation is often nonlinear (spreads, midprice dynamics). The pipeline addresses these violations with purpose-designed extensions.

### Filter Cascade Architecture

The H-infinity filter (IEEE Transactions on Signal Processing) replaces the Gaussian noise assumption with a minimax formulation: find the estimator that minimizes the worst-case ratio of estimation error energy to disturbance energy, over all possible disturbance sequences bounded in energy. This produces an estimator that is robust to any bounded disturbance, including heavy-tailed price shocks. The implementation uses a 4-state model (position, velocity, acceleration, jerk) with innovation gating — observations whose innovation exceeds a threshold are downweighted, preventing outlier contamination of the state estimate. A tick-rate adaptive R matrix scales measurement noise with market activity.

The Unscented Kalman Filter addresses the nonlinearity problem. Instead of linearizing the state transition function (as the Extended Kalman Filter does), UKF uses a deterministic sigma point transform: a minimal set of carefully chosen sample points that exactly capture the mean and covariance of a Gaussian distribution are propagated through the nonlinear function, and the output statistics are extracted from the propagated points. The Cholesky decomposition ensures numerical stability of the sigma point generation.

The particle filter (Sequential Monte Carlo) handles multi-modal posteriors: when the price could be in one of several regimes simultaneously, maintaining a single Gaussian estimate is inadequate. The particle filter represents the posterior as a weighted sample set. Importance resampling focuses computational effort on high-probability regions. The RBPF (Rao-Blackwellized Particle Filter) extends this: continuous state variables (price, velocity) are marginalized analytically via Kalman filters per particle, while discrete regime labels are sampled with particles. This hybrid approach achieves higher statistical efficiency than either method alone.

The IMM (Interacting Multiple Model) filter runs three-regime Kalman filters in parallel — Trending (persistent velocity), Ranging (mean-reverting), Volatile (random walk) — with a Markov transition matrix governing regime probability updates. Model probabilities mix state estimates from all three filters, weighting by each filter's likelihood.

### KalmanNet Direction

The prediction crate's expert aggregator and conformal prediction bounds approach the frontier identified by KalmanNet (IEEE 2021): neural network aided Kalman filtering for partially known dynamics. KalmanNet replaces the Kalman gain computation with a learned network, enabling adaptation when the noise covariance model is imprecise or partially unknown. The platform's expert aggregation (Hedge algorithm: multiplicative weights update with exponential loss penalty η) and non-parametric conformal prediction coverage bounds address the same problem from a different angle: instead of learning the dynamics, they quantify prediction uncertainty empirically.

### Multi-Resolution Analysis

The Morlet wavelet CWT (20 log-spaced scales) provides simultaneous time and frequency localization that windowed Fourier transforms cannot achieve. At each scale, the CWT captures signal energy in a time-frequency tile sized inversely to the scale — fine temporal resolution at high frequencies, fine frequency resolution at low frequencies. This makes the CWT appropriate for detecting transient features at multiple timescales simultaneously: a price spike at the tick level and a trend reversal at the hourly level are both detectable without choosing a single analysis window.

The Hilbert transform constructs the analytic signal: the FFT is computed, negative-frequency components are zeroed, and the inverse FFT yields a complex signal whose magnitude is the instantaneous amplitude and whose argument is the instantaneous phase. The time derivative of the instantaneous phase is the instantaneous frequency — a measure of local oscillation rate that has no equivalent in classical Fourier analysis.

---

## Quantitative Finance Implementation

The quant stack implements institutional-grade tools from mathematical foundations — not wrappers around third-party libraries, but direct algorithmic implementations with explicit mathematical derivations.

### Alpha Factor Architecture

24 alpha factor implementations, each conforming to the `AlphaFactor` trait, form the composable signal layer. The trait defines a standard interface: `compute(&self, market_data: &MarketContext) -> AlphaSignal`. Dynamic dispatch (`Box<dyn AlphaFactor>`) is chosen deliberately over static dispatch — runtime composability and the ability to load factor pipelines from TOML configuration artifacts are worth the modest overhead.

The Hawkes process factor applies a self-exciting point process model borrowed from seismology: λ(t) = μ + Σ α·exp(-β·(t−tᵢ)) where each past event excites future event arrival rate with exponential decay. Applied to order arrival, this captures the empirically observed clustering of trades. The factor-hawkes crate implements cascade threshold detection for trading signals.

The DQN ensemble factor trains a Deep Q-Network on state representations of the factor pipeline output, learning to combine multiple weaker signals into a single stronger one. This connects to the emerging paradigm of Large Investment Models (LIM): learning signal patterns across instruments and frequencies rather than hand-engineering combination rules. The platform's modular AlphaFactor architecture predates and aligns with this approach.

### Risk Gate Architecture

Risk management operates through composable gate chains: each gate returns Pass, Reject, or Resize. Gates compose: `chain([MinEdgeGate, MaxDrawdownGate, MaxPositionsGate, KellyGate])` applies all gates in sequence, stopping at the first Reject. This design enables runtime configuration of risk parameters per deployment without modifying trading logic.

VaR and CVaR are implemented in both parametric (normal assumption) and historical (empirical quantile) forms. The parametric form uses the inverse normal CDF; the historical form sorts the P&L distribution and reads the target quantile. Circuit breakers use `AtomicBool` flags — hot-path reads are lock-free, ensuring risk checks do not add latency to the execution path.

### Market Making: Avellaneda-Stoikov

The Kokoro MM market making engine implements the full Avellaneda-Stoikov (A-S) framework — the academic model that derives optimal bid-ask spreads under inventory risk. The A-S framework models the market maker's optimization problem: maximize expected P&L while controlling inventory risk through spread and quote size. The reservation price adjusts for inventory risk:

```
r = s - q · γ · σ² · (T-t)
```

where s is the fair value, q is current inventory, γ is risk aversion, σ is volatility, and (T-t) is time horizon. The optimal spread scales with volatility and the inventory risk penalty. The implementation adds multi-source fair value estimation (exponential freshness decay across multiple price feeds, confidence-weighted EWMA), adverse selection detection (fill pattern monitoring triggering cancellation waves), and laddered quote generation (392-line `QuoteGenerator`).

The full quoting cycle completes within a 2-second engine tick: discover active rounds → estimate fair value → compute spread → generate quote ladder → submit orders → sync state → settle filled orders.

---

## Blockchain and DeFi Engineering

### Solana: 20 Anchor Programs

The Kokoro Protocol comprises 20 Anchor programs on Solana organized in a three-layer architecture: 6 infrastructure programs (treasury, token, user vault, house pool, reward pool, governance) support 5 DeFi programs (AMM, lending, yield vaults, liquidation engine, leveraged positions) and 7 gaming/auxiliary programs (6 casino game types, prediction market, NFT auction).

The house pool architecture implements LP deposit/withdrawal, game lock/settlement, circuit breaker, and rebalance operations — a complete liquidity management layer. The reward system implements rakeback accrual, tiered claim mechanics, and referral tracking. All program interactions are composable through Cross Program Invocations (CPIs) using the Anchor framework's type-safe account validation.

### EVM: Flash Loan Liquidation Across 6 Chains

The liquidation bot runs simultaneous monitoring across Ethereum, Base, Arbitrum, Polygon, Optimism, and Avalanche. The multi-chain architecture uses the `ProtocolAdapter` trait to abstract chain-specific behavior: each lending protocol (Aave V3, Compound V3, Seamless, Moonwell) implements a separate adapter with protocol-specific health factor calculation, close factor logic, and liquidation call encoding.

The custom `FlashLiquidator.sol` Solidity contract executes the complete liquidation sequence atomically within a single transaction:

1. Flash-borrow the debt asset from Aave
2. Execute the liquidation against the target protocol
3. Swap received collateral to repayment asset via Uniswap V3
4. Repay the flash loan

Zero capital is required from the operator because steps 1 and 4 (borrow and repay) are atomic — if the sequence fails at any step, the entire transaction reverts. Profit is the excess collateral above the flash loan repayment.

The circuit breaker trips after 5 consecutive on-chain reverts, protecting against systematic execution failures (gas estimation errors, price feed staleness, or protocol-level edge cases).

---

## Infrastructure and Operations

### Three-Server WireGuard Mesh

The three production servers — DigitalOcean Singapore (primary, 12+ containers), AWS Ireland (Kokoro MM, liquidation bot), AWS London (copy trader) — form a WireGuard mesh VPN on the 10.10.0.0/24 subnet. Per-node firewall ACL rules are generated programmatically from the VPN configuration, ensuring that service exposure follows from architectural intent rather than manual firewall management.

The mesh makes physical server boundaries transparent to the application layer. Services on different servers address each other by mesh IP — no service discovery, no external DNS, no load balancer between internal services. Cross-region latency is the only performance consideration; protocol-level routing is eliminated.

### Observability Stack

Observability is first-class across all services:

- **Prometheus**: Metrics instrumented on all services (request counts, latencies, error rates, domain-specific gauges for signal pipeline throughput, factor computation time, order submission rate)
- **Grafana**: Dashboards for all services, alerting on error rate thresholds
- **OpenTelemetry**: Distributed tracing across service boundaries (Lab → Engine → external execution)
- **Structured logging**: JSON-format logs via the Rust `tracing` crate with span context propagation
- **Uptime Kuma**: External availability monitoring for all public endpoints

### AI-Augmented Development as Engineering Infrastructure

The MCP (Model Context Protocol) layer represents a structural investment in operational capability, not a convenience tool. Two MCP servers with 115 tools between them expose every service boundary — signal pipeline state, factor weights, backtesting, position management, bot deployment, system health — through a structured protocol accessible to both AI agents and human operators.

The Model Context Protocol reached 97 million monthly SDK downloads in March 2026 (up from 2 million at its November 2024 launch), with 6,400+ registered servers. AI-augmented development is now a recognized engineering methodology. The platform's 115 MCP tools represent one of the largest known domain-specific MCP implementations, and were built as operational infrastructure before the protocol reached widespread adoption.

Agent Orchestra manages parallel development across AI coding agents: git worktree isolation, dependency-aware merge ordering, automated build-test-report pipelines, approval gates on conflicts and failures. The same infrastructure that currently coordinates AI agent teams will coordinate human engineering teams as the platform scales.

---

## Live Testing and Empirical Validation

### Polymarket Bot Strategy Failure and Post-Mortem

The Kokoro Polymarket Bot ran live in early 2026. The initial strategy — fair-value dislocation — produced a $55 loss in 12 minutes. The post-mortem is technically instructive:

The strategy estimated fair value from an ensemble of price signals, then traded markets where current price deviated from the estimate. In backtesting, this appeared profitable. In live trading, it failed structurally.

The root cause: the strategy had a structural directional bias toward Down outcomes (lower probability estimates), and the backtesting validation was tautological — the validation data shared the same structural bias. The model was learning the bias, not the signal.

A formal quantitative investigation followed: 11,348 historical Polymarket markets analyzed, 15 specific research questions formulated. The Brownian Bridge path conditioning signal was validated at 100% accuracy on a sample of 18 test cases. Hierarchical cascade (multi-timeframe confirmation) achieved 77.8% accuracy. Per-asset volatility profiles were characterized.

The replacement strategy architecture specifies an explicit signal ranking: path conditioning first, 1-hour spread second, hierarchical cascade third, 15-minute lock fourth, 5-minute spread fifth, momentum sixth. The original strategy used only the sixth-ranked signal — the weakest available.

This failure-and-recovery cycle is the expected pattern in research-driven quantitative trading: live deployment surfaces structural biases that backtesting validates away. The value is in the systematic response: formal post-mortem, quantitative research, hypothesis validation, and a better-specified replacement architecture.

---

## Technical Scale

| Metric                       | Value                                                                                           |
| ---------------------------- | ----------------------------------------------------------------------------------------------- |
| Total production code        | 530,000+ lines (Rust, TypeScript, Python, Go, Solidity)                                         |
| Rust code                    | 330,000+ lines across 100+ crates                                                               |
| Automated tests              | 1,860+ across all repositories                                                                  |
| MCP tools                    | 115 (98 lab-mcp + 17 kokoro-mm)                                                                 |
| REST API endpoints           | 200+                                                                                            |
| Frontend pages/routes        | 200+                                                                                            |
| Solana Anchor programs       | 20                                                                                              |
| Blockchain chains integrated | 23 (6 EVM + Solana + 17 staking)                                                                |
| DeFi protocols               | 8+                                                                                              |
| Exchange data feeds          | 5 (Binance, Coinbase, Deribit, Pyth, Polymarket)                                                |
| Production servers           | 3 (Singapore, Ireland, London — WireGuard mesh)                                                 |
| Docker containers            | 12+ in production                                                                               |
| Redis Streams                | 10 named streams, dual JSON/proto, consumer groups                                              |
| Alpha factors                | 24 (each conforming to `AlphaFactor` trait)                                                     |
| DSP filters                  | 11 (H-infinity, UKF, particle, IMM, RBPF, wavelet, Hilbert, Mellin, dual Kalman, EWMA, Fourier) |

---

## Open Source

Three projects from this portfolio are publicly available:

- **claude-init** — Auto-generates `.claude/` configuration directories for any project by detecting language (9 options) and framework (18 options). Zero external dependencies. Available on GitHub.
- **claude-dev-pipeline** — Parallel development pipeline skill for Claude Code implementing 4-phase execution (research → team → review → merge). MIT license.
- **kokoro-vpn** — Self-hosted WireGuard VPN platform with Tauri v2 desktop client. MIT license.

---

## Commercial Applications

The architecture described in this document is not only the foundation for Kokoro Tech's own products — it is a deployable model for client engagements. Each architectural layer translates to a concrete service capability.

### Modular Crate Architecture Enables Rapid Client Customization

The 65-crate monorepo is organized so that individual components can be extracted and reused without carrying the full platform's dependencies. A client commissioning a quantitative signal processing system receives the relevant filter crates (`dsp-filters`, `factor-enhanced`, `prediction`) configured for their asset class, without the trading execution or market making layers. A client building a DeFi liquidation bot receives the `ProtocolAdapter` trait hierarchy and the relevant chain adapters, configured for their target protocols.

This is not theoretical extensibility — the platform was designed with the Clean Integration Layer specifically to enable this: 63 pure-logic crates contain zero I/O and have no external runtime dependencies. Extracting a crate for a client project means extracting tested, pure logic that compiles and runs independently.

### Trait-Based Plugin System Means Client-Specific Implementations Integrate Cleanly

Every extension point in the platform — `AlphaFactor`, `ExecutionBackend`, `ProtocolAdapter`, `LiquidationExecutor`, `RiskGate` — is defined as a Rust trait. Client-specific implementations simply implement the trait and register with the factory. A client-specific liquidation strategy implements `LiquidationExecutor`. A proprietary alpha signal implements `AlphaFactor`. Custom risk rules implement the `RiskGate` chain interface.

This architecture pattern means client customizations do not require forking the core platform — they plug in at the defined extension points. Client code is isolated from platform internals, meaning platform upgrades do not break client customizations and client customizations do not destabilize the platform core.

### MCP Tools Demonstrate Structured AI Interface Capability for Any Domain

The 115 MCP tools across two production servers are the clearest demonstration that Kokoro Tech can build structured AI tool interfaces for any domain. Each tool follows the same pattern: a well-typed schema, a documented contract, a production API call behind it. The lab-mcp server has 98 tools covering signal pipeline state, backtesting, factor analysis, execution, and system management. The kokoro-mm MCP server has 17 tools for the market making platform.

For clients building AI-powered products — whether in trading, enterprise SaaS, developer tools, or any other domain — this is the capability: a complete MCP server implementation from protocol layer to domain logic, tested and production-ready. The same tooling that allows Claude to autonomously manage the Kokoro platform can be built for any structured domain.

### Multi-Region Infrastructure Proves Operational Capability at Global Scale

Three production servers (DigitalOcean Singapore, AWS Ireland, AWS London) connected by a self-built WireGuard mesh VPN are not an architectural aspiration — they are an operational reality. The mesh was built, configured, and has run without incident across a multi-year development cycle. Per-node ACL firewall rules are generated programmatically. Cross-region latency is the only variable; routing is eliminated.

For clients requiring global deployment — latency-sensitive trading systems, geographically distributed SaaS platforms, multi-region data pipelines — Kokoro Tech has already solved the infrastructure design problem in production. The design can be adapted and deployed for client environments without starting from first principles.

The full observability stack (Prometheus on all services, Grafana dashboards, OpenTelemetry distributed tracing, structured logging, Uptime Kuma external monitoring) transfers directly to client deployments. Every service pattern in this document — API Gateway, Event-Driven Architecture via Redis Streams, Circuit Breaker, CQRS, Saga Pattern — has been implemented, tested, and operated in production. Client systems built on these patterns inherit operational maturity rather than discovering production edge cases post-launch.

---

## Contact

**GitHub (Organization):** https://github.com/happykokoro

**GitHub (Personal):** https://github.com/anescaper

**Company Website:** https://tech.happykokoro.com

**Portfolio:** https://happykokoro.com
