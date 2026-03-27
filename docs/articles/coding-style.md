# Coding Style and Architecture Philosophy: Engineering Decisions Across 300,000+ Lines of Production Code

This document is a detailed examination of the architectural patterns, coding conventions, and engineering trade-offs present across the Kokoro codebase — a multi-language, multi-project system totaling over 300,000 lines of production code spanning Rust, TypeScript, Python, Go, Solidity, and Protocol Buffers. What follows is not a style guide. It is an account of specific decisions made under specific constraints, along with honest reasoning about what those constraints were and why each choice was the right one at the time.

---

## 1. Architecture Philosophy

### The Clean Integration Layer

The most significant architectural commitment across the codebase is a pattern I call the Clean Integration Layer, or CIL. It is implemented at its largest scale in `kokoro-alpha-lab`, a 242,000-line Rust monorepo that houses the alpha research and live trading platform. The core principle is deceptively simple: **business logic crates contain zero I/O**.

```
crates/     → 63 pure-logic crates (no tokio, no network, no filesystem)
apps/       → 3 binaries that wire crates together and own all I/O
services/   → shared infrastructure (Redis client, proto, payments)
```

This single rule changes the testing economics of the entire system. A `factor-swap-momentum` crate depends only on `factor-core` and math libraries. It has no idea whether it is running in a backtest, a live trading engine, or a WASM sandbox. Any factor, strategy, or risk model can be tested without spinning up databases, Redis instances, or network mocks. There are no test containers, no embedded brokers, no mock HTTP servers. A `cargo test` on any individual crate is entirely self-contained.

The enforcement mechanism is also trivially simple: it does not require a framework, a set of annotations, or any kind of abstract factory. The rule is just "does this crate import `tokio`, `reqwest`, `sqlx`, or `std::fs`? If yes, it is not a `crates/` member." The Cargo dependency graph enforces this structurally — if a pure crate tries to add a network dependency, the layering invariant fails at the dependency resolution level, before any code compiles.

There is one known violation: the `event-store` crate uses `std::fs` directly for append-only JSONL logging. This is tracked as tech debt and will be migrated to PostgreSQL when event replay requirements grow. The violation is acknowledged because an append-only file write was too operationally simple to justify a full trait abstraction at the time it was written. Honesty about these decisions matters more than pretending the codebase is perfectly clean.

The CIL pattern was chosen over three serious alternatives, each of which was genuinely considered.

**Hexagonal architecture** (ports and adapters) achieves a similar separation but with significantly more ceremony for a solo developer. Each port requires a trait, an adapter, and a test double — three times the surface area of CIL's single rule. The cognitive overhead of maintaining that scaffolding across 63 crates would have slowed iteration without improving the testability guarantees.

**Domain-Driven Design with bounded contexts** maps poorly to a trading pipeline where signals flow linearly through factors, then composition, then risk gating, then execution. DDD's bounded context model assumes relatively autonomous domains with well-defined message contracts between them. A linear signal pipeline does not have that topology — CIL's layered dependency model matches the actual data flow far better.

**The actor model** — something like `actix` actors with message passing — introduces message-passing overhead that is entirely unnecessary when the pipeline is synchronous within each tick. CIL crates are called directly as ordinary function calls. There is no queue, no mailbox, no serialization cost between stages. The actor model would have added complexity and latency with no benefit in this context.

For a solo developer building a production trading system, the simplest correct architecture wins. CIL is the simplest architecture that achieves the testability and separation-of-concerns properties required.

### The Single-Binary MVP for SaaS Products

The architecture philosophy shifts substantially for SaaS products like `kokoro-mm` and `kokoro-vpn`. Here, all logical services collapse into a single process with direct function call IPC rather than network-based inter-service communication.

```rust
// mm-bin/src/main.rs (408 lines)
let db = mm_db::create_pool(&config.database_url).await?;
let redis = mm_redis::RedisClient::new(&config.redis_url)?;
let engine = mm_engine::Engine::new(db.clone(), redis.clone());
let datahub = mm_datahub::DataHubService::new(redis.clone());
let gateway = mm_gateway::build_app(engine, datahub, db);
axum::serve(listener, gateway).await?;
```

There is no gRPC between these services, no message queue, no service discovery. `mm_engine` calls `mm_datahub` as a Rust function through a shared `Arc`. The latency is sub-nanosecond. The operational footprint is a single binary and a single container.

