# Kokoro VPN — Business Plan

**Prepared**: March 2026
**Author**: Kokoro Tech
**Status**: Seed-stage, self-funded

---

## 1. Executive Summary

Kokoro VPN is a self-hosted WireGuard VPN platform that solves a problem no single open-source tool currently addresses cleanly: running both a traditional client VPN (hub-and-spoke) and a full-mesh server interconnect in one unified deployment, managed through a single CLI and REST API, with a polished desktop application and infrastructure-as-code provisioning built in.

The product is written entirely in Rust, licensed under MIT, and is already in production — a three-node mesh network connecting cloud servers across DigitalOcean Singapore, AWS Ireland, and AWS London powers the Kokoro Tech production infrastructure. It ships as two binaries: `kokoro-vpn-server` (the coordination daemon with JWT authentication, WireGuard peer management, sandbox guest tunnels, and Prometheus-compatible metrics) and `kokoro-vpn` (the CLI for mesh topology management, ACL authoring, health polling, and firewall script generation). A Tauri v2 desktop application wraps these capabilities in a native GUI for macOS, Windows, and Linux users who prefer point-and-click management over the CLI.

The business model is layered. The core product is and will remain free and open-source under MIT — that is the distribution engine. Revenue comes from three additional tiers: a managed hosting service for users who want Kokoro VPN infrastructure without operating it themselves, enterprise support and consulting for organizations deploying at scale, and premium desktop application features for professional users. The total addressable market for VPN infrastructure is large ($45B+ globally), but the immediate, winnable segment — self-hosted and privacy-conscious technical users, plus SMBs operating distributed infrastructure — is estimated at several hundred million dollars in aggregate annual spend and growing.

The founding team brings direct, production-validated expertise: Kokoro VPN was not designed in the abstract. It was built because the founder needed exactly this tool to connect production infrastructure across three cloud providers and found no existing solution that handled both use cases without significant friction.

---

## 2. Product Overview

### 2.1 Core Architecture

Kokoro VPN ships as two Rust binaries, which means deployment is a single binary copy to a server — no runtime dependencies, no package manager, no interpreter. Rust's compile-time guarantees and zero-cost abstractions make the server binary suitable for resource-constrained VPS instances as readily as dedicated hardware.

**`kokoro-vpn-server`** is the coordination daemon. It listens on port 3000 (REST API) and manages two WireGuard interfaces:

- `wg0` — the client VPN interface, hub-and-spoke topology, subnet `10.8.0.0/24`, UDP port 51820. This is the traditional "roadwarrior" VPN mode: individual devices connect to a central server and gain access to private resources. JWT-authenticated API endpoints handle peer provisioning, key rotation, and sandbox guest tunnel creation.
- `wg1` — the mesh VPN interface, full-mesh topology, subnet `10.10.0.0/24`, UDP port 51821. In an N-node mesh, the server establishes N\*(N-1)/2 encrypted tunnels, one between every pair of nodes. This is used for server-to-server communication in distributed infrastructure — each server is a peer to every other server, with no central relay.

**`kokoro-vpn`** is the CLI used by operators to manage the mesh topology: adding and removing nodes, generating per-node ACL configurations, running health checks across the mesh, and rendering firewall scripts ready for deployment.

**Desktop Application**: The Tauri v2 desktop app (built with React 19, Vite 6, and Tailwind v4) provides a native GUI for all server and CLI operations. Tauri v2 compiles to a native binary for each platform, consuming far less memory than an Electron equivalent, while providing a modern web-based UI through a system WebView. The app is particularly targeted at professionals who manage their own infrastructure but prefer visual tools for monitoring and topology management.

**Terraform Configurations**: Kokoro VPN ships with Terraform modules for one-click provisioning on DigitalOcean and AWS. A user can run `terraform apply` and have a fully configured VPN server running within minutes, with DNS records, firewall rules, and the Kokoro VPN binaries installed and started as a systemd service.

### 2.2 Dual-Mode Operation

The dual-mode design — supporting both hub-and-spoke and full-mesh in the same deployment — is the defining technical differentiator.

**Client VPN mode** solves the classic access problem: employees, contractors, and devices that need access to private resources are connected through a central server. The `10.8.0.0/24` subnet is private. Peer provisioning is handled via the REST API with JWT authentication, so adding a new device takes a single API call. Sandbox guest tunnels allow temporary access grants with configurable expiry — useful for contractors or auditors who need time-limited access.

