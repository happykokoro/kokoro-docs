# Coding Style & Architecture Philosophy

> Detailed analysis of coding conventions, design decisions, architecture philosophy, and engineering principles demonstrated across the Kokoro codebase. Derived from patterns observed in 300,000+ lines of production code. Architecture documented following ISO/IEC/IEEE 42010:2022 conventions.

---

## 1. Architecture Philosophy

The architecture follows **ISO/IEC/IEEE 42010:2022 — Systems and Software Engineering: Architecture Description**. Three primary architecture viewpoints structure design decisions: the Signal Processing viewpoint (concerns of strategy developers), the Execution viewpoint (concerns of trading operators), and the Infrastructure viewpoint (concerns of DevOps). Each architectural decision is traceable to a stakeholder concern in one of these viewpoints.

### Clean Integration Layer (CIL)

The flagship architectural pattern, implemented at scale in kokoro-alpha-lab (242K lines). Core principle: **business logic crates contain zero I/O**.

```
crates/     → 63 pure-logic crates (no tokio, no network, no filesystem)
apps/       → 3 binaries that wire crates together and own all I/O
services/   → shared infrastructure (Redis client, proto, payments)
```

**Why this matters**: Any factor, strategy, or risk model can be tested without spinning up databases, Redis, or network mocks. A `factor-swap-momentum` crate depends only on `factor-core` and math libraries — it has no idea whether it's running in a backtest, a live trading engine, or a WASM sandbox.

**Single known violation**: `event-store` uses `std::fs` directly for append-only JSONL logging — tracked as tech debt.

### Single-Binary MVP (SaaS Projects)

For SaaS products (kokoro-mm, kokoro-vpn), the architecture collapses all logical services into a single binary with direct function call IPC:

```rust
// mm-bin/src/main.rs (408 lines)
let db = mm_db::create_pool(&config.database_url).await?;
let redis = mm_redis::RedisClient::new(&config.redis_url)?;
let engine = mm_engine::Engine::new(db.clone(), redis.clone());
let datahub = mm_datahub::DataHubService::new(redis.clone());
let gateway = mm_gateway::build_app(engine, datahub, db);
axum::serve(listener, gateway).await?;
```

No gRPC, no message queues between services — just Rust function calls through shared `Arc` state. gRPC is scaffolded (stub files exist) but intentionally deferred until horizontal scaling is needed.

### Layered Crate Architecture

Every Rust workspace follows a strict dependency layering:

```
L0: Types & Traits     (mm-types, mm-proto, mm-traits, factor-core)
L1: Domain Logic        (mm-market, mm-order, mm-strategy, factors)
L2: Infrastructure      (mm-polymarket, mm-db, mm-redis, data-source)
L3: Services            (mm-engine, mm-datahub, mm-gateway)
L4: Entry Point         (mm-bin, apps/lab, apps/engine)
```

**Enforced rule**: Lower layers never import higher layers. `mm-types` has zero dependencies on other workspace crates. `mm-engine` depends on L0-L2 but never on `mm-gateway`.

### Multi-Repo Ecosystem Coordination

The Kokoro platform is not a monorepo — it is a federation of 7+ repositories that coordinate as one logical system. Each repository is independently deployable and independently versioned, but participates in the larger platform through well-defined contracts at every service boundary. This follows the cloud-native microservices pattern adopted by 80%+ of enterprise applications in 2026 (CNCF). The coordination mechanisms are explicit and layered:

**Shared type crate with semantic versioning.** A single `shared-types` crate (and its compiled proto definitions) defines the canonical domain types used across all repositories: signal shapes, event schemas, position structs, billing tier enums. Satellite repositories pin to tagged releases (`shared-v0.x.x`) rather than a git SHA, enforcing a deliberate upgrade process. When a type changes, the change propagates through a controlled dependency bump — not silently across a monorepo boundary.

