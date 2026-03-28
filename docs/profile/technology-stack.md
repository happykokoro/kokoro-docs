# Technology Stack — Complete Inventory

> Comprehensive catalog of every language, framework, library, tool, protocol, and service used across the Kokoro ecosystem. Organized by category with specific version numbers, usage context, and which projects employ each technology. Aligned with 2026 CNCF cloud-native standards.

---

## 1. Programming Languages

### Primary Languages (daily production use)

| Language       | Proficiency Level | Lines of Code | Projects                                                                                                                                                                      |
| -------------- | ----------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Rust**       | Expert            | ~264,000+     | kokoro-alpha-lab (242K), kokoro-mm (63K), kokoro-polymarket-bot (15.5K), kokoro-liquidation-bot (5.1K), kokoro-wallet-monitor, kokoro-pricing-service, kokoro-vpn, kokoro-pay |
| **TypeScript** | Expert            | ~100,000+     | kokoro-alpha-lab-frontend, kokoro-mm frontend, lab-mcp, kokoro-pipeline, kokoro-tech, kokoro-protocol (tests), kokoro-staking (frontend)                                      |
| **Python**     | Advanced          | ~10,000+      | agent-orchestra, claude-init, kokoro-copy-trader, kokoro-polymarket-bot (strategy service), research scripts                                                                  |
| **Go**         | Advanced          | ~15,000+      | kokoro-staking (full backend)                                                                                                                                                 |

### Secondary Languages (project-specific use)

| Language         | Context                                                                                  |
| ---------------- | ---------------------------------------------------------------------------------------- |
| **PHP**          | Laravel 11 enterprise projects, Blade templating, Composer                               |
| **Solidity**     | FlashLiquidator.sol (kokoro-liquidation-bot), on-chain contracts                         |
| **SQL**          | PostgreSQL schemas, SQLx migrations (58 migration pairs in kokoro-mm alone), raw queries |
| **Shell / Bash** | claude-dev-pipeline skill, deployment scripts, CI/CD workflows                           |
| **TOML**         | Cargo workspace configs, strategy artifact definitions                                   |
| **YAML**         | Docker Compose configs, GitHub Actions CI, agent-orchestra team definitions              |
| **Markdown**     | AI coding agent skills (SKILL.md protocol), documentation                                |
| **JavaScript**   | Legacy/utility scripts, agentPlan                                                        |

### Historical / Academic

| Language   | Context                                           |
| ---------- | ------------------------------------------------- |
| **Java**   | Listed in tech stack (Spring framework knowledge) |
| **C/C++**  | Listed in tech stack                              |
| **Dart**   | Listed in tech stack (Flutter knowledge)          |
| **Kotlin** | Listed in tech stack                              |
| **Pug**    | blockchain-demo fork                              |

---

## 2. Rust Ecosystem (Deep Expertise)

Rust is the primary systems language across the platform. As of 2026, Rust is described as "non-negotiable for serious HFT" in industry discourse, with the first TokioConf announced for 2026 and projects like MeV-RS demonstrating Rust's role in production DeFi MEV infrastructure. The platform's 330,000+ lines of production Rust represent a direct investment in this trajectory.

### Async Runtime & Networking

