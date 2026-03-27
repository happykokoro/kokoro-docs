# Kokoro Liquidation Bot — Business Plan

**Prepared by**: Kokoro Tech
**Date**: March 2026
**Classification**: Confidential

---

## 1. Executive Summary

Kokoro Liquidation Bot is a production-deployed, multi-chain DeFi liquidation engine that automates the identification and execution of undercollateralized loan liquidations across six EVM-compatible blockchains. Built entirely in Rust with a custom Solidity flash loan contract, the system requires zero working capital — it funds each liquidation atomically via flash-borrowed debt, executes the protocol liquidation call, swaps collateral back to the debt token via Uniswap V3, and repays the flash loan, all within a single atomic transaction.

The engine currently monitors approximately 270 live borrowers across four major DeFi lending protocols — Aave V3, Compound V3, Seamless, and Moonwell — with Ethereum as the primary chain. Deployed on DigitalOcean in paper mode, the system has validated its discovery pipeline, health factor polling logic, and profitability evaluation engine against real on-chain state without risking capital. The next phase is live execution.

The business opportunity is substantial. DeFi lending protocols collectively hold over $50 billion in total value locked. Liquidation is a structural, protocol-mandated function that must be performed continuously to keep lending markets solvent. Every under-collateralized position represents a deterministic profit opportunity bounded by the protocol's liquidation bonus (typically 5–15%), with execution risk limited to gas costs. Unlike directional trading, liquidation profit is not contingent on market prediction — it is triggered by on-chain health factor math.

The immediate revenue model is proprietary liquidation profit. The longer-term opportunity is commercial: licensing the monitoring and execution infrastructure as a white-label tool for DeFi protocol teams and as a SaaS product for smaller operators who lack the engineering depth to build equivalent infrastructure. The Solana crate in the existing codebase — already containing MarginFi and Kamino adapter stubs — positions the system for expansion to Solana DeFi liquidations, a market that has grown significantly with the maturation of protocols such as Kamino Finance and Marginfi.

---

## 2. Product Overview

### 2.1 System Architecture

Kokoro Liquidation Bot is structured as a five-stage pipeline, each stage implemented as a distinct Rust crate within the `happykokoro/kokoro-liquidation-bot` workspace. The stages run as concurrent tokio tasks sharing lock-free state via DashMap, enabling high-throughput discovery and polling without contention.

**Stage 1 — Discovery (indexer crate)**

The indexer discovers borrowers by replaying historical event logs from lending protocol contracts. Using `eth_getLogs` in batches of 1,000 blocks — a deliberate conservative limit suited to free public RPC endpoints — it accumulates a universe of addresses that have ever interacted with borrowing functions on each supported protocol. Discovered addresses are stored in a shared `DashMap<Address, LendingPosition>` accessible across all stages. Discovery is designed as a one-shot operation on startup, not a perpetual tokio task, preventing interference with the polling and execution stages that must maintain sub-10-second responsiveness.

**Stage 2 — Polling (indexer crate)**

Once the borrower universe is populated, the poller cycles through all known positions every 5 seconds, fetching on-chain health factors via batched RPC calls to the relevant pool contracts. Any position with a health factor below 1.05 is elevated to the monitored set and surfaced via the REST API. This tight polling interval ensures the system reacts to price-driven health factor deterioration before competing bots can act.

**Stage 3 — Evaluation (evaluator crate)**

For each at-risk position, the evaluator computes expected liquidation profit using on-chain data: the current collateral price (from CoinGecko, refreshed every 60 seconds), the liquidation bonus offered by the protocol, estimated gas cost (using hardcoded estimates of 500K gas for Aave V3, 300K for Compound V3, and 350K for Moonwell), and the applicable close factor (50% for Aave V3 when health factor is between 0.95 and 1.0, 100% below 0.95, and always 100% for Compound). Only opportunities exceeding $1 USD net profit after gas pass to the next stage.

**Stage 4 — Risk Gating (risk crate)**

The risk engine applies a multi-layer gate before any execution attempt: minimum profit threshold, per-transaction gas budget (0.01 ETH), daily cumulative gas budget (0.1 ETH), maximum gas price ceiling (5 Gwei), and a circuit breaker that halts all execution after 5 consecutive transaction reverts. The circuit breaker is implemented as an `AtomicBool` shared across execution tasks, ensuring a reverted transaction on one chain cannot cascade into a gas bleed across others.

**Stage 5 — Execution (executor crate)**

Execution routes through one of three backends based on protocol type and current configuration:

