# The Kokoro Technology Stack: A Complete Technical Architecture Review

> This article provides a comprehensive, in-depth examination of every language, framework, library, protocol, and infrastructure component deployed across the Kokoro ecosystem. It is written for senior engineers, chief technology officers, and technical investors who need to assess the depth, coherence, and production-readiness of the stack from first principles.

---

## Overview: A Polyglot, Multi-Chain Financial Engineering Platform

The Kokoro ecosystem is not a single product but a constellation of interconnected systems spanning automated trading, decentralized finance, market-making, quantitative research, and developer tooling. The technology choices across these systems reflect a deliberate philosophy: use the right tool for each job without sacrificing coherence. Rust handles anything where performance, safety, or concurrency is non-negotiable. TypeScript powers every user-facing interface and AI-integration layer. Python is reserved for rapid quantitative research and orchestration. Go underpins the staking backend where concurrency primitives and ecosystem maturity matter most. Solidity and the Anchor framework govern on-chain logic where the execution environment is immutable by design.

The result is approximately 264,000 lines of Rust, 100,000 lines of TypeScript, 15,000 lines of Go, and 10,000 lines of Python in active production use, spread across more than ten repositories. This article walks through every layer of that stack in technical depth.

---

## 1. Programming Languages

### The Four Primary Languages

**Rust** is the dominant language of the ecosystem, accounting for roughly 264,000 lines of production code. It is used at the expert level across eight separate repositories: the kokoro-alpha-lab monorepo (approximately 242,000 lines across 65 crates), the kokoro-mm market-making platform (63,000 lines across 20 crates), the kokoro-polymarket-bot trading bot (15,500 lines), the kokoro-liquidation-bot (5,100 lines across 8 crates), and the supporting services — kokoro-wallet-monitor, kokoro-pricing-service, kokoro-vpn, and the payment service embedded in the monorepo. The choice of Rust is not merely stylistic: the signal processing pipelines, Kalman filters, and portfolio optimizers in alpha-lab demand zero-cost abstractions and predictable latency; the liquidation bot requires memory safety when managing flash loan execution paths on mainnet Ethereum; and the market-making engine needs to handle concurrent WebSocket order book updates without race conditions. Rust's ownership model enforces these constraints at compile time rather than at runtime, which is exactly the right trade-off for financial software.

**TypeScript** accounts for approximately 100,000 lines and is the exclusive language for all frontend work and AI-integration tooling. The alpha-lab frontend, the kokoro-mm frontend, the kokoro-tech marketing site, and the kokoro-staking frontend are all Next.js applications written in TypeScript. The lab-mcp repository — a Model Context Protocol server exposing 98 platform tools to AI agents — is also TypeScript. The kokoro-pipeline project, which handles developer workflow automation and marketplace billing, is a full Node.js TypeScript application. TypeScript's static type system makes it the natural companion to Rust-backed APIs: types defined in OpenAPI or manually mirrored from Rust structs give the frontend the same compile-time correctness guarantees at the boundary layer.

**Python** serves as the language for rapid quantitative research and multi-agent orchestration, with approximately 10,000 lines across three active projects. The kokoro-copy-trader and the polymarket-bot strategy service are FastAPI applications running statistical inference, Hurst exponent computation, and GARCH volatility modeling. The agent-orchestra project, which coordinates parallel AI coding agent agents across multiple git worktrees with automated merge and build pipelines, is written entirely in Python using its async ecosystem. The claude-init tool — a zero-dependency CLI for generating project scaffolding — is also Python. Python's dominance in scientific computing (numpy, scipy, scikit-learn) and its REPL-friendly iteration cycle make it the right choice for research scripts and orchestration glue, even though it would be wholly inappropriate for the latency-sensitive Rust services.

**Go** backs the kokoro-staking platform with approximately 15,000 lines of application code. Go was chosen here for a specific reason: the staking backend makes concurrent cross-chain RPC queries against more than a dozen blockchain networks, and Go's `errgroup` concurrency primitive handles partial failures across those parallel requests more ergonomically than equivalent Rust or Python patterns. The `pgx/v5` PostgreSQL driver, the `gin` HTTP framework, and `shopspring/decimal` for arbitrary-precision financial arithmetic are all mature, well-maintained Go packages that make this a pragmatic choice for a service where concurrency and database performance are the primary concerns.

### Secondary and Specialist Languages

Several additional languages fill specific roles that neither the primary four nor general-purpose tooling can satisfy.

**Solidity** is used in the kokoro-liquidation-bot for the `FlashLiquidator.sol` contract, which implements the IERC3156 flash loan callback interface. On-chain Solidity is unavoidable when the logic must execute atomically within a single Ethereum transaction — flash loan initiation, collateral swap, debt repayment, and profit capture all happen inside a single contract call that reverts entirely if any step fails.

**SQL** is written directly in many places rather than hidden behind ORMs. The kokoro-mm codebase alone contains 58 migration pairs managed by SQLx, and the alpha-lab monorepo maintains its own schema evolution. Raw SQL is used deliberately: the query planner behavior of PostgreSQL 16 is more predictable when the developer controls the query text than when an ORM generates it from object graphs.

**Shell and Bash** appear in the claude-dev-pipeline skill, deployment scripts, and GitHub Actions workflows. These are kept minimal — complex logic is pushed into Rust or Python binaries — but shell remains irreplaceable for composing Unix utilities in CI pipelines.

**TOML**, while not a Turing-complete language, deserves mention because it structures two important artifacts: the Cargo workspace configuration files that define the 65-crate monorepo dependency graph, and the strategy artifact definitions in alpha-lab where human-readable configuration is a requirement.

**YAML** is the configuration language for Docker Compose service definitions, GitHub Actions CI pipeline declarations, and agent-orchestra team templates. The separation of YAML configuration from executable code is intentional: infrastructure topology and agent team compositions should be editable by operators without recompiling any binary.

### Historical and Academic Languages

Java (Spring framework), C/C++, Dart (Flutter), Kotlin, and Pug appear in the technology inventory as background competencies or legacy dependencies. Java and C/C++ reflect academic and professional foundations. Dart and Kotlin represent mobile development experience. Pug appears as a templating dependency in a blockchain-demo fork. None of these are active in current production systems.

---

## 2. The Rust Ecosystem in Depth

The Rust dependency graph across the Kokoro ecosystem is extensive and carefully curated. What follows is a detailed account of every major crate category, what each library does at a technical level, and where it is deployed.

### Asynchronous Runtime and Networking