This is not an accident or an oversight. gRPC is intentionally scaffolded — stub files exist, proto definitions are written, the service boundaries are drawn — but the transport layer is deferred until horizontal scaling is actually needed. For an early-stage SaaS product with single-digit active users, the operational complexity of multiple containers, service discovery, load balancing, and inter-service authentication outweighs the theoretical benefits of microservices. Direct function calls are zero-cost. The architecture can be migrated to distributed services when the scale genuinely demands it, and the crate boundaries that already exist make that migration tractable.

### Layered Crate Architecture

Every Rust workspace, regardless of the project, follows a strict five-level dependency hierarchy:

```
L0: Types & Traits     (mm-types, mm-proto, mm-traits, factor-core)
L1: Domain Logic        (mm-market, mm-order, mm-strategy, factors)
L2: Infrastructure      (mm-polymarket, mm-db, mm-redis, data-source)
L3: Services            (mm-engine, mm-datahub, mm-gateway)
L4: Entry Point         (mm-bin, apps/lab, apps/engine)
```

The enforced invariant is that lower layers never import higher layers. `mm-types` has zero dependencies on other workspace crates — it is the leaf of the dependency tree. `mm-engine` depends on L0 through L2 but never on `mm-gateway`. This means the gateway can be replaced, rewritten, or swapped for a different web framework without touching a single line of engine code.

This layering is not a formality. It determines where changes ripple. A change to `mm-types` potentially affects everything above it. A change to `mm-gateway` affects nothing below it. The dependency graph is a change-impact map, and keeping it acyclic and strictly layered keeps that map navigable.

---

## 2. Rust Coding Conventions

### Error Handling: A Two-Tier Strategy

Rust's error handling ecosystem offers genuine choices, and conflating them is one of the most common quality problems in Rust codebases. The approach taken here makes a clean distinction based on context.

In application code — pipeline drivers, request handlers, orchestration logic — `anyhow::Result<T>` is the right tool. It provides ergonomic error propagation with contextual annotation, making production log traces meaningful:

```rust
let position = adapter.get_position(address)
    .await
    .context("failed to fetch position for health check")?;
```

The `.context()` call transforms a bare I/O error into a diagnostic that tells the operator exactly what the system was trying to do when it failed. In a production trading system, that context is the difference between a five-minute incident diagnosis and a two-hour one.

At library boundaries — public crate APIs that other crates depend on — `anyhow` is the wrong choice. `thiserror` typed error enums are used instead:

```rust
#[derive(Debug, thiserror::Error)]
pub enum FactorError {
    #[error("insufficient data: need {required}, got {actual}")]
    InsufficientData { required: usize, actual: usize },
    #[error("computation failed: {0}")]
    ComputationFailed(String),
}
```

The distinction matters because library callers need to match on error variants. An `anyhow::Error` is opaque — the caller cannot distinguish `InsufficientData` from `ComputationFailed` without string parsing. `thiserror` enums are matchable, which means callers can make runtime decisions based on error type: retry on `ComputationFailed`, skip the factor on `InsufficientData`.

For non-critical failures — optional reads that should not crash the pipeline — `.unwrap_or_default()` is used explicitly. The semantic is: "this failure is expected and recoverable; log a warning, continue execution." This is a deliberate choice, not an oversight. The alternative — propagating every optional failure as a `Result` — would introduce noise into the error-handling layer and make genuine failures harder to find.

`unwrap()` appears in tests and one-time initialization only. There is no `unwrap()` in production paths. This is a hard rule, enforced by `cargo clippy -D warnings` with a `clippy::unwrap_in_result` lint configuration.

### Derive and Attribute Discipline

Every domain struct follows a standard derive set that covers the most common use cases without over-specifying:

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

`Debug` for logging and test assertions, `Clone` for pipeline stage handoffs, `Serialize`/`Deserialize` for Redis and API serialization. No `Copy` unless the type is genuinely trivially copyable. No `Hash` or `Eq` unless the type is used as a map key.

Configuration structs add a deliberate pattern for backward compatibility:

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

The choice to use explicit named functions like `default_max_drawdown()` rather than `impl Default` is intentional. It makes each field's default visible in the source without requiring the reader to find an `impl Default` block. When reviewing a config struct, the default values are right there, annotated on the field. This is self-documenting in a way that `impl Default` is not.