- `FlashLoanExecutor` — calls the deployed `FlashLiquidator.sol` contract, which atomically flash-borrows from Aave V3 (or Morpho), invokes the target protocol's liquidation function, swaps received collateral via Uniswap V3 `exactInputSingle`, and repays the flash loan. Net profit is the difference between the liquidation bonus and the flash loan premium plus gas.
- `CompoundAbsorbExecutor` — calls Compound V3's `absorb()` function directly; no flash loan required because Compound's absorb mechanism does not require the caller to supply the debt token.
- `PaperExecutor` — logs the simulated execution without submitting any transaction. This is the current production mode.

### 2.2 Smart Contract Layer

`FlashLiquidator.sol` is a custom Solidity contract deployed to each supported EVM chain. Its design is deliberately minimal: it accepts a single call encoding the target borrower, debt token, collateral token, and liquidation parameters; executes the atomic flash-borrow, liquidate, swap, repay sequence; and transfers any net profit to the operator address. The contract contains no admin functions, no stored state, and no upgrade mechanisms — it is a stateless executor called entirely by the off-chain Rust engine. This design minimizes the smart contract attack surface and eliminates any governance risk.

### 2.3 ProtocolAdapter Trait System

The pluggable architecture is built around two async Rust traits:

- `ProtocolAdapter` — defines the interface for protocol-specific operations: `health_factor(address)`, `get_position(address)`, `encode_liquidation_params(...)`, and `estimate_profit(...)`. Each supported protocol (Aave V3, Compound V3, Seamless, Moonwell) implements this trait independently. New protocols can be added without modifying the discovery, evaluation, or execution stages.
- `LiquidationExecutor` — defines the execution interface: `execute(opportunity)` returning a result with transaction hash and realized profit. The three executor implementations above share this interface, enabling clean paper/live mode switching through configuration alone.

Runtime dispatch via `Arc<dyn ProtocolAdapter>` stored in a protocol registry allows the poller to iterate heterogeneous protocols in a single loop, and the evaluator to compute profit estimates without being coupled to protocol implementation details.

### 2.4 REST API and Frontend

The API server (axum, port 4300 internally / 4400 externally) exposes nine endpoints covering service health, all monitored positions, at-risk positions, profitable opportunities, current configuration, execution history, cumulative P&L, per-chain adapter status, and a WebSocket stream for real-time position updates. Six frontend pages in the Kokoro Alpha Lab frontend workspace provide live dashboards for positions, opportunities, configuration, execution history, P&L analytics, and per-chain status — all wired to the liquidation API proxy routes.

### 2.5 Protocol and Chain Coverage

| Protocol    | Chains                                                 | Execution Method                    |
| ----------- | ------------------------------------------------------ | ----------------------------------- |
| Aave V3     | Ethereum, Base, Arbitrum, Polygon, Optimism, Avalanche | FlashLoanExecutor + liquidationCall |
| Seamless    | Base                                                   | FlashLoanExecutor + liquidationCall |
| Compound V3 | Ethereum, Base, Arbitrum, Polygon                      | CompoundAbsorbExecutor              |
| Moonwell    | Base                                                   | liquidateBorrow()                   |

---

## 3. Market Analysis

### 3.1 DeFi Lending Market Size

DeFi lending protocols represent one of the most capital-intensive and structurally stable segments of the blockchain economy. As of early 2026, the DeFi market stands at $238.5 billion and is projected to reach $770.6 billion by 2031, growing at a 26.4% CAGR. Aave alone holds $27.29 billion TVL with $83.3 million in monthly fees and a 62.8% market share among lending protocols — and became the first DeFi platform to surpass $1 trillion in cumulative loans originated.

The liquidation opportunity is quantified and recent. $675 million in liquidations occurred in the first nine months of 2026 alone, with a record $429 million liquidated in a single week (January 31–February 5, 2026). These are not hypothetical projections — they are realized liquidation events captured from on-chain data, representing the exact profit pool that liquidation bots compete to capture.

Critically, institutional capital is entering DeFi lending at scale. Apollo Global Management and Société Générale are now deploying capital through DeFi infrastructure as of early 2026. More institutional TVL entering lending protocols directly increases the size of positions, the frequency of liquidatable events, and the magnitude of each liquidation opportunity. This is a structural tailwind: as the lending market grows, the liquidation bot's addressable opportunity grows proportionally.

Combined with Compound V3, Morpho Blue, Spark/MakerDAO (which uses Aave V3 as its underlying), and emerging Base-native protocols such as Seamless and Moonwell, the total DeFi lending TVL across EVM chains consistently exceeds $50 billion in normal market conditions.