**Redis Streams as the inter-service message bus.** 10 named streams carry asynchronous events between services that run on different servers or different processes. Messages are encoded in a dual JSON/protobuf format: the `enc` field signals which encoding is in use, and all consumers auto-detect. This allows old and new service versions to coexist during rolling deployments without coordination. Consumer groups enable parallel processing within a service tier.

**gRPC for synchronous service-to-service calls.** Three service pairs use Tonic gRPC for request-response and server-streaming interactions: Lab↔Engine (signal submission, execution confirmation), Engine↔Platform (tier enforcement, billing events), and Platform↔external clients (authenticated, rate-limited API surface). Proto `.proto` files are the source of truth; generated Rust types are checked into `services/proto/`.

**REST APIs at the external boundary.** The Platform binary translates internal gRPC calls into REST responses for the frontend and third-party integrators. No external consumer calls internal gRPC directly — the REST surface is the stable public contract, and internal gRPC bindings can evolve behind it.

**SSE for real-time frontend streaming.** Server-Sent Events push live data from the Platform binary to the browser without requiring WebSocket upgrades. The frontend maintains an `EventSource` connection with exponential backoff reconnection.

**WireGuard mesh making cross-server communication transparent.** All three production servers (Singapore, Ireland, London) participate in a WireGuard mesh on the 10.10.0.0/24 subnet. Services address each other by mesh IP regardless of which physical server they run on. A service on the Singapore server communicates with a service on the Ireland server exactly as if they were on the same LAN — no public internet exposure, no external load balancer, no service discovery overhead.

**Docker Compose per server, with health checks and restart policies.** Each server runs its own Docker Compose stack. Container health checks gate `depends_on` startup ordering. `restart: unless-stopped` ensures services recover from transient failures. Shared infrastructure (Redis, PostgreSQL) is managed within the same Compose stack as the services that depend on it.

**The key insight: each repository is independently deployable but participates in a larger system through well-defined contracts.** Adding a new satellite service does not require modifying the monorepo. Adding a new message type requires only bumping the `shared-types` version and updating consumers. The system grows by extending contracts, not by restructuring boundaries.

---

## 2. Rust Coding Conventions

Rust is now described as "non-negotiable for serious HFT" in 2026 industry discourse, with the first TokioConf announced for 2026. Tokio is the de facto async runtime (28,000+ GitHub stars). Axum 0.8's tower::Service middleware model enables composable, zero-overhead HTTP infrastructure — middleware layers (auth, tracing, rate limiting, compression) compose without touching handler function signatures. The codebase adopts these patterns throughout.

### Error Handling Strategy

**Application code (pipelines, handlers)**: `anyhow::Result<T>` for ergonomic error propagation with context.

```rust
let position = adapter.get_position(address)
    .await
    .context("failed to fetch position for health check")?;
```

**Library boundaries (public crate APIs)**: `thiserror` for typed, matchable error enums.

```rust
#[derive(Debug, thiserror::Error)]
pub enum FactorError {
    #[error("insufficient data: need {required}, got {actual}")]
    InsufficientData { required: usize, actual: usize },
    #[error("computation failed: {0}")]
    ComputationFailed(String),
}
```

**Non-critical failures**: `.unwrap_or_default()` for optional reads that shouldn't crash the pipeline. Warnings logged, execution continues.

**No `unwrap()` in production paths**: All production code uses `?` or explicit error handling. `unwrap()` appears only in tests and one-time initialization.

### Derive & Attribute Patterns

Every domain struct follows a standard derive set:

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlphaSignal {
    pub factor_name: String,
    pub token: String,
    pub direction: SignalDirection,
    pub confidence: f64,
    // ...
}
```

Config structs add backward-compatible defaults:

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RiskConfig {
    #[serde(default = "default_max_drawdown")]
    pub max_drawdown: f64,
    #[serde(default = "default_confidence_threshold")]
    pub confidence_threshold: f64,
}

fn default_max_drawdown() -> f64 { 0.15 }
fn default_confidence_threshold() -> f64 { 0.6 }
```

