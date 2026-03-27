# Culture & Values

---

## Core Values

The name "Kokoro" (心) was chosen deliberately. In Japanese — borrowed from Chinese 心 (xīn) — the character means heart, mind, and spirit simultaneously. There is no clean English translation because English separates what the character holds together: rational analysis and ethical purpose as one practice, not two.

That integration is the foundation of how this company builds.

---

### Compassion in Engineering — 慈悲

Technology should serve those who need it most, not those who can pay the most.

Every architectural decision at Kokoro Tech is evaluated by a single question: does this empower the user, or does it create dependency? Self-hosted by default. Self-custodied by design. The user's sovereignty is not a feature — it is the constraint that shapes everything else.

Encrypted key derivation so that even our own infrastructure cannot recover user keys without the user's master secret. WireGuard mesh so that cross-server traffic never touches the public internet. No telemetry, no cloud dependency for core function. These are not marketing claims — they are architecture choices with a cost, made because the alternative is building tools that serve the operator instead of the user.

The developers in Southeast Asia and Lagos appear in our philosophy document because they are the actual intended beneficiaries of this infrastructure. Not an afterthought. Not a marketing gesture. The reason the work exists.

---

### Interconnectedness — 因縁

No system exists in isolation. Every component in the Kokoro ecosystem was designed as a node in a network, not a standalone product.

A signal detected by the wallet monitor flows through the pricing service, into the factor pipeline, through risk management gates, and into execution — a continuous chain where each link depends on and strengthens every other. The 7+ repositories coordinate as one logical organism. Services feed each other across three continents. Type contracts defined in the shared crate enforce that coordination without tight coupling.

This is how we build: not as isolated features added to a list, but as interconnected systems where value emerges from the relationships between components. Removing one well-placed crate can break three downstream dependencies. Adding one well-designed abstraction can unlock capabilities that didn't exist before.

The discipline this requires — explicit interfaces, semantic versioning across repository boundaries, dual-format protocol migrations that maintain backward compatibility — is the discipline of thinking about how things connect, not just how they work individually.

---

### Right Effort — 正精進

Build what works, not what impresses.

GARCH-T was validated as the most effective volatility model in live testing — not because it is the most mathematically elegant, but because empirical testing against real data proved it. The Kalman filter is elegant. GARCH-T is effective. We choose effective.

Every algorithm in the platform earns its place through validation against data, not through theoretical beauty. Brownian Bridge path conditioning was validated against 11,348 historical Polymarket markets before being promoted to the production signal pipeline. Copula dependence structures were included because the data supported them; methods that tested poorly were removed regardless of their academic pedigree.

Right effort also means not over-engineering. Clean trait implementations that compose predictably. Errors handled at system boundaries only. No unnecessary abstractions between the algorithm and the execution path. The 65-crate monorepo has boundaries because those boundaries reflect real domain separations — not because more crates signal more sophistication.

---

### Transparency — 明

In code, in architecture, in philosophy.

The philosophy document on this site includes Section VII — Intellectual Honesty — because a philosophy that doesn't acknowledge the weaknesses of its own position is marketing, not philosophy. The OECD says DeFi hasn't democratized finance? We agree, and we show specifically how the interpretation gap forms and what we are building to close it. MEV bots extract value from retail participants using the same on-chain transparency that theoretically benefits them? Correct — and worth saying explicitly.

Open-source where possible. IEEE-referenced where applicable. The three public repositories — claude-init, Agent Orchestra, kokoro-vpn — are auditable because "verify, don't trust" applies to our own code as much as to anyone else's.

Transparency is not a weakness. It is the foundation of trust that survives contact with reality.

---

### Impermanence and Adaptation — 無常

Markets change. Algorithms decay. Strategies that worked yesterday fail tomorrow.

This is not a risk to hedge against — it is a design constraint to build for. The platform's composable factor pipelines were designed so that strategies can be swapped without touching execution infrastructure. Risk gates can be reconfigured without redeploying the full system. Feature-gated compilation changes what the binary does without changing what it is.

The dual JSON/protobuf migration across all 10 Redis Streams was executed without downtime because the system was built to expect format transitions. The multi-repository architecture was extracted from the monorepo as services reached operational maturity — not as a planned reorganization, but as a natural consequence of building for change.