**Mesh VPN mode** solves the infrastructure interconnect problem: when you operate servers in multiple cloud regions or across multiple cloud providers, those servers need to communicate securely over private channels. Public cloud providers charge for inter-region traffic and their private networking often does not extend across provider boundaries. A WireGuard mesh creates an encrypted overlay network entirely within your control. With full-mesh topology, any server can reach any other server directly without a relay — this eliminates single points of failure and minimizes latency compared to hub-and-spoke for server-to-server traffic.

Both modes operate simultaneously on the same host, serving different traffic classes through different interfaces.

### 2.3 Per-Node ACL Firewall Generation

One of Kokoro VPN's most operationally valuable features is automated firewall script generation. Each node in the mesh may have different access rules — a database server might accept connections from application servers but not from jump hosts; a payment processor might be isolated to only accept traffic from specific peer IPs.

The CLI generates per-node iptables and nftables scripts that encode these rules into a dedicated `KOKORO_MESH` chain, keeping mesh-related rules isolated from the host's existing firewall configuration. Rules are expressed as YAML ACL definitions and rendered to shell scripts ready for review and application. This bridges the gap between WireGuard (which handles encryption and routing) and network-level access control (which WireGuard intentionally does not handle).

### 2.4 Monitoring

The server exposes two monitoring endpoints:

- `GET /api/mesh/health` — returns per-node connectivity status, last handshake timestamps, and whether each peer's latest handshake is within the expected window
- `GET /api/mesh/metrics` — returns Prometheus-formatted metrics for scraping by a Prometheus instance

This allows Kokoro VPN to integrate into any existing Prometheus + Grafana monitoring stack with zero custom work.

### 2.5 Current Deployment State

Kokoro VPN is not vaporware. The 3-node production mesh has been running continuously, connecting the following infrastructure:

- `sg-main` (10.10.0.1) — DigitalOcean Singapore — Kokoro Alpha Lab production
- `ie-poly` (10.10.0.2) — AWS Ireland — Kokoro MM production
- `uk-pay` (10.10.0.3) — AWS London — Kokoro Copy Trader

All inter-service traffic between these nodes routes through the WireGuard mesh. The client VPN allows secure remote administration of all three servers from any device.

---

## 3. Market Analysis

### 3.1 Total Addressable Market

The global VPN market was valued at approximately $45 billion in 2023 and is projected to exceed $130 billion by 2030, driven by remote work adoption, data privacy regulation (GDPR, CCPA), and expanding cybersecurity budgets. However, the overwhelming majority of this market is consumer VPN services (NordVPN, ExpressVPN, Surfshark) — a segment Kokoro VPN is not competing in.

The relevant segment is enterprise and infrastructure VPN: companies running distributed systems across cloud providers, self-hosted infrastructure operators, development teams managing remote access to staging and production environments, and privacy-conscious individuals who refuse to route their traffic through a commercial VPN provider. This segment is smaller but less commoditized, higher value per customer, and growing as cloud-native infrastructure becomes the default.

The self-hosted VPN segment specifically is experiencing strong growth driven by:

1. **Zero-trust architecture adoption**: Organizations are moving away from perimeter-based security toward network segmentation, where every service-to-service connection is explicitly authorized. This requires programmable network infrastructure — exactly what Kokoro VPN provides.
2. **Multi-cloud deployments**: As organizations use AWS, GCP, Azure, and providers like DigitalOcean and Hetzner simultaneously, they need private network overlays that span provider boundaries.
3. **Remote work normalization**: The post-2020 shift to remote and distributed teams created permanent demand for client VPN solutions that teams can operate without relying on commercial providers who may log or sell traffic metadata.
4. **Regulatory pressure**: Healthcare, finance, and government organizations are under increasing regulatory pressure to demonstrate control over their network traffic — something that is impossible with commercial VPN services.

### 3.2 Competitive Landscape

The self-hosted VPN and mesh networking space has seen significant activity:

**Tailscale** is the dominant player in the mesh VPN category. Built on WireGuard, it provides an excellent user experience with a centralized coordination server (their cloud), automatic NAT traversal, and a generous free tier. As of early 2026, Tailscale has raised $275 million in total funding and reached unicorn valuation — validating that the self-hosted WireGuard VPN market has genuine venture scale and broad enterprise demand. Its weakness remains the coordination server dependency — free tier users have their network metadata logged by Tailscale's infrastructure, and enterprise pricing scales steeply with node count. Self-hosted Tailscale (via Headscale, an open-source reimplementation of the coordination server) exists but lacks official support and lags behind the official client.