Explicit `fn default_X()` over `impl Default` — each field's default is self-documenting.

Forward-compatible enums use `#[serde(other)]`:

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FactorInputType {
    Swap, Price, OrderFlow, Cluster,
    #[serde(other)]
    Custom,
}
```

### Concurrency Primitives (Decision Framework)

| Primitive             | When Used                                       | Example                                                |
| --------------------- | ----------------------------------------------- | ------------------------------------------------------ |
| `DashMap`             | Hot-path concurrent reads/writes to shared maps | signal-store, blackboard, known_borrowers, correlation |
| `Arc<RwLock<>>`       | Slower-changing config state, read-heavy        | ExecutionPipeline.config, attribution                  |
| `Arc<Mutex<>>`        | Single-writer state                             | event-store append                                     |
| `AtomicBool`          | Single-flag read in hot path                    | Circuit breaker trip flag                              |
| `Arc<AtomicI64>`      | Lock-free timestamp tracking                    | Data adapter watchdog last-data tracking               |
| `std::sync::RwLock`   | Avoid async overhead in sync-heavy paths        | polymarket-bot AppState (deliberately not tokio's)     |
| `tokio::sync::RwLock` | Only when lock is held across `.await`          | Rarely used                                            |

### Naming Conventions

- **Crate names**: kebab-case, prefixed by project (`mm-engine`, `factor-swap-momentum`, `exec-paper`)
- **Module names**: snake_case (`fair_value.rs`, `spread.rs`, `adverse_selection.rs`)
- **Trait names**: PascalCase, verb-noun (`AlphaFactor`, `ExecutionBackend`, `MarketProvider`)
- **Types**: PascalCase with domain vocabulary (`AlphaSignal`, `ComposedSignal`, `LendingPosition`, `BookDiff`)
- **Test modules**: `#[cfg(test)] mod tests` co-located in source files, or `*_tests.rs` separate files for larger test suites
- **Feature flags**: kebab-case matching crate names (`factor-swap-momentum`, `live-signing`, `slow-tests`)

### Code Organization Within Files

Consistent ordering within each module:

1. `use` imports (std, external crates, workspace crates)
2. Type definitions (`struct`, `enum`)
3. `impl` blocks (constructors first, then public methods, then private methods)
4. Trait implementations
5. `#[cfg(test)] mod tests` at the bottom

### Builder Pattern Usage

Chainable builders for complex domain objects:

```rust
AlphaSignal::new(factor_name, token, direction, confidence)
    .with_metadata(key, value)
    .with_chain(chain_id)
    .with_prediction(prediction)
    .with_predictions(vec![...])
```

```rust
DataHub::new()
    .add_tick(binance_adapter)
    .add_tick(clob_adapter)
    .add_rest(coinbase_adapter)
    .start()
```

### Testing Style

**Pure-function first**: Strategies, algorithms, and risk gates are pure functions — given inputs, they produce deterministic outputs. No network, no filesystem, no time dependencies.

```rust
#[test]
fn test_garch_fit_short_series() {
    let returns = vec![0.01, -0.02, 0.015, -0.01, 0.005];
    let garch = Garch11::fit(&returns);
    assert!(garch.alpha + garch.beta < 0.999);
    assert!(garch.omega > 0.0);
}
```

**Synthetic data inline**: Tests generate their own input data — no fixture files, no external dependencies:

```rust
#[test]
fn test_hurst_trending_series() {
    let trending: Vec<f64> = (0..200).map(|i| i as f64 * 0.1 + rand()).collect();
    let h = hurst_exponent(&trending);
    assert!(h > 0.5, "trending series should have H > 0.5, got {h}");
}
```

**Feature-gated expensive tests**: Convergence tests and Monte Carlo simulations behind `slow-tests` flag:

```rust
#[cfg(feature = "slow-tests")]
#[test]
fn test_particle_filter_convergence_1000_particles() {
    // ... expensive test
}
```

---

## 3. TypeScript / Frontend Conventions

### Next.js Architecture

- **App Router** (Next.js 15/16) with server components as default
- **Route organization**: Grouped by domain (`/mm/`, `/lab/`, `/engine/`, `/polymarket/`, `/liquidation/`)
- **Page files**: `page.tsx` in each route directory, client components marked with `"use client"`
- **API routes**: `/api/` proxies to backend services (no direct backend calls from client)

### State Management Pattern

```typescript
// Zustand store — single store per domain
const useMmStore = create<MmStore>((set) => ({
  strategies: [],
  activeOrders: [],
  rounds: [],
  positions: [],
  tickData: null,
  // ... actions
}));

// SWR hooks — one per API endpoint
function useMarkets(filters?: MarketFilters) {
  return useSWR(["/api/mm/markets", filters], fetcher);
}
```

### Real-Time Data Pattern

Custom `useSSE` hook with exponential backoff:

```typescript
function useSSE(url: string) {
  // EventSource-based connection
  // Reconnect: 1s → 2s → 4s → ... → 30s max
  // Automatic cleanup on unmount
}
```

### Component Patterns

- **Radix UI primitives** for accessible, unstyled components
- **Tailwind v4** for all styling (no CSS modules, no styled-components)
- **Client-side theme management** via `ThemeProvider` + `ThemeToggle`
- **Scroll-triggered animations** via custom `ScrollAnimate` component

---

## 4. Python Conventions

### Strategy Service Pattern (polymarket-bot)

```python
# Auto-registration via decorator
@register_strategy("garch-t")
class GarchTStrategy(BaseStrategy):
    def predict(self, market: Market, context: DataContext) -> Prediction:
        # ... pure computation
        return Prediction(direction=..., confidence=..., edge=...)

# Profile → strategy mapping
PROFILE_STRATEGIES = {
    "garch-t": ["GarchTStrategy"],
    "bilateral-mm": ["SpreadDynamicsStrategy"],
    "fair-value": ["BrownianBridge", "HierarchicalCascade"],
}
```

### Agent Orchestra Pattern

```python
# Async orchestration with asyncio
class GeneralManager:
    async def run_pipeline(self):
        # 7 phases: launch → wait → analyze → merge → build → test → complete
        await self.launch_agents()
        await self.wait_for_completion()
        await self.analyze_results()
        # ... approval gate on failure
```

### Claude Init Pattern

- **Zero dependencies**: Pure stdlib only (`argparse`, `pathlib`, `json`, `os`, `dataclasses`)
- **Single file**: 1,229 lines in `init.py`
- **Detection layers**: Language → Framework → Project structure → Output generation

---

## 5. Go Conventions (kokoro-staking)

### Interface Segregation

```go
// Adapters implement only what they support
type StakingReader interface {
    GetValidators(ctx context.Context) ([]Validator, error)
    GetDelegations(ctx context.Context, addr string) ([]Delegation, error)
}

type TxBuilder interface {
    BuildStakeTx(ctx context.Context, req StakeRequest) (*UnsignedTx, error)
    BuildUnstakeTx(ctx context.Context, req UnstakeRequest) (*UnsignedTx, error)
}

type HealthChecker interface {
    CheckHealth(ctx context.Context) (*HealthStatus, error)
}
```

### Financial Safety

- `shopspring/decimal` for all monetary calculations (never `float64`)
- `errgroup` for partial-failure-tolerant cross-chain queries
- Client-side signing only — backend never handles private keys
- Prometheus instrumented on every RPC call
- Zap structured logging throughout

---

## 6. Design Decisions & Trade-offs

### CIL Over Alternative Architectures

**Decision**: Clean Integration Layer (63 pure crates + 3 I/O binaries) over hexagonal architecture, DDD packages, or actor model.

