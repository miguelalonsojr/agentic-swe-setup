# system-designing

Use this skill to work from service requirements to a distributed architecture. It asks for load, data growth, latency, availability, and operating constraints before choosing storage, replication, partitions, queues, or caches. The procedure traces requests and data, describes failure behavior, and checks how writes become visible to readers. It also calls for capacity arithmetic, observability, and a comparison with a simpler option.

The output is a proposal with explicit assumptions and testable risks. It does not treat a diagram as proof of throughput or availability. For class relationships and method-level design, use a low-level design guide. For a failing implementation, investigate the defect first rather than assuming a new architecture is needed.