The entire Rust service layer is built on **tokio 1.x** with the `full` feature flag, which enables the multi-threaded work-stealing runtime (`rt-multi-thread`), async I/O and networking primitives, timers, macros (`tokio::select!`, `tokio::spawn`), synchronization primitives (`Mutex`, `RwLock`, `Semaphore`, `Notify`), signal handling, and filesystem access. Tokio is the only serious choice for Rust async I/O at production scale; its work-stealing scheduler and zero-cost `async/await` compilation model mean that the alpha-lab's 10 concurrent Redis Stream consumers, the liquidation-bot's parallel chain pollers, and the market-maker's WebSocket connections all run efficiently on a small thread pool without the overhead of spawning an OS thread per task.

**axum 0.8** is the HTTP framework for every REST API in the ecosystem: alpha-lab, kokoro-mm, liquidation-bot, polymarket-bot, kokoro-vpn, and the pricing service. Axum is built directly on top of tokio and hyper and uses a type-safe extractor pattern — request body, headers, path parameters, and query strings are parsed and validated by the type system before handler code runs. This eliminates an entire class of runtime errors at API boundaries. Axum was chosen over alternatives like actix-web because its integration with the tower middleware ecosystem is first-class, and because it composes naturally with the rest of the tokio stack.

**tower and tower-http** provide the middleware layer that wraps every axum router. The tower-http crate specifically adds CORS policy enforcement, per-route rate limiting, distributed tracing integration, response compression, and request timeout enforcement as reusable `Layer` implementations. These cross-cutting concerns are composed declaratively rather than wired inline in handler code, which keeps individual route handlers focused on business logic.

**reqwest 0.12** is the async HTTP client for all outbound API calls: Binance REST endpoints for OHLC candles and funding rates, Polymarket Gamma API for round discovery, Alpaca equity data REST endpoints, and Pyth Network oracle price feeds. Version 0.12 is current and aligns with the hyper 1.x release.

**tonic 0.13** and **prost 0.13** together implement gRPC communication between the three primary alpha-lab services — Lab, Engine, and Platform — which run as separate binaries but communicate over a local gRPC channel. Tonic generates client and server stubs from `.proto` files compiled by prost, giving the inter-service API the same typed contract guarantees as the REST layer. This is particularly important for the signal pipeline: a `Signal` message produced in Lab and consumed by Engine must survive serialization with zero ambiguity about field types and defaults.

**tokio-tungstenite** handles long-lived WebSocket connections to external data feeds: Binance spot and futures streams, the Polymarket CLOB order book, Deribit options volatility streams, and Solana program log subscriptions. WebSocket connections for financial data require careful reconnection logic — tokio-tungstenite provides the async read/write halves needed to implement exponential backoff reconnect with state preservation.

### Serialization and Data Representation

**serde 1.x** is the universal serialization framework. Every domain type — orders, positions, signals, candles, strategy artifacts — carries `#[derive(Serialize, Deserialize)]` derived implementations. Serde's zero-cost abstraction means serialization of a struct compiles to the same machine code as hand-written encoding, with no runtime reflection.

**serde_json 1.x** handles JSON encoding for REST API request and response bodies, Redis Streams message values, and configuration files. JSON is chosen for external-facing APIs and human-readable configs because it is the lingua franca of web services; internally, Protocol Buffers replace JSON on the hot path.

**prost 0.13** appears twice in the dependency graph: as the gRPC message generator via tonic, and independently as the serialization codec for Redis Streams. The Redis Streams migration moved all 10 active streams in alpha-lab to a dual-format architecture where messages can be published and consumed in both JSON and protobuf encoding simultaneously. This enables a zero-downtime migration path: consumers can be upgraded to the proto codec one by one without breaking existing JSON consumers.

**bincode** provides binary serialization for performance-critical internal paths where neither human readability nor cross-language interoperability is required. Binary encoding is typically an order of magnitude faster to produce and consume than JSON and produces significantly smaller payloads, which matters for high-frequency signal data.

**toml 0.8** parses strategy artifact configuration files in alpha-lab. TOML is preferred over JSON for human-authored configuration because it supports comments, has cleaner multiline string syntax, and is less error-prone to write by hand.

### Database and State Management

**sqlx 0.8** is the async PostgreSQL driver used across alpha-lab, kokoro-mm, and kokoro-vpn. Its defining feature is compile-time query verification: SQL query strings embedded in Rust source code are checked against the live database schema at compile time via the `sqlx::query!` and `sqlx::query_as!` macros. Type mismatches between Rust types and PostgreSQL column types become compiler errors rather than runtime panics. The kokoro-mm codebase manages 21 separate query modules and 58 migration pairs entirely through sqlx, giving the database schema the same level of version control rigor as application code.

**redis 1.1** (maintained as a custom fork with 0.27 compatibility shims) is the client for Redis 7.x, used as the primary message bus across all services. The alpha-lab architecture runs 10 named Redis Streams — one per major data domain — with consumer groups managed via `XREADGROUP` and `XACK`. Consumer group semantics guarantee exactly-once delivery within a group and enable independent consumer lag monitoring per stream. The kokoro-mm system uses Redis pub/sub alongside Streams for SSE event broadcasting to frontend clients.

**rusqlite** provides synchronous SQLite access in polymarket-bot (positions, signals, trade history) and kokoro-vpn. SQLite is the right choice for single-process workloads where an embedded database is sufficient and the operational overhead of a PostgreSQL server is not justified.

**dashmap 6.x** is the lock-free concurrent `HashMap` implementation used throughout the codebase as the primary shared-state primitive. In alpha-lab it backs the signal store, the strategy blackboard, the correlation matrix cache, and the portfolio orchestrator's position tracking. In the liquidation-bot it holds the `known_borrowers` map shared between the discovery thread, the health-factor polling loop, and the API handler. DashMap uses shard-based locking internally, achieving near-linear read throughput as thread count increases — a critical property for services where dozens of async tasks read shared state concurrently.

### Blockchain and Cryptographic Primitives

**alloy 1.x** is the modern Ethereum interaction library, used in the liquidation-bot for building flash loan transactions, calling on-chain smart contract methods, and ABI-encoding calldata via the `sol!` macro. Alloy supersedes ethers-rs and provides a cleaner API for transaction building, provider multiplexing, and contract interaction. The kokoro-mm Polygon adapter also uses alloy for EVM chain interaction.