| Crate                  | Version   | Usage                                                                                                                                                    |
| ---------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tokio`                | 1.x       | De facto async runtime (28K+ GitHub stars, first TokioConf 2026). Features: `full` (rt-multi-thread, io, net, time, macros, sync, signal, fs)            |
| `axum`                 | 0.8       | HTTP framework for all REST APIs (alpha-lab, kokoro-mm, liquidation-bot, polymarket-bot, vpn, pricing-service). tower::Service middleware composability. |
| `tower` / `tower-http` | 0.4 / 0.6 | Middleware stack: CORS, rate limiting, tracing, compression, timeout — composable without modifying handler signatures                                   |
| `reqwest`              | 0.12      | HTTP client for external API calls (Binance, Polymarket, Alpaca, Pyth)                                                                                   |
| `tonic`                | 0.13      | gRPC server/client (alpha-lab Lab↔Engine↔Platform communication)                                                                                         |
| `prost`                | 0.13      | Protocol Buffer code generation for gRPC message types                                                                                                   |
| `hyper`                | 1.x       | Underlying HTTP implementation (via axum/reqwest)                                                                                                        |
| `tokio-tungstenite`    | —         | WebSocket client for exchange data feeds (Binance, CLOB, Deribit, Solana)                                                                                |

### Serialization & Data

| Crate        | Version | Usage                                                                                       |
| ------------ | ------- | ------------------------------------------------------------------------------------------- |
| `serde`      | 1.x     | Universal serialization framework. `#[derive(Serialize, Deserialize)]` on every domain type |
| `serde_json` | 1.x     | JSON encoding for REST APIs, Redis Streams, config files                                    |
| `toml`       | 0.8     | Strategy artifact config parsing (alpha-lab)                                                |
| `bincode`    | —       | Binary serialization for performance-critical paths                                         |
| `prost`      | 0.13    | Protobuf serialization for gRPC and Redis Streams dual-format                               |

### Database & Storage

