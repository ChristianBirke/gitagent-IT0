# Good Outputs — Calibration Examples

These examples illustrate the quality, structure, and depth expected from the architect-agent. Use these as reference when evaluating outputs.

---

## Example 1: Tech Deep Dive with Real Benchmarks and "When NOT to Use"

**User prompt:** "Give me a deep dive on Apache Kafka — we're considering it for our event streaming pipeline."

---

## Deep Dive: Apache Kafka

**TL;DR:** Kafka is a distributed, durable, high-throughput log designed for streaming data pipelines. Use it when you need persistent, replayable event streams at scale. Don't use it when you need simple queue semantics or have a team that can't operate it.

### Overview

Kafka is a distributed commit log, not a traditional message queue. Records are appended to partitioned, ordered logs and retained for a configurable period — not deleted on consumption. Consumers track their own position (offset) in the log, which enables multiple independent consumer groups, event replay, and stream processing. This is what distinguishes it from RabbitMQ, SQS, and other queue systems.

Kafka's architecture: producers publish to topics, topics are partitioned across brokers, consumers read from partitions in consumer groups. Replication factor (typically 3) ensures durability. The Controller (one broker) manages partition leadership. Zookeeper (or KRaft in Kafka 3.x+) handles cluster coordination.

It was built at LinkedIn to handle billions of events per day and open-sourced in 2011. Today it underpins real-time infrastructure at Uber, Netflix, Airbnb, and most financial institutions doing real-time processing.

### Strengths

1. **Throughput** — Kafka's sequential disk I/O and batching achieves millions of messages per second per broker. LinkedIn published benchmarks showing 2M writes/sec on commodity hardware. Confluent benchmarks (2022) demonstrated 1B messages/day on a 3-broker cluster with <10ms P99 latency. Source: [Kafka performance whitepaper, Confluent 2022](https://www.confluent.io/blog/kafka-fastest-messaging-system/)

2. **Durability and replayability** — Messages are persisted to disk and replicated. A consumer can rewind to any point in history and reprocess. Invaluable for debugging production issues, backfilling new consumers, and recovering from downstream failures.

3. **Decoupling producers from consumers** — Producers publish without knowing who consumes. Adding a new consumer requires no producer changes. This enables safe fan-out: one `OrderPlaced` event consumed independently by inventory, billing, analytics, and notifications.

4. **Mature ecosystem** — Kafka Connect (100+ connectors for ingestion/egress), Kafka Streams (lightweight stream processing in Java), ksqlDB (SQL on streams). Managed offerings: Confluent Cloud, AWS MSK, Aiven.

### Weaknesses