**Netmaker** is an open-source WireGuard mesh manager targeting developers and DevOps teams. It provides a web UI, supports full-mesh and hub-and-spoke, and offers a managed hosting option. Netmaker raised seed funding and has a commercial tier. Its codebase is in Go. The primary weakness is complexity — deployment requires multiple services (UI, API, broker) and the operational overhead is higher than Kokoro VPN's single-binary model.

**Headscale** is the unofficial open-source Tailscale control server. It enables running Tailscale's client network without Tailscale's cloud, but requires users to still run official Tailscale clients. It is a solid option but inherits all of Tailscale's client behaviors and does not solve the dual-mode use case.

**Netbird** is an open-source zero-trust network access platform built on WireGuard. It supports full-mesh, ACL policies, and has both self-hosted and managed cloud options. It is well-funded and actively developed. Its scope is broader than Kokoro VPN (closer to a full ZTNA platform) and accordingly more complex to deploy.

**WireGuard (raw)** is always an option for technically sophisticated operators. Many infrastructure teams simply manage `wg0.conf` files directly. This "competitor" is actually the largest competitor in practice — the question Kokoro VPN must answer is: what does it provide over manually managed WireGuard configs? The answer is: automation, multi-node coordination, ACL generation, health monitoring, the client VPN + mesh VPN dual-mode, JWT-authenticated provisioning API, guest tunnels, Prometheus metrics, and a desktop GUI.

### 3.3 Kokoro VPN's Positioning

Kokoro VPN positions between raw WireGuard management and the full complexity of Netbird or Netmaker. It is:

- **Simpler than Netmaker/Netbird**: Two binaries, no separate database service, no broker, no UI server required (CLI is the primary interface, desktop app is optional)
- **Privacy-sovereign unlike Tailscale**: No coordination server dependency — your network metadata never leaves your infrastructure
- **More capable than raw WireGuard**: Automated peer management, dual-mode topology, ACL generation, Prometheus metrics, REST API, desktop app, Terraform provisioning
- **Developer-native**: CLI-first, REST API for automation, Terraform configs, Prometheus integration — everything a DevOps-oriented user expects

### 3.4 Target Customers

**Primary: Self-hosted infrastructure operators** — individuals and small teams running distributed servers across multiple cloud providers or regions. They are comfortable with Linux administration, use tools like Docker, Terraform, and Prometheus, and have strong preferences for open-source software they control. Community: r/selfhosted (1.2M members), Hacker News, Lobsters, homelab communities.

**Secondary: SMBs with distributed teams** — companies with 10-100 employees operating remote work environments, staging/production environments across cloud providers, and security requirements that exclude commercial VPN logging. They need client VPN for employees and mesh VPN for infrastructure.

**Tertiary: Enterprise DevOps teams** — organizations at the 100-1000 employee scale where network management is owned by a platform team. They value compliance-ready audit logging, SSO integration, and vendor-supported deployments. This tier is the path to enterprise contracts.

---

## 4. Revenue Model

Kokoro VPN uses a layered open-source monetization model. The core software is and will remain free. Revenue is generated from services and features that add operational value on top of the free foundation.

### 4.1 Community Tier (Free)

The complete server binary, CLI, desktop application, and Terraform configs are free under proprietary license. There is no feature gating at the software level in the community tier. This is deliberate: the goal is to maximize adoption, which creates the community, brand recognition, and inbound pipeline that monetizable tiers depend on.

Community users contribute bug reports, feature requests, documentation improvements, and word-of-mouth referrals. GitHub stars, Hacker News discussions, and r/selfhosted posts are the primary distribution channels for this tier.

### 4.2 Managed Hosting Tier

Many users who want the privacy and control of self-hosted VPN do not want to operate servers. Managed hosting removes the operational burden: Kokoro Tech provisions, monitors, updates, and backs up the VPN server infrastructure on behalf of the customer. The customer retains full control of their network topology, ACL rules, and peer configurations — they simply do not manage the underlying servers.

Pricing is per-node per-month, with volume discounts:

- **Starter**: Up to 5 nodes — $29/month (includes 1 managed server)
- **Team**: Up to 20 nodes — $79/month (includes 2 managed servers for redundancy)
- **Business**: Up to 100 nodes — $199/month (multi-region, 99.9% uptime SLA)

Gross margin on managed hosting is approximately 60-70% after infrastructure costs. This is the primary near-term revenue stream.

### 4.3 Enterprise Support and Consulting

Enterprise deployments require dedicated support: custom deployment architectures, compliance documentation (SOC 2, HIPAA network segmentation evidence), integration with existing identity providers (LDAP, Active Directory, SAML SSO), custom audit logging pipelines, and on-call support contracts.