| Crate      | Version | Usage                                                                                                                                                                               |
| ---------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sqlx`     | 0.8     | Async PostgreSQL driver (alpha-lab, kokoro-mm, kokoro-vpn). Compile-time query checking, migrations                                                                                 |
| `redis`    | 1.1     | Redis Streams pub/sub (custom fork with 0.27 compat). 10 active streams in alpha-lab                                                                                                |
| `rusqlite` | —       | SQLite for polymarket-bot (positions, signals, history) and kokoro-vpn                                                                                                              |
| `dashmap`  | 6.x     | Lock-free concurrent HashMap. Primary shared-state primitive across alpha-lab (signal-store, blackboard, correlation, portfolio-orchestrator) and liquidation-bot (known_borrowers) |

### Blockchain & Crypto

| Crate             | Version | Usage                                                                                                                             |
| ----------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `alloy`           | 1.x     | EVM interaction: contract calls, transaction building, ABI encoding via `sol!` macro (liquidation-bot, kokoro-mm polygon adapter) |
| `ethers` / `k256` | —       | ECDSA signing for EIP-712 orders (polymarket-bot LiveSigner)                                                                      |
| `solana-sdk`      | 2.2     | Solana transaction building, keypair management (wallet-monitor)                                                                  |
| `anchor-lang`     | 0.30.1  | Solana program framework (kokoro-protocol: 20 programs)                                                                           |
| `jsonwebtoken`    | —       | JWT token generation/validation (all API servers)                                                                                 |
| `argon2`          | —       | Password hashing (kokoro-mm, kokoro-vpn auth)                                                                                     |
| `hmac` / `sha2`   | —       | HMAC-SHA256 for Polymarket CLOB API authentication                                                                                |
| `aes-gcm`         | —       | AES-256-GCM wallet key encryption (kokoro-mm)                                                                                     |
| `hkdf`            | —       | HKDF-SHA256 per-user key derivation from master key (kokoro-mm)                                                                   |

### Mathematics & Signal Processing

| Crate       | Version | Usage                                                                                                            |
| ----------- | ------- | ---------------------------------------------------------------------------------------------------------------- |
| `nalgebra`  | 0.34    | Linear algebra: matrix operations for Kalman filters, Markowitz MVO (Cholesky decomposition), UKF sigma points   |
| `statrs`    | 0.18    | Statistical distributions: Normal, Student-t, Chi-squared CDF/PDF/quantile for VaR, hypothesis testing           |
| `rustfft`   | —       | FFT for pairwise factor correlation computation, Hilbert transform                                               |
| `good_lp`   | 1.8     | Linear programming (minilp feature) for portfolio optimization                                                   |
| `rand`      | 0.8     | RNG for Monte Carlo simulation, particle filter resampling, random search optimization                           |
| `criterion` | 0.5     | Benchmarking framework for pipeline performance testing                                                          |
| `petgraph`  | —       | Directed graph analysis: fund-flow graphs, Louvain community detection for Sybil identification (wallet-monitor) |

### Error Handling & Utilities

| Crate                            | Version   | Usage                                                               |
| -------------------------------- | --------- | ------------------------------------------------------------------- |
| `anyhow`                         | 1.x       | Application-level error handling (`Result<T>` throughout pipelines) |
| `thiserror`                      | 2.x       | Typed error enums at crate boundaries                               |
| `tracing` / `tracing-subscriber` | 0.1 / 0.3 | Structured logging with span-based context across all services      |
| `clap`                           | 4.x       | CLI argument parsing (kokoro-vpn, claude-init equivalent)           |
| `chrono`                         | 0.4       | Datetime handling for timestamps, candle aggregation, scheduling    |
| `uuid`                           | 1.x       | Unique identifiers for orders, positions, sessions                  |
| `once_cell` / `lazy_static`      | —         | Static initialization for registries and config                     |

### Testing

| Crate                                 | Version | Usage                                                 |
| ------------------------------------- | ------- | ----------------------------------------------------- |
| `tokio-test`                          | —       | Async test utilities                                  |
| `criterion`                           | 0.5     | Performance benchmarks (`pipeline_bench.rs`)          |
| `assert_approx_eq` / float comparison | —       | Floating-point tolerance testing for quant algorithms |

---

## 3. TypeScript / JavaScript Ecosystem

### Frontend Frameworks

| Package     | Version     | Usage                                                                                                               |
| ----------- | ----------- | ------------------------------------------------------------------------------------------------------------------- |
| `next`      | 15.x / 16.x | Primary frontend framework. alpha-lab-frontend (15), kokoro-mm (16), kokoro-tech (16), kokoro-staking frontend (16) |
| `react`     | 19.x        | UI library across all frontends                                                                                     |
| `react-dom` | 19.x        | DOM rendering                                                                                                       |
| `vite`      | 6.x         | Build tool for kokoro-vpn desktop app                                                                               |

### UI Component Libraries

| Package           | Version | Usage                                                                                                         |
| ----------------- | ------- | ------------------------------------------------------------------------------------------------------------- |
| `@radix-ui/*`     | Various | Headless UI primitives: Dialog, Dropdown, Tooltip, Switch, Tabs, Select, etc. (kokoro-mm, alpha-lab-frontend) |
| `shadcn/ui`       | —       | Pre-styled Radix components with Tailwind (alpha-lab-frontend)                                                |
| `tailwindcss`     | v4      | Utility-first CSS across all frontends                                                                        |
| `framer-motion`   | —       | Animation library (kokoro-tech scroll animations, UI transitions)                                             |
| `three.js`        | —       | 3D rendering (listed in tech stack)                                                                           |
| `@tauri-apps/api` | v2      | Desktop app bridge (kokoro-vpn desktop client)                                                                |

### Charting & Visualization

| Package                         | Version   | Usage                                                                                   |
| ------------------------------- | --------- | --------------------------------------------------------------------------------------- |
| `lightweight-charts`            | 5.x       | TradingView-style OHLC/candlestick charts (alpha-lab-frontend, kokoro-mm tick page)     |
| `recharts`                      | 2.x / 3.x | React chart components for dashboards, P&L charts                                       |
| `chart.js` + `react-chartjs-2`  | 4.x       | General purpose charts (alpha-lab-frontend)                                             |
| `plotly.js` + `react-plotly.js` | 3.x       | Scientific/quantitative plots (alpha-lab-frontend)                                      |
| `d3`                            | 7.x       | Custom data visualizations (alpha-lab-frontend)                                         |
| `@xyflow/react` (React Flow)    | 12.x      | Node-graph flow diagram editor for strategy builder canvas (kokoro-mm, kokoro-pipeline) |

### State Management & Data Fetching

| Package                | Version | Usage                                                                                 |
| ---------------------- | ------- | ------------------------------------------------------------------------------------- |
| `zustand`              | 5.x     | Client-side state store (kokoro-mm: strategies, orders, rounds, positions, tick data) |
| `swr`                  | 2.x     | Data fetching with caching and revalidation (kokoro-mm hooks)                         |
| `EventSource` (native) | —       | SSE client with exponential backoff reconnect (alpha-lab-frontend useSSE hook)        |

### MCP & AI Integration

| Package                     | Version | Usage                                                                  |
| --------------------------- | ------- | ---------------------------------------------------------------------- |
| `@modelcontextprotocol/sdk` | 1.12+   | MCP server implementation (lab-mcp: 98 tools, kokoro-mm MCP: 17 tools) |
| `zod`                       | 3.x     | Runtime schema validation for MCP tool inputs                          |

### Backend (Node.js)

| Package     | Version | Usage                                             |
| ----------- | ------- | ------------------------------------------------- |
| `express`   | —       | API server (kokoro-pipeline console)              |
| `prisma`    | —       | PostgreSQL ORM with 30+ models (kokoro-pipeline)  |
| `payload`   | 3.77    | Headless CMS (happykokoro.com website)            |
| `commander` | —       | CLI framework (kokoro-pipeline)                   |
| `stripe`    | —       | Billing integration (kokoro-pipeline marketplace) |

### Testing (Frontend)

| Package                  | Version | Usage                                              |
| ------------------------ | ------- | -------------------------------------------------- |
| `vitest`                 | —       | Unit test runner (kokoro-mm frontend, kokoro-tech) |
| `@testing-library/react` | —       | Component testing utilities                        |
| `playwright`             | —       | E2E browser testing (happykokoro.com)              |

---

## 4. Python Ecosystem

### Web Frameworks

| Package    | Version | Usage                                                                                     |
| ---------- | ------- | ----------------------------------------------------------------------------------------- |
| `fastapi`  | —       | REST API server (polymarket-bot strategy service port 8100, kokoro-copy-trader port 4500) |
| `uvicorn`  | —       | ASGI server for FastAPI                                                                   |
| `pydantic` | v2      | Request/response validation                                                               |

### Quantitative Finance

| Package                  | Version | Usage                                                    |
| ------------------------ | ------- | -------------------------------------------------------- |
| `arch`                   | —       | GARCH(1,1) MLE fitting (polymarket-bot strategy service) |
| `scipy.stats`            | —       | Student-t CDF, statistical distributions                 |
| `sklearn` (scikit-learn) | —       | PCA for factor model decomposition                       |
| `nolds`                  | —       | Hurst exponent calculation                               |
| `pywt`                   | —       | Wavelet transforms                                       |
| `numpy`                  | —       | Numerical computation foundation                         |

### Blockchain / Trading

| Package          | Version | Usage                                           |
| ---------------- | ------- | ----------------------------------------------- |
| `py-clob-client` | —       | Polymarket CLOB API client (kokoro-copy-trader) |
| `httpx`          | —       | Async HTTP client                               |
| `websockets`     | —       | WebSocket connections for data feeds            |

### AI / Orchestration

| Package     | Version | Usage                                               |
| ----------- | ------- | --------------------------------------------------- |
| `aiosqlite` | —       | Async SQLite for agent-orchestra dashboard          |
| `pyyaml`    | —       | YAML config parsing (agent-orchestra)               |
| `jinja2`    | —       | HTML template rendering (agent-orchestra dashboard) |

---

## 5. Go Ecosystem

| Package              | Version | Usage                                                     |
| -------------------- | ------- | --------------------------------------------------------- |
| `gin`                | —       | HTTP framework (kokoro-staking backend)                   |
| `pgx/v5`             | —       | PostgreSQL driver                                         |
| `go-ethereum`        | —       | Ethereum chain interaction                                |
| `cobra`              | —       | CLI framework                                             |
| `shopspring/decimal` | —       | Arbitrary-precision decimal arithmetic for financial math |
| `errgroup`           | —       | Partial-failure-tolerant concurrent cross-chain queries   |
| `zap`                | —       | Structured logging                                        |
| `prometheus`         | —       | Metrics instrumentation on every RPC call                 |

---

## 5.5 PHP Ecosystem

| Package             | Usage                                                                            |
| ------------------- | -------------------------------------------------------------------------------- |
| `laravel/framework` | 11.31 — Full MVC framework for web applications                                  |
| `laravel/breeze`    | Authentication scaffolding (login, register, password reset, email verification) |
| `pestphp/pest`      | Modern PHP testing framework                                                     |
| `laravel/sail`      | Docker development environment                                                   |
| Blade               | Server-side templating engine                                                    |
| Eloquent ORM        | Active Record pattern for database operations                                    |
| Artisan CLI         | Database migrations, seeders, scheduling, queue management                       |
| Composer            | PHP dependency management                                                        |

---

## 6. Solana / Blockchain Stack

### On-Chain (kokoro-protocol)

| Technology               | Version | Details                                         |
| ------------------------ | ------- | ----------------------------------------------- |
| **Anchor**               | 0.30.1  | Solana program framework — 20 programs deployed |
| **Solana SDK**           | 2.x     | Transaction building, keypair management        |
| **SPL Token**            | —       | Token operations (platform_token mint/redeem)   |
| **SPL Associated Token** | —       | ATA management                                  |

### Program Categories

| Category       | Programs                                                                             | Count |
| -------------- | ------------------------------------------------------------------------------------ | ----- |
| Infrastructure | platform_treasury, platform_token, user_vault, house_pool, reward_pool, governance   | 6     |
| DeFi           | dex_amm, lending_protocol, yield_vaults, liquidation_engine, leveraged_betting       | 5     |
| Casino/Gaming  | game_dice, game_crash, game_coinflip, game_slots, game_sports, game_d20, game_escrow | 7     |
| Prediction     | prediction_market                                                                    | 1     |
| NFT            | nft_auction                                                                          | 1     |

### DEX Integrations

| DEX            | Integration Type                                                      | Projects                                   |
| -------------- | --------------------------------------------------------------------- | ------------------------------------------ |
| Jupiter V6     | Swap routing, quote API, slippage/depth estimation                    | wallet-monitor, pricing-service, alpha-lab |
| Raydium AMM    | Pool state parsing, swap detection                                    | wallet-monitor, pricing-service            |
| Orca Whirlpool | Position tracking, swap detection                                     | wallet-monitor, pricing-service            |
| Pump.fun       | Program ID detection                                                  | wallet-monitor                             |
| Uniswap V3     | `exactInputSingle` swap, QuoterV2 on-chain quotes, fee tier selection | liquidation-bot                            |

### EVM Chains (liquidation-bot)

| Chain     | Protocols                                                               |
| --------- | ----------------------------------------------------------------------- |
| Ethereum  | Aave V3, Compound V3                                                    |
| Base      | Aave V3, Seamless (Aave fork), Compound V3, Moonwell (Compound V2 fork) |
| Arbitrum  | Aave V3, Compound V3                                                    |
| Polygon   | Aave V3, Compound V3                                                    |
| Optimism  | Aave V3                                                                 |
| Avalanche | Aave V3                                                                 |

### Prediction Markets

| Platform           | Integration Depth                                                                                                                        | Projects                         |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| Polymarket (CLOB)  | Full: REST scanning, WebSocket book streaming, EIP-712 order signing, HMAC auth, fill detection, CTF splitPosition/mergePositions/redeem | kokoro-mm, kokoro-polymarket-bot |
| Polymarket (Gamma) | Round discovery, market metadata                                                                                                         | kokoro-mm, kokoro-polymarket-bot |
| Kalshi             | Market provider adapter (venue router)                                                                                                   | kokoro-mm                        |
| Manifold           | Market provider adapter (venue router)                                                                                                   | kokoro-mm                        |

### Exchange Data Feeds

| Exchange     | Protocol                          | Data                                                           |
| ------------ | --------------------------------- | -------------------------------------------------------------- |
| Binance      | WebSocket (spot + futures) + REST | Spot prices, funding rates, open interest, funding predictions |
| Coinbase     | REST                              | Spot reference prices                                          |
| Deribit      | WebSocket                         | Options implied volatility                                     |
| Pyth Network | WebSocket + REST                  | Oracle price feeds, reference prices                           |
| Alpaca       | REST + WebSocket                  | Equity bars, real-time quotes (exec-alpaca crate in alpha-lab) |

### WASM Toolchain

| Component                | Details                                                                        |
| ------------------------ | ------------------------------------------------------------------------------ |
| `wasm32-unknown-unknown` | Compilation target for user-compiled strategy factors                          |
| `factor-sdk`             | Crate with `kokoro_factor!` macro that generates WASM export boilerplate       |
| `factor-wasm`            | Crate that hosts WASM modules as native `AlphaFactor` trait objects at runtime |

---

## 7. Database & Storage

| Technology     | Version | Usage                                                                                                                                                              |
| -------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **PostgreSQL** | 16      | Primary OLTP database: alpha-lab (backtests, events, positions), kokoro-mm (21 query modules, 58 migrations), kokoro-staking, kokoro-pipeline (Prisma, 30+ models) |
| **Redis**      | 7.x     | Message bus: 10 Redis Streams (alpha-lab), pub/sub + SSE event bus (kokoro-mm). Consumer groups with XREADGROUP + ACK                                              |
| **SQLite**     | —       | Lightweight persistence: polymarket-bot (rusqlite), kokoro-vpn (sqlx), kokoro-copy-trader, happykokoro.com (Payload CMS)                                           |
| **JSONL**      | —       | Append-only event log (alpha-lab event-store), P&L recording (liquidation-bot)                                                                                     |

---

## 8. Infrastructure & DevOps

Aligned with 2026 CNCF cloud-native standards (89% organizational adoption, 80% running Kubernetes in production). The platform implements Event-Driven Architecture (Redis Streams), API Gateway (Platform binary), Circuit Breaker (AtomicBool risk gates), and Service Mesh (WireGuard) patterns across 3 cloud regions.

### Containerization & Orchestration

| Tool               | Usage                                                                                                                                                 |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Docker**         | All production services containerized. Multi-stage builds for Rust binaries                                                                           |
| **Docker Compose** | Service orchestration on all 3 servers. kokoro-services defines 11 utility containers                                                                 |
| **Kubernetes**     | Container orchestration knowledge (prior professional experience); K8s not used in current deployment — Docker Compose is sufficient at current scale |
| **Caddy**          | Reverse proxy with automatic HTTPS/TLS (kokoro-mm on AWS Ireland)                                                                                     |
| **Nginx**          | Reverse proxy (DigitalOcean main server)                                                                                                              |
| **PM2**            | Node.js process management                                                                                                                            |
| **systemd**        | Service management for VPN, bot processes                                                                                                             |

### CI/CD

| Tool               | Usage                                                                                                                                    |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **GitHub Actions** | CI pipelines: `cargo build --release`, `cargo clippy -D warnings`, `cargo fmt --check`, `cargo deny check`, `npm run build`, test suites |
| **Jenkins**        | CI/CD pipeline management (prior production experience)                                                                                  |
| **rsync**          | Static site deployment (kokoro-tech → production server)                                                                                 |
| **SCP**            | Binary deployment (copy-trader, liquidation-bot)                                                                                         |

### IaC & Provisioning

| Tool           | Usage                                                                                    |
| -------------- | ---------------------------------------------------------------------------------------- |
| **Terraform**  | Infrastructure provisioning for DigitalOcean droplets and AWS EC2 instances (kokoro-vpn) |
| **cargo-deny** | Dependency license audit and vulnerability scanning (CI gate)                            |

### Monitoring & Observability

| Tool                             | Usage                                                                                |
| -------------------------------- | ------------------------------------------------------------------------------------ |
| **Prometheus**                   | Metrics collection from all Rust services (tower-http metrics middleware)            |
| **Grafana**                      | Dashboard visualization (oncall latency dashboard at grafana.internal/d/api-latency) |
| **OpenTelemetry**                | Distributed tracing                                                                  |
| **Uptime Kuma**                  | Service uptime monitoring (self-hosted, port 3003)                                   |
| **Umami**                        | Web analytics (self-hosted, port 3001)                                               |
| `tracing` + `tracing-subscriber` | Structured logging with span context across all Rust services                        |

### Networking & Security

| Tool                          | Usage                                                                                                               |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **WireGuard**                 | VPN infrastructure: client mode (hub-and-spoke, 10.8.0.0/24) + mesh mode (full-mesh, 10.10.0.0/24) across 3 servers |
| **Cloudflare**                | DNS, CDN, DDoS protection for all public-facing services                                                            |
| **Let's Encrypt** (via Caddy) | Automatic TLS certificate management                                                                                |
| **TOTP (RFC 6238)**           | Two-factor authentication (kokoro-mm)                                                                               |
| **AES-256-GCM**               | Wallet key encryption at rest                                                                                       |
| **HKDF-SHA256**               | Per-user cryptographic key derivation                                                                               |
| **Argon2**                    | Password hashing                                                                                                    |
| **JWT**                       | Session tokens for API authentication                                                                               |
| **HMAC-SHA256**               | API key authentication, Polymarket CLOB auth                                                                        |
| **Flashbots**                 | MEV protection for Ethereum liquidation transactions                                                                |
| **SOPS**                      | Secrets management (encrypted config files)                                                                         |

### Self-Hosted Services (kokoro-services)

| Service         | Port       | Purpose                  |
| --------------- | ---------- | ------------------------ |
| Umami           | 3001       | Web analytics            |
| Gitea           | 3002       | Self-hosted Git server   |
| Uptime Kuma     | 3003       | Uptime monitoring        |
| Excalidraw      | 3004       | Collaborative whiteboard |
| Homepage        | 3005       | Service dashboard        |
| Shlink + Web UI | 8080, 8081 | URL shortener            |
| PrivateBin      | 8082       | Encrypted paste bin      |
| Linkding        | 9090       | Bookmark manager         |
| Syncthing       | 8384       | File synchronization     |

### Cloud Infrastructure

| Provider         | Instance                  | Location            | Purpose                                                                                            |
| ---------------- | ------------------------- | ------------------- | -------------------------------------------------------------------------------------------------- |
| **DigitalOcean** | 4 vCPU / 8 GB RAM         | Singapore           | Main server: alpha-lab, engine, platform, frontend, MCP, payment, monitoring, self-hosted services |
| **AWS EC2**      | t3.medium (2 vCPU / 4 GB) | Ireland (eu-west-1) | kokoro-mm, kokoro-polymarket-bot                                                                   |
| **AWS EC2**      | t3.small (2 vCPU / 2 GB)  | London (eu-west-2)  | kokoro-copy-trader, market data storage                                                            |

---

## 9. AI / ML & Agent Infrastructure

### AI coding agent Integration

| Tool                       | Usage                                                                                                                                                           |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **AI coding agent CLI**    | Primary development tool. `--dangerously-skip-permissions` for autonomous agent operation                                                                       |
| **MCP Protocol**           | 115 total MCP tools (98 in lab-mcp + 17 in kokoro-mm MCP) exposing platform APIs to AI agents                                                                   |
| **AI coding agent Skills** | Custom skills: dev-pipeline (parallel agent execution), signal-pipeline, risk-management, kalman-filter, polymarket-arbitrage, anchor-patterns, dex-integration |
| **Agent Teams**            | Orchestrated via agent-orchestra: feature-dev (3 agents), build-fix (1 agent), code-review, debug, research                                                     |

### AI Models & Techniques

| Technique                          | Implementation                                                                    | Project                      |
| ---------------------------------- | --------------------------------------------------------------------------------- | ---------------------------- |
| DQN (Deep Q-Network)               | Experience replay buffer, Q-network, epsilon-greedy exploration                   | alpha-lab (factor-ai crate)  |
| LLM Integration                    | Copilot crate: factor advisor, risk explainer, strategy generator, trace analyzer | alpha-lab                    |
| WASM Plugin System                 | `factor-sdk` with `kokoro_factor!` macro for user-compiled strategy factors       | alpha-lab                    |
| Expert Aggregator                  | Multiplicative weights update (Hedge algorithm) with exponential loss penalty     | alpha-lab (prediction crate) |
| Conformal Prediction               | Rolling calibration set, quantile-based coverage bounds (95% target)              | alpha-lab, kokoro-mm         |
| PCA (Principal Component Analysis) | Factor decomposition for polymarket-bot Python strategy service (scikit-learn)    | kokoro-polymarket-bot        |

---

## 10. Protocols & Standards

| Protocol/Standard             | Usage                                                                    |
| ----------------------------- | ------------------------------------------------------------------------ |
| **EIP-712**                   | Typed structured data signing for Polymarket CLOB orders                 |
| **ERC-1155**                  | CTF (Conditional Token Framework) position tokens on Polygon             |
| **gRPC**                      | Inter-service communication (alpha-lab: Lab↔Engine↔Platform)             |
| **REST/HTTP**                 | All external-facing APIs                                                 |
| **SSE (Server-Sent Events)**  | Real-time streaming: signal updates, tick data, news feeds               |
| **WebSocket**                 | Exchange data feeds (Binance, Polymarket CLOB, Deribit, Solana logs)     |
| **Protocol Buffers (proto3)** | Message serialization for gRPC and Redis Streams dual-format             |
| **JSON-RPC**                  | Ethereum/Solana RPC node communication                                   |
| **WireGuard**                 | VPN tunneling protocol                                                   |
| **TOTP (RFC 6238)**           | Time-based one-time passwords for 2FA                                    |
| **FIX Protocol**              | Stub for institutional connectivity (kokoro-mm Phase 8)                  |
| **SCIM 2.0**                  | Identity provisioning (kokoro-pipeline enterprise)                       |
| **SAML / OIDC**               | SSO authentication (kokoro-pipeline enterprise)                          |
| **Stripe Webhooks**           | Payment event processing                                                 |
| **IERC3156**                  | Flash loan callback interface standard (liquidation-bot FlashLiquidator) |

---

## 11. Technology Count Summary

| Category                             | Count                                                                                                   |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| Programming Languages (active)       | 7 (Rust, TypeScript, Python, Go, Solidity, SQL, Shell)                                                  |
| Rust Crates (workspace dependencies) | 50+ unique crates                                                                                       |
| npm Packages (across all frontends)  | 80+ unique packages                                                                                     |
| Python Libraries                     | 15+                                                                                                     |
| Go Modules                           | 8+                                                                                                      |
| Databases                            | 3 (PostgreSQL, Redis, SQLite)                                                                           |
| Blockchain Chains                    | 8 (Ethereum, Base, Arbitrum, Polygon, Optimism, Avalanche, Solana, Cosmos + 13 more via kokoro-staking) |
| DeFi Protocols                       | 8 (Aave V3, Compound V3, Seamless, Moonwell, Jupiter, Raydium, Orca, Pump.fun)                          |
| Exchange Integrations                | 5 (Binance, Coinbase, Deribit, Pyth, Polymarket)                                                        |
| Cloud Providers                      | 2 (AWS, DigitalOcean)                                                                                   |
| Self-Hosted Services                 | 11                                                                                                      |
| MCP Tools                            | 115                                                                                                     |
| Anchor Programs                      | 20                                                                                                      |
| Docker Containers (production)       | 12+                                                                                                     |
| CI/CD Pipelines                      | GitHub Actions across all repos                                                                         |

---

→ [Read the full article version](../articles/technology-stack.md)

---

**Next steps:** [Explore our services →](../services/overview.md) | [View technical profile →](../profile/resume.md) | [Contact us →](../services/contact.md)

---

_Kokoro Tech — [tech.happykokoro.com](https://tech.happykokoro.com) · [GitHub](https://github.com/happykokoro) · [Contact](../services/contact.md)_
