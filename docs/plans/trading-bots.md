# Business Plan: Kokoro Trading Bot Ecosystem

### Polymarket Algorithmic Trading & Copy Trading Platform

**Version**: 1.0 — March 2026
**Author**: Kokoro Tech
**Confidential**

---

## Table of Contents

1. Executive Summary
2. Product Overview
3. Market Analysis
4. Lessons Learned from Live Trading
5. Revenue Model
6. Product Roadmap
7. Technical Moat
8. Financial Projections
9. Risks & Mitigations

---

## 1. Executive Summary

Kokoro Tech is building two complementary products targeting Polymarket, the world's largest prediction market exchange with over $1 billion in monthly volume. Together, these products cover both ends of the strategy spectrum: sophisticated quantitative trading driven by statistical models, and social/copy trading that democratizes access to proven traders' positions.

**Kokoro Polymarket Bot** is a multi-strategy algorithmic trading system implemented in Rust and Python. It runs eight parallel strategy pipelines in a single binary, each pursuing a distinct quantitative edge — from GARCH volatility forecasting to Brownian Bridge path conditioning derived from analysis of over 11,000 historical markets. The system features composable risk gates, per-asset Kelly sizing, bilateral market making, and a pluggable Python strategy service for rapid research iteration.

**Kokoro Copy Trader** is a Python bot that monitors high-win-rate traders on Polymarket, discovers their category-specific edge, and mirrors new position entries via GTC limit orders held to resolution. It filters traders by win rate (55% minimum), trade count (20+ settled trades), and profit ($50+ net), then restricts copy activity to only the categories in which each trader has demonstrated real edge.

Neither product is currently active in live trading. The Polymarket Bot is stopped after a live trading failure in March 2026 that produced hard-won lessons about strategy validity, paper testing circularity, and risk gate completeness. The Copy Trader is in paper testing on AWS London. Both represent substantial infrastructure investment — over 15,000 lines of Rust, 1,500 lines of Python, 72 automated tests — that is ready to be deployed against better strategies.

The near-term priority is implementing the Brownian Bridge path conditioning strategy (validated at 100% accuracy across 18 historical samples), per-asset parameter tuning, and the hierarchical cascade signal (77.8% accuracy) before any live capital is deployed. The medium-term vision is a fleet of specialized bots operating across diverse prediction market categories, eventually offered as a managed service with profit sharing.

---

## 2. Product Overview

### 2.1 Kokoro Polymarket Bot

**Repository**: `anescaper/My-First-Bot` (public, commented) + `happykokoro/kokoro-polymarket-bot` (private)
**Stack**: Rust 1.8x + Python 3.12
**Rust LOC**: 15,491 | **Python LOC**: ~1,470 | **Tests**: 72

#### Architecture

The bot is organized into seven Rust crates that form a clean pipeline from market discovery to order execution:

- **scanner** — Discovers live binary option rounds on Polymarket (BTC/ETH/SOL/XRP across 5-minute, 15-minute, and 1-hour timeframes). Aggregates Binance spot and futures WebSocket feeds alongside Polymarket CLOB WebSocket and Pyth oracle data.
- **data** — Pluggable adapter system with `TickAdapter` and `RestAdapter` traits. `DataHub` orchestrates all feeds, builds candles per timeframe, runs a watchdog for automatic reconnection. Pipeline frequency adapts to round proximity: 1-second cadence in the final 30 seconds, degrading to 5-second intervals further out.
- **data-hub** — Separate binary providing candle store, round tracker, and multi-timeframe intelligence (parent-round context, prior child outcomes, 1h/15m/5m hierarchy).
- **risk** — Composable `RiskGateChain` architecture. Each gate implements `Pass / Reject / Resize`. Gates: MinEdge (12% minimum), MaxExposure (25% drawdown), Drawdown, PositionCount (max 10), Volatility. Per-asset multipliers: SOL 1.4x (wider gates for higher vol), ETH 0.9x (tighter). Pending GTC order exposure is counted against all gate calculations.
- **executor** — EIP-712 + HMAC-SHA256 order signing and CLOB submission. Routes between paper and live backends. GTC limit orders with hold-to-resolution logic (no selling before Polymarket oracle settlement).
- **api** — REST and WebSocket API (axum, port 4200), SQLite persistence, backtesting endpoint.
- **bot** — Main binary: 8-pipeline orchestrator, 4 quant modules, 3 strategy tiers, bilateral market making, timeframe intelligence.

#### Three Strategy Tiers

The bot supports three levels of strategy sophistication, selectable via profile configuration:

**Tier 1 — Rust Baseline**: Six static Rust-native strategies including momentum, mean-reversion, regime-aware, and spread-based approaches. Fast execution, no Python dependency.

**Tier 2 — QuantCryptoComposer**: Three hybrid profiles mixing Rust signals with quantitative overlays — GARCH-T (volatility forecasting), Hurst-HInf (H-infinity filtered momentum adjusted for market regime), and FullQuant (all models combined).

**Tier 3 — Python Strategy Service**: A FastAPI service (port 8100) implementing computationally intensive strategies using SciPy, NumPy, and Scikit-learn. Current implementations: GARCH(1,1) MLE with n-step ahead variance forecast, Student-t CDF for tail-risk-adjusted edge estimation, PCA factor model, wavelet decomposition, and the Brownian Bridge path conditioning model.

#### Quantitative Models

**GARCH(1,1)**: Grid search MLE over alpha in [0.015, 0.300] and beta in [0.025, 1.0]. Produces n-step ahead variance forecasts used to scale edge thresholds dynamically. High-volatility regimes tighten entry criteria.

**Hurst Exponent**: R/S analysis on log-returns with OLS regression of log(R/S) versus log(n). Classifies each market as trending (H > 0.6), random walk (H ~0.5), or mean-reverting (H < 0.4). Regime classification feeds into strategy selection.

**Jump Detection**: Z-score threshold at 3.0 standard deviations on log-returns. Triggers position avoidance during abnormal price movement.

**Brownian Bridge Path Conditioning**: The most powerful signal in the stack, derived from empirical analysis of 11,348 historical Polymarket markets. A Brownian Bridge models the conditional distribution of a price path given its starting point and endpoint constraint. Applied to prediction markets, it asks: given that we are at position X in a binary round with Y time remaining, and the parent timeframe moved UP, and the prior two 5-minute children moved DOWN, what is the probability that this round resolves UP? The Q6 research finding: parent=UP, prior children=[DOWN, DOWN] yields p_up = 95% with 100% historical accuracy across 18 occurrences. This is the strategy that should have been live before the March 2026 deployment but was not yet integrated at the time.

**Hierarchical Cascade**: Multi-timeframe signal propagation where 1-hour and 15-minute rounds constrain 5-minute entries. When 1h and 15m direction agree, 5-minute win rate lifts to 77.8% (Q15 research finding). Per-asset edge thresholds from Q7 analysis: SOL 5%, others 3%.

#### Bilateral Market Making

Beyond directional strategies, the bot implements bilateral market making: quoting both sides of the binary market with an inventory-skewed spread. When inventory is long, the bid is widened and the ask is tightened, replicating the Avellaneda-Stoikov inventory management model adapted for binary prediction markets.

### 2.2 Kokoro Copy Trader

**Repository**: `happykokoro/kokoro-copy-trader`
**Stack**: Python 3.12
**Status**: Paper testing on AWS London (18.130.126.48, port 4500)

#### Architecture

The copy trader is a lean Python service with clear separation of concerns:

- **discovery.py** — Scans Polymarket's public data API for traders meeting the filter criteria. Broad scan covers global trades; targeted scan focuses on specific market categories. Filter: 55% win rate minimum, 20+ settled trades, $50+ net profit.
- **monitor.py** — Polls watched traders every 30 seconds for new position entries. Implements position seeding on first encounter (distinguishes existing positions from genuinely new entries) to prevent copying already-resolved markets.
- **copier.py** — Executes GTC limit buy orders for new positions. Operates in paper mode by default, logging hypothetical fills. Holds all positions to resolution — no selling before Polymarket oracle settlement.
- **categories.py** — Classifies markets into 9 categories (crypto excluded, covered by the quant bot). Sports, finance, politics, entertainment, geopolitics, science, climate, economics, and other. Copy activity for each trader is restricted to categories where they have demonstrated 55%+ win rate.
- **db.py** — SQLite with WAL mode. Tracks traders, category stats, copy trades, and known positions.
- **api.py** — FastAPI on port 4500 exposing /api/stats, /api/traders, /api/trades for monitoring.

#### Trader Discovery Criteria

Traders are evaluated on:

- Overall win rate >= 55% (filters out coin-flippers and unlucky participants)
- Minimum 20 settled trades (ensures statistical significance)
- Net profit >= $50 (filters traders who win small and lose big)
- Per-category win rate >= 55% with >= 3 category-specific settled trades (ensures the copy is in the domain of the trader's actual edge)

In the paper testing session, top traders discovered included influenz.eth (86% WR, $77k all-time PnL), ArbitrageFund (76% WR, $39k PnL), and melchior1248 (82% WR). These represent genuine long-term edges on the platform.

#### Position Execution

Positions are entered as GTC limit buys at the current market ask price, sized at max 10% of bankroll per position (max $10 on a $100 bankroll) with a maximum of 10 concurrent positions. All positions are held to resolution, allowing the copied trader's signal to play out against Polymarket's oracle settlement.

---

## 3. Market Analysis

### 3.1 Polymarket as a Market Opportunity

Polymarket has emerged as the dominant prediction market platform globally. Monthly trading volume exceeded $1 billion in late 2024 during the U.S. election cycle, demonstrating both the depth of liquidity and the breadth of user interest. The platform's CLOB (Central Limit Order Book) infrastructure, launched in 2023 via CLOB v2, provides institutional-grade matching and execution comparable to centralized exchanges.

The crypto binary options markets on Polymarket — which ask whether BTC, ETH, SOL, or XRP will close above a reference price within 5-minute, 15-minute, or 1-hour windows — offer continuous trading 24/7 with clear settlement mechanics and no counterparty risk beyond the smart contract. These are the primary target for the Kokoro Polymarket Bot.

Beyond crypto binaries, Polymarket hosts thousands of markets on politics, sports, finance, science, and geopolitics. These markets provide the terrain for the copy trader, which deliberately avoids crypto (covered by the quant bot) in favor of domains where human judgment and domain expertise can generate persistent edge.

### 3.2 The Competitive Landscape

Prediction market trading tools are in an early stage compared to the tooling available for equity or crypto markets. The majority of Polymarket participants trade manually using the web interface. A small number use basic API scripts with simple logic. There are no publicly available multi-strategy bots with composable risk management, no copy trading platforms integrated with Polymarket, and no institutional-grade backtesting infrastructure targeted at prediction markets.

This creates an asymmetric opportunity. A sophisticated, data-driven approach is competing primarily against manual traders and naive automations. The edge does not need to be large to be profitable — even a 55% win rate on a binary market with correct position sizing compounds meaningfully over time.

Indirect competitors include:

- Manual Polymarket traders with large bankrolls and domain expertise
- DeFi arbitrage bots (not targeting the same markets)
- General-purpose trading bots repurposed for prediction markets (no native support for Polymarket's CLOB, no binary-option-specific logic)

The key differentiators of the Kokoro approach are: CLOB-native execution with EIP-712 signing, binary-market-specific risk gates, the Brownian Bridge statistical model derived from empirical analysis of actual Polymarket settlement data, and the combination of quant and copy trading in a unified ecosystem.

### 3.3 Copy Trading in Prediction Markets

Copy trading is well-established in crypto (eToro, Bybit Copy Trading, Binance Copy Trading) and forex (eToro, ZuluTrade). The model is simple: identify traders with proven track records and mirror their positions. The extension of this model to prediction markets is a natural evolution that no platform currently offers natively.

The key difference from crypto copy trading is the binary, hold-to-resolution nature of prediction market positions. There is no need to copy closes or position sizing adjustments — the copy trader enters once and waits for settlement. This simplifies the execution model and reduces slippage risk. The primary alpha source is the top trader's information or judgment advantage, not timing.

The category-specific filtering is the critical innovation over naive copy trading. A trader with 86% overall win rate may derive all of that edge from political prediction markets, performing at chance on sports. By tracking per-category statistics, the copy trader only follows each trader into their domain of genuine knowledge.

---

## 4. Lessons Learned from Live Trading

This section documents the live trading failure of March 17, 2026, in full detail. It is the most valuable part of this document because it captures real-world trading experience that cannot be obtained from backtesting alone.

### 4.1 The Event

At approximately 06:02 UTC on March 17, 2026, the Kokoro Polymarket Bot was activated in live trading mode on a $376 portfolio. The strategy running was `fair_value_dislocation`, which signals DOWN when the current market price is below the bot's estimated fair value reference price.

Over the next twelve minutes, the bot placed 13 orders across 5-minute and 15-minute rounds, deploying approximately $137 against a $100 bankroll (a risk gate failure described below). By 06:17 UTC, the portfolio had dropped to $376.84 with 7 of 8 positions resolving as losses. Net loss after a single SOL UP win: approximately $55.

### 4.2 Root Cause 1 — The Strategy Has Structural Directional Bias

The fair value dislocation strategy computes a reference price from recent Binance candle data and signals DOWN when the Polymarket token price is below that reference. The critical flaw: when crypto has been in a persistent downtrend, the reference price is set during the downtrend, and current prices are reliably below it. The result is that 12 of 13 live signals were DOWN — not because the market was overpriced, but because the reference calculation was contaminated by the same trend it was trying to trade against.

Every position lost because the price, which had dipped below the reference during the round, recovered to the reference by settlement time. This is textbook mean-reversion killing a momentum-chasing strategy. The Polymarket oracle settles on the actual close price, not the intra-round low.

### 4.3 Root Cause 2 — Paper Testing Was Tautological

Before going live, the bot was tested in paper mode and appeared to validate: 3 wins out of 3 trades. This validation was meaningless.

In paper mode, the bot checks resolution by re-querying its own price data at round end. The strategy signals DOWN when price is below reference. Resolution is checked when price is still near that dip. The strategy grades its own homework: it signals DOWN during a dip and checks the result while still in the dip. Live trading uses Polymarket's oracle, which settles at a later time when the price has often mean-reverted.

The lesson is unambiguous: paper testing that uses the same data source and timing as the strategy signal provides no external validity. Real paper testing requires waiting for Polymarket oracle settlement and comparing that result against the bot's prediction.

### 4.4 Root Cause 3 — Risk Gate Incomplete

The risk gates correctly tracked open positions but did not account for pending GTC orders that had been submitted but not yet filled or confirmed. When the bot placed 4 orders on a 15-minute round, then immediately placed 4 more on a 5-minute round, the pending-but-unconfirmed orders from the first batch were not counted against the bankroll. Total deployed reached $137 on a $100 bankroll — 37% over limit.

This bug was fixed after the incident. All pending GTC order exposure is now included in every risk gate calculation.

### 4.5 Root Cause 4 — Hold-to-Resolution Was Bypassed

The bot's position management logic had a code path where a "Round ended" event triggered a SELL order before oracle settlement, overriding the `hold_to_resolution=true` configuration. One position attempted to sell at price=0.0, which the CLOB rejected. This created confusion about whether orders had filled and contributed to the incorrect initial assessment that orders had expired unfilled.

This bug was also fixed: positions with `hold_to_resolution=true` now mark themselves as `pending_settlement` on "Round ended" events and skip the SELL path entirely.

### 4.6 The Brownian Bridge Research

Following the live trading failure, a systematic analysis of 11,348 historical Polymarket binary markets was conducted to identify statistically valid trading signals. The research (documented in issues #61, #69, #73 on the private repository) produced the following findings:

**Q6 — Path Conditioning (Brownian Bridge)**: The most powerful signal found. Among all markets where the parent 1-hour round moved UP and the two prior 5-minute children moved DOWN, the current 5-minute child resolved UP 100% of the time (n=18). A Brownian Bridge model formalizes this intuition: given a known starting state and the constraint that the path must return toward the parent's mean, the probability of a continued DOWN move diminishes with each sequential DOWN child.

**Q15 — Hierarchical Cascade**: When the 1-hour and 15-minute rounds agree on direction, the 5-minute resolution rate improves to 77.8% in the agreed direction (n=54). This is the weakest of the strong signals but provides fallback coverage for rounds where the Brownian Bridge condition is not met.

**Q7, Q10 — Per-Asset Parameters**: SOL requires a minimum edge of 5% (vs. 3% for BTC/ETH/XRP) due to higher idiosyncratic volatility. ETH confidence should be scaled to 90%, SOL to 75%, BTC to 85%, XRP to 80%, reflecting different mean-reversion dynamics per asset.

**Signal Ranking**: The research established a clear hierarchy. Path conditioning (Brownian Bridge) is the strongest signal. Hierarchical cascade is second. 1-hour spread, 15-minute lock, 5-minute spread, and momentum round out the remaining signals. The failed fair-value dislocation strategy was essentially using the weakest signal (#6) while ignoring signals #1-#5.

### 4.7 Key Lessons

The live trading disaster produced the following principles that now govern all development decisions:

1. Paper validation using the same data source and timing as the signal is meaningless — only oracle-verified settlement counts.
2. Bug fixes on a fundamentally flawed strategy accelerate losses, not profits. Clean execution of a bad strategy loses money faster.
3. Risk gates must count all capital at risk, including pending-but-unconfirmed orders.
4. Hold-to-resolution must be architecturally enforced, not configuration-dependent.
5. Mean-reversion in 5-minute rounds eliminates momentum-chasing strategies by default.
6. Systematic directional bias (12/13 signals in one direction) is a strategy failure signal, not alpha.
7. No live deployment without explicit research validation against actual settlement data.

---

## 5. Revenue Model

The revenue model for the trading bot ecosystem combines three complementary streams: direct trading profits, subscription access, and managed service fees.

### 5.1 Direct Trading P&L

The primary revenue source is profits from the bots' own trading capital. Both bots operate on the founder's capital initially, with profit tracked per strategy. As strategies validate in paper mode against real settlement data, capital allocation grows.

The Polymarket Bot targets binary option rounds with a minimum 12% edge requirement. At a 55-60% win rate on binary markets with approximately equal expected payoff, the expected value per trade is 10-20%. Applied to a $1,000 bankroll with Kelly sizing (quarter-Kelly for safety), expected daily trades of 8-15 (given current round frequency), and assuming an average position size of $30-50, estimated daily turnover is $240-750 with an expected PnL of $24-90 per day in favorable conditions.

The Copy Trader at $100 bankroll is a proof-of-concept vehicle. At scale, a $10,000 bankroll copying traders with 70-80% win rates across 20+ simultaneous positions generates meaningful compounding returns.

### 5.2 Signal Subscription Service

As the Polymarket Bot's strategies demonstrate live performance, the signals themselves become a product. Subscribers pay a monthly fee to receive the bot's trading signals (market, direction, confidence, recommended size) without running the bot infrastructure themselves. This is the model used successfully by proprietary signal vendors in crypto and forex.

Pricing tiers:

- Basic ($49/month): Raw signals, no context, 15-minute delay
- Pro ($199/month): Full signals with confidence scores, reasoning, per-asset analytics, real-time delivery
- Enterprise ($999/month): API access, webhook delivery, custom filters, historical signal archive

The signal product requires zero additional infrastructure beyond the already-built bot — it is a revenue layer on top of existing output.

### 5.3 Copy Trader as a Service

The copy trader architecture, once validated in paper mode, can be offered as a managed service. Users deposit USDC, configure their risk tolerance and category preferences, and the service handles discovery, monitoring, and execution on their behalf. Revenue is taken as a percentage of profits (20% profit share, no fee on losses).

This model mirrors successful crypto copy trading platforms and requires no upfront subscription commitment from users. The alignment of incentives (we profit only when users profit) reduces friction for user acquisition.

### 5.4 White-Label Licensing

For larger operations — trading firms, prediction market funds — the bot infrastructure can be licensed as a white-label deployment. The buyer deploys on their own infrastructure with their own API keys. License fee covers setup, customization, and ongoing support. Price: $5,000-15,000 setup + $2,000/month support retainer.

---

## 6. Product Roadmap

### Phase 1 — Validation (Current, 4-8 Weeks)

The immediate priority is validating the Brownian Bridge and hierarchical cascade strategies with real Polymarket settlement data before any live capital is deployed.

**Deliverables:**

- Integrate resolved_rounds data into Python prediction payload (wire DataHub parent-child context to strategy service)
- Implement Brownian Bridge conditional probability table in production code (pattern tables from Q6 research already partially implemented in brownian_bridge.py, needs full wiring)
- Implement hierarchical_cascade.py with per-asset parameters (already implemented as prototype)
- Run paper mode with oracle-verified settlement tracking (not internal price checks) for minimum 4 weeks
- Achieve statistically significant sample: minimum 100 trades per strategy
- Acceptance criteria: >= 55% win rate on oracle-settled paper trades with positive expected value after fees

**Copy Trader:**

- Commit the 4 bug fixes that are currently deployed via SCP but not in git (Issue #5)
- Run continuous paper mode for 4 more weeks to accumulate sufficient resolved trade history
- Target: 50+ resolved trades, 55%+ win rate, positive expected PnL

### Phase 2 — Limited Live Trading (Weeks 8-16)

Once paper validation passes acceptance criteria:

**Quant Bot:**

- Deploy Brownian Bridge profile live with $200 initial bankroll
- Implement automated circuit breaker: stop all trading if rolling 20-trade win rate drops below 45%
- Begin per-asset parameter tuning with live data (SOL/ETH/BTC/XRP behave differently in live vs. paper due to slippage and partial fills)
- Weekly P&L reporting and strategy performance attribution

**Copy Trader:**

- Deploy copy trader live with $200 bankroll
- Monitor for trader drift: re-evaluate all watched traders weekly against updated win rate data
- Add stock price market trader discovery (lower filter thresholds for niche categories)

### Phase 3 — Fleet Scaling (Months 4-8)

With validated strategies and live track record:

**Multi-Strategy Fleet:**

- Deploy 3-4 parallel bot instances with different strategy profiles
- Brownian Bridge bot: $500 bankroll, crypto binaries only
- Hierarchical cascade bot: $500 bankroll, 15-minute rounds
- Copy trader: $1,000 bankroll, non-crypto categories
- General prediction bot: $500 bankroll, broad market coverage

**Infrastructure:**

- Automated strategy selection: route each round to the highest-confidence strategy available
- Position correlation monitoring: prevent over-exposure to the same directional view across multiple bots
- Unified dashboard via the existing Alpha Lab frontend (Polymarket section already built with 107 routes)

**Signal Product Launch:**

- Launch signal subscription at Basic tier
- Collect 3-month live performance track record before opening Pro/Enterprise tiers

### Phase 4 — Platform (Months 8-18)

**Managed Copy Trading Service:**

- Infrastructure for multi-tenant copy trading (each user's capital isolated, separate USDC account)
- Performance fee billing via Stripe integration (already built in Alpha Lab payment service)
- Strategy marketplace: top traders can publish their Polymarket strategy as a copy target

**Advanced Strategies:**

- Extend Brownian Bridge analysis to non-crypto prediction markets (politics, sports have different path dynamics)
- Kalshi integration via the existing multi-venue router in Kokoro MM
- Options-style strategies: combinations of long/short binary positions creating synthetic spread trades

---

## 7. Technical Moat

The combination of the Polymarket Bot and Copy Trader represents a technical position that would take a well-funded team 6-12 months to replicate. The components of this moat are:

### 7.1 CLOB-Native Execution Infrastructure

Both products use a fully native Polymarket CLOB integration — EIP-712 typed signing with manual Keccak256 implementation, HMAC-SHA256 authentication, Polygon on-chain position settlement, CTF token redemption. This is not a wrapper around a third-party library. The low-level understanding of order signing, fill detection, and settlement mechanics enables optimizations (GTC order management, hold-to-resolution enforcement) that are impossible with higher-level abstractions.

### 7.2 Composable Risk Gate Architecture

The `RiskGateChain` in the quant bot is the kind of infrastructure that separates serious trading systems from hobby bots. Each gate is independently testable, can return Pass/Reject/Resize, and operates on a complete view of current risk including pending orders. Adding a new risk constraint is a matter of implementing one trait method. Most competing bots have a single hardcoded stop-loss.

The architecture also enforces separation between strategy logic and risk logic. A strategy produces a signal with an edge estimate. The risk layer decides whether and how much to trade. This separation means a strategy can be swapped without touching the risk system and vice versa.

### 7.3 Python Strategy Service with Scientific Stack

The Python strategy service provides access to the full scientific Python ecosystem (NumPy, SciPy, scikit-learn, arch) without sacrificing the performance of the Rust pipeline. The Rust bot does what Rust is good at: data collection, order management, risk gate evaluation, execution. Python does what Python is good at: statistical modeling, research iteration, numerical optimization.

The GARCH(1,1) MLE implementation using SciPy optimization, the Student-t CDF for edge estimation, and the PCA factor model are all research-grade implementations that would be extremely difficult to replicate in pure Rust without significant engineering investment.

### 7.4 Empirical Research Foundation

The Brownian Bridge signal is not a hypothesis borrowed from academic finance. It is derived from analysis of 11,348 actual Polymarket settlement outcomes, looking for conditional probability patterns in the specific binary option structure of the platform. This kind of platform-specific empirical research is the highest-quality edge source available.

The research methodology — formulating questions (Q1-Q15), analyzing historical data, computing win rates at specific conditioning levels, and maintaining a hierarchy of signal strength — is a repeatable framework that can be extended to other market categories and other conditioning variables indefinitely.

### 7.5 15.5K Lines of Rust in 7 Crates

The quant bot's Rust codebase is not a prototype. It has 72 automated tests, adaptive polling frequency, multi-source data aggregation with watchdog reconnection, EIP-712 signing, and a structured pipeline that has been tuned through multiple deployment iterations. Rebuilding this from scratch would require weeks even for a senior Rust developer familiar with Polymarket's API.

The copy trader's Python codebase, while simpler, incorporates lessons about Polymarket's API quirks that are not documented anywhere — the unreliability of the Gamma API's condition_id lookup for multi-outcome events, the need for position seeding to distinguish existing from new positions, the behavior of partial fills in the CLOB. These are bugs that would have to be found again by any new implementer.

### 7.6 Data Hub Integration

The quant bot's DataHub aggregates five real-time data feeds: Binance spot WebSocket, Binance futures WebSocket, Polymarket CLOB WebSocket, Deribit options data, and Pyth oracle prices. Multi-timeframe candle building, parent-child round tracking, and cross-asset state are maintained in a shared data structure accessible to all 8 pipeline instances. This unified view of the market is the foundation for the hierarchical cascade signal — the 1-hour and 15-minute round data needed to condition 5-minute trades is continuously available.

---

## 8. Financial Projections

All projections are based on the statistical properties of the validated strategies and known market parameters. They represent expected values under continued strategy validity and are not guarantees.

### 8.1 Strategy Expected Values

**Brownian Bridge (Best Case Scenario)**

- Historical accuracy: 100% across 18 samples (small n, requires live validation)
- Conservative live estimate: 70% win rate after accounting for small-sample bias
- Binary payoff: approximately 1:1 (slight edge to house via spread)
- Kelly fraction at 70% WR: f\* = (0.70 - 0.30) / 1.0 = 40%; quarter-Kelly = 10%
- Expected value per $100 at 10% sizing: $100 × 0.10 × (0.70 - 0.30) = $4 per trade
- Estimated daily opportunities: 3-5 (only when parent=UP and prior=[DOWN,DOWN] condition is met)
- Estimated daily EV: $12-$20 on $100 bankroll

**Hierarchical Cascade (Second Tier)**

- Historical accuracy: 77.8% when 1h and 15m agree
- Conservative live estimate: 60% (agreement condition is rare, small-sample correction)
- Expected value per $100 at 5% sizing: $100 × 0.05 × (0.60 - 0.40) = $1 per trade
- Estimated daily opportunities: 5-10
- Estimated daily EV: $5-$10 on $100 bankroll

**Copy Trader (Based on Followed Traders)**

- Followed trader win rate: 70-86% (top 5 traders as of paper session)
- Copy execution adds slippage: effective win rate 60-70% after execution costs
- Position size: 10% of bankroll per trade
- Expected value per trade at 65% WR: $100 × 0.10 × (0.65 - 0.35) = $3 per trade
- Estimated monthly trades (copy traffic depends on trader activity): 20-50
- Estimated monthly EV: $60-$150 on $100 bankroll (60-150% monthly return — note: high because prediction markets have high variance, this is expected value, not guaranteed)

### 8.2 Bankroll Scaling

| Bankroll | Monthly EV (Conservative) | Monthly EV (Expected) | Risk of Ruin             |
| -------- | ------------------------- | --------------------- | ------------------------ |
| $500     | $150                      | $400                  | 3% (at 25% max drawdown) |
| $2,000   | $600                      | $1,600                | 2%                       |
| $10,000  | $3,000                    | $8,000                | 1%                       |
| $50,000  | $15,000                   | $40,000               | <1%                      |

Risk of ruin estimates assume quarter-Kelly sizing, 25% maximum drawdown circuit breaker, and uncorrelated positions across the fleet. These are actuarial estimates and are sensitive to the true underlying win rate — a 5% downward shift in win rate significantly increases ruin probability.

### 8.3 Signal Subscription Revenue (18-Month Projection)

| Month | Subscribers (Basic) | Subscribers (Pro) | Monthly Revenue |
| ----- | ------------------- | ----------------- | --------------- |
| 1-3   | 0 (validation)      | 0                 | $0              |
| 4-6   | 10                  | 2                 | $888            |
| 7-9   | 30                  | 8                 | $3,062          |
| 10-12 | 80                  | 20                | $7,920          |
| 13-18 | 200                 | 60                | $21,800         |

Revenue projections assume launch after a 3-month live performance track record, organic growth via trading community presence (Twitter/X, Polymarket Discord), no paid advertising.

### 8.4 Total 18-Month Revenue Projection

| Stream                                         | Conservative | Expected     |
| ---------------------------------------------- | ------------ | ------------ |
| Direct trading P&L ($10k bankroll by month 12) | $30,000      | $80,000      |
| Signal subscriptions                           | $15,000      | $35,000      |
| Copy-trader-as-a-service (5% AUM fee)          | $5,000       | $20,000      |
| White-label licensing (1 deal)                 | $0           | $20,000      |
| **Total**                                      | **$50,000**  | **$155,000** |

---

## 9. Risks & Mitigations

### 9.1 Strategy Alpha Decay

**Risk**: The Brownian Bridge path conditioning and hierarchical cascade signals are derived from historical data. Market participants may adapt to these patterns over time, reducing their predictive power. More importantly, small-sample signals (n=18 for the best-documented Brownian Bridge condition) may not generalize.

**Mitigation**: Continue expanding the historical analysis to larger sample sizes. Track live win rates weekly and compare against historical baselines. If the rolling 20-trade win rate drops below 50% on a previously validated strategy, halt trading and investigate before resuming. Maintain the research framework (Q-series analysis) as an ongoing process rather than a one-time activity. Never deploy a strategy that has not cleared 100 oracle-verified paper trades.

### 9.2 Polymarket Regulatory Risk

**Risk**: Polymarket operates under regulatory ambiguity in multiple jurisdictions. A regulatory action could restrict access, require KYC/AML compliance that disrupts the automated bot model, or reduce platform liquidity significantly.

**Mitigation**: The multi-venue router already built in Kokoro MM supports Kalshi and Manifold as alternative prediction markets. The strategy research (Brownian Bridge, hierarchical cascade) is conceptually portable to other binary prediction markets. The copy trader is partially insulated — copying human traders remains valid across any platform. Maintain no more than 20% of total trading capital on any single platform.

### 9.3 Execution Risk

**Risk**: The CLOB is a competitive environment. Large market participants may front-run GTC orders, reducing effective fill prices. Partial fills on GTC orders leave residual exposure that complicates position accounting. Polygon network congestion may delay on-chain settlements.

**Mitigation**: GTC order placement is the current architecture but the executor supports FOK (fill-or-kill) mode for markets with sufficient liquidity. Residual GTC exposure is now correctly tracked in the risk gate system. Settlement delays are mitigated by the hold-to-resolution architecture — the bot does not attempt to sell positions, avoiding the $0.00 sell bug from the March 2026 failure. Polygon gas is low and unlikely to cause meaningful execution costs.

### 9.4 Overfitting Risk

**Risk**: With 11,348 historical markets analyzed and 15+ conditional probability questions asked (Q1-Q15), there is inherent risk of data mining — finding apparent patterns that are noise artifacts rather than genuine structure.

**Mitigation**: The Brownian Bridge signal has a clear theoretical basis (conditional path distribution in a Brownian Bridge model, not just empirical frequency). The out-of-sample test is live trading — patterns that persist live have structural validity. The small-sample caveat (n=18) is explicitly recognized and a 70% live win rate (below the 100% historical rate) is used for financial projections. No strategy is deployed live based solely on paper testing.

### 9.5 Bankroll Management Risk

**Risk**: The March 2026 incident demonstrated that bankroll management failures (pending orders not counted, $137 deployed on $100 bankroll) compound losses during adverse market conditions.

**Mitigation**: The GTC exposure risk gate fix is committed and deployed. All pending orders are now counted against position limits and exposure limits. Quarterly-Kelly sizing (0.25 × Kelly fraction) limits maximum individual position size. The 25% maximum drawdown circuit breaker (implemented as an AtomicBool) halts all execution upon triggering and requires manual restart. No automated recovery from circuit breaker trips — human review required.

### 9.6 Concentration Risk — Single Platform

**Risk**: Both products are currently exclusively on Polymarket. A single API outage, rate limit change, or policy update could halt all revenue.

**Mitigation**: The multi-venue architecture (already planned via Kokoro MM's multi-venue router) is the long-term solution. In the near term, paper trading mode allows continuation of strategy research even when live trading is halted. The signal subscription product (if launched) provides platform-independent recurring revenue.

### 9.7 Founder Single Point of Failure

**Risk**: Both products are maintained and operated by a single developer. Illness, extended unavailability, or context loss between sessions could leave deployed bots unmonitored.

**Mitigation**: Comprehensive session logging (all key decisions and code changes documented in local .md files) enables rapid context recovery. The circuit breaker system halts trading autonomously on adverse performance. The bot is designed to be stopped safely at any time without open position risk (hold-to-resolution prevents orders from hanging). No automatic capital deployment without manual confirmation — the `AUTO_START=false` default requires explicit startup.

---

## Conclusion

The Kokoro Trading Bot ecosystem represents a genuine attempt to build institutional-grade quantitative trading infrastructure for prediction markets, informed by real trading experience including a significant live failure. The March 2026 disaster, while costly, produced insights about strategy validity, paper testing limitations, and risk gate completeness that most algo traders only learn after much larger losses.

The path forward is clear: validate the Brownian Bridge and hierarchical cascade strategies against real settlement data, deploy live capital only after statistical validation, scale bankroll progressively with demonstrated performance, and layer the subscription and managed service revenue streams on top of a proven trading track record.

The infrastructure is built. The research is done. The lessons are learned. The remaining work is execution — which, in this context, means patient validation before deployment.

---

_Kokoro Tech — https://tech.happykokoro.com_
_GitHub: github.com/happykokoro (org), github.com/anescaper (personal)_