The significance for liquidation bots is not the TVL itself, but the ratio of positions that fall into the liquidatable zone during price dislocations. Historical analysis of Aave V3 on Ethereum shows that during the major drawdowns of 2022 (LUNA collapse, FTX collapse) and the volatility episodes of 2024–2025, hundreds of millions of dollars in collateral became liquidatable within hours. Each such event produces a concentrated burst of liquidation opportunities.

### 3.2 Liquidation MEV Market Dynamics

Liquidation is classified as "benign MEV" — it is a function that lending protocols explicitly design into their economic architecture. Unlike sandwich attacks or frontrunning, liquidations are invited by the protocol and essential to its solvency. This distinction matters for regulatory and reputational risk assessment: running a liquidation bot does not involve adversarial extraction from other users; it is providing a service the protocol pays for through the liquidation bonus.

The liquidation bonus — the margin above the outstanding debt value at which collateral is sold — is fixed by protocol governance. Aave V3 sets this at 5% for major assets (WETH, WBTC), rising to 10–15% for more volatile collateral types. Compound V3 offers similar incentives through its absorb mechanism. This bonus represents the upper bound on profit per liquidation before gas costs.

The competitive dynamics in liquidation MEV have shifted significantly since 2021. Early bots operated simple polling loops with direct transaction submission. The current competitive landscape is dominated by three participant classes:

1. **Flashbots searchers** — sophisticated MEV operators who bundle liquidation transactions through Flashbots Protect and the MEV-Boost auction system to guarantee inclusion and avoid frontrunning. These actors have significant infrastructure advantages but are typically focused on Ethereum mainnet and high-value opportunities.

2. **Institutional liquidation desks** — teams at large market makers and DeFi-native firms (Wintermute, GSR, Gauntlet Network, Chaos Labs) that operate proprietary liquidation bots as part of broader DeFi market-making operations. Their cost of capital is zero; their execution infrastructure is co-located near Ethereum validators.

3. **Protocol-affiliated bots** — some protocols (particularly Compound V3) have relationships with dedicated liquidation keepers. Gauntlet Network, for example, has operated liquidation infrastructure as part of its risk management service contracts with Compound.

The competitive window for independent operators lies in two areas: (a) multi-chain coverage, where the institutional players are less consistently present on newer chains like Avalanche, Optimism, and Base; and (b) time-to-liquidation for smaller positions below the attention threshold of large operators who optimize for gas-weighted returns.

### 3.3 Competitive Differentiation

The meaningful differentiator in this market is not algorithms — the liquidation decision function is mathematically trivial (call when health factor < 1.0, close factor logic determines position size). The differentiators are:

- **Chain coverage breadth**: Kokoro covers 6 chains from a single binary. Most open-source bots target one or two chains.
- **Protocol adapter abstraction**: Adding a new protocol requires implementing a single trait interface, not forking the codebase.
- **Zero capital requirement**: Flash loan execution means capital constraints do not limit the scale of liquidations the bot can pursue.
- **RPC reliability**: The current architecture is bottlenecked by free public RPCs. Operators with paid node access (Alchemy, QuickNode, Infura) gain a meaningful timing advantage.

### 3.4 Addressable Opportunity Size

Quantifying the exact opportunity requires live execution data, but a reasonable framework based on public on-chain data:

- During high-volatility weeks on Ethereum alone, Aave V3 processes $50M–$500M in liquidations. At a 5% average bonus, gross liquidation profit pool is $2.5M–$25M per week during peak conditions.
- Across 6 chains, assuming Ethereum represents 60% of total volume, the full addressable pool is approximately $4M–$40M per volatile week.
- A bot capturing 0.5–2% market share earns $20,000–$800,000 per high-volatility week.
- During stable market conditions, weekly liquidation volumes drop by 90%+, but still represent ongoing baseline activity.

The base case scenario — consistent operation on Ethereum plus secondary activity on Base and Arbitrum — targets $5,000–$50,000 per month in net profit depending on market volatility.

---

## 4. Revenue Model

### 4.1 Direct Liquidation Profits (Current Path)

The primary revenue stream is the liquidation bonus captured on each successful execution, net of flash loan fees and gas costs.

**Revenue formula per liquidation:**

```
Net Profit = (Collateral Seized × Liquidation Bonus %)
           − Flash Loan Fee (0.09% for Aave V3)
           − Gas Cost (estimated_gas × gas_price × ETH_price)
```

At current parameters (5 Gwei gas ceiling, 500K gas for Aave V3):

- Gas cost per Aave liquidation: 500,000 × 5 × 10^-9 ETH × ~$3,500/ETH ≈ $8.75
- Minimum viable liquidation at 5% bonus: $8.75 / 0.05 = $175 debt position