1. **Operational complexity** — Kafka cluster management is non-trivial. Partition rebalancing during broker failures, consumer group lag monitoring, log compaction configuration, and schema registry operations require dedicated expertise. Source: [Production Kafka Operations, Confluent docs](https://docs.confluent.io/platform/current/kafka/operations.html)

2. **No true priority queues** — All partitions within a topic are served in order, but there's no native priority routing between topics. Workaround: separate topics per priority tier, but this multiplies operational surface.

3. **Small message overhead** — Kafka optimizes for high-throughput at the cost of latency for tiny payloads. For 100-byte messages at low volume, the batching model works against you. RabbitMQ or SQS handles low-volume, small-message workloads more efficiently.

4. **Consumer group rebalancing** — When consumers join or leave, all partitions are reassigned. During the rebalancing window (seconds to minutes), processing pauses. Kafka 3.1+ cooperative rebalancing reduces this, but it's still a concern for latency-sensitive consumers.

### Real-World Adoption

- **Uber** uses Kafka as the backbone for 1T+ messages/day across its real-time data platform. Source: [Uber Engineering Blog, 2021](https://eng.uber.com/kafka/)
- **Netflix** uses Kafka for their real-time monitoring pipeline processing 700B events/day. Source: [Netflix Tech Blog](https://netflixtechblog.com/kafka-inside-keystone-pipeline-dd5aeabaf6bb)
- **New York Times** migrated from a monolith to Kafka-based event streaming for article publish workflows. Source: [Martin Kleppmann, Designing Data-Intensive Applications]

### When to Use This

- You need durable, replayable event streams where consumers can process at their own pace
- You're building a data pipeline that fans out to multiple consumers (analytics, ML, notifications)
- You need to decouple services and accept eventual consistency between them
- Your team has the operational capacity to run a Kafka cluster or budget for a managed service (MSK, Confluent)

### When NOT to Use This

- **Simple task queues** — If you need "process this job once and remove it," use SQS or RabbitMQ. Kafka's log model is overkill and adds complexity.
- **Small teams without Kafka experience** — Kafka has a steep operational learning curve. A 3-person team building a startup MVP will spend more time on Kafka operations than on product. Use SQS or a simple hosted Pub/Sub service.
- **Sub-millisecond latency requirements** — Kafka's batching model optimizes throughput over latency. If you need consistent sub-1ms message delivery, consider NATS or a direct gRPC call.
- **Transient, ephemeral events** — If you don't need to replay events and don't need durability, a simpler queue is sufficient.

### Cost & Operational Considerations

**Self-hosted (3-broker cluster on AWS):**
- Compute: 3x r6g.xlarge = ~$450/month reserved
- Storage: 3x 1TB EBS GP3 = ~$240/month
- Operations: Requires 1 engineer knowledgeable in Kafka to maintain (significant hidden cost)

**AWS MSK (managed Kafka):**
- 3x kafka.m5.large (production minimum) = ~$1,100/month
- Storage: $0.10/GB/month
- Connector: Additional charges
- Trade-off: You lose tuning flexibility but eliminate cluster operations overhead

**Confluent Cloud:**
- CKU (Confluent Processing Unit)-based pricing. Minimum viable cluster ~$400/month.
- Fully managed, Schema Registry included, better managed connectors than MSK.
- Most expensive managed option but lowest operational overhead.

### Recommendation

Given you're evaluating this for an event streaming pipeline: if your team has 2+ engineers with Kafka experience and you expect >10K messages/second or need durable, replayable streams, Kafka is the right choice — go with MSK if your team is AWS-native to reduce operational burden. If you're < 10K messages/second, the team is small, or the use case is primarily task queuing, I'd recommend SQS (simpler, cheaper, near-zero ops) and revisit Kafka if you outgrow it.

### Sources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Confluent Kafka Performance Benchmarks 2022](https://www.confluent.io/blog/kafka-fastest-messaging-system/)
- [Designing Data-Intensive Applications, Kleppmann 2017]
- [AWS MSK Pricing](https://aws.amazon.com/msk/pricing/)

---

## Example 2: Comparison Matrix with Weighted Scoring

**User prompt:** "We need to choose between PostgreSQL, CockroachDB, and PlanetScale for our SaaS product. We care most about global multi-region and developer experience."

---

## Comparison: PostgreSQL vs CockroachDB vs PlanetScale

**Context:** SaaS product requiring global multi-region distribution, strong developer experience. Team is 8 engineers, primarily familiar with SQL. Budget is startup-scale.

### Decision Matrix

| Criteria | Weight | PostgreSQL (+ Citus/Aurora) | CockroachDB | PlanetScale |
|----------|--------|-----------------------------|-------------|-------------|
| Multi-region distribution | 30% | 2 — Requires Aurora Global or Citus; complex to configure; read replicas only without distributed write | 5 — Native distributed SQL with geo-partitioning; multi-region writes are the core value proposition | 4 — Branching model; global reads built-in; writes still route to primary region (improving) |
| Developer experience | 25% | 5 — Postgres is the lingua franca; every ORM, client, and tool supports it; massive community | 3 — Wire-compatible with Postgres but differences surface; some Postgres features unsupported | 4 — Excellent DX; schema branching for migrations; Vitess-based but abstracted away |
| Cost (startup scale) | 20% | 5 — RDS/Aurora cheapest managed option; self-host possible; no per-seat licensing | 2 — Expensive at startup scale; $0.12/RU on Serverless; dedicated clusters start ~$300/month | 3 — Free tier generous; Scaler plan $39/month; production ready at reasonable cost |
| Operational complexity | 15% | 4 — Managed via RDS/Aurora (straightforward); multi-region adds complexity | 3 — Fully managed on Cockroach Cloud; single-region simple; multi-region operations still require expertise | 5 — Fully managed by PlanetScale; near-zero ops; schema changes are safe by design |
| Maturity & ecosystem | 10% | 5 — 30+ years, most stable, largest community, every library supports it | 3 — Production-proven at scale (DoorDash, Netflix) but smaller ecosystem, some rough edges | 3 — Vitess is battle-tested (used by YouTube, Slack), PlanetScale layer is newer |
| **Weighted Score** | **100%** | **3.75** | **3.40** | **3.80** |

### Recommendation

**PlanetScale** — narrowly, for your specific context. The combination of strong multi-region support, excellent developer experience, zero-ops overhead, and startup-friendly pricing edges it ahead. The score difference is small; the real decision is between PlanetScale and CockroachDB.

**The nuance the matrix doesn't fully capture:**
- PlanetScale's write model still routes writes to a primary region. If you need multi-region write distribution (users in EU writing to EU, US writing to US with consistency), CockroachDB's geo-partitioning is far superior.
- PlanetScale uses Vitess, which doesn't support foreign key constraints. If your schema is FK-heavy, this creates migration friction.

**When to choose CockroachDB instead:** You're building for genuinely global write distribution from day one (not just global reads), and you have budget and at least one engineer experienced with distributed SQL.

**When to choose PostgreSQL instead:** Your MVP is single-region, the team is small, and you want to defer the multi-region complexity. Start with Aurora, add global replicas when you have paying customers in multiple regions.

### Caveats

- These scores are for startup-scale workloads. At hyperscale (>1M active users), the calculus shifts significantly.
- PlanetScale's pricing model changes as you scale — verify current pricing for your projected query volume.

---

## Example 3: Discovery Session Uncovering Hidden Constraint

**User prompt:** "We want to move our application to Kubernetes. We're running on EC2 with Auto Scaling today."

---

## Discovery Summary: Kubernetes Migration

**After structured discovery questions, a critical hidden constraint emerged.**

### Current State

Single-region EC2 deployment (us-east-1). Auto Scaling groups for web tier (3-10 instances), 2 fixed database nodes (RDS PostgreSQL). Deployed via Ansible + manual AMI baking. ~15 services, all deployed as long-running processes.

### Requirements

**Functional:** Need shorter deployment cycles, better resource utilization, ability to run multiple environments.

**Non-functional:** 99.9% availability SLA. Deployments must not cause downtime.

### Constraints

**Technical:** Services are all stateless except for two that write session data to local disk (not EBS). Services communicate via internal load balancer hostnames — no service discovery.

**Organizational (CRITICAL — surfaced during discovery):**

> "Who on your team has Kubernetes experience?"
> "We have nobody who's done it before. We watched a few tutorials."

The team of 6 engineers has zero production Kubernetes experience. Nobody has operated a Kubernetes cluster, debugged a CrashLoopBackOff, configured network policies, or managed RBAC.

**Business:** Need to ship the migration in 3 months. One engineer available full-time for infrastructure work.

### Scale

**Current:** 50K daily active users, 500 req/sec peak.

**Projected (12 months):** 100K DAU, 1,000 req/sec peak.

### Priorities (ranked)

1. Reduce deployment friction and cycle time
2. Improve environment parity (prod/staging)
3. Better resource utilization

### Key Risks Identified

**Kubernetes is likely the wrong answer for this team right now.**

The stated goals — shorter deployments, environment parity, better resource utilization — can be achieved without Kubernetes. The hidden constraint is organizational: a team with no Kubernetes experience, a 3-month deadline, and one full-time infrastructure engineer faces a very high risk of:
- Deploying Kubernetes incorrectly and creating more incidents than they prevent
- Consuming all 3 months on K8s learning and setup, with nothing shipped
- Creating a system that nobody on the team can debug in production at 2am

### Recommended Next Step

**Options Analysis** — I recommend evaluating 3 options:
1. **Lean:** ECS Fargate — container orchestration without Kubernetes complexity. 80% of K8s benefits, 20% of the operational overhead. The team can learn containers without learning Kubernetes.
2. **Balanced:** EKS with managed node groups + a 2-month K8s fundamentals investment — feasible but tight timeline.
3. **Premium:** Full Kubernetes with Helm, Argo CD, network policies — correct long-term direction but realistically an 18-month journey to production-ready operations for this team.

My recommendation before seeing the options: ECS Fargate gets you to your goals in 3 months. K8s gets you there eventually, but not on this timeline with this team.

---

## Example 4: Recommendation Brief a Non-Technical VP Could Understand

**User prompt:** "Write a recommendation brief for our VP of Engineering on why we should move from our current monolith to an event-driven architecture."

---

## Recommendation Brief: Event-Driven Architecture Migration

### Problem

Our current order management system processes all operations synchronously in a single application — when a customer places an order, that single process must check inventory, process payment, update fulfillment, and send notifications before the order can complete. As we've grown to 50K orders/day, this design causes two business-critical problems: order completion time has increased from 800ms to 4.2 seconds under peak load, and a failure in any single step (payment processor timeout, email provider outage) causes the entire order to fail, resulting in abandoned carts and refund requests.

### Recommendation

Migrate the order pipeline to an event-driven architecture where each processing step (payment, inventory, fulfillment, notifications) operates independently and asynchronously, communicating through a message queue. Orders complete when payment confirms; everything else happens in the background.

### Why This Approach

- **Eliminates cascading failures** — A notification service outage will no longer fail orders. Each component fails independently. Orders continue to process even when downstream services are degraded.
- **Improves order completion time** — Orders confirm when payment succeeds (~400ms). Background processing (fulfillment handoff, email) no longer blocks the customer experience.
- **Enables independent scaling** — During peak periods (Black Friday), we can scale the payment processor without scaling the fulfillment or notification services, reducing costs by ~35% during spikes.
- **Future-proof** — Adds a new partner integration or analytics system by subscribing to existing events — no changes to the core order flow.

### Trade-offs

- **What we gain:** Resilience, performance, and flexibility to extend the platform without touching the core order flow.
- **What we accept:** Orders are confirmed before all processing completes, which requires customer-facing messaging ("your order is confirmed; fulfillment will be scheduled shortly"). This is the norm for e-commerce at our scale but requires a UX update.

### Investment

- **Estimated cost:** ~$2,400/month additional infrastructure (AWS SQS + SNS, managed Kafka alternative). One-time implementation cost: approximately 8 weeks of engineering (2 engineers full-time).
- **Timeline:** 12 weeks to production-ready migration for the order pipeline.
- **Team impact:** No new hires required. Two existing engineers will need 2-3 weeks of ramp-up on event-driven patterns.

### Risks

- **Data consistency during migration** — Running old and new systems in parallel requires careful cut-over. Mitigation: migrate one event type at a time, maintain rollback capability for 4 weeks post-migration.
- **New debugging complexity** — Distributed systems are harder to debug than monoliths. Mitigation: invest in distributed tracing (OpenTelemetry) as part of the project — $0 additional cost on AWS X-Ray.

### Next Steps

1. **Engineering lead:** Define event schema for OrderPlaced, PaymentConfirmed, FulfillmentScheduled — 2 weeks.
2. **VP Engineering approval:** Approve 2-engineer allocation for Q3 — needed by end of month.
3. **Infrastructure:** Provision message queue infrastructure in staging — 1 week after approval.
