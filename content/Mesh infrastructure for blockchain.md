---
title: Mesh infrastructure for blockchain
description: What mesh networking can and cannot do for blockchains in areas without connectivity
image: img/Mesh-in-blockchain.webp
date: 2026-10-02
---
How could people in areas without internet coverage ever use a blockchain? And what happens if a large-scale conflict destroys network infrastructure in part of the world? I was turning these questions over when my father sent me a post about **Meshtastic** and **MeshCore**, and the question became concrete: "*can a mesh network carry a blockchain?*"

### Why a mesh cannot run consensus
---
Mesh topology is appealing, but **LoRa-based meshes** offer very **little bandwidth** and **high latency**.
Block confirmation requires consensus to spread quickly across the network. A radio mesh partitions often, and every partition that keeps producing blocks becomes a fork. A mesh is therefore **the wrong place to run consensus**.

### Mesh as a transport layer
---
That does not make it useless. A signed transactions is small, and it can hop from node to node until it reaches a gateway that submits it on-chain. Used this way, **mesh could become an emergency-relay**: it carries signatures and identity, not state.

This suggests a three-layer architecture:
- **Edge (mesh)** — nodes sign compressed transaction offline and relay them.
- **Gateway/Aggregator** — nodes with an intermittent uplink (satellite, occasional 4G) that store, forward and batch transactions.
- **Anchors (L1/L2)** — the chain responsible for ordering and finality.

### The main problem: offline double-spending
---
Without a synchronized global state, a user can sign several transaction spending the same balance in different partitions. **Two mitigation** stand out:
1. **Escrow**. Capital is locked in advance, so the maximum loss is bounded by the deposit. It's simple but immobilizes funds.
2. **Capped spending with slashing**. Each key has an offline spending limit, backed by collateral. When the gateway anchors the transactions and a conflict is detected, the collateral is slashed and paid to the party that suffered the loss. This frees capital but requires a dispute contract.

The choice depends on the value at risk. For micro-payments, either option is enough. For attestations (sensor data, supply chain), double spending does not arise at all: the only requirement ius a credible timestamp, witch the anchor provides.

### What follows from this
---
Because the mesh cannot provide finality, the protocol must expose it: a transaction is either _locally provisional_ or _anchored_, and applications decide which one they accept. The second **open question is economic**: **gateways carry the cost** of uplink and anchoring, so **a model that pays them has to exist** before the network can be relied on.