**Alternatives considered**:

- Hexagonal architecture (ports & adapters): too much ceremony for a single developer. Each port requires a trait + adapter + test double — 3× the surface area of CIL's "just don't import I/O crates" rule.
- Domain-Driven Design packages: DDD's bounded contexts map poorly to a trading pipeline where signals flow linearly through factors → composition → risk → execution. CIL's layered model matches the data flow.
- Actor model (e.g., actix actors): message-passing overhead is unnecessary when the pipeline is synchronous within each tick. CIL crates are called directly, not via message queues.

**Rationale**: For a solo developer, the simplest correct architecture wins. CIL's enforcement mechanism is trivial: "does this crate import tokio, reqwest, sqlx, or std::fs? If yes, it's not a crate/ member." No framework needed, no annotations, no abstract factories. The compiler enforces the boundary via Cargo dependency resolution.

### Dynamic Dispatch Over Generics (Factors)

**Decision**: `Box<dyn AlphaFactor>` (50+ occurrences) instead of generic monomorphization.

**Rationale**: The factor pipeline needs runtime composability — users configure which factors to run via TOML config files. Generic monomorphization would require compile-time factor selection, preventing dynamic composition. The vtable overhead (~5ns per call) is negligible compared to the microsecond-scale filter computations.

### `DashMap` Over `RwLock<HashMap>`

**Decision**: `DashMap` as primary shared-state primitive.

**Rationale**: Signal store, blackboard, and correlation monitor are read-heavy with concurrent writers. `DashMap` uses fine-grained per-shard locking, avoiding global lock contention. In hot paths (100+ factor evaluations per pipeline tick), this eliminates the serial bottleneck of a single `RwLock`.

### Single Binary Over Microservices (SaaS)

**Decision**: kokoro-mm runs all services in one process.

**Rationale**: For an early-stage SaaS with single-digit users, the operational complexity of multiple containers, service discovery, and gRPC outweighs the benefits. Direct function calls are zero-cost. gRPC stubs exist for Phase 8 scaling.

### Feature-Gated Factor Registry

**Decision**: `#[cfg(feature)]` compilation flags instead of runtime registration.

**Rationale**: The Engine binary runs frozen strategies and doesn't need 24 factor implementations. `minimal` feature set compiles in seconds; `all-factors` takes minutes. Compile-time exclusion is zero-runtime-cost and reduces binary size.

### `std::sync::RwLock` Over `tokio::sync::RwLock`

**Decision**: polymarket-bot uses stdlib locks, not tokio's.

**Rationale**: The hot path (signal evaluation, strategy prediction) is CPU-bound, not I/O-bound. tokio's async RwLock adds overhead for yielding that's unnecessary when the critical section never awaits. `std::sync::RwLock` is faster for short, synchronous critical sections.

### Dual JSON/Proto Format on Redis Streams

**Decision**: Messages include an `enc: "proto"` marker; consumers auto-detect format.

**Rationale**: Rolling migration from JSON to proto without downtime. Old producers emit JSON, new producers emit proto, consumers accept both. Zero coordination required between service deployments. This zero-downtime protocol evolution technique is now a recognized industry pattern; it was designed and executed across all 10 platform streams before widespread documentation.

### Cloud-Native Pattern Alignment (2026 CNCF Baseline)

89% of organizations now run cloud-native technologies; 80% run Kubernetes in production (CNCF Annual Survey 2026). The platform implements the full set of cloud-native patterns that constitute the 2026 engineering baseline:

- **Event-Driven Architecture**: Redis Streams (durable, ordered, consumer-group-aware) — not simple Pub/Sub
- **API Gateway**: Platform binary centralizes auth, billing, tier enforcement, and protocol translation
- **Circuit Breaker**: `AtomicBool` lock-free flags in every trading system
- **CQRS**: Physical Lab/Engine binary separation enforces read/write path isolation
- **Service Mesh**: WireGuard mesh eliminates public exposure of internal services
- **Saga Pattern**: Solidity flash loan contract implements distributed transaction atomicity