**ethers and k256** are retained in the polymarket-bot for ECDSA signing of EIP-712 structured data — specifically for signing Polymarket CLOB orders. EIP-712 defines how Ethereum wallets sign off-chain typed data in a way that is verifiable on-chain; k256 provides the secp256k1 elliptic curve primitives needed to produce these signatures.

**solana-sdk 2.2** handles Solana transaction construction, keypair management, and RPC interaction in the wallet-monitor service, which tracks Solana wallet activity and DEX interactions.

**anchor-lang 0.30.1** is the Solana program development framework used to build kokoro-protocol's 20 on-chain programs. Anchor generates the account validation, serialization boilerplate, and IDL (Interface Definition Language) file that TypeScript clients use to call programs. Version 0.30.1 is current as of the time of writing.

**jsonwebtoken** generates and validates JWT (JSON Web Tokens) for session authentication across all API servers. JWTs are stateless bearer tokens — the server encodes claims (user ID, tier, expiry) into a signed token, eliminating the need for a session database lookup on every authenticated request.

**argon2** handles password hashing in kokoro-mm and kokoro-vpn. Argon2id is the winner of the Password Hashing Competition and is the current NIST recommendation; it provides configurable memory, parallelism, and iteration cost parameters that make brute-force attacks computationally infeasible.

**hmac and sha2** implement HMAC-SHA256, used for authenticating requests to the Polymarket CLOB API, which requires a keyed message authentication code on each API call.

**aes-gcm** and **hkdf** together implement the wallet key management in kokoro-mm. Wallet private keys are encrypted at rest using AES-256-GCM (Authenticated Encryption with Associated Data), and each user's encryption key is derived from a master key using HKDF-SHA256 (HMAC-based Key Derivation Function). This means compromising a single user's derived key does not expose the master key or other users' keys — a standard defense-in-depth pattern for multi-tenant key management.

### Mathematics and Signal Processing

The quantitative layer of alpha-lab relies on a carefully selected set of scientific computing crates, each serving a distinct mathematical role.

**nalgebra 0.34** is the linear algebra library underlying the entire signal processing stack. It provides dense matrix and vector types with statically-verified dimensionality, used for: Kalman filter state transition matrices and covariance updates; Markowitz Mean-Variance Optimization via Cholesky decomposition of the covariance matrix; Unscented Kalman Filter (UKF) sigma point generation; and Particle Filter resampling weight normalization.

**statrs 0.18** provides statistical distribution implementations — Normal, Student-t, Chi-squared — with CDF (Cumulative Distribution Function), PDF (Probability Density Function), and quantile functions. These are used in Value-at-Risk calculations (where the Normal or Student-t quantile determines the loss threshold at a given confidence level) and in hypothesis testing within the signal evaluation pipeline.

**rustfft** provides Fast Fourier Transform computation for pairwise factor correlation analysis and the Hilbert transform, which converts a real-valued time series into its analytic signal representation (useful for instantaneous amplitude and phase extraction in cyclical markets).

**good_lp 1.8** with the `minilp` feature provides a linear programming solver for portfolio optimization problems that require hard allocation constraints, such as maximum per-asset weight bounds or sector exposure limits. LP solvers are more appropriate than gradient-based optimizers for these piecewise-linear constrained problems.

**rand 0.8** provides cryptographically-seeded pseudo-random number generation for Monte Carlo simulation (option pricing, scenario generation), particle filter resampling, and random search in hyperparameter optimization.

**criterion 0.5** is the benchmarking framework used to measure pipeline latency, compiled as `pipeline_bench.rs`. Criterion performs statistically rigorous timing measurements, using Welch's t-test to determine whether observed performance differences are statistically significant rather than noise.

**petgraph** provides directed graph data structures and algorithms used in wallet-monitor for fund-flow graph analysis. Transaction graphs between wallets are represented as directed graphs; Louvain community detection identifies clusters of wallets that move funds together, which is a primary signal for Sybil identification.

### Error Handling and Observability

**anyhow 1.x** and **thiserror 2.x** are used together following a deliberate boundary: anyhow provides ergonomic `Result<T>` propagation inside application code (using the `?` operator to convert any error into a boxed `anyhow::Error`), while thiserror derives typed error enums at crate API boundaries where callers need to match on specific error variants.

**tracing 0.1 and tracing-subscriber 0.3** provide structured, span-based logging across all Rust services. The tracing crate allows code to emit events with structured key-value fields (`tracing::info!(order_id = %id, side = %side, "order accepted")`) and to open spans that represent units of work. The tracing-subscriber layer collects these events and formats them as JSON log lines or human-readable output, with full span context preserved. This structured approach is essential for correlating log events across concurrent async tasks where traditional line-based logging loses context.

**chrono 0.4** handles all datetime arithmetic: timestamp conversion between Unix milliseconds and `NaiveDateTime`, candle period boundary calculation, and cron-style scheduling for periodic rebalancing tasks.

**clap 4.x** provides declarative CLI argument parsing, used in kokoro-vpn and equivalent tools. Clap derives the argument structure from Rust structs and enums, generating help text and error messages automatically.

**uuid 1.x** generates Version 4 (random) UUIDs for order identifiers, position identifiers, and session tokens throughout the platform. UUIDs are 128-bit random identifiers with negligible collision probability and are safe to generate in distributed systems without coordination.

---

## 3. The TypeScript and JavaScript Ecosystem

### Frontend Framework Architecture

All user-facing interfaces are built on **Next.js** versions 15.x and 16.x, using **React 19.x** as the underlying UI library. Next.js was chosen over plain React for several practical reasons: its file-system-based routing eliminates boilerplate router configuration; its built-in API routes allow lightweight backend logic (like proxy routes for CORS management) to live alongside the frontend; and its static export mode (`next export`) enables the kokoro-tech marketing site to be deployed as a simple directory of HTML, CSS, and JavaScript files with no Node.js process required at runtime. React 19 introduces concurrent rendering features that improve perceived performance for data-intensive trading dashboards.

**Vite 6.x** is used as the build tool for kokoro-vpn's desktop client, where the Tauri integration requires a different build pipeline than Next.js provides. Vite's near-instant hot module replacement and fast production builds make it the preferred choice outside the Next.js context.

### UI Component Architecture

The UI component strategy is layered: **Radix UI** primitives (`@radix-ui/*` packages) provide unstyled, accessibility-compliant interactive components — Dialog, Dropdown Menu, Tooltip, Switch, Tabs, Select, and others — while **shadcn/ui** applies pre-designed Tailwind CSS styles on top of Radix in the alpha-lab frontend. This separation of behavior (Radix) from styling (Tailwind) means that accessibility guarantees (keyboard navigation, ARIA attributes, focus management) are provided by a well-tested library while visual design remains fully customizable.