Forward-compatible enums use `#[serde(other)]` to handle unknown variants gracefully:

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FactorInputType {
    Swap, Price, OrderFlow, Cluster,
    #[serde(other)]
    Custom,
}
```

Without `#[serde(other)]`, deserializing a message containing a new `FactorInputType` variant from a newer producer would panic or return an error in an older consumer. With it, the consumer degrades gracefully to `Custom` and continues processing. In a distributed system where producers and consumers are deployed independently, this property is essential.

### Concurrency Primitive Selection

Choosing the right concurrency primitive is one of the decisions that most directly affects runtime performance and correctness. The codebase uses five distinct primitives with clear, documented selection criteria:

`DashMap` is the primary choice for hot-path concurrent reads and writes to shared maps. The signal store, the blackboard, the known-borrowers registry, and the correlation monitor all use `DashMap`. The reason is fine-grained per-shard locking: rather than a single global lock over the entire map, `DashMap` partitions the key space across multiple shards, each with its own lock. In paths where 100 or more factor evaluations occur per pipeline tick, this eliminates the serial bottleneck that a single `RwLock<HashMap>` would create.

`Arc<RwLock<>>` is reserved for slower-changing config state that is read-heavy but infrequently written. The `ExecutionPipeline.config` and the attribution state use this pattern. The global lock cost is acceptable when writes happen on a seconds or minutes timescale.

`Arc<Mutex<>>` covers single-writer state — the `event-store` append path, for example. One writer, no concurrent write contention, the simplest correct primitive.

`AtomicBool` handles single-flag reads in the hottest paths. The circuit breaker trip flag is read on every order evaluation. An `AtomicBool` load is a single CPU instruction with no lock acquisition overhead.

`Arc<AtomicI64>` enables lock-free timestamp tracking for data adapter watchdogs. The last-data timestamp needs to be updated by producers and read by watchdog goroutines with no synchronization overhead.

One subtler decision: the polymarket-bot uses `std::sync::RwLock` deliberately, not `tokio::sync::RwLock`. The hot path — signal evaluation and strategy prediction — is CPU-bound, not I/O-bound. The async RwLock adds yielding overhead that is counterproductive when the critical section never awaits. `std::sync::RwLock` is faster for short, synchronous critical sections. Reaching for tokio's async primitives by default in an async application is a common mistake; these are the right tool only when the lock is genuinely held across an `.await` point, which happens rarely.

### Naming Conventions

Naming is where codebases either document themselves or require constant explanation. The conventions here are consistent and meaningful:

Crate names are kebab-case and prefixed by project: `mm-engine`, `factor-swap-momentum`, `exec-paper`. The prefix makes the project namespace clear when working across multiple workspaces. Module names are snake_case following Rust convention: `fair_value.rs`, `spread.rs`, `adverse_selection.rs`. Trait names use PascalCase with a verb-noun structure that communicates the role: `AlphaFactor`, `ExecutionBackend`, `MarketProvider`. Domain types use PascalCase with vocabulary drawn from the problem domain: `AlphaSignal`, `ComposedSignal`, `LendingPosition`, `BookDiff`. Feature flags mirror crate names in kebab-case: `factor-swap-momentum`, `live-signing`, `slow-tests`.

### Code Organization Within Files

Every module follows the same structural ordering: `use` imports first (standard library, then external crates, then workspace crates), then type definitions (`struct` and `enum`), then `impl` blocks (constructors first, then public methods, then private methods), then trait implementations, and finally the test module at the bottom under `#[cfg(test)] mod tests`.

This is not a bureaucratic style choice. When every file follows the same structure, navigating an unfamiliar module is predictable. The type definitions are always in the same place. The constructor is always the first method in the `impl` block. Tests are always at the bottom. A reader who knows the convention knows where to look without searching.

### Builder Pattern for Complex Domain Objects

Complex domain objects that accumulate optional configuration use chainable builders rather than multi-argument constructors. The pattern is applied consistently:

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

The builder pattern here serves a practical purpose beyond ergonomics. It makes optional fields explicit at the call site — the caller is not forced to pass `None` for fields they do not need, which would be the case with a constructor that takes all optional fields as arguments. It also makes the construction sequence readable as prose: create a DataHub, add a tick source, add another tick source, add a REST source, start it.

### Testing Philosophy

The testing strategy is built around a single principle: tests that require external state are expensive to write and expensive to maintain. The design pushes as much logic as possible into pure functions so that tests require no external state at all.

Strategies, algorithms, and risk gates are pure functions — given inputs, they produce deterministic outputs with no network calls, no filesystem access, and no time dependencies:

```rust
#[test]
fn test_garch_fit_short_series() {
    let returns = vec![0.01, -0.02, 0.015, -0.01, 0.005];
    let garch = Garch11::fit(&returns);
    assert!(garch.alpha + garch.beta < 0.999);
    assert!(garch.omega > 0.0);
}
```

Test data is generated inline — no fixture files, no seed databases, no external test data sources:

```rust
#[test]
fn test_hurst_trending_series() {
    let trending: Vec<f64> = (0..200).map(|i| i as f64 * 0.1 + rand()).collect();
    let h = hurst_exponent(&trending);
    assert!(h > 0.5, "trending series should have H > 0.5, got {h}");
}
```

Expensive tests — convergence tests, Monte Carlo simulations, particle filter runs with large particle counts — are gated behind a `slow-tests` feature flag:

```rust
#[cfg(feature = "slow-tests")]
#[test]
fn test_particle_filter_convergence_1000_particles() {
    // ... expensive test
}
```

The separation keeps the default test suite fast enough to run on every commit, while preserving the ability to run the full suite for pre-release validation or CI. A test suite that takes twenty minutes is a test suite that developers stop running.

---

## 3. TypeScript and Frontend Conventions

### Next.js App Router Architecture

The frontend follows the Next.js App Router model (Next.js 15/16) with server components as the default. This is the right default for a dashboard-heavy application: server components reduce the JavaScript bundle delivered to the client, and the initial HTML is fully rendered before the client needs to hydrate. Client components are marked explicitly with the `"use client"` directive, which means the boundary between server and client rendering is always visible in the source.

Routes are organized by domain — `/mm/`, `/lab/`, `/engine/`, `/polymarket/`, `/liquidation/` — rather than by type. Domain grouping means that adding a new feature to the market-making section requires touching only files under `/mm/`, not scattered across a flat route directory. API routes under `/api/` act as proxies to backend services; there are no direct backend calls from client code. This provides a security boundary (client code never exposes backend service URLs) and a single point of control over API access patterns.

### State Management

The state management approach uses two tools with clearly separated responsibilities. Zustand manages global client-side state — UI state, active selections, lists that need to be shared across components:

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
```

SWR manages server-fetched data with one hook per API endpoint:

```typescript
function useMarkets(filters?: MarketFilters) {
  return useSWR(["/api/mm/markets", filters], fetcher);
}
```

The separation is meaningful. SWR handles caching, revalidation, deduplication, and loading states for data that lives on the server. Zustand handles state that is local to the UI session. Mixing these concerns — putting server-fetched data in a Zustand store without SWR — would require manual cache management and manual loading state tracking, both of which SWR handles correctly by default.

### Real-Time Data

Real-time data flows through a custom `useSSE` hook built on the browser's `EventSource` API. The hook implements exponential backoff reconnection — 1 second, 2 seconds, 4 seconds, doubling up to a 30-second maximum — and automatic cleanup on component unmount. Exponential backoff is the correct reconnection strategy for server-sent events: aggressive reconnection after a server restart or network interruption can cause thundering herd problems. The cleanup-on-unmount guarantee prevents stale event listeners from accumulating as users navigate between pages.

### Component Architecture

All UI primitives are built on Radix UI's unstyled, accessible components. The choice of Radix over a styled component library is deliberate: styled component libraries impose visual decisions that are difficult to override without fighting the library. Radix provides correct accessibility semantics — focus management, ARIA attributes, keyboard navigation — while leaving all visual decisions to Tailwind v4. There are no CSS modules, no styled-components, no inline style objects. Every visual decision is expressed as Tailwind utility classes, which means the full styling surface of the application is visible in the markup without context-switching to a separate stylesheet.

---

## 4. Python Conventions

### Strategy Registration in polymarket-bot

The Python strategy layer uses a decorator-based auto-registration pattern that eliminates boilerplate factory code:

```python
@register_strategy("garch-t")
class GarchTStrategy(BaseStrategy):
    def predict(self, market: Market, context: DataContext) -> Prediction:
        # ... pure computation
        return Prediction(direction=..., confidence=..., edge=...)

