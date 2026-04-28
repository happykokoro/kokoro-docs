---
description: Portable network appliances pairing into customer-owned upstream egress; reference and custom SKUs.
---

# Network services — hardware

Portable network appliances that pair with a customer's network deployment to extend controlled egress to client devices that cannot run a VPN client themselves.

## What we provide

- **Stable-identity Wi-Fi appliance.** A pocket-sized device that bridges client devices over Wi-Fi into the customer's upstream egress, presenting a fixed IP to all downstream traffic. Solves the problem of consumer devices, IoT, and BYOD that cannot install a VPN client.
- **Two operator-selectable modes.** Stable-identity mode pins all device traffic to a single upstream egress for IP-reputation-sensitive services; rotating-egress mode distributes across multiple upstream egresses for standard locality privacy.
- **Single-tenant by construction.** The appliance authenticates upstream into the customer's own dedicated infrastructure — never a shared exit, never a third-party broker. The "fixed IP" is the customer's own infrastructure IP.
- **Reference SKU selection.** Firmware targets OpenWrt-compatible routers (primary) and Debian/Ubuntu single-board computers (secondary). Cross-compilation supported for ARM Cortex-A53/A7, MIPSel, and ARMv7. Reference devices are operator-sourced from established Wi-Fi vendor lines.
- **Custom hardware.** Custom PCB, enclosure, and branded SKUs are accepted post-pilot once economics justify the design IP and tooling cost.
- **Device attestation and lifecycle.** Each appliance carries a device-bound keypair; enrollment, attestation, telemetry, and factory-reset are first-class operations on the upstream control plane.

## Delivery models

- **Turnkey hardware-software bundle.** Reference appliance shipped pre-flashed and pre-paired to the customer's deployment. Includes operator CLI and a maintenance runbook.
- **Buildable firmware.** Source firmware buildable against the customer's chosen reference SKU, for customers who prefer to provision their own hardware.
- **White-label.** Customer branding, customer-issued attestation roots, region-specific SKU selection. Volume terms negotiated per-engagement.
- **Custom hardware pilots.** Custom PCB or branded enclosure work, post-firmware-stable, contracted as a separate hardware engagement.
- **Managed device fleet.** Lifecycle (provisioning, attestation, retirement, telemetry rollup) operated as a service against customer-owned hardware.

## Engagement

Hardware engagements typically begin with a scoped pilot using reference SKUs to validate the firmware and device-pairing workflow against the customer's deployment. Custom hardware decisions follow the pilot.