**Tailwind CSS v4** is the utility-first CSS framework used across all frontends. Version 4 introduces a new CSS-native configuration system that removes the `tailwind.config.js` file in favor of CSS custom properties, reducing build toolchain complexity. Tailwind's utility class approach is particularly effective for trading interfaces where dense, information-rich layouts require precise spacing and typography control that semantic CSS abstractions make difficult.

**Framer Motion** provides declarative animation primitives used for scroll-triggered animations on the kokoro-tech marketing site and UI transitions in the trading dashboards. Framer Motion's layout animation system handles animated list reordering and component mount/unmount transitions without manual keyframe management.

**Three.js** appears in the technology stack inventory as a 3D rendering capability, reflecting familiarity with WebGL-based visualization.

**@tauri-apps/api v2** is the bridge between the kokoro-vpn's JavaScript frontend and the native Rust backend process managed by the Tauri framework. Tauri builds desktop applications by embedding a web view for the UI and a Rust binary for native system access, achieving native performance for VPN tunnel management while using a web-based UI toolkit.

### Data Visualization and Charting

The data visualization stack is intentionally diverse because different chart types require fundamentally different rendering approaches.

**lightweight-charts 5.x** (TradingView's open-source charting library) renders OHLC candlestick charts and price series in the alpha-lab frontend and kokoro-mm tick page. Lightweight-charts uses an HTML5 Canvas renderer optimized for financial time series — it can render thousands of candlesticks at 60 frames per second while streaming live tick updates, which a DOM-based SVG renderer cannot achieve.

**Recharts 2.x and 3.x** provides React component wrappers for common dashboard chart types — line charts, area charts, bar charts — used for P&L visualization and equity curve displays. Recharts renders to SVG and integrates naturally with React's data flow model.

**Chart.js 4.x with react-chartjs-2** provides a second general-purpose charting option in the alpha-lab frontend, used for chart types where Chart.js's rendering model is more convenient than Recharts.

**Plotly.js 3.x with react-plotly.js** handles scientific and quantitative visualizations: scatter plots with regression lines, heatmaps for correlation matrices, and statistical distribution plots. Plotly's built-in support for logarithmic scales, error bars, and multi-axis layouts makes it appropriate for quant research output.

**D3 7.x** is used for custom data visualizations where neither Recharts nor Plotly provides sufficient control. D3 operates at the level of SVG elements and data binding — it is more verbose than chart libraries but enables arbitrary visualization designs.

**@xyflow/react (React Flow) 12.x** provides the node-graph canvas editor used in kokoro-mm's strategy builder and kokoro-pipeline's workflow designer. React Flow renders an interactive directed graph where nodes represent strategy components and edges represent data flow — a visual programming paradigm for composing trading strategies from modular building blocks.

### State Management and Real-Time Data

**Zustand 5.x** manages client-side application state in kokoro-mm, where multiple UI components need shared access to strategies, open orders, active rounds, current positions, and live tick data. Zustand uses a minimal store API — a store is a plain JavaScript object with getter and setter functions — that avoids the boilerplate of Redux while providing the same predictable state update semantics.

**SWR 2.x** (Stale-While-Revalidate) handles data fetching with automatic caching, deduplication, and background revalidation in kokoro-mm hooks. SWR's model is simple: return cached data immediately, revalidate in the background, and update the UI when fresh data arrives. This gives trading interfaces a fast initial render without stale data persisting indefinitely.

**EventSource (native browser API)** with a custom exponential backoff reconnect implementation provides the alpha-lab frontend's real-time streaming data connection via Server-Sent Events. The `useSSE` hook wraps the native EventSource with automatic reconnection, making the connection resilient to network interruptions without the bidirectional complexity of WebSocket.

### MCP and AI Tool Integration

**@modelcontextprotocol/sdk 1.12+** implements the Model Context Protocol server that exposes platform capabilities to AI agents. The lab-mcp repository implements 98 MCP tools; the kokoro-mm MCP service implements 17 tools — 115 total across the ecosystem. MCP allows AI agents to call platform APIs (run a backtest, fetch signal history, deploy a bot, check system health) as tool calls within a conversation, enabling AI-assisted trading strategy development and platform management.

**Zod 3.x** validates the input schema for every MCP tool at runtime. Zod schemas define the exact shape and type constraints for tool arguments, and validation errors are returned to the AI caller as structured error messages that can be corrected and retried.

### Node.js Backend and CMS

**Express** serves the API layer in kokoro-pipeline's developer console. **Prisma** provides a type-safe PostgreSQL ORM with 30+ data models for the pipeline's marketplace, billing, and workflow management features — a higher-level abstraction than sqlx is appropriate here because kokoro-pipeline is a developer tooling product rather than a low-latency financial service.

**Payload CMS 3.77** is the headless content management system backing the happykokoro.com website. Payload provides a self-hosted admin interface for managing site content and handles the contact form submission pipeline, forwarding messages via the Resend email adapter.

**Commander** provides CLI argument parsing for the kokoro-pipeline command-line interface.

**Stripe** handles billing and payment processing in the kokoro-pipeline marketplace, managing subscription tiers, usage-based billing, and webhook-based payment event processing.

### Testing Infrastructure

**Vitest** runs unit tests for the kokoro-mm frontend and kokoro-tech. Vitest uses the same configuration file format as Vite and has a Jest-compatible API, making migration from Jest straightforward while providing faster test execution through Vite's transform pipeline.

**@testing-library/react** provides component testing utilities that query the DOM by accessibility role, label text, and visible content rather than by CSS selector or component internals — encouraging tests that verify user-visible behavior rather than implementation details.

**Playwright** runs end-to-end browser tests against the happykokoro.com website, automating real browser interactions to verify that the contact form, navigation, and rendering all work correctly in a real browser environment.

---

## 4. The Python Ecosystem

### Web Framework and API Layer

**FastAPI** serves as the REST API framework for the polymarket-bot strategy service (running on port 8100) and the kokoro-copy-trader (port 4500). FastAPI is built on Starlette and Pydantic and provides automatic OpenAPI documentation generation, type-annotated request and response models, and native async support via Python's `asyncio`. It is the clear choice for Python API servers that need to coexist with CPU-bound scientific computing.

**Uvicorn** is the ASGI server that runs FastAPI applications. ASGI (Asynchronous Server Gateway Interface) is the modern successor to WSGI, enabling true async request handling in Python web applications.

**Pydantic v2** handles all request and response validation. Pydantic v2 is a ground-up rewrite of v1 with a Rust-based validation engine (`pydantic-core`), providing dramatically faster validation for high-throughput API endpoints.

### Quantitative Finance Libraries

The Python quant layer assembles a standard but carefully chosen scientific stack.

**arch** fits GARCH(1,1) models to volatility time series using Maximum Likelihood Estimation. GARCH(1,1) — Generalized Autoregressive Conditional Heteroskedasticity — models the time-varying variance of financial returns, capturing the empirical phenomenon of volatility clustering where large price moves tend to follow large price moves. This model is used in the polymarket-bot strategy service to estimate current market volatility for position sizing.

**scipy.stats** provides the Student-t distribution CDF and other statistical functions. The Student-t distribution has heavier tails than the Normal distribution and better fits financial return distributions, particularly important for tail risk estimation.

**scikit-learn (sklearn)** provides Principal Component Analysis (PCA) for factor model decomposition in the polymarket-bot. PCA decomposes a matrix of correlated market features into uncorrelated principal components, reducing dimensionality and identifying the dominant risk factors driving price movements.

**nolds** calculates the Hurst exponent, which measures the long-range dependence and fractal characteristics of a time series. A Hurst exponent above 0.5 indicates a trending series; below 0.5 indicates mean-reversion. This metric is used to classify market regimes and select appropriate strategy modes.

**pywt** provides wavelet transforms for time-frequency analysis of price series. Unlike the Fourier transform, which decomposes a signal into pure sinusoids, the wavelet transform provides a time-localized frequency decomposition — useful for detecting regime changes where the dominant frequency content of a market shifts.

**numpy** is the foundational numerical computing library, providing the array primitives and linear algebra routines that all other scientific Python libraries build upon.

### Blockchain and Trading Clients

**py-clob-client** is the official Polymarket CLOB (Central Limit Order Book) API client for Python, used in kokoro-copy-trader to place, cancel, and monitor orders on the Polymarket prediction market exchange.

**httpx** provides async HTTP client capabilities equivalent to Python's requests library but with full `asyncio` support, used for outbound API calls in the Python services.

**websockets** manages WebSocket connections for real-time market data feeds in the Python trading services.

### Orchestration and Templating

**aiosqlite** provides async SQLite access for the agent-orchestra dashboard, storing agent run history, worktree states, and pipeline execution records without blocking the async event loop.

**PyYAML** parses the YAML team definition files that agent-orchestra uses to configure multi-agent pipelines — specifying which agents to spawn, their roles, and the coordination protocol between them.

**Jinja2** renders the HTML dashboard served by agent-orchestra, templating dynamic data (agent status, worktree states, approval cards) into the web interface.

---

## 5. The Go Ecosystem

The kokoro-staking backend is the primary Go project, and its dependency graph reflects Go's strengths in networked, concurrent systems.

**Gin** is the HTTP framework, providing a minimal but fast router for the staking API. Gin's context-based middleware composition and clean handler signature make it the most popular Go web framework for API-first services.

**pgx/v5** is the high-performance PostgreSQL driver, used directly rather than through a Go ORM. Like sqlx in Rust, pgx provides prepared statement support and connection pooling at the driver level.

**go-ethereum** provides Ethereum chain interaction capabilities for the staking service, which needs to read on-chain staking contract state and submit transactions.

**Cobra** provides the CLI framework for any command-line tooling in the Go ecosystem.

**shopspring/decimal** is a critical dependency for a financial application: Go's native `float64` type uses IEEE 754 floating-point arithmetic, which introduces rounding errors in financial calculations (0.1 + 0.2 ≠ 0.3 in floating-point). The shopspring/decimal package provides arbitrary-precision decimal arithmetic that handles financial rounding correctly.

**errgroup** (from `golang.org/x/sync`) enables concurrent goroutine groups where partial failures are collected and returned together. The staking backend uses this for fan-out cross-chain queries — querying 13+ blockchain networks simultaneously where any subset may time out or return errors — with a single clean failure boundary.

**Zap** provides structured JSON logging from Uber's engineering team, analogous to the `tracing` crate in the Rust services.

**Prometheus** client library instruments every RPC call in the staking service with request duration histograms and error counters, feeding the centralized Prometheus scrape endpoint.

---

## 6. Solana and Blockchain Infrastructure

### On-Chain Program Architecture (kokoro-protocol)

The kokoro-protocol repository contains 20 Solana programs written in Rust using the **Anchor 0.30.1** framework. Anchor dramatically reduces the boilerplate required to write Solana programs: it provides the `#[program]` and `#[derive(Accounts)]` macros that automatically generate account ownership validation, signer verification, and discriminator checking — the most common source of security vulnerabilities in hand-written Solana programs.

The 20 programs are organized into five functional categories. The six infrastructure programs — `platform_treasury`, `platform_token`, `user_vault`, `house_pool`, `reward_pool`, and `governance` — form the financial backbone: token minting and redemption, user fund custody, liquidity pool management, and on-chain governance voting. The five DeFi programs — `dex_amm`, `lending_protocol`, `yield_vaults`, `liquidation_engine`, and `leveraged_betting` — implement core DeFi primitives. The seven casino and gaming programs provide provably fair game logic for dice, crash, coin flip, slots, sports betting, d20 rolls, and escrow management. The prediction market program and NFT auction program complete the suite.

**SPL Token** and **SPL Associated Token Account** are the Solana Program Library standards for fungible tokens and user token accounts, used throughout the protocol for the platform token mint and redemption flows.

### DEX Integration Layer

The wallet-monitor and pricing-service interact with four Solana DEXes through direct account state parsing and API integration.

**Jupiter V6** is Solana's dominant swap aggregator, and the integration covers its swap routing API, quote API with slippage estimation and depth analysis, and execution path selection. Jupiter routes swaps across all major Solana liquidity sources, so integrating Jupiter effectively integrates the entire Solana DeFi liquidity landscape.

**Raydium AMM** integration parses pool account state directly from the Solana ledger to detect swap transactions and read current pool prices.

**Orca Whirlpool** integration tracks concentrated liquidity positions and detects swap events in the Orca concentrated liquidity AMM.

**Pump.fun** is monitored by program ID detection — the wallet-monitor identifies when wallets interact with the Pump.fun memecoin launchpad, which is a meaningful signal about wallet risk appetite.

**Uniswap V3** integration appears in the liquidation-bot, which uses `exactInputSingle` for collateral-to-debt asset swaps as part of the flash liquidation path. The integration uses QuoterV2 on-chain quotes for accurate pre-trade price estimation and handles fee tier selection (0.05%, 0.3%, 1%) based on the asset pair being swapped.

### EVM Chain Coverage

The liquidation-bot monitors undercollateralized positions across six EVM-compatible chains. **Ethereum mainnet** runs Aave V3 and Compound V3. **Base** runs four protocols: Aave V3, Seamless (an Aave V3 fork with its own parameter set), Compound V3, and Moonwell (a Compound V2 fork with Base-native incentives). **Arbitrum** and **Polygon** each run Aave V3 and Compound V3. **Optimism** and **Avalanche** both run Aave V3. The pluggable `ProtocolAdapter` trait in the liquidation-bot codebase allows new protocols and chains to be added without modifying the core execution or discovery logic.

### Prediction Market Integrations

**Polymarket** is integrated at two levels. The CLOB (Central Limit Order Book) API integration is the deepest: it covers REST endpoint scanning for market discovery, WebSocket streaming for real-time order book updates, EIP-712 typed data signing for order construction, HMAC-SHA256 authentication for private endpoints, fill detection, and CTF (Conditional Token Framework) operations — `splitPosition`, `mergePositions`, and `redeem` — for managing binary outcome tokens on Polygon. The Gamma API provides higher-level market metadata and round discovery. This integration depth is present in both kokoro-mm and kokoro-polymarket-bot.

**Kalshi** and **Manifold** are integrated as venue router adapters in kokoro-mm's market provider abstraction layer, enabling the strategy engine to route orders to the most favorable liquidity venue across multiple prediction markets.

### Exchange Data Feed Architecture

The system ingests market data from five external sources, each serving a distinct data role. **Binance** provides spot prices, perpetual futures funding rates, open interest, and funding rate predictions via both WebSocket streams (for real-time tick data) and REST endpoints (for historical data). **Coinbase** provides spot reference prices via REST. **Deribit** streams options implied volatility data via WebSocket, which feeds the options pricing models in alpha-lab. **Pyth Network** provides oracle price feeds for both on-chain and off-chain consumption, used as reference prices in strategy logic. **Alpaca** provides equity market bar data and real-time quotes via both REST and WebSocket, consumed by the `exec-alpaca` crate in alpha-lab.

### WASM Strategy Plugin System

Alpha-lab implements a WebAssembly-based plugin architecture for user-compiled strategy factors, consisting of three components. The `wasm32-unknown-unknown` compilation target allows Rust code to be compiled to WASM bytecode without any system dependencies. The `factor-sdk` crate provides the `kokoro_factor!` macro, which generates the WASM export function signatures and boilerplate needed for a user's factor function to be callable from the host runtime. The `factor-wasm` crate hosts compiled WASM modules at runtime as native `AlphaFactor` trait objects, using a WASM runtime (such as Wasmtime or Wasmer) to execute sandboxed user code within the alpha-lab signal pipeline. This architecture allows users to write custom alpha factors in Rust, compile them to WASM, and upload them to the platform without ever running untrusted native code.

---

## 7. Database and Storage Architecture

The storage layer uses three complementary databases, each selected for a specific access pattern.

**PostgreSQL 16** is the primary OLTP (Online Transaction Processing) database for all persistent, relational data. In alpha-lab it stores backtest results, portfolio events, and position history. In kokoro-mm it manages 21 query modules covering strategies, orders, rounds, positions, wallet keys, user accounts, and billing data, with 58 migration pairs tracking the schema evolution. In kokoro-staking it stores staking positions and reward calculations. In kokoro-pipeline it backs the Prisma ORM with 30+ models for marketplace, billing, and user management. PostgreSQL 16 was chosen for its mature ACID guarantees, rich query planner, JSONB support for schema-flexible data, and the excellent Rust (sqlx) and Go (pgx) driver ecosystems.

**Redis 7.x** serves as the message bus and real-time event backbone. The alpha-lab architecture uses 10 named Redis Streams — one per data domain (signals, candles, fills, portfolio events, etc.) — with consumer groups managed via `XREADGROUP` and `XACK`. Consumer group semantics ensure that each message is processed exactly once per consumer group, and that unacknowledged messages are redeliverable after a timeout if a consumer crashes. Kokoro-mm uses Redis pub/sub for broadcasting real-time events to the SSE (Server-Sent Events) endpoint that frontend clients subscribe to. The dual-format proto migration added Protocol Buffer encoding alongside JSON on all 10 streams, enabling a zero-downtime codec migration.

**SQLite** is used for lightweight, single-process persistence where PostgreSQL's client-server architecture would add unnecessary operational complexity. The polymarket-bot stores trade history and signal records in SQLite via rusqlite. Kokoro-vpn uses sqlx with SQLite for its tunnel and peer configuration database. Kokoro-copy-trader and the happykokoro.com Payload CMS instance also use SQLite.

**JSONL (JSON Lines)** append-only event logs provide an immutable audit trail for the alpha-lab event store and liquidation-bot P&L recording. Appending to a file is faster than any database write for high-frequency event recording, and JSONL files are trivially processable by standard Unix tools and Python scripts.

---

## 8. Infrastructure and DevOps

### Containerization and Service Orchestration

Every production service runs in a Docker container with a multi-stage build: the first stage compiles the Rust binary (or Node.js bundle) in a full build environment; the second stage copies only the compiled binary and runtime dependencies into a minimal base image, producing containers that are typically under 100MB. This dramatically reduces attack surface and image pull times.

**Docker Compose** orchestrates services on all three production servers. The kokoro-services repository defines 11 utility containers (the self-hosted services described below). Each application repo has its own `docker-compose.yml` for local development and production deployment.

**Caddy** handles reverse proxying and automatic TLS on the AWS Ireland server running kokoro-mm. Caddy integrates with Let's Encrypt automatically: it requests, receives, and renews TLS certificates without configuration, eliminating the manual certificate rotation work that Nginx requires.

**Nginx** handles reverse proxying on the main DigitalOcean server, where the more complex multi-service routing and existing configuration warranted its continued use.

**PM2** manages Node.js process lifecycles for any Node.js services that run outside Docker, providing process supervision, log aggregation, and automatic restart on crash.

**systemd** manages long-running native service processes — the VPN daemon and certain bot processes — at the operating system level.

### Continuous Integration and Deployment

Every repository runs **GitHub Actions** CI pipelines triggered on push and pull request. Rust pipelines execute `cargo build --release`, `cargo clippy -D warnings` (treating all lint warnings as errors), `cargo fmt --check` (enforcing consistent formatting), `cargo deny check` (license compliance and vulnerability audit), and the full test suite. TypeScript pipelines run `npm run build` and test suites. These gates prevent untested or lint-failing code from being merged.

Deployment tooling is appropriately minimal. **rsync** deploys the kokoro-tech static site by synchronizing the built output directory to the production server. **SCP** deploys compiled binaries for the copy-trader and liquidation-bot. Neither approach requires a container registry or deployment platform for services where simplicity is more valuable than rollback sophistication.

**cargo-deny** deserves particular mention as a CI gate: it checks all transitive Rust dependencies against known vulnerability databases and license compatibility matrices, ensuring that no dependency with a security advisory or an incompatible license can be merged into the codebase.

### Infrastructure as Code

**Terraform** provisions the DigitalOcean droplets and AWS EC2 instances used in production, with the kokoro-vpn infrastructure as the primary managed resource. Infrastructure as code ensures that server configurations are reproducible and version-controlled.

### Monitoring and Observability

The observability stack provides full-stack visibility from individual request latency to service health.

**Prometheus** scrapes metrics from all Rust services via the tower-http metrics middleware, which automatically instruments every HTTP request with duration histograms, status code counters, and in-flight request gauges. The Go staking service also instruments every RPC call individually. Prometheus stores metrics as time-series data optimized for range queries and alerting.

**Grafana** visualizes Prometheus metrics as dashboards, with the primary oncall latency dashboard available at `grafana.internal/d/api-latency`. Grafana's alerting system fires notifications when latency or error rate thresholds are breached.

**OpenTelemetry** provides distributed tracing, allowing a single user request to be followed across service boundaries — from the frontend through the REST API through the gRPC internal service call — as a single trace with timing for each span.

**Uptime Kuma** (self-hosted, port 3003) monitors service availability by making periodic HTTP health checks against all production endpoints, providing uptime history and alerting on downtime.

**Umami** (self-hosted, port 3001) provides GDPR-compliant web analytics for the public-facing frontends without sending user data to third-party analytics services.

### Networking and Security Architecture

The three production servers — DigitalOcean Singapore, AWS Ireland, and AWS London — are connected by a **WireGuard** VPN mesh. WireGuard operates in two topologies: a hub-and-spoke mode (10.8.0.0/24) where all traffic flows through a central node, and a full-mesh mode (10.10.0.0/24) where each server maintains direct tunnels to all others. WireGuard's cryptographic design uses Noise Protocol Framework handshakes with Curve25519 key exchange and ChaCha20-Poly1305 encryption, providing modern authenticated encryption with significantly less attack surface than OpenVPN or IPSec.

**Cloudflare** sits in front of all public-facing services, providing DNS resolution, CDN edge caching, and DDoS attack mitigation. Cloudflare's network absorbs volumetric attacks before they reach the origin servers.

**Let's Encrypt** (via Caddy's ACME integration) manages TLS certificate lifecycle automatically, ensuring all HTTPS connections use valid, up-to-date certificates without manual intervention.

