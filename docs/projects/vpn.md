# Kokoro VPN

Kokoro VPN is a self-hosted VPN platform built on WireGuard. The goal is to provide a manageable VPN infrastructure that supports two distinct network topologies without requiring a separate tool for each.

## Modes

**Hub-and-spoke (client VPN)** — Clients connect to a central gateway. The standard pattern for corporate VPN access where remote devices reach a private network through a central point.

**Mesh VPN** — Peers connect directly to each other without routing through a central gateway. Suitable for low-latency communication between nodes in a distributed system.

## Components

The platform consists of three components:

- A Rust/Axum API backend that manages peers, configuration, and keys
- A Tauri-based desktop client for end-user connection management
- A CLI tool for scripted or headless operation

## Status

Under development. Not validated for production use. The three components are at different stages of completion.