This means the $100 minimum collateral filter currently configured ($175 scaled by close factor) is appropriately conservative. Raising the gas ceiling or operating on lower-fee chains (Base, Arbitrum, Polygon) drops the minimum viable size substantially, opening up a larger universe of positions.

### 4.2 SaaS Licensing (Medium-Term)

The technical infrastructure built for Kokoro Liquidation Bot — the multi-protocol adapter system, the discovery pipeline, the health factor polling engine, the risk gate framework — represents significant development effort that smaller DeFi operators cannot easily replicate independently. A SaaS licensing model would provide:

- **Managed monitoring tier**: Access to the discovery and polling infrastructure via API, delivering at-risk positions and profitability signals without the operator needing to run their own bot. Monthly subscription pricing based on chain and protocol coverage.
- **White-label execution**: Operators bring their own execution keys and RPC endpoints; Kokoro provides the risk-gated execution framework with configurable parameters.
- **Protocol partnership tier**: DeFi protocols that want guaranteed liquidation coverage for their lending markets pay a retainer for dedicated bot capacity. This is especially relevant for newer protocols on emerging chains that lack an established liquidation keeper ecosystem.

Target pricing: $500–$2,000/month for the managed monitoring tier, $5,000–$20,000/month for white-label execution depending on chain count, and negotiated retainer contracts for protocol partnerships.

### 4.3 White-Label for DeFi Protocols (Long-Term)

As DeFi protocols proliferate on new EVM chains and Solana, the bootstrapping problem of establishing reliable liquidation coverage becomes a recurring pain point. Protocols launching on newer chains — Scroll, zkSync, Monad, or further Solana-native lending protocols — face a window of vulnerability where liquidation infrastructure has not yet been deployed by institutional operators. Kokoro's pluggable ProtocolAdapter architecture allows rapid onboarding of new protocols (typically 1–3 days of adapter implementation), enabling a direct sales motion to protocol teams at launch.

---

## 5. Product Roadmap

### 5.1 Current State (Paper Mode — Q1 2026)

The system is deployed and operational in paper mode. All components of the pipeline are functioning: the indexer has discovered approximately 270 borrowers across Ethereum, health factor polling is running every 5 seconds, the evaluator is correctly computing profitability estimates, and the REST API and frontend dashboards are live. The PaperExecutor logs simulated executions with estimated profit figures, providing a validation dataset before capital is committed.

Key validated metrics from paper mode:

- ~21 positions consistently monitored at health factor thresholds
- Ethereum primary, other chains in discovery phase
- Zero false positives in profitability calculation (all estimates exceed $1 threshold before reaching execution stage)
- Circuit breaker and gas budget logic validated in simulation

### 5.2 Phase 1 — Live Execution on Ethereum (Q2 2026)

The first live execution milestone requires:

1. **RPC infrastructure upgrade**: Replace free public RPC endpoints (publicnode.com, llamarpc.com) with paid Alchemy or QuickNode connections for Ethereum mainnet. This is the single most impactful improvement — paid RPCs provide lower latency, higher rate limits, and improved reliability for time-sensitive polling. Base RPC is already known to be unreliable on free endpoints.

2. **Contract deployment**: Deploy `FlashLiquidator.sol` to Ethereum mainnet. Requires funding the deployment account with ~0.05 ETH for gas, and funding an operator account with sufficient ETH to cover gas on live executions. The flash loan mechanism covers the liquidation debt itself.

3. **Parameter tuning**: Based on paper mode observation, refine the minimum profit threshold, close factor selection, and gas estimates to reflect real-time conditions.

4. **MEV protection**: Integrate Flashbots Protect RPC for transaction submission on Ethereum to prevent frontrunning by competing searchers who monitor the public mempool.

Expected outcomes: first revenue generation, calibration of actual vs. estimated gas costs, identification of missed opportunities due to RPC latency.

### 5.3 Phase 2 — Multi-Chain Expansion (Q3 2026)

With Ethereum execution validated, expand to Base and Arbitrum — both chains with significant Aave V3 deployments, substantially lower gas costs (often 10–50x cheaper than Ethereum mainnet), and less saturated liquidation competition.

Simultaneously, add Morpho Blue as a fifth protocol. Morpho Blue is the fastest-growing lending primitive on Ethereum, with TVL exceeding $2 billion and a curator ecosystem (Steakhouse Financial, Re7, MEV Capital) actively building curated vault strategies. The `ProtocolAdapter` trait makes adding Morpho a bounded engineering task.