The authentication and key management stack is defense-in-depth: **TOTP RFC 6238** provides time-based one-time passwords for two-factor authentication in kokoro-mm; **AES-256-GCM** encrypts wallet private keys at rest; **HKDF-SHA256** derives per-user encryption keys from a master secret; **Argon2id** hashes passwords with configurable memory and CPU cost; **JWT** provides stateless session tokens; and **HMAC-SHA256** authenticates API calls to external services.

**Flashbots** MEV protection is used for Ethereum liquidation transactions in the liquidation-bot. Flashbots allows transactions to be submitted to validators privately via a bundle submission mechanism, bypassing the public mempool and preventing front-running bots from detecting and sandwiching profitable liquidation transactions.

**SOPS** (Secrets OPerationS) manages encrypted configuration files, allowing secrets to be stored in version control in encrypted form and decrypted at deployment time using cloud key management service keys.

### Self-Hosted Service Ecosystem

The kokoro-services repository defines eleven self-hosted utility services running on the DigitalOcean server, each serving a specific internal operational need. **Umami** (port 3001) provides privacy-first web analytics. **Gitea** (port 3002) is a self-hosted Git server for repositories that should not be publicly accessible. **Uptime Kuma** (port 3003) monitors all service endpoints. **Excalidraw** (port 3004) is a collaborative whiteboard for architecture diagrams. **Homepage** (port 3005) is a service dashboard aggregating status across all internal tools. **Shlink** with its web UI (ports 8080 and 8081) provides URL shortening for internal links. **PrivateBin** (port 8082) is an encrypted paste bin for sharing sensitive text internally. **Linkding** (port 9090) is a self-hosted bookmark manager. **Syncthing** (port 8384) handles file synchronization between development machines and servers.

