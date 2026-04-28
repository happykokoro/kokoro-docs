---
description: Multi-chain on-chain infrastructure — PoS aggregation, smart-contract development, brokerage and clearing, market-making.
---

# DeFi & on-chain

Multi-chain on-chain infrastructure — proof-of-stake aggregation, smart-contract development, brokerage and clearing systems, market-making infrastructure, and the off-chain services that keep them running.

## What we provide

- **Multi-chain PoS support.** Validator integration, delegation, undelegation, and reward claims across 17 PoS networks with on-chain transaction execution wired through: Ethereum, Solana, Cosmos Hub, Celestia, Osmosis, Injective, Sei, Polkadot, Avalanche, Sui, BNB Chain, Tron, NEAR, Aptos, Cardano, MultiversX, Tezos.
- **Wallet authentication.** Chain-specific signature schemes (SIWE for EVM, Ed25519 for Solana / Cosmos / Sui / Aptos / NEAR, CIP-30 for Cardano, Polkadot.js, etc.) bound to JWT-issued sessions.
- **Validator and delegator infrastructure.** Validator explorer with APR, commission, uptime, and delegation tracking; configurable alerts on validator health, reward milestones, and slashing risk.
- **Solana protocol development.** Anchor-framework programs spanning treasury, vault, lending, prediction markets, AMM, governance, NFT auction, leveraged positions, and yield vaults — built as a coherent program family wired through a shared treasury and house pool.

## Brokerage, clearing, and market-making

For organizations building DeFi brokerage products — execution venues that take customer order flow and route it to one or more underlying liquidity sources — we build the integrated post-trade and market-making layers that make those products economically viable.

- **Clearing and settlement.** Post-trade position netting, margin calculation, mark-to-market, settlement instructions to on-chain venues. Per-account ledgers reconciled against on-chain balances on every settlement cycle.
- **Custody and segregation.** Customer-asset segregation patterns appropriate to the regulatory regime in scope: omnibus, sub-account, or fully segregated. Treasury vaults with multi-signature or threshold-signature control.
- **Margin and risk engines.** Real-time exposure calculation per account and per book, configurable margin models (initial / maintenance / liquidation thresholds), pre-trade risk gates, post-trade risk monitoring with auto-deleveraging hooks.
- **Market-making infrastructure.** LP position automation against AMM pools (concentrated liquidity rebalancing, fee-tier selection, inventory rebalancing); two-sided quoting against orderbook venues with inventory-aware spread management; cross-venue arbitrage primitives.
- **Order routing and best execution.** Smart order routing across multiple liquidity sources with documented execution policy. Post-trade transaction-cost analysis against documented benchmarks (arrival price, VWAP, implementation shortfall).
- **Liquidation engines.** Per-protocol liquidation bots with configurable trigger logic, gas-optimized transaction submission, partial-liquidation strategies, and cross-venue collateral recovery.

## Off-chain operational layer

- **Blockchain listeners** with reorg-safe event consumption, idempotent handlers, and at-least-once delivery semantics.
- **VRF resolvers, crank services, position monitors, risk engines** — the operational layer that makes on-chain protocols work in practice.
- **Typed SDKs.** First-class TypeScript SDKs with typed client classes per program, PDA derivation helpers, and risk-cap constants checked into source.
- **Subscription-gated access.** USDC billing through our payments stack (see [payments](payments.md)) for hosted DeFi products; activation-code mechanism for one-shot access tiers.

## Delivery models

- **Custom protocol development.** Solana, EVM, or Cosmos SDK protocol design and implementation — including audit-ready code, devnet deployment, and the off-chain services to operate it.
- **Brokerage backend builds.** End-to-end clearing, margin, and execution infrastructure for a new DeFi brokerage product, integrated with the customer's chosen liquidity venues.
- **Market-making operations.** LP and market-making strategies operated against customer-funded inventory under joint-management agreement. Strategy IP and inventory remain customer property.
- **Validator partnerships.** Custom validator integrations for new chains, fee-sharing arrangements, or white-label staking interfaces.
- **White-label staking aggregator.** The full staking aggregator rebranded to the customer's identity, with their selected chain set.
- **Smart-contract audits.** Pre-audit review against deployment checklists, with the audit firm relationship handled separately.
- **Off-chain operations.** Listener, keeper, and liquidation engines operated as a managed service for protocols deployed by the customer.

## Engagement

On-chain engagements assume the customer accepts that audit and security review precede mainnet deployment, regardless of internal pressure. Brokerage and clearing engagements additionally require a written regulatory analysis (jurisdictions in scope, customer classification, asset classification) before code is written. Deliverables include source under proprietary or open-source license per agreement, devnet deployment, deployment runbook, and the off-chain operational stack required to keep the protocol running.

Defect liability for brokerage, clearing, and market-making code follows the [engagement models](../services/engagement-models.md) framework with cure windows tightened to Class A treatment. Defects in code we wrote that affect settlement, position accounting, or risk-engine logic are corrected at our cost within the SOW cure window, with refund of attributable fees as fallback. We do not assume liability for protocol-level risk in third-party contracts the customer chose to integrate against; the boundary is documented per engagement.