Kubernetes was intentionally not adopted — the operational complexity of K8s cluster management exceeds its benefits for a 3-server deployment where Docker Compose provides sufficient orchestration. gRPC stubs exist for future horizontal scaling when the single-binary architecture is outgrown.

### JSONL Event Store (Known Violation)

**Decision**: `event-store` crate uses `std::fs` directly despite CIL rules.

**Rationale**: Tracked as tech debt. Append-only file write was too simple to justify a full trait abstraction at the time. Will be migrated to PostgreSQL when event replay requirements grow.

---

## 7. Code Quality Metrics

### Enforced Standards

| Check                      | Scope                  | Strictness                             |
| -------------------------- | ---------------------- | -------------------------------------- |
| `cargo clippy -D warnings` | All Rust code          | All lint warnings are errors           |
| `cargo fmt --check`        | All Rust code          | Enforced formatting (rustfmt defaults) |
| `cargo deny check`         | All dependencies       | License audit + vulnerability check    |
| `cargo build --release`    | All code               | Zero-warning release builds            |
| `cargo test --workspace`   | All crates             | All tests must pass                    |
| Prettier                   | JS/TS/CSS/HTML/JSON/MD | Auto-applied via hooks                 |
| ESLint                     | TypeScript             | Standard rules                         |

### Test Density

| Project                | LOC         | Tests     | Ratio                    |
| ---------------------- | ----------- | --------- | ------------------------ |
| kokoro-alpha-lab       | 242,466     | 1,074     | 1 test per 226 lines     |
| kokoro-mm              | 62,641      | 690       | 1 test per 91 lines      |
| kokoro-polymarket-bot  | 15,491      | 72        | 1 test per 215 lines     |
| kokoro-liquidation-bot | 5,130       | 24        | 1 test per 214 lines     |
| **Total**              | **325,728** | **1,860** | **1 test per 175 lines** |

### Codebase Scale

| Metric                          | Value                    |
| ------------------------------- | ------------------------ |
| Total Rust lines of code        | ~330,000+                |
| Total TypeScript lines of code  | ~180,000+                |
| Total Python lines of code      | ~12,000+                 |
| Total Go lines of code          | ~15,000+                 |
| Rust crates (workspace members) | 100+ across all projects |
| Anchor programs                 | 20                       |
| MCP tools                       | 115                      |
| REST API endpoints              | 200+                     |
| Frontend pages/routes           | 150+                     |
| Docker services (production)    | 12+                      |
| Unit/integration tests          | 1,860+                   |
| CI/CD pipelines                 | 8+ repos                 |

---

## 8. Solidity Conventions

### Flash Loan Pattern

- IERC3156-compatible callback interface: `FlashLiquidator.sol` implements the Aave V3 flash loan callback
- Atomic execution guarantee: borrow → liquidationCall → Uniswap V3 swap → repay within single transaction
- Reentrancy protection: execution is inherently reentrant-safe because the entire operation completes or reverts atomically
- Fee tier selection logic: classifies collateral/debt pair (stable-stable=0.05%, WETH-stable=0.05%, default=0.3%)
- Gas optimization: inline ABI definitions via `alloy::sol!` macro in Rust, avoiding separate ABI JSON files and external Solidity compilation toolchain

### On-Chain Contract Design

- Single-purpose contracts: FlashLiquidator does exactly one thing (flash-borrow, liquidate, swap, repay)
- No storage variables beyond immutable constructor parameters
- No admin functions or upgradeability — immutable deployment
- Parameters passed entirely through calldata, not storage reads

---

## 9. Protocol Buffer & gRPC Conventions

### Proto Design

