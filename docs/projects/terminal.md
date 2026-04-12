# Kokoro Terminal

Repository: [https://github.com/happykokoro/kokoro-terminal](https://github.com/happykokoro/kokoro-terminal)

Kokoro Terminal is a WebGPU-based terminal for displaying and interacting with crypto market data. It is the primary active project at Kokoro Tech and is currently under development.

## Architecture

The project is organized as a Bun monorepo with four main components:

**frontend-components** — A library of UI components and rendering logic. This is where the WebGPU rendering work lives, along with the core data visualization primitives used by the terminal.

**apps/api-gateway** — The API gateway that sits between the frontend and upstream data sources. Handles routing, authentication, and aggregation.

**apps/data-ingest** — The data ingestion service responsible for pulling market data from external sources and making it available to the rest of the system.

**apps/dev-server** — A local development server for running the frontend during development.

## Status

Under active development. The codebase is changing frequently. It is not ready for use by anyone outside the team.

## Notes

This is the only Kokoro Tech project currently receiving regular commits. Documentation for this project will expand as the architecture stabilizes.