Enterprise support pricing:

- **Standard Support**: $500/month — guaranteed 48-hour response time, private support channel, monthly check-in call
- **Premium Support**: $2,000/month — 4-hour response time, dedicated Slack channel, quarterly architecture review, early access to features
- **Custom Consulting**: $250/hour — architecture design, deployment, migration from existing VPN infrastructure, custom feature development

Enterprise contracts are typically annual commitments of $6,000-$24,000 per year.

### 4.4 Desktop Application Premium Features

The desktop application is free for basic use. A premium tier unlocks features targeting professional users who manage large deployments:

- **Multi-server management**: connect to and manage multiple `kokoro-vpn-server` instances from one UI
- **Visual topology editor**: drag-and-drop mesh topology design with real-time connectivity visualization
- **Advanced ACL editor**: GUI for building ACL rules without writing YAML
- **Audit log viewer**: searchable, filterable log of all peer operations
- **Certificate management UI**: simplified key rotation with one-click peer re-provisioning

Desktop premium: $49/year per user, or $149/year for teams of up to 10.

### 4.5 Revenue Summary

| Tier                     | Price        | Target Customer                                  |
| ------------------------ | ------------ | ------------------------------------------------ |
| Community                | Free         | Self-hosted operators, hobbyists                 |
| Managed Hosting Starter  | $29/month    | Solo developers, homelab                         |
| Managed Hosting Team     | $79/month    | Small engineering teams                          |
| Managed Hosting Business | $199/month   | SMBs, distributed teams                          |
| Enterprise Standard      | $500/month   | Mid-market organizations                         |
| Enterprise Premium       | $2,000/month | Large organizations with compliance requirements |
| Desktop Premium          | $49/year     | Professional individual users                    |
| Consulting               | $250/hour    | Any tier needing custom work                     |

---

## 5. Product Roadmap

### 5.1 Current State (Q1 2026)

- Two production Rust binaries: `kokoro-vpn-server` and `kokoro-vpn` CLI
- Client VPN hub-and-spoke on `wg0` (10.8.0.0/24)
- Mesh VPN full-mesh on `wg1` (10.10.0.0/24)
- JWT authentication on all server API endpoints
- Sandbox guest tunnels with configurable expiry
- Per-node ACL firewall generation (iptables and nftables)
- Health monitoring endpoint
- Prometheus metrics endpoint
- Tauri v2 desktop application (React 19, Tailwind v4)
- Terraform deployment configs for DigitalOcean and AWS
- 3-node production mesh deployed and operating continuously
- Public repository, proprietary license, GitHub published

### 5.2 Near-Term Roadmap (Q2-Q3 2026)

**Expanded OS and Platform Support**

The desktop application currently targets the three major desktop platforms (macOS, Windows, Linux) via Tauri v2. Near-term additions:

- iOS and Android mobile applications using Tauri Mobile (currently in beta) or a React Native wrapper, enabling mobile devices to connect to the client VPN from native apps rather than requiring third-party WireGuard apps
- Package manager distributions: Homebrew formula, AUR (Arch User Repository) package, `.deb` and `.rpm` packages for Linux, Windows MSI installer with auto-update — reducing friction for non-Docker users

**SSO Integration**

Enterprise and SMB deployments universally require single sign-on. Planned integrations:

- OIDC provider support (Okta, Auth0, Google Workspace, Azure AD) — peers are provisioned automatically when a user authenticates through the organization's IdP
- SAML 2.0 for legacy enterprise IdP compatibility
- LDAP/Active Directory for on-premise organizations

**Audit Logging**

Compliance-critical deployments need comprehensive audit trails. The server will gain structured audit log output capturing all peer add/remove/modify events, authentication attempts, guest tunnel creation and expiry, ACL changes, and health state transitions. Log output can be configured for local file, syslog, or forwarding to a SIEM (Splunk, Datadog, Elastic) via standard log shipping agents.

**Automated Certificate Rotation**

WireGuard key pairs should be rotated periodically. The server will support configurable key rotation schedules with automated peer re-provisioning — rotating a node's keypair without any manual intervention or service disruption.

### 5.3 Medium-Term Roadmap (Q3-Q4 2026)

**Web Management UI**

While the CLI and desktop app serve most users, a self-hosted web UI broadens accessibility to non-CLI operators (sysadmins who prefer browser-based tooling). The web UI will be a lightweight React application served by the `kokoro-vpn-server` binary itself — no additional service required.

**Multi-Tenant Management Console**