- Package naming: `kokoro.{domain}.v1` (e.g., `kokoro.common.v1`, `kokoro.lab.v1`, `kokoro.engine.v1`, `kokoro.platform.v1`, `kokoro.payment.v1`, `kokoro.artifact.v1`)
- Message naming: PascalCase matching Rust struct names (e.g., `AlphaSignal`, `FactorInput`, `BacktestResult`)
- Field numbering: sequential, never reused after deprecation
- `optional` for fields that may be absent (e.g., metadata, predictions); required fields use direct types
- Timestamp fields use `google.protobuf.Timestamp` or i64 Unix millis depending on context

### Dual-Format Streaming

- Redis Streams carry both JSON and proto messages simultaneously during migration
- Producer decides format; consumer auto-detects via `enc` field marker (`"enc": "proto"` for binary, absent for JSON)
- `publish_proto<T: ProstMessage>` and `consume_auto<T: DeserializeOwned>` methods in shared Redis client
- Bidirectional conversion functions for all 10 stream message types

### gRPC Service Design

- Server-streaming RPCs for continuous data: `StreamSignals`, `StreamPositions`, `StreamTrades`
- Client-streaming for bulk upload: `UploadData`
- Unary RPCs for request-response: `GetFactors`, `SubmitBacktest`, `DeployBot`
- Platform service proxies Engine service — clients never call Engine directly

---

## 10. Database Schema Conventions

### PostgreSQL (SQLx)

- Table names: snake_case, plural (e.g., `orders`, `positions`, `backtest_results`)
- Primary keys: UUID (`uuid` crate) for all domain entities
- Audit timestamps: `created_at TIMESTAMPTZ DEFAULT NOW()`, `updated_at TIMESTAMPTZ DEFAULT NOW()` on every table
- Soft deletes: not used — hard deletes with foreign key cascades
- Query pattern: `sqlx::query_as!` for typed queries with compile-time checking, `sqlx::query!` for updates/inserts
- Repository trait pattern: `BacktestRepo`, `EventRepo`, `PositionRepo` traits with `Pg*` implementations and in-memory stubs for testing
- Migrations: `sqlx migrate` with sequential numbering (58 migration pairs in kokoro-mm)
- Connection pooling: `sqlx::PgPool` with configurable `max_connections`

### SQLite (rusqlite)

- Used where PostgreSQL is overkill: polymarket-bot (positions, signals, round history), kokoro-vpn (users, devices, ACLs)
- `bundled` feature flag: ships SQLite as part of the binary, no system dependency
- WAL mode for concurrent read access

---

## 11. Docker & Deployment Conventions

> **Background**: The containerization conventions here are grounded in professional Kubernetes experience predating the current projects. Before Docker Compose became the deployment target, production infrastructure was managed with Kubernetes — cluster management, pod scheduling, service discovery — operated entirely via SSH and documented shell commands. The current Docker Compose approach is a deliberate simplicity trade-off for a solo operator, not a lack of familiarity with orchestration at scale.

### Multi-Stage Rust Builds

```dockerfile
# Stage 1: Build
FROM rust:latest AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY crates/ crates/
COPY apps/ apps/
COPY services/ services/
RUN cargo build --release --bin <target>

# Stage 2: Runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/<target> /usr/local/bin/
CMD ["<target>"]
```

- Cargo.toml/Cargo.lock copied first for layer caching — source changes don't invalidate dependency builds
- `debian:bookworm-slim` as runtime base (not `scratch`) — needs ca-certificates for HTTPS and OpenSSL for TLS
- Single binary per container — no multi-service containers
- Health check: every container exposes `GET /health` endpoint

### Docker Compose Patterns

- Service dependency: `depends_on: condition: service_healthy` for databases
- Volume naming: `<service>-data` for persistent data, `<service>-config` for configuration
- Network: single default network per compose file, explicit port mapping only for externally-accessible services
- Environment: `.env` file for secrets, never committed to git; `.env.example` committed with placeholder values
- Restart policy: `restart: unless-stopped` for all production services