Architecture that assumes permanence accumulates technical debt. Architecture that assumes change accumulates optionality.

---

## Who We're Looking For

Kokoro Tech is early, ambitious, and running fast. The right people for this environment are not people who want a defined role in a stable system. They are people who want to build the system itself.

---

**Traders who see beyond price action**

If you understand that markets are driven by information flows — that order flow imbalance, volatility clustering, and regime detection are more analytically useful than support/resistance lines — you think the way we build.

We want traders who have opinions backed by data and the discipline to change those opinions when the data changes. The Brownian Bridge validation work that drove a complete strategy pivot started with a hypothesis that the original approach was structurally flawed. Being right about the hypothesis wasn't enough — it required 11,348 data points and empirical accuracy verification before the conclusion was acted on.

If you find that process intellectually satisfying rather than tedious, we want to hear from you.

---

**Believers in financial democratization**

Not ideologues. Believers who acknowledge the OECD's criticism and want to build the tools that close the gap.

You understand that a developer in Southeast Asia deserves the same signal processing infrastructure as a trading desk in New York — and that the path there is engineering, not manifestos. You can hold the vision ("institutional-grade tools should be universally accessible") and the current reality ("the platform currently requires meaningful technical sophistication to deploy") without treating the gap between them as hypocrisy.

Financial democratization is a multi-decade engineering and design problem. We are working on one part of it, with honesty about which part.

---

**Ambitious programmers who want to build real systems**

If you find satisfaction in a clean trait implementation that enables a new factor to plug into a 65-crate pipeline — or in a Redis Streams consumer that gracefully handles dual JSON/proto format without downtime — or in a Docker Compose stack that orchestrates 12 containers with health checks and proper dependency ordering — you belong here.

We write Rust, TypeScript, Python, and Go. We deploy to production. We monitor what we build. The 1,860+ automated tests are not a coverage metric — they are the confidence that lets us move fast without breaking the execution path for a live trading system.

The platform was designed for AI-augmented development as a first-class methodology. 115 MCP tools expose every service boundary for autonomous operation. If you want to learn how to build systems that AI agents can work with effectively — and how to build AI agents that can operate complex systems effectively — this is where that work is happening at production scale.

---

## Our Aspiration

In 2026, AI-augmented development has compressed the leverage available to small technical teams by an order of magnitude. Dario Amodei (Anthropic CEO) gave 70-80% odds that the first billion-dollar company built by a very small team would emerge by 2026 — specifically in proprietary trading and developer tools. Those are the exact domains Kokoro Tech operates in.

We are building toward that future. Not by cutting corners, but by building systems that compound: every MCP tool makes the next one faster to build and test. Every crate makes the next product possible without rebuilding foundations. Every deployment to a new region teaches us something about operating infrastructure globally. The 530,000+ lines of production code are not just a size metric — they are the accumulated result of that compounding.

The platform is not theoretical. It runs on three continents. It processes live liquidation data across six EVM chains. It has executed trades in live prediction markets. It has survived the gap between a working model and a model that works in production — which is a different and harder problem.

Kokoro Tech is not looking for passengers. We are looking for people who find the mission worth the intensity it requires: institutional-grade financial infrastructure that serves individuals, built by a team small enough that every person's work is visible in the architecture.

If that sounds right, reach out.

---

## Kokoro (心) — The Name

心 (kokoro in Japanese, xīn in Chinese) means heart, mind, and spirit simultaneously. It is a single character for a concept that European languages require three words to approximate — and even then, the approximation misses the integration.

In the philosophical tradition that informs this company, heart and mind are not separated. Rational analysis and ethical purpose are not competing claims on the same decision — they are one practice. You cannot build good systems by treating technical excellence and human impact as separate concerns that trade off against each other.

Technology built with kokoro serves people. Technology built without it serves shareholders.

The name is a daily reminder: every commit, every deployment, every architectural decision carries both technical and ethical weight. The same decision that determines query latency also determines whether the system is operable by the person it was built for. These are not separate questions.

That is the standard against which this work is measured.

---

_Kokoro Tech — [tech.happykokoro.com](https://tech.happykokoro.com)_