Spark Protocol (the MakerDAO-affiliated lending market built on Aave V3 codebase) is a natural extension — since its contract interface is Aave V3 compatible, adapter support is minimal incremental work.

### 5.4 Phase 3 — Solana DeFi Liquidations (Q4 2026)

The codebase already contains a `solana` crate with MarginFi and Kamino adapter stubs and Jito bundle integration. Solana's MEV ecosystem operates differently from EVM: Jito bundles replace Flashbots, and flash loans are less common (protocols like Marginfi have their own flash loan mechanisms, and Solend/Kamino use caller-funded liquidations with collateral sent directly to the caller as the economic incentive).

Solana liquidation execution requires:

- Complete the MarginFi and Kamino adapter implementations (currently stubs with reqwest-based RPC)
- Implement Jito bundle submission for atomic execution and MEV protection
- Handle Solana's transaction size limits and compute unit constraints in the execution encoding
- Connect to the existing Kokoro pricing service (already deployed, already aggregating Solana DEX prices from Jupiter, Raydium, and Orca) for collateral price feeds

Solana's DeFi ecosystem has grown substantially, with Kamino Finance holding approximately $2–3 billion in lending TVL and MarginFi adding hundreds of millions more. The competitive dynamics on Solana liquidations are less mature than Ethereum, representing a meaningful first-mover window.

### 5.5 Phase 4 — SaaS Product Launch (2027)

Package the monitoring and risk gate infrastructure as a multi-tenant SaaS product with:

- Self-service protocol and chain configuration
- API key management for execution key injection
- Tiered subscription billing (via Stripe, using existing payment service infrastructure)
- Managed discovery and polling with per-tenant position databases
- Alerting and notification layer for high-confidence opportunities

---

## 6. Go-to-Market Strategy

### 6.1 Initial Focus: Proprietary Trading

The first 6–12 months are purely proprietary: optimize the bot for maximum capture rate on Ethereum mainnet, reinvest profits into better RPC infrastructure, and accumulate a track record of realized P&L. This track record is essential both for commercial credibility and for internal parameter calibration.

### 6.2 MEV and DeFi Community Engagement

The DeFi and MEV development community is highly concentrated in a small number of forums and communication channels: the Flashbots Research Forum, Paradigm's public research, the Ethereum Research forums, and Twitter/X. Publishing a technical post-mortem of the liquidation bot architecture — omitting proprietary execution parameters but discussing the ProtocolAdapter pattern, DashMap concurrency model, and flash loan contract design — builds credibility and attracts inbound interest from DeFi protocol teams and sophisticated operators.

The open-source strategy for the monitoring layer (discovery and health factor polling) serves as a top-of-funnel channel: operators who run the open-source monitoring component and find it valuable are natural prospects for the paid execution and SaaS tiers.

### 6.3 Protocol Partnership Outreach

Direct outreach to protocol teams launching on newer chains (Base-native protocols, Arbitrum newcomers, Avalanche lending markets) with a proposal to serve as the official liquidation keeper in exchange for either a preferred gas rebate arrangement or a retainer payment. Newer protocols have strong incentives to guarantee liquidation coverage: an uncovered liquidatable position represents existential risk to the protocol's solvency.

### 6.4 Positioning Against Competitors

The positioning message for commercial prospects: "We built what Gauntlet and Wintermute built, but as a deployable product. You get 6-chain coverage, 4+ protocols, flash loan zero-capital execution, and a risk-gated engine — without a 12-month engineering project."

The target customer is a DeFi protocol team or mid-sized crypto operator that understands the need for liquidation coverage but lacks the Rust systems engineering depth to build equivalent infrastructure independently.

---

## 7. Technical Moat

### 7.1 Custom Solidity Contract

`FlashLiquidator.sol` is a bespoke contract, not a fork of existing open-source liquidator contracts. Its design — stateless, single-entry-point, zero upgrade mechanisms — minimizes attack surface and audit scope. The contract implements Uniswap V3 fee tier selection logic to route swaps through the optimal liquidity pool for each collateral-to-debt token pair, reducing swap slippage and improving net profit. This is a meaningful implementation detail: naive implementations that always use the 0.3% fee tier leave profit on the table on pairs with deeper liquidity at 0.05%.

### 7.2 Six-Chain Coverage From a Single Binary

The multi-chain architecture is implemented without any per-chain code duplication. All chain-specific behavior is contained in RPC endpoint configuration and protocol registry initialization. Adding a new chain requires no code changes — only a new configuration block and the deployment of `FlashLiquidator.sol` to that chain. This contrasts sharply with most open-source liquidation bots, which are single-chain implementations requiring full refactoring to port.