For managed hosting customers and MSPs managing multiple independent deployments, a multi-tenant management console provides a single pane of glass: view all customer networks, node health, alert conditions, and billing status from one interface.

**NAT Traversal**

Today's deployment assumes all nodes have public IP addresses or are behind NAT with port forwarding configured. Adding relay-assisted NAT traversal (similar to Tailscale's DERP relay infrastructure) would enable Kokoro VPN to work in environments where nodes are behind strict NAT without requiring firewall rule changes. This would be offered as an optional managed relay service.

**Network Visualization**

Real-time graph visualization of the mesh topology with node health overlays, traffic flow indicators, and historical connectivity charts integrated directly into the desktop app and web UI.

### 5.4 Long-Term Vision (2027 and Beyond)

**Zero Trust Network Access (ZTNA)**

The mesh VPN and per-node ACL system are foundational building blocks for a full ZTNA posture. The long-term product direction is to extend Kokoro VPN beyond tunneling into full zero-trust policy enforcement: per-application access policies, device posture checks, continuous authorization (not just at connection time), and integration with identity governance platforms.

This is the direction Netbird and Tailscale are heading with their enterprise tiers. Kokoro VPN's path to this is incremental — the ACL system is already per-node, extending it to per-application and per-user is an architectural evolution rather than a rewrite.

**Multi-Tenant Enterprise Console**

A SaaS control plane that enterprise customers can use without self-hosting the management layer, while their VPN nodes remain on-premise or in their own cloud accounts. This is the MSP (Managed Service Provider) and large enterprise play — organizations that want Kokoro VPN without operating any Kokoro infrastructure themselves.

**Hardware Appliance Partnership**

Partnerships with small form-factor hardware vendors (Raspberry Pi ecosystem, MikroTik, Ubiquiti) to pre-install Kokoro VPN as a turnkey network appliance for home and small office deployments.

---

## 6. Go-to-Market Strategy

### 6.1 Open-Source Distribution

The primary distribution channel is GitHub. An repository with clear documentation, a working Terraform quick-start, and a compelling README that demonstrates the value proposition in the first 30 seconds is the foundation.

Key open-source GTM tactics:

- **README-driven design**: Every feature explained with concrete commands and expected output. Screenshots of the desktop app. A quick-start that gets a new node online in under 5 minutes.
- **GitHub Releases with pre-built binaries**: Linux (x86_64, aarch64), macOS (Apple Silicon, Intel), and Windows binaries attached to every release. No build-from-source required for standard deployments.
- **Comparison documentation**: Honest, technically detailed comparisons against Tailscale, Netmaker, Headscale, and Netbird — covering use cases where each is the better choice and where Kokoro VPN has an advantage. These comparisons rank well in search results ("tailscale vs netmaker vs kokoro-vpn") and attract high-intent users.

### 6.2 Community Channels

**r/selfhosted** (1.2M members) is the highest-concentration community for self-hosted infrastructure tools. A well-received Show HN or r/selfhosted post from a legitimate product can generate thousands of GitHub stars and hundreds of early users in a single day. The community rewards: open-source licensing, honest documentation, no required cloud dependency, and evidence the product is actually running in production.

**Hacker News** — "Show HN: Kokoro VPN — self-hosted WireGuard with dual client+mesh modes, Rust, MIT" — is a standard launch vector for developer tools. The key differentiator to highlight is the dual-mode architecture and the Rust single-binary deployment model.

**Dev.to, Hashnode, personal blog**: Tutorial content — "Setting up a 3-server WireGuard mesh with Kokoro VPN", "Replacing Tailscale with a self-hosted WireGuard mesh", "Zero-trust firewall ACL generation for WireGuard mesh networks" — drives organic search traffic from developers actively solving these problems.

**Twitter/X and Mastodon developer communities**: Short-form content sharing architecture diagrams, quick demos, and deployment examples. The Tauri desktop app provides visual content (screenshots, demo recordings) that performs well in these channels.

### 6.3 Content Marketing

Search-intent content targeting developers evaluating self-hosted VPN options:

- "WireGuard mesh VPN setup guide"
- "self-hosted VPN open source 2026"
- "Tailscale alternative self-hosted"
- "WireGuard hub and spoke vs mesh"
- "iptables ACL automation WireGuard"
- "Terraform WireGuard DigitalOcean"

Each of these represents a high-intent search from someone who is exactly the target customer. Blog posts and documentation that genuinely answer these questions — with working code, not content marketing fluff — convert readers into users.

### 6.4 Developer Integrations and Ecosystem

Listing in relevant curated collections:

- **awesome-selfhosted**: The canonical GitHub repository listing self-hosted software. A listing in the VPN category drives sustained organic discovery.
- **Terraform Registry**: Publishing the Terraform modules to the Terraform Registry makes them discoverable by the Terraform-using community.
- **Homebrew**: A Homebrew tap lowers the installation barrier for macOS users to `brew install kokoro-vpn`.
- **DigitalOcean Marketplace**: DigitalOcean allows publishing one-click application droplets. A Kokoro VPN one-click droplet would place the product in front of DigitalOcean's user base.

### 6.5 Managed Hosting Conversion Funnel

The conversion path from free community user to paid managed hosting customer:

1. User discovers Kokoro VPN via GitHub/HN/r/selfhosted
2. User deploys self-hosted — successful, but they experience the operational burden of server management, updates, and incident response
3. Kokoro Tech sends in-app notifications (opt-in) and email sequences about managed hosting when users connect to their self-hosted instance
4. User evaluates: $29/month vs. their own time managing servers — many will convert
5. Migration path: managed hosting import tool reads the user's existing peer configuration and migrates it to managed infrastructure with zero reconfiguration on client devices

---

## 7. Technical Moat

### 7.1 Rust Performance and Reliability

The choice of Rust for both binaries is not aesthetic — it provides concrete competitive advantages:

**Memory safety without garbage collection**: WireGuard is a kernel module in Linux but Kokoro VPN's management layer runs in userspace. Rust ensures that the server binary cannot segfault, cannot have buffer overflows, and cannot have use-after-free bugs. In a VPN context, these guarantees are security-relevant: a memory corruption vulnerability in a VPN server is a potential pivot point for a network attacker.

**Single static binary deployment**: Rust's compilation model produces statically linked binaries by default. Deploying `kokoro-vpn-server` to a new machine is a `scp` followed by a systemd unit file — no package manager, no dependency resolution, no shared library version conflicts.

**Performance**: The server handles peer provisioning, key management, health polling, metrics collection, and REST API requests within a single tokio async runtime. Memory usage for a 20-node mesh with active monitoring is measured in megabytes, not hundreds of megabytes. This matters for resource-constrained VPS deployments.

### 7.2 Dual-Mode Architecture

No direct competitor offers both hub-and-spoke client VPN and full-mesh server interconnect in a single deployment with a unified management API.

- **Tailscale/Headscale**: Full-mesh only (every node is equal). Does not support the hub-and-spoke model natively.
- **Netmaker**: Supports both modes but requires separate "networks" — you cannot have the same server act as a hub for client devices while also being a mesh peer to other servers without running two separate network configurations managed by separate API resources.
- **Raw WireGuard**: Any topology is possible, but requires manual configuration management.
- **OpenVPN**: Hub-and-spoke by design. Mesh networking is possible but complex and uncommon.

Kokoro VPN's dual-mode design reflects how distributed systems are actually built: servers need mesh connectivity to each other for low-latency, direct service-to-service calls, while individual developer machines, mobile devices, and contractor endpoints need hub-and-spoke client connectivity for access to private resources.

### 7.3 Per-Node ACL Firewall Generation

The ACL system is a practical capability that no minimalist WireGuard tool provides. The gap between "WireGuard handles routing" and "iptables handles access control" is a real operational burden for infrastructure operators — they must maintain separate firewall scripts per server that reference the WireGuard peer IPs, ensure those scripts are kept in sync when peers are added or removed, and test them for correctness.

Kokoro VPN's ACL generation turns this into a declarative, topology-aware operation. Write an ACL definition once; regenerate scripts for all nodes with one command. Scripts are rendered with named comments identifying which rules correspond to which peers, making them human-auditable.

### 7.4 Tauri Desktop Application

Tauri v2 provides a native desktop application with significantly lower resource consumption than Electron — 10-20MB binary size and sub-100MB memory usage versus Electron's typical 200-400MB. For a tool that runs in the background monitoring VPN status, this is meaningful to users who are already memory-constrained.

The desktop app also enables the premium feature tier: visual topology editing, multi-server management, and advanced ACL authoring are features that are natural in a GUI but awkward in a CLI. The app expands the addressable market to operators who are comfortable with servers but prefer not to live in the terminal.

### 7.5 Production-Validated Credibility

Kokoro VPN is not an aspirational project — it is production infrastructure. The 3-node mesh connecting three cloud providers has been operating continuously under real load (routing inter-service traffic for multiple production applications). This is a meaningful differentiator in a market where many open-source tools are maintained by authors who do not use their own software in production. Bug reports that come in from the community are triaged against a real production deployment, not a toy environment.

