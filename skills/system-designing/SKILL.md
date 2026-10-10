---
name: system-designing
description: Use when designing a distributed service from requirements for traffic, failure handling, storage, consistency, and operations.
---

## When to use

Use this skill for services spanning machines under changing load or failures. It covers capacity, data placement, replication, consistency, recovery, and data movement. For class or method design, use a low-level design guide. Investigate specific code defects before proposing architecture changes.

## Procedure

1. Ask for peak read/write rates, data size and growth, latency and availability targets, retention, geographic scope, and operational constraints. Label unknowns as assumptions.
2. Describe key request and data paths separately. Estimate storage, network transfer, and peak work. Show the arithmetic and identify potential hot spots.
3. Sketch components and data flows. Choose where state lives, who owns writes, and how requests find it. Add caches, queues, replicas, or partitions only for stated needs. Identify the source of truth and how to rebuild derived state.
4. Specify failure behavior at each boundary. Cover process loss, unavailable storage, a network split, and delayed or duplicate messages where applicable. For each operation, say whether it fails, retries, serves stale data, or waits; explain the effect on users and data.
5. Choose the required consistency per operation rather than for the whole service. Explain how writes become visible, how conflicting writes are handled, and what replication or partition movement does to that guarantee. Trace one normal write and one recovery path end to end.
6. Compare one simpler alternative with the proposed design. State the cost in latency, availability, complexity, and data movement. Keep decisions that can change later separate from choices that constrain stored data or client behavior.
7. Define what operators can see: request latency and errors, saturation, replication lag, backlog, and recovery progress where relevant. State alerts or checks tied to the stated targets, plus a safe way to test a failure mode.

## Verification

Check that each major component maps to a requirement or a measured constraint. Recalculate capacity with peak rather than average load and test the design against one component failure and one delayed-data scenario. Confirm that a reader can identify the source of truth, the user-visible behavior during failure, and the evidence needed to validate uncertain assumptions. Label untested claims as hypotheses.

## Limits

Do not claim a performance, availability, or consistency guarantee without a workload model and a mechanism that could provide it. Do not invent product interfaces, cloud features, measurements, or test results. Treat security, privacy, and cost constraints as requirements to clarify, not properties implied by a diagram. This guide produces an architecture proposal, not a production readiness certificate.

## References

- [Architecture tradeoffs](references/ch01-tradeoffs-architecture.md)