PROFILE_STRATEGIES = {
    "garch-t": ["GarchTStrategy"],
    "bilateral-mm": ["SpreadDynamicsStrategy"],
    "fair-value": ["BrownianBridge", "HierarchicalCascade"],
}
```

The decorator registers the strategy class by name at import time, making it available for TOML-driven composition without any explicit factory function or switch statement. Adding a new strategy requires only writing the class and adding the decorator — the registration infrastructure handles itself. The `PROFILE_STRATEGIES` map then provides a layer of named profiles that bundle strategies for common use cases, so operators configure profiles rather than individual strategy names.

### Agent Orchestration

The Agent Orchestra's general manager is structured as a seven-phase async pipeline:

```python
class GeneralManager:
    async def run_pipeline(self):
        # 7 phases: launch → wait → analyze → merge → build → test → complete
        await self.launch_agents()
        await self.wait_for_completion()
        await self.analyze_results()
        # ... approval gate on failure
```

The pipeline pauses at merge conflicts, build failures, and test failures and broadcasts a decision card to the dashboard, requiring human approval before proceeding. This is the right safety posture for a system that modifies production source code: automation up to the point of irreversible action, then a human in the loop.

### Zero-Dependency CLI Design

The `claude-init` tool takes an extreme position on dependencies: pure standard library only (`argparse`, `pathlib`, `json`, `os`, `dataclasses`). The entire tool is 1,229 lines in a single file. No virtual environment, no pip install, no dependency resolution. The detection pipeline runs through language identification, framework detection, and project structure analysis to generate `CLAUDE.md`, `settings.json`, agents, skills, and commands tailored to the detected stack.

This design is not premature optimization — it is a genuine usability decision. A tool that requires setup before you can use it to set up your project creates a bootstrap problem. A single Python file that runs on any Python 3.x installation eliminates that problem entirely.

---

## 5. Go Conventions

### Interface Segregation in kokoro-staking

The Go code follows strict interface segregation — adapters implement only the interfaces they actually support, rather than a single large interface with optional methods:

```go
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

This means a chain adapter that supports read queries but not transaction building can implement `StakingReader` and `HealthChecker` without being forced to provide stub implementations of `TxBuilder`. The separation also makes the capability surface of each adapter explicit in the type system: passing a `StakingReader` to a function documents that the function will only read, not submit transactions.

### Financial Safety Discipline

The financial safety rules in the Go code are non-negotiable. `shopspring/decimal` is used for all monetary calculations — never `float64`. IEEE 754 floating-point arithmetic is unsuitable for financial calculations because rounding errors accumulate in ways that are not predictable without careful analysis. `decimal` provides arbitrary-precision arithmetic with deterministic rounding semantics.

`errgroup` handles partial-failure-tolerant cross-chain queries — a query that fails for one chain should not prevent results from being returned for other chains. Private keys never touch the backend; signing is client-side only. Every RPC call is instrumented with Prometheus metrics for latency and error tracking. Structured logging via Zap provides machine-parseable log output for production observability.

---

## 6. Design Decisions and Trade-offs

### Dynamic Dispatch Over Generic Monomorphization for Factors

The factor pipeline uses `Box<dyn AlphaFactor>` in over 50 places rather than generic monomorphization. This is a deliberate performance trade-off, and it is the right trade-off here.

Generic monomorphization would require compile-time factor selection. The factor pipeline is configured via TOML files that specify which factors to run, what their parameters are, and how to compose them. That configuration is read at runtime. There is no way to express runtime-configurable factor composition through Rust generics without either enumerating every possible combination at compile time or reaching for macros that would generate that enumeration automatically.

`Box<dyn AlphaFactor>` solves this cleanly. The vtable lookup overhead is approximately 5 nanoseconds per dispatch. Factor computations are on the order of microseconds. The overhead is negligible. The benefit — users can configure arbitrary factor pipelines in TOML without recompiling the binary — is substantial.

### DashMap Over RwLock<HashMap>

The signal store, blackboard, and correlation monitor all use `DashMap` rather than `Arc<RwLock<HashMap>>`. The rationale is contention reduction under concurrent workloads.

A global `RwLock<HashMap>` means every writer must acquire exclusive access to the entire map. In a pipeline where 100 or more factor evaluations run per tick, and where each factor may need to write to the signal store, a global write lock becomes a serial bottleneck. `DashMap` partitions the key space across shards, each with its own lock. Two writers whose keys hash to different shards never contend. In high-throughput paths, this difference is measurable.

The trade-off is that `DashMap` is slightly more complex than `RwLock<HashMap>` and has a larger binary footprint. For the hot paths in this system, that complexity is fully justified.

### Feature-Gated Factor Registry