### Cloud Infrastructure

The production infrastructure spans two cloud providers across three regions.

The **DigitalOcean** server (4 vCPU / 8 GB RAM, Singapore region) is the main production hub, hosting the alpha-lab Lab, Engine, and Platform services, the Next.js frontend, the lab-mcp server, the payment service, Prometheus, Grafana, and all the self-hosted utility services described above. Its Singapore location provides low latency to Southeast Asian users and acceptable latency to the Asian cryptocurrency markets the alpha-lab monitors.

Two **AWS EC2** instances handle the remaining services. A `t3.medium` (2 vCPU / 4 GB RAM) in the Ireland (`eu-west-1`) region runs kokoro-mm and kokoro-polymarket-bot, with low latency to European Polymarket users and the AWS network backbone. A `t3.small` (2 vCPU / 2 GB RAM) in the London (`eu-west-2`) region runs kokoro-copy-trader and stores market data, co-located with the AWS London zone for proximity to UK financial market data sources.

---

## 9. AI, Machine Learning, and Agent Infrastructure

### AI coding agent Integration Architecture

The ecosystem has deep integration with AI coding agent as an AI development tool and autonomous agent platform. The **AI coding agent CLI** is the primary development interface, used with the `--dangerously-skip-permissions` flag to enable fully autonomous operation in non-interactive pipeline mode.