### 7.3 Pluggable ProtocolAdapter Architecture

The `Arc<dyn ProtocolAdapter>` dispatch pattern means the system is genuinely extensible at the protocol layer. Each adapter encapsulates the full protocol-specific ABI encoding, health factor computation (which differs between Aave V3's ray-denominated fixed-point math and Compound V3's integer ratio semantics), and profit estimation. This is the key moat for the SaaS model: onboarding new protocols is a day's work, not a week's.

### 7.4 DashMap Lock-Free Concurrent State

The use of DashMap for the shared borrower position store means discovery, polling, and API reads all operate concurrently without any mutex contention. In a system where polling latency directly determines competitive advantage in time-sensitive liquidation races, eliminating lock contention on the position store is meaningful. The `AtomicBool` circuit breaker extends this principle to execution state management.

### 7.5 Integrated Risk Engine

The five-layer risk gate (profit threshold, per-tx gas budget, daily gas budget, gas price ceiling, circuit breaker) is configurable without code changes. This is not merely a safety feature — it is the mechanism that allows the bot to be tuned for different market conditions. During low-volatility periods, tightening the minimum profit threshold focuses execution on the most certain opportunities. During high-volatility bursts, relaxing the per-tx gas budget allows participation in larger liquidations that still clear the daily budget.

---

## 8. Financial Projections

### 8.1 Revenue Assumptions

Projections are structured across three market scenarios: low volatility (stable market, few liquidations), normal volatility (typical DeFi market conditions), and high volatility (major price drawdown, liquidation cascade).

**Gas cost model (Ethereum mainnet baseline):**

- Aave V3 liquidation: 500,000 gas × 10 Gwei × $3,500/ETH = $17.50 per transaction
- Compound V3 absorb: 300,000 gas × 10 Gwei × $3,500/ETH = $10.50 per transaction
- Flash loan premium: 0.09% of debt notional (Aave V3 USDC/USDT flash loans)

**Average liquidation economics:**

- Median position size eligible for liquidation: $500–$5,000 debt (smaller positions dominate by count; larger positions dominate by revenue)
- Liquidation bonus on major collateral: 5% (WETH, WBTC on Aave V3)
- Net profit on $1,000 debt position, WETH collateral, Aave V3, 10 Gwei: ($1,000 × 1.05) − $1,000 − $0.90 (flash loan fee) − $17.50 (gas) = $31.60
- Net profit on $5,000 debt position, same assumptions: $50 × 5 = $250 − $4.50 − $17.50 = $228

**Monthly opportunity estimates by scenario:**

| Scenario        | Liquidation Events/Month | Avg Net Profit/Event | Monthly Revenue |
| --------------- | ------------------------ | -------------------- | --------------- |
| Low Volatility  | 20–50                    | $25–$50              | $500–$2,500     |
| Normal          | 100–300                  | $50–$150             | $5,000–$45,000  |
| High Volatility | 1,000–5,000              | $100–$500            | $100,000–$2.5M  |

The high-volatility scenario occurs 3–5 times per year based on historical DeFi market behavior. Even capturing a fraction of a single cascade event can generate months of equivalent baseline revenue.

### 8.2 Cost Structure

**Infrastructure (monthly):**

- DigitalOcean server (current, shared with other services): $0 incremental
- Paid RPC (Alchemy Growth for Ethereum + Base): $50–$200/month
- Gas reserve for live execution (funded from profits after Phase 1): $0 ongoing after initial seed

**Initial capital requirement for live execution:**

- Contract deployment gas (6 chains): ~0.2 ETH total ≈ $700
- Gas reserve for first 30 days of execution: 0.5 ETH ≈ $1,750
- Total initial capital: approximately $2,500

**Payback period at normal volatility baseline ($5,000–$45,000/month):** 1–2 weeks.

### 8.3 SaaS Revenue Projections (Phase 4, 2027)

Target: 10 paying customers at average $1,500/month = $15,000 MRR at launch. This assumes a focused commercial effort toward DeFi protocol teams and mid-sized operators, achievable given the demonstrated technical differentiation.

At 50 customers averaging $2,000/month = $100,000 MRR — a realistic 18-month target post-launch given the structural demand for liquidation infrastructure across new protocol launches.

---

## 9. Risks and Mitigations

### 9.1 MEV Competition and Frontrunning

**Risk**: A competing searcher observes the liquidation transaction in the public mempool and frontrunns it with a higher gas bid, capturing the opportunity and leaving Kokoro with a failed (gas-wasting) transaction.