The Engine binary uses `#[cfg(feature)]` compilation flags to exclude unused factors, rather than runtime registration with lazy evaluation or dynamic loading. This is a compile-time correctness and performance choice.

The Engine runs frozen, deployed strategies. It does not need all 24 factor implementations available in the Lab environment. The `minimal` feature set compiles in seconds; `all-factors` takes minutes. By excluding factors at compile time, the Engine binary is smaller, faster to build in CI, and carries no dead code. The compile-time boundary also provides a stronger correctness guarantee than runtime feature detection: a factor that is not compiled cannot accidentally be invoked.

### Dual JSON/Proto Format on Redis Streams

The migration from JSON to Protocol Buffers on Redis Streams uses a format auto-detection strategy: messages include an `enc: "proto"` marker, and consumers check for this field to determine how to deserialize the message. Producers emit the format they support; consumers accept both.

This design allows rolling migration with zero coordination between service deployments. An old producer emitting JSON and a new consumer expecting proto coexist without failure. A new producer emitting proto and an old consumer expecting JSON also coexist, because the old consumer can fall back to JSON deserialization when the `enc` marker is absent. The migration can proceed service by service, deployment by deployment, without a coordinated cutover.

The alternative — a flag day where all services simultaneously switch to proto — is incompatible with the independent deployment model. Any production system that requires simultaneous deployments across multiple services has a fragile deployment posture.

### The JSONL Event Store as Deliberate Tech Debt

The `event-store` crate's use of `std::fs` violates the CIL rule. This is tracked and acknowledged. The decision at the time was that an append-only file write was too simple to justify building a full trait abstraction, an adapter, and a test double around it. That is a reasonable judgment for a feature under active development with unclear long-term requirements. When event replay requirements grow and the event store needs to support queries, the migration to PostgreSQL will happen. The debt is bounded and the exit path is clear.

---

## 7. Code Quality Standards and Metrics

### Enforced Quality Gates

Quality is enforced through tooling, not convention. Every Rust project runs `cargo clippy -D warnings` — all lint warnings are treated as compilation errors. `cargo fmt --check` enforces formatting with rustfmt defaults, eliminating formatting discussions entirely. `cargo deny check` audits all dependencies for license compliance and known vulnerabilities. `cargo build --release` must produce zero warnings. `cargo test --workspace` must pass in full.

On the frontend side, Prettier is auto-applied as a pre-commit hook for all JavaScript, TypeScript, CSS, HTML, JSON, and Markdown files. ESLint enforces standard TypeScript rules. These tools run automatically — code that fails formatting or linting cannot be committed.

The value of this approach is not individual rule enforcement. It is that the rules are not negotiable and not forgettable. A developer who has been away from the codebase for two months and comes back to make a change cannot accidentally commit unformatted code or ignore a clippy warning. The tooling enforces the standard without requiring review feedback on mechanical issues.

### Test Coverage by Project

Test density varies by project maturity and domain complexity:

| Project                | Lines of Code | Tests     | Ratio                    |
| ---------------------- | ------------- | --------- | ------------------------ |
| kokoro-alpha-lab       | 242,466       | 1,074     | 1 test per 226 lines     |
| kokoro-mm              | 62,641        | 690       | 1 test per 91 lines      |
| kokoro-polymarket-bot  | 15,491        | 72        | 1 test per 215 lines     |
| kokoro-liquidation-bot | 5,130         | 24        | 1 test per 214 lines     |
| **Total**              | **325,728**   | **1,860** | **1 test per 175 lines** |

`kokoro-mm` has the highest density at 1 test per 91 lines. This reflects the SaaS product's maturity and the importance of correctness guarantees for a system that handles user funds. `kokoro-alpha-lab` at 1 per 226 lines reflects the reality that a large portion of the codebase is signal processing and factor research code where the "test" is often a backtest run rather than a unit test.

### Codebase Scale

The total footprint across all projects:

- Rust: over 330,000 lines
- TypeScript: over 180,000 lines
- Python: over 12,000 lines
- Go: over 15,000 lines
- Rust workspace crates: 100+ across all projects
- Anchor programs: 20
- MCP tools: 115
- REST API endpoints: 200+
- Frontend pages and routes: 150+
- Docker production services: 12+
- Unit and integration tests: 1,860+
- CI/CD pipelines: 8+ repositories

---

## 8. Solidity Conventions

### Flash Loan Contract Design