The **Model Context Protocol (MCP)** server infrastructure exposes 115 platform tools to AI agents across two MCP servers: 98 tools in lab-mcp and 17 tools in kokoro-mm's embedded MCP service. These tools cover the full operational surface of both platforms — running backtests, inspecting signal history, deploying bots, checking system health, managing strategies, and monitoring positions. AI agents can invoke these tools as function calls within a conversation, enabling AI-assisted strategy development where the AI can iteratively run experiments, observe results, and refine strategies without human intervention at each step.

**AI coding agent Skills** are custom workflow definitions (following the SKILL.md protocol) that encode complex multi-step operations: `dev-pipeline` for parallel multi-agent code generation, `signal-pipeline` for signal processing workflows, `risk-management` for portfolio risk analysis, `kalman-filter` for filter configuration, `polymarket-arbitrage` for arbitrage opportunity analysis, `anchor-patterns` for Solana program patterns, and `dex-integration` for DEX adapter implementation.

**agent-orchestra** is the multi-agent coordination platform, running orchestrated AI coding agent agent teams — feature-dev (3-agent architect/implementer/reviewer), build-fix (single-agent focused compilation), code-review, debug, and research — across parallel git worktrees with automated merge, build, and test pipelines. The General Manager (GM) module automates the full lifecycle: launch → wait → analyze → merge → build → test, with an approval gate that pauses for human decision on merge conflicts or test failures.