---

## 8. Financial Projections

### 8.1 Assumptions and Model Framework

These projections are built from a bottom-up conversion funnel model, using conservative assumptions appropriate for a solo-founder open-source project in its first year of public operation.

The model assumes:

- Community user growth through organic channels (no paid acquisition)
- Conversion rate from free to paid managed hosting: 2% (industry baseline for developer tools is 1-5%)
- Desktop premium conversion: 5% of active desktop app users
- Enterprise deals close at 12-18 month sales cycles

**Year 1 (2026) — Foundation**

GitHub repository goes public in Q1 2026. Product-market fit exploration phase. Revenue goal is covering operational costs and beginning managed hosting.

| Metric                    | Q2 2026 | Q3 2026 | Q4 2026  |
| ------------------------- | ------- | ------- | -------- |
| GitHub stars              | 500     | 1,500   | 3,000    |
| Active community installs | 100     | 400     | 800      |
| Managed hosting customers | 3       | 12      | 25       |
| Desktop premium users     | 5       | 20      | 50       |
| Monthly Recurring Revenue | $200    | $800    | $2,000   |
| Annual 2026 Revenue       | —       | —       | ~$12,000 |

**Year 2 (2027) — Growth**

SSO integration, mobile apps, and web management UI ship in H1 2027. Enables SMB customer segment. First enterprise support contracts.

| Metric                       | Q2 2027 | Q4 2027   |
| ---------------------------- | ------- | --------- |
| GitHub stars                 | 6,000   | 10,000    |
| Active community installs    | 2,000   | 4,000     |
| Managed hosting customers    | 60      | 120       |
| Enterprise support contracts | 2       | 5         |
| Monthly Recurring Revenue    | $10,000 | $22,000   |
| Annual 2027 Revenue          | —       | ~$180,000 |

**Year 3 (2028) — Scale**

ZTNA features, multi-tenant console, hardware partnerships. Enterprise sales motion established.

| Metric                       | Q4 2028   |
| ---------------------------- | --------- |
| GitHub stars                 | 20,000+   |
| Managed hosting customers    | 300       |
| Enterprise support contracts | 15        |
| Monthly Recurring Revenue    | $60,000+  |
| Annual 2028 Revenue          | ~$700,000 |

### 8.2 Unit Economics

**Managed Hosting (Starter, $29/month)**

- Infrastructure cost per customer: ~$8/month (1 VPS, monitoring, backups)
- Gross margin: 72%
- Payback period on any acquisition cost: immediate (no paid acquisition)

**Enterprise Support ($500-$2,000/month)**

- Marginal cost: founder/engineer time at estimated $150/hour
- Average hours per enterprise customer per month: 2-4 hours (standard), 8-12 hours (premium)
- Gross margin on Standard: ~75%; on Premium: ~65%

**Desktop Premium ($49/year)**

- Infrastructure cost: near-zero (license key validation, no ongoing compute)
- Gross margin: >95%

### 8.3 Path to Profitability

The business reaches operational profitability (covering infrastructure, tooling, and founder salary equivalent of $80,000/year) at approximately 250 managed hosting customers plus 5 enterprise support contracts — a milestone projected for mid-2027 based on the growth model above.

The capital requirement to reach this milestone is minimal. Infrastructure costs scale with revenue (managed hosting pays its own infrastructure), and customer acquisition is entirely organic. No external funding is required under this model.

---

## 9. Risks and Mitigations

### 9.1 Open-Source Monetization Challenge

**Risk**: The vast majority of users will never pay. An product with no feature gating means anyone can use the full product forever for free. This is the fundamental tension of open-source monetization, and it has ended many well-intentioned projects.

**Mitigation**: The monetization strategy deliberately avoids the "open-core" trap — gating important features behind a paid tier creates resentment in open-source communities and fragment the user base between free and paid users who have fundamentally different experiences. Instead, revenue comes from services (managed hosting, support) and convenience (desktop premium, multi-server management) — things that require ongoing operational effort or provide time savings, not features that users feel they are being denied.

The freemium business model for developer tools has a well-established conversion rate range (1-5% to paid tiers). At 3,000 active community installs — a milestone achievable within 18 months of public launch based on comparable open-source VPN tool growth rates — even a 1% conversion to the $29/month managed hosting tier generates meaningful revenue.

### 9.2 Tailscale Dominance

**Risk**: Tailscale has significant brand recognition, $100M in funding, a polished UX that is genuinely excellent, and a generous free tier. Many developers who encounter Kokoro VPN will already have Tailscale deployed and will see no reason to switch.