The Solidity contracts follow a single-responsibility principle taken to its logical conclusion. `FlashLiquidator.sol` does exactly one thing: flash-borrow, liquidate, swap the collateral to repay the debt, and repay the flash loan — all within a single atomic transaction. If any step fails, the entire transaction reverts. There is no partial execution state to clean up.

The `FlashLiquidator` implements the IERC3156-compatible flash loan callback interface, which is the standard Aave V3 uses. The fee tier selection logic for the Uniswap V3 swap is embedded in the contract itself: stable-stable pairs use 0.05%, WETH-stable pairs use 0.05%, and all others default to 0.3%. This logic belongs in the contract, not in the calling code, because it must execute atomically with the rest of the liquidation to guarantee correct swap pricing.

Reentrancy protection is inherently guaranteed by the atomic execution model. The entire operation completes or reverts within a single transaction — there is no external call during which a reentrant attack could occur in a meaningful way.

The Rust integration uses `alloy::sol!` to define ABI interfaces inline, eliminating the need for separate ABI JSON files and an external Solidity compilation toolchain. This reduces build complexity and keeps the contract interface definition co-located with the Rust code that uses it.

### Immutable Contract Design

The contracts have no storage variables beyond immutable constructor parameters, no admin functions, and no upgradeability mechanisms. All parameters are passed through calldata, not storage reads.

This is a deliberate security and trust design. A contract with admin functions requires trusting the admin. A contract with upgradeability requires trusting whoever controls the upgrade key. An immutable contract with no storage is fully auditable at deployment time — the code that runs six months after deployment is identical to the code that was audited. For a flash liquidation contract that handles significant sums in a single transaction, this immutability guarantee is worth more than operational flexibility.

---

## 9. Protocol Buffer and gRPC Conventions

### Proto Schema Design

Package naming follows a consistent domain hierarchy: `kokoro.{domain}.v1`, producing packages like `kokoro.common.v1`, `kokoro.lab.v1`, `kokoro.engine.v1`, `kokoro.platform.v1`, `kokoro.payment.v1`, and `kokoro.artifact.v1`. The version suffix is included from the start, not added when backward incompatibility becomes necessary. This avoids the painful situation of migrating a `kokoro.lab` package to `kokoro.lab.v2` because `v1` was never in the name.

Message names use PascalCase matching the Rust struct names they serialize: `AlphaSignal`, `FactorInput`, `BacktestResult`. This one-to-one naming makes conversion code unambiguous.

Field numbering is sequential and never reused after deprecation. Reusing field numbers after deprecation is one of the most dangerous proto mistakes — it can corrupt old serialized messages when they are read by new code expecting a different type at the same field number. The convention here is permanent retirement: deprecated fields stay reserved forever.

`optional` marks fields that may legitimately be absent. Required fields use direct types. Timestamps use either `google.protobuf.Timestamp` or `i64` Unix milliseconds depending on context — `Timestamp` for fields that need timezone-aware manipulation, Unix millis for fields that are compared arithmetically or stored in Redis.

### gRPC Service Architecture

The gRPC service design uses streaming RPCs where the data is genuinely continuous — `StreamSignals`, `StreamPositions`, `StreamTrades` are server-streaming RPCs. Bulk data upload uses client-streaming with `UploadData`. Request-response interactions — `GetFactors`, `SubmitBacktest`, `DeployBot` — use unary RPCs. The RPC type is chosen to match the actual data flow, not defaulted to unary for simplicity.

The Platform service acts as a proxy to the Engine service. Clients never call Engine directly. This provides a stable API boundary that can absorb Engine internal changes without requiring client updates, and gives the Platform layer a location to enforce authentication, authorization, and rate limiting before requests reach the computation layer.

---

## 10. Database Schema Conventions

### PostgreSQL with SQLx

The PostgreSQL conventions follow standard production patterns with a few specific choices worth noting.

Table names are snake_case and plural: `orders`, `positions`, `backtest_results`. Primary keys are UUIDs from the `uuid` crate — not auto-incrementing integers. UUID primary keys eliminate the possibility of ID collisions when merging data from multiple sources and make records unguessable by external parties.

Every table carries `created_at TIMESTAMPTZ DEFAULT NOW()` and `updated_at TIMESTAMPTZ DEFAULT NOW()` audit timestamps. Soft deletes are not used — the codebase uses hard deletes with foreign key cascades. Soft deletes are operationally convenient but create significant query complexity: every query must include a `WHERE deleted_at IS NULL` clause, and omitting that clause is a silent data integrity bug. Hard deletes with cascades are simpler to reason about.