### AI and Machine Learning Techniques

The alpha-lab signal processing pipeline implements several machine learning and statistical techniques directly in Rust.

The **DQN (Deep Q-Network)** implementation in the `factor-ai` crate includes an experience replay buffer for breaking correlation between training samples, a Q-network for action-value estimation, and epsilon-greedy exploration for balancing exploitation of known good actions against exploration of new ones. This reinforcement learning agent can learn trading policies from simulated market experience.

The **LLM Integration** in the `copilot` crate provides four AI-assisted tools: a factor advisor that explains why a given factor is or is not generating signal, a risk explainer that translates portfolio risk metrics into natural language, a strategy generator that proposes new strategy configurations from performance data, and a trace analyzer that diagnoses why a strategy is underperforming.

**Conformal Prediction** provides statistically calibrated prediction intervals in both alpha-lab and kokoro-mm. Rather than returning a point prediction, conformal prediction returns a set of outcomes that contains the true outcome with a user-specified coverage probability (95% by default). This is achieved through a rolling calibration set that tracks historical prediction errors and sets quantile-based bounds on future predictions.

**Expert Aggregator** (in the `prediction` crate) implements the Hedge algorithm — a multiplicative weights update rule — to combine predictions from multiple independent forecasting models. Each model's weight is updated multiplicatively based on its prediction errors, applying an exponential loss penalty for confident wrong predictions. This ensemble approach is more robust than any single forecasting model.

**PCA factor decomposition** in the polymarket-bot Python strategy service uses scikit-learn to reduce a high-dimensional feature set (derived from market data) into a small number of uncorrelated principal components, improving model generalization by removing multicollinearity.

---

## 10. Protocols and Standards

The ecosystem implements and adheres to a comprehensive set of networking, financial, and security standards.

**EIP-712** (Ethereum Improvement Proposal 712) defines the typed structured data signing scheme used for Polymarket CLOB order construction. EIP-712 allows Ethereum accounts to sign off-chain structured data — such as a limit order with price, size, and expiry — in a format that is both human-readable in wallet UIs and verifiable on-chain. This is the standard for all decentralized exchange order signing.

**ERC-1155** is the multi-token standard governing Conditional Token Framework (CTF) position tokens on Polygon — the on-chain representation of Polymarket prediction market positions. Each market outcome is a distinct ERC-1155 token ID.

**gRPC** with **Protocol Buffers proto3** provides the internal service communication bus between the Lab, Engine, and Platform services in alpha-lab, as well as the dual-format Redis Streams serialization layer.

**SSE (Server-Sent Events)** and **WebSocket** cover the real-time data streaming requirements, with SSE used for server-to-client push (signal updates, tick data, news feeds) and WebSocket used for bidirectional exchange data feeds.

**JSON-RPC** is the wire protocol for Ethereum and Solana RPC node communication — the standard interface exposed by all EVM nodes (via Infura, Alchemy, or public providers) and Solana validators.

**TOTP RFC 6238** implements the time-based one-time password algorithm for two-factor authentication, generating a 6-digit code that changes every 30 seconds based on the current Unix time and a shared secret.

**FIX Protocol** is stubbed in kokoro-mm Phase 8 scope for institutional connectivity. FIX (Financial Information eXchange) is the industry standard messaging protocol for institutional order routing and execution reporting.

**SCIM 2.0**, **SAML**, and **OIDC** are specified in kokoro-pipeline's enterprise features for identity provisioning and single sign-on.

**IERC3156** is the ERC standard for flash loan callback interfaces, implemented by the `FlashLiquidator.sol` contract in the liquidation-bot. IERC3156 defines the `onFlashLoan` callback signature that flash loan providers (Aave, Morpho) call after disbursing the loan, within which the borrower must execute their arbitrage or liquidation logic and repay the loan plus fee.

---

## 11. Scale and Totals

To close, a summary of the ecosystem's breadth.

Seven programming languages are in active production use: Rust, TypeScript, Python, Go, Solidity, SQL, and Shell. The Rust workspace carries 50 or more unique crate dependencies; the npm packages across all frontends number 80 or more; the Python library count stands at 15 or more; and the Go module count is 8 or more.

Three databases serve the storage layer: PostgreSQL 16 for relational persistence, Redis 7 for message streaming and real-time events, and SQLite for lightweight embedded persistence.

Eight blockchain networks are actively monitored or transacted on: Ethereum, Base, Arbitrum, Polygon, Optimism, Avalanche, and Solana — with Cosmos and 13 additional chains via the kokoro-staking platform. Eight DeFi protocols are integrated: Aave V3, Compound V3, Seamless, Moonwell, Jupiter, Raydium, Orca, and Pump.fun. Five exchange integrations feed market data: Binance, Coinbase, Deribit, Pyth Network, and Polymarket. Twenty on-chain Anchor programs are deployed in kokoro-protocol.

The AI integration layer exposes 115 MCP tools to AI agents across two servers. The production deployment runs 12 or more Docker containers across two cloud providers (AWS and DigitalOcean) in three geographic regions (Singapore, Ireland, London), connected by a WireGuard VPN mesh and protected by Cloudflare at the edge.

The stack represents a coherent, production-tested architecture for a multi-product quantitative finance and decentralized finance platform, with deliberate language selection, defense-in-depth security, and full observability from request metrics to distributed traces.