**Mitigation**: Kokoro VPN does not need to displace Tailscale to succeed. The target market is users for whom Tailscale's cloud dependency is a non-starter — privacy-conscious operators, compliance-constrained organizations, and users who have experienced Tailscale's free tier limitations (3 users, 100 devices on the free plan). For these users, the choice is not "Tailscale vs. Kokoro VPN" — it is "Kokoro VPN vs. manually managing WireGuard configs" or "Kokoro VPN vs. complex Netmaker/Netbird deployments."

Additionally, Tailscale's full-mesh-only architecture means it cannot replace Kokoro VPN's hub-and-spoke client VPN use case without deploying both a Tailscale exit node (which routes traffic through a single node) and the mesh — operationally equivalent to Kokoro VPN's dual-mode but using Tailscale's proprietary client and cloud coordination.

### 9.3 WireGuard Commoditization

**Risk**: WireGuard has been in the Linux kernel since 5.6 (2020) and is widely understood by network engineers. Any experienced systems administrator can manage WireGuard configurations manually. The "raw WireGuard" option will always be free and available. As more tools (including cloud providers like AWS and DigitalOcean) build WireGuard management into their native offerings, the value proposition of a third-party tool may erode.

**Mitigation**: Cloud provider VPN offerings (AWS VPN, DigitalOcean Managed VPN) are expensive ($0.05/GB transfer + hourly gateway cost), not open-source, and do not support multi-cloud topologies by definition. They are not a substitute for a self-managed WireGuard mesh across heterogeneous providers.

The product roadmap mitigates commoditization risk by moving up the value stack: ACL generation, SSO integration, ZTNA policy enforcement, and multi-tenant management are features that differentiate Kokoro VPN from both raw WireGuard and cloud-native VPN offerings. A pure "WireGuard management GUI" is commoditized; a "zero-trust network access platform with WireGuard as the transport layer" is not.

### 9.4 Single Developer Bus Factor

**Risk**: Kokoro VPN is currently maintained by a single developer. If the founder becomes unavailable — illness, burnout, a major competing priority — the project stalls. For enterprise customers relying on Kokoro VPN for production infrastructure, this is a real concern.

**Mitigation**: The proprietary license is itself a mitigation — if Kokoro Tech were to dissolve, any user or third party could fork and continue development. The codebase is designed for readability and maintenance: idiomatic Rust, no external runtime dependencies, clear separation between the server and CLI concerns.

Beyond the license, enterprise support contracts create the financial incentive and contractual commitment to maintain the product. An enterprise customer paying $2,000/month for premium support has effectively funded ongoing development and has contractual recourse if support quality degrades.

Longer-term, the project will actively recruit community contributors and, as revenue permits, engage part-time contractors for specific feature work — reducing the bus factor below one.

### 9.5 Security Vulnerabilities

**Risk**: A VPN product that ships with a security vulnerability is uniquely damaging. A misconfigured firewall rule or JWT validation bug could expose private network resources. Given that Kokoro VPN is managing actual network access control, a vulnerability is not just a software bug — it is potentially a network breach.

**Mitigation**: Rust eliminates entire categories of memory safety vulnerabilities that have historically plagued C and C++ network software. The JWT authentication implementation uses established Rust crates rather than custom cryptography. The ACL generation system produces scripts for human review before application — it does not directly modify firewall rules.

A formal security audit from an independent third party is planned as a pre-condition for the enterprise support tier launch. Security advisories will be handled through GitHub's private security advisory system, with coordinated disclosure and patch release before public disclosure.

---

## Conclusion

Kokoro VPN occupies a defensible and growing niche: the developer and infrastructure operator who wants the privacy and control of a self-hosted WireGuard solution but needs more capability than raw WireGuard management, without the operational complexity of enterprise-oriented tools like Netbird or Netmaker. The dual-mode architecture — serving both client VPN and mesh VPN use cases from a single deployment — is a real differentiator with no direct equivalent in the open-source VPN landscape.

The product is already production-tested. The technology is sound. The market is real and growing. The monetization strategy is conservative and proven for open-source developer tools. The risks are real but manageable.

The path forward is execution: publish the repository, build the community, launch managed hosting, and let the product's quality drive growth.

---

**Next steps:** [Contact us →](../services/contact.md) | [How We Work →](../services/how-we-work.md) | [View technical profile →](../profile/resume.md)

---

_Kokoro Tech — [tech.happykokoro.com](https://tech.happykokoro.com) · [GitHub](https://github.com/happykokoro) · [Contact](../services/contact.md)_