`sqlx::query_as!` provides compile-time checked typed queries — the query is validated against the actual database schema at compile time, and the result type is inferred from the schema. This catches type mismatches between the Rust struct and the database column before deployment. `sqlx::query!` is used for mutations where the return type is simpler.

The repository trait pattern is consistent throughout: `BacktestRepo`, `EventRepo`, and `PositionRepo` are traits, with `Pg*` implementations for production and in-memory stubs for testing. This is exactly what the CIL pattern requires at the database layer — the domain logic depends on the trait, not the concrete implementation, which means tests can run against an in-memory stub without a database connection.

Migrations use `sqlx migrate` with sequential numbering. `kokoro-mm` has 58 migration pairs, representing a clear record of how the schema has evolved. Connection pooling uses `sqlx::PgPool` with configurable `max_connections`.

### SQLite for Lighter Workloads

SQLite via `rusqlite` is used where PostgreSQL is operational overhead without commensurate benefit: the polymarket-bot (positions, signals, round history) and kokoro-vpn (users, devices, ACLs) use SQLite. The `bundled` feature flag ships SQLite as part of the binary, eliminating any system dependency on a SQLite installation. WAL mode is enabled for concurrent read access, which is the correct SQLite configuration for any application with multiple readers.

---

## 11. Docker and Deployment Conventions

### Multi-Stage Rust Builds

Every Rust service uses a two-stage Docker build. The first stage builds the binary; the second stage copies only the binary into a minimal runtime image:

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

The `Cargo.toml` and `Cargo.lock` are copied before source files. This is the canonical Docker layer caching optimization for Rust: the dependency compilation layer is cached separately from the source compilation layer. A source change that does not affect `Cargo.toml` or `Cargo.lock` skips the dependency compilation step entirely, reducing incremental build times from minutes to seconds.

`debian:bookworm-slim` is the runtime base image rather than `scratch`. The reason is pragmatic: Rust binaries built against the system OpenSSL need `ca-certificates` and `libssl` to make HTTPS connections. A `scratch` base would require static linking against musl and a separate cross-compilation target, which adds build complexity. `bookworm-slim` provides the necessary runtime libraries with a minimal footprint.

Each container runs a single binary. No multi-service containers. Every container exposes a `GET /health` endpoint for Docker health check configuration.

### Docker Compose Operational Discipline

Service dependencies use `depends_on: condition: service_healthy` rather than `depends_on` alone. The `service_healthy` condition waits for the dependency's health check to pass before starting the dependent service, which prevents startup race conditions where a service begins processing before its database is ready.

Volume naming follows `<service>-data` for persistent data and `<service>-config` for configuration. All services share a single default network per compose file, with explicit port mapping only for externally-accessible services. Internal service-to-service communication happens over the Docker network without external port exposure, which is the correct network isolation posture for a production deployment.

Secrets are managed through `.env` files that are never committed to git. `.env.example` files with placeholder values are committed instead, providing a template for new deployments without exposing credentials. The distinction between `.env` (secret) and `.env.example` (template) is enforced by the project-level `.gitignore`.

All production services use `restart: unless-stopped`, which means containers automatically restart after crashes or host reboots while still respecting explicit `docker stop` commands. This is the right restart policy for long-running production services — automatic recovery from unexpected failures without preventing intentional shutdowns.

---

## Closing Observations

The patterns described above reflect a consistent set of values: prefer simplicity that is provably correct over sophistication that requires discipline to use correctly; make constraints enforced by tooling rather than convention; and match architectural complexity to actual operational requirements rather than anticipated ones.

The CIL pattern is simple to explain and trivially enforceable by the Rust compiler. The two-tier error handling strategy is simple to follow once the distinction between application code and library boundaries is clear. The concurrency primitive selection table represents a set of decisions made once and then applied consistently. The test philosophy — pure functions, inline data, feature-gated expensive tests — eliminates an entire category of test infrastructure complexity.

None of these decisions are novel. What is notable is the consistency with which they are applied across a codebase that spans five languages, twelve Docker services, and hundreds of thousands of lines of production code written under the time and resource constraints of a solo developer building multiple production systems simultaneously.

Consistency at this scale is itself an architectural property. It means that the patterns described here are not aspirational — they are observably present in the code, across every project, at every layer of the stack.
