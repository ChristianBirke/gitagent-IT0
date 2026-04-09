# Distributed Systems Fundamentals

The conceptual foundations behind every distributed architecture decision. Understanding these makes the difference between confident design and cargo-culting patterns.

---

## CAP Theorem

### What It Is

CAP Theorem (Brewer, 2000) states that a distributed data system can guarantee at most two of three properties:

- **Consistency (C)** — Every read receives the most recent write or an error. All nodes see the same data at the same time.
- **Availability (A)** — Every request receives a response (not an error), though it may not be the most recent data.
- **Partition Tolerance (P)** — The system continues operating when network partitions prevent some nodes from communicating.

**The practical implication:** Network partitions are unavoidable in distributed systems. You cannot eliminate P. So the real choice is: during a network partition, do you prefer Consistency (reject requests that can't guarantee fresh data) or Availability (respond with potentially stale data)?

### CAP in Practice

- **CP systems** — Prioritize consistency over availability during partitions. HBase, Zookeeper, etcd, most SQL databases with synchronous replication. They may return errors rather than stale data.
- **AP systems** — Prioritize availability over consistency during partitions. Cassandra, DynamoDB, CouchDB. They will respond with potentially stale data rather than returning an error.
- **CA systems** — Theoretically possible only when there are no network partitions — i.e., single-node systems. Not relevant for distributed deployments.

### Common Misconceptions

- **CAP is not a permanent trade-off** — It applies only during partition events. Under normal operation (no partition), CP systems can achieve high availability. The choice is only relevant when the network fails.
- **CAP doesn't capture the full picture** — PACELC extends CAP to describe latency vs. consistency trade-offs even without partitions. Most modern systems have both partition tolerance and latency concerns.
- **"Eventual consistency" is not one thing** — The spectrum from strong to eventual consistency has many points, each with different guarantees.

---

## Consistency Models

### Strong Consistency

After a write completes, all subsequent reads from any node will see that write. The system behaves as if there is a single copy of data.

**Cost:** High — requires coordination (consensus) on every write. High latency, reduced availability under partition.

**Examples:** Single-master SQL databases with synchronous replication, Google Spanner (using TrueTime + Paxos), etcd.

**Use when:** Correctness is critical and you cannot tolerate stale reads. Financial transactions, distributed locks, configuration management.

### Eventual Consistency

If no new updates are made to a piece of data, all replicas will eventually converge to the same value. Reads may return stale data.

**Cost:** Low — replicas accept writes immediately and sync asynchronously. Low latency, high availability.

**Examples:** DNS, Cassandra (with ANY consistency level), DynamoDB (eventually consistent reads).

**Use when:** Availability and performance matter more than immediate consistency. Social media feeds, product catalogs, user preferences.

### Causal Consistency

Operations that are causally related are seen by all nodes in the same order. If event B happens because of event A, B will never be observed without first observing A. Concurrent (causally unrelated) operations may be observed in different orders.

**Cost:** Medium — requires tracking causality (vector clocks, logical timestamps). More available than strong, more consistent than eventual.

**Examples:** MongoDB multi-document sessions, CockroachDB serializable transactions, some Cassandra configurations.

**Use when:** You need to reason about cause-and-effect across operations but can tolerate some reordering of unrelated events. Collaborative editing, comment threads, social graph updates.

### Read-Your-Writes Consistency

A client always reads its own most recent writes. Other clients may still see stale data.

**Practical value:** High — users expect to see what they just submitted. A comment that disappears after posting is a frustrating experience.

**Implementation:** Route each user's reads to the same replica that processed their write, or use session tokens to identify the minimum replica state the user should see.

### Monotonic Read Consistency

Once a client has seen a value, it will never see an older value. You won't read V3, then read V1.

**Implementation:** Sticky session routing to the same replica, or client-side tracking of observed versions.

---

## Partitioning Strategies

### Hash Partitioning

Data is distributed across nodes by hashing the partition key. Each node owns a range of hash values. Simple, even distribution, fast lookups by key.

**Strength:** Even distribution prevents hotspots. No range scans on the partition key.

**Weakness:** Range queries on the partition key require scanning all partitions. Schema changes require rehashing (consistent hashing mitigates this).

**Use when:** Access pattern is primarily key lookups. Cassandra, DynamoDB, Redis Cluster all use hash partitioning.

### Range Partitioning

Data is partitioned into contiguous key ranges. Node 1 handles keys A-F, Node 2 handles G-M, etc.

**Strength:** Efficient range scans. HBase, Bigtable, and sorted SSTable-based systems excel here.

**Weakness:** Sequential access patterns (auto-incrementing IDs, time-series data sorted by time) create write hotspots on the "last" partition.

**Mitigation:** Prefix keys with a hash bucket to distribute sequential writes (e.g., `[hash(timestamp) % 10]_[timestamp]`).

### Consistent Hashing

A technique for hash partitioning where adding or removing nodes only requires remapping a fraction of keys (1/n where n is node count) rather than remapping everything. Virtual nodes (vnodes) further balance distribution.

**Use case:** Distributed caches (Memcached, Redis Cluster), distributed storage systems where nodes join and leave frequently.

---

## Consensus Algorithms

### What Problem They Solve

Multiple nodes must agree on a single value (e.g., who is the current leader, what is the committed state of a log). This must work correctly even when some nodes fail or messages are delayed.

### Paxos

The foundational consensus algorithm (Lamport, 1989). Proves that consensus is achievable in asynchronous networks despite node failures. Notoriously difficult to implement correctly. Multi-Paxos is the practical variant used in production systems.

**In practice:** Google Chubby, Google Spanner, Apache Zookeeper.

### Raft

Designed to be more understandable than Paxos while providing equivalent guarantees (Ongaro & Ousterhout, 2014). Separates leader election, log replication, and safety into distinct subproblems.

**Leader election:** Nodes campaign on timeout; first to win majority becomes leader.
**Log replication:** Leader appends to its log, replicates to followers, commits when majority acknowledges.

**In practice:** etcd (Kubernetes' backing store), CockroachDB, TiKV, Consul.

**Practical implications:** Raft requires 2f+1 nodes to tolerate f failures. A 3-node cluster tolerates 1 failure. A 5-node cluster tolerates 2 failures. Odd numbers only — even numbers don't improve failure tolerance.

### Viewstamped Replication / Zab

Zookeeper uses ZAB (Zookeeper Atomic Broadcast), a protocol similar to Paxos optimized for the leader-centric replication pattern common in coordination services.

---

## Distributed Transactions

### Two-Phase Commit (2PC)

**Phase 1 (Prepare):** Coordinator asks all participants to prepare — can they commit? Participants lock resources and respond yes/no.

**Phase 2 (Commit/Abort):** If all said yes, coordinator sends commit. If any said no, coordinator sends abort.

**Problems:**
- **Coordinator failure** — If the coordinator crashes after Phase 1, participants are blocked holding locks indefinitely. Fix requires persistent coordinator state and recovery.
- **Blocking protocol** — Participants hold locks until the coordinator responds. Under network partition, this stalls progress.
- **Not suitable for microservices** — 2PC requires all participants to implement the XA protocol and accept a direct coordination channel. Most microservices don't.

**When still appropriate:** Within a single database (most RDBMS implement 2PC internally), or in tightly coupled systems where you control all participants and accept the blocking risk.

### Sagas (see Cloud Patterns)

The practical alternative to 2PC for microservices. Sequence of local transactions with compensating actions.

### Outbox Pattern

Ensures that a service's database update and event publication happen atomically — without distributed transactions.

**How it works:**
1. Within the same local DB transaction, write the business state change AND write the event to an outbox table.
2. A separate process (transactional outbox poller or CDC system like Debezium) reads the outbox table and publishes events to the message broker.
3. Delete (or mark) the outbox entry after successful publication.

**Guarantee:** The event will be published if and only if the business transaction commits. No event lost, no event for a rolled-back transaction.

---

## Idempotency

### What It Is

An operation is idempotent if performing it multiple times has the same effect as performing it once. Critical in distributed systems where "at-least-once delivery" means the same message may arrive multiple times.

### Why It Matters

Network retries, message redelivery, and client retries are standard practice. Without idempotency, a retried payment charge is a double charge; a retried user creation is a duplicate account.

### Implementation Strategies

**Idempotency keys:** Client generates a unique key per operation. Server stores the key + result. If the same key arrives again, return the stored result without re-executing. Stripe's idempotency keys are the canonical example.

**Optimistic locking with versioning:** Include the expected version of a resource in the write. If the version has changed (someone else wrote first), reject the write. Safe for concurrent updates.

**Natural idempotency:** Some operations are naturally idempotent: `SET x = 5` is idempotent; `INCREMENT x` is not. Design data models to prefer idempotent operations where possible.

**Deduplication windows:** For event processing, maintain a window of recently seen event IDs (in Redis or a DB). Discard duplicates within the window. Practical for short-window deduplication (minutes to hours).

### Exactly-Once vs At-Least-Once

"Exactly-once" processing is extremely hard to achieve end-to-end in distributed systems. Most practical systems achieve exactly-once semantics by combining at-least-once delivery with idempotent consumers — the message may be delivered multiple times, but the consumer handles it exactly once.

Kafka Streams and Apache Flink offer exactly-once semantics within their processing boundaries, but this does not extend to side effects (database writes, external API calls) without additional idempotency design.