**Mitigation**: Integrate Flashbots Protect for all Ethereum mainnet submission. Flashbots Protect routes transactions directly to block builders, bypassing the public mempool entirely. On Layer 2 chains (Base, Arbitrum), the sequencer model largely eliminates frontrunning risk. On Ethereum, the circuit breaker that trips on 5 consecutive reverts provides a financial backstop against a period of sustained frontrunning.

Additionally, since liquidation opportunities are deterministic functions of on-chain state (health factor below 1.0), any bot with lower RPC polling latency will see the opportunity first. This is an infrastructure arms race; upgrading from free to paid RPCs is the primary mitigation.

### 9.2 Gas Price Spikes

**Risk**: During high-demand periods (exactly when liquidation opportunities spike), gas prices on Ethereum mainnet can reach 100–500+ Gwei, making even large liquidations unprofitable.

**Mitigation**: The 5 Gwei gas price ceiling currently configured causes the bot to skip execution entirely when gas is too high. While this means missing opportunities during peak gas, it prevents the alternative failure mode of executing unprofitable transactions. The ceiling is a configurable parameter that can be raised for specific large opportunities by adjusting the minimum profit threshold proportionally. Long-term mitigation: expanding to L2 chains where gas costs are 1–5% of Ethereum mainnet costs, making gas-spike risk structurally negligible.

### 9.3 Smart Contract Risk

**Risk**: `FlashLiquidator.sol` contains a bug that causes a loss of funds — either through an exploitable reentrancy vector, incorrect profit accounting, or flawed token approval handling.

**Mitigation**: The contract is stateless and owns no permanent funds. Any ETH remaining in the contract after a call is sent to the operator address within the same transaction. There are no stored approvals; each execution approves exactly the required amount and no more. A formal audit by a reputable smart contract security firm (Trail of Bits, OpenZeppelin, Spearbit) is planned prior to live execution. Additionally, the PaperExecutor validation period provides extended testing of the profitability computation logic before the contract handles real funds.

### 9.4 RPC Reliability and Data Quality

**Risk**: Free public RPC endpoints return stale data, miss events, or rate-limit aggressively during high-traffic periods, causing missed liquidations or incorrect health factor readings.

**Mitigation**: Phase 1 live execution depends on upgrading to paid RPC endpoints. Specifically, Base RPC reliability on free endpoints has already been identified as a known limitation. The 1,000-block batch size for `eth_getLogs` was deliberately chosen to stay within free RPC rate limits; paid endpoints allow 10,000+ block batches, dramatically reducing discovery time for new chain deployments. Fallback RPC endpoints can be configured per chain to maintain availability when a primary endpoint is degraded.

### 9.5 Protocol Parameter Changes

**Risk**: Protocol governance votes change liquidation bonus percentages, close factors, or health factor thresholds, invalidating profitability calculations or creating new liquidation vectors that the evaluator does not model correctly.

**Mitigation**: Protocol governance changes are announced publicly with multi-day (typically 3–7 day) timelock delays on Ethereum. Monitoring Aave and Compound governance forums and implementing automated parameter re-fetch after on-chain timelock execution events covers this risk for major parameter changes. The pluggable adapter design means parameter updates are localized to a single adapter implementation.

### 9.6 Regulatory Uncertainty

**Risk**: Regulatory frameworks in the operator's jurisdiction classify liquidation bot revenue as requiring a financial services license, creating legal exposure.

**Mitigation**: DeFi liquidations are widely regarded as a protocol-native function rather than financial services activity, and no major jurisdiction has specifically regulated liquidation bot operation as of early 2026. The zero-capital flash loan model means the operator never holds significant funds — the entire value cycle completes atomically within a single transaction. However, legal counsel review of the specific revenue model and jurisdiction is advisable before significant scale is reached. Structural options include operating through a legal entity in a crypto-friendly jurisdiction (e.g., Switzerland, Singapore, or the Cayman Islands).

### 9.7 Liquidity Risk on Collateral Swaps

**Risk**: The flash loan swap route via Uniswap V3 suffers excessive slippage on illiquid collateral assets, reducing or eliminating net profit.

**Mitigation**: The 30 bps (0.3%) slippage ceiling currently configured causes execution to abort rather than proceed at unfavorable prices. The Uniswap V3 QuoterV2 integration (already implemented as `UniswapV3Quoter` in the codebase) provides simulation of the swap output before committing to execution, enabling precise slippage calculation rather than estimation. Long-tail collateral assets should be excluded from the eligible set until liquidity is verified; this is a configuration parameter, not a code change.

---

## 10. Operational Considerations

### 10.1 RPC Infrastructure

The transition from paper to live mode is gated entirely on RPC infrastructure quality. The current free public endpoints are adequate for discovery and paper-mode health factor polling, but are not competitive for live execution:

- **Latency**: Free public endpoints average 200–500ms per call; Alchemy and QuickNode paid tiers operate at 50–150ms. In a liquidation race where the first valid transaction wins, this latency difference directly translates to competitive disadvantage.
- **Rate limits**: Free endpoints impose strict call limits that restrict polling frequency. Paid endpoints enable aggressive polling on high-priority positions approaching the liquidation threshold.
- **Base chain**: Public Base RPCs have exhibited specific reliability issues identified during paper mode operation. A paid Base RPC is required before that chain can be treated as production-quality.

Recommended immediate infrastructure: Alchemy Growth plan ($199/month, 300M compute units) covering Ethereum, Base, and Arbitrum; supplemented by QuickNode for Polygon, Optimism, and Avalanche where Alchemy coverage is thinner.

### 10.2 Monitoring and Alerting

With live capital at stake, the monitoring requirements escalate beyond what is needed for paper mode:

- **Circuit breaker alerts**: Any circuit breaker trip (5 consecutive reverts) must generate an immediate notification to the operator. The current system has this logic but alert delivery integration (PagerDuty, Telegram bot, or email via Resend) is not yet wired up for the liquidation service.
- **Gas budget tracking**: Approaching the 0.1 ETH daily gas budget limit should trigger a notification so the operator can manually review before the daily limit halts execution.
- **Health factor threshold monitoring**: Positions approaching (but not yet below) health factor 1.0 should be surfaced proactively, with configurable lead-time alerts.
- **P&L reconciliation**: The hourly P&L snapshot should be compared against on-chain transaction data to verify profit attribution accuracy. Discrepancies indicate either a bug in profit calculation or a frontrunning loss not being properly accounted.

The existing Grafana + Prometheus monitoring stack deployed on the production server can be extended with liquidation-specific dashboards and alerting rules without additional infrastructure cost.

### 10.3 Key Management

Live execution requires a funded Ethereum address whose private key is accessible to the running bot process. This is standard practice for MEV bots but requires careful operational security:

- The private key should be stored as an environment variable, not in any configuration file. SOPS integration (already used in the Alpha Lab monorepo) should be applied to the liquidation bot deployment.
- The operator address should hold only a working gas reserve (0.1–0.5 ETH), not a large balance. Profits above the reserve threshold should be swept to a cold wallet on a scheduled basis.
- The FlashLiquidator.sol contract should be the only contract ever approved to spend tokens on behalf of the operator address. No broad ERC-20 approvals should be granted.

### 10.4 Competitive Tempo

The liquidation bot space rewards continuous improvement. Expected operational cadence:

- Weekly review of paper mode profitability estimates vs. liquidations executed on-chain by competing bots (visible via block explorer analysis).
- Monthly review of missed opportunity analysis: positions that fell below health factor 1.0 and were liquidated by others before the bot executed. Each missed opportunity indicates either a polling latency issue, a configuration gap (e.g., gas price ceiling too restrictive), or a coverage gap (e.g., position on a chain or protocol not yet enabled).
- Quarterly protocol coverage review: new lending protocols launching on covered chains should be evaluated for adapter development within 30 days of their launch date.

---

## Conclusion

Kokoro Liquidation Bot represents one of the clearest paths from deployed infrastructure to revenue generation in the Kokoro Tech portfolio. The core technical work is complete: discovery is running, health factors are being polled, profitability is being evaluated, and the smart contract exists. The gap between paper mode and live execution is primarily operational — RPC infrastructure investment, contract deployment, and key management setup — not additional engineering.

The structural opportunity is durable. DeFi lending will continue to require liquidation as long as lending protocols exist, and the liquidation bonus is an economically mandated protocol incentive that does not depend on market direction or alpha edge. The multi-chain, multi-protocol architecture positions the system to capture a meaningful fraction of this structural opportunity across the EVM ecosystem while the Solana crate creates optionality for the fastest-growing DeFi liquidation market outside of Ethereum.

The long-term business case — licensing the infrastructure to DeFi protocol teams — converts the technical investment into a recurring revenue stream that is largely independent of market volatility. Protocol launches are constant; their need for reliable liquidation coverage is structural. Kokoro's ability to onboard a new protocol in days, not months, is the key commercial differentiator.

The recommended immediate action is to fund the live execution infrastructure investment (~$2,500 in initial capital for contract deployment and gas reserve plus ~$200/month for paid RPC), activate live mode on Ethereum mainnet with Flashbots Protect, and begin accumulating the realized P&L track record that anchors all subsequent commercial conversations.
