# Cloud Architecture Patterns

Reference guide for common cloud and application architecture patterns. For each pattern: what it is, when to use it, when NOT to use it, and common pitfalls.

---

## Microservices

### What It Is

Microservices decompose an application into small, independently deployable services, each responsible for a single business capability. Services communicate over the network — typically REST, gRPC, or messaging. Each service has its own data store (database-per-service), its own deployment lifecycle, and its own team ownership.

The promise: independent deployability, polyglot technology choices, isolated fault domains, and team autonomy at scale.

### When to Use

- **Large organizations with multiple teams** — Conway's Law applies. If you have 5+ teams working on the same system, microservices align architectural boundaries with team boundaries.
- **Different scaling requirements per component** — When your image processing service needs 50x the resources of your user profile service, independent scaling pays off.
- **Polyglot requirements** — When different parts of your system genuinely benefit from different technologies (e.g., ML inference in Python, real-time features in Go, transactional workflows in Java).
- **Mature DevOps capabilities** — You have CI/CD, container orchestration, distributed tracing, and service mesh in place.

### When NOT to Use

- **Small teams (< 10 engineers)** — The operational overhead of managing 20 services, 20 CI/CD pipelines, and 20 deployment targets is a full-time job for a team that should be building product. Start with a modular monolith.
- **Early-stage products** — Domain boundaries are unclear early on. Splitting prematurely locks you into the wrong seams. Getting microservice boundaries wrong is more painful than getting monolith boundaries wrong.
- **Low-traffic systems** — If you're serving hundreds of requests per day, network overhead, service discovery, and distributed debugging cost more than they save.
- **Teams without distributed systems experience** — Microservices surface every distributed systems problem: network failures, partial failures, consistency challenges. These are hard problems with steep learning curves.

### Common Pitfalls

- **Distributed monolith** — Services that are technically separate but logically coupled (shared database, synchronous call chains) give you the worst of both worlds. Fix: enforce database-per-service, prefer async communication.
- **Chatty services** — Fine-grained decomposition leads to dozens of synchronous network calls per request. Fix: aggregate at the API gateway, denormalize data, or reconsider service boundaries.
- **Missing observability** — A request failure in a microservices system could originate from any of 10 services. Without distributed tracing (Jaeger, Zipkin, OpenTelemetry), debugging is nearly impossible.
- **Inconsistent data** — Without distributed transactions, maintaining consistency across services requires careful design (sagas, outbox pattern). Many teams underestimate this challenge.

---

## Event-Driven Architecture

### What It Is

Services communicate by publishing and consuming events rather than making direct calls. An event represents something that happened (e.g., `OrderPlaced`, `PaymentProcessed`). Producers don't know who consumes their events; consumers subscribe to the event streams they care about. Infrastructure: Kafka, RabbitMQ, AWS SNS/SQS, Google Pub/Sub.

### When to Use

- **Loose coupling between teams/services** — Publishers and consumers evolve independently. Adding a new consumer doesn't require changing the producer.
- **High throughput with burst traffic** — Message queues absorb spikes and smooth out load. Producers write at their pace; consumers process at theirs.
- **Audit trails and event sourcing** — Retaining every event gives you a complete history of what happened and when. Invaluable for compliance and debugging.
- **Cross-domain workflows** — Business processes that span multiple domains (order → inventory → shipping → billing) are naturally modeled as event chains.
- **Fan-out patterns** — One event needs to trigger many downstream actions (e.g., `UserSignedUp` triggers email, analytics, onboarding, billing).

### When NOT to Use

- **Simple CRUD applications** — If your app is mostly create/read/update/delete with low complexity, event-driven adds ceremony without benefit.
- **When you need immediate consistency** — Async by nature. If the user needs to see the effect of their action immediately (e.g., check-out confirmation), you need synchronous confirmation before publishing the event.
- **Small teams without queue infrastructure experience** — Kafka operations are non-trivial. Misconfigured retention policies, consumer group lag, and partition rebalancing are real operational hazards.

### Common Pitfalls

- **Event schema drift** — Producers change event shape without coordinating with consumers. Fix: use a schema registry (Confluent Schema Registry, AWS Glue), enforce compatibility modes (backward, forward, full).
- **Poison pill messages** — A malformed event causes a consumer to crash repeatedly, blocking the queue. Fix: implement dead-letter queues (DLQ) and alerting on DLQ depth.
- **Unordered events** — At-least-once delivery without partitioning guarantees can deliver events out of order. Fix: design consumers to be idempotent, use Kafka partition keys to order related events.
- **Temporal coupling through events** — A long chain of event handlers creates an implicit synchronous workflow that's hard to reason about and debug. Fix: make workflows explicit with saga orchestration or workflow engines.

---

## CQRS (Command Query Responsibility Segregation)

### What It Is

CQRS separates the write model (commands — operations that change state) from the read model (queries — operations that return data). The write model enforces business rules and consistency. The read model is optimized for query patterns — often denormalized, pre-aggregated, and stored in a read-optimized store (Elasticsearch, Redis, a separate database). The read model is kept up to date by consuming events from the write side.

### When to Use

- **Very different read and write performance characteristics** — Your write throughput is high and writes are complex, but reads need to be sub-millisecond and support complex queries.
- **Multiple read models for different consumers** — Mobile app, internal dashboard, and external API all need the same data in different shapes. CQRS lets you maintain purpose-built read models.
- **Event sourcing** — CQRS and event sourcing are frequently combined. Event sourcing is the write model; CQRS projections are the read models.
- **Complex business domains** — Domain-driven design contexts where writes involve invariants and aggregates that are awkward to query directly.

### When NOT to Use

- **Simple applications** — CRUD apps with a few tables do not benefit from CQRS. The additional complexity is pure overhead.
- **When eventual consistency is unacceptable** — Read models lag behind the write model. Users may read stale data. If this is a problem for your use case, reconsider.
- **Small teams** — Maintaining two models, synchronization logic, and potentially two data stores doubles the surface area of your system.

### Common Pitfalls

- **Stale read models** — Read model updates fail silently and users read stale data indefinitely. Fix: monitor read model lag, implement health checks, expose staleness metadata.
- **Over-engineering** — CQRS for a simple CRUD app with one read pattern. Start with a single model and extract CQRS only where query/write asymmetry proves painful.
- **Complex projections** — Read model projections that require joining many events become complex and slow to rebuild. Fix: keep projections simple, snapshot state periodically.

---

## Saga Pattern

### What It Is

A saga is a sequence of local transactions, where each step publishes an event (or message) that triggers the next step. If any step fails, compensating transactions are executed to undo the work of previous steps. Two flavors:

- **Choreography** — Each service subscribes to events and decides what to do. No central coordinator.
- **Orchestration** — A central saga orchestrator tells each service what to do and handles failures.

Sagas are the standard solution for distributed transactions across microservices.

### When to Use

- **Long-running business processes across services** — Order fulfillment (reserve inventory → charge payment → schedule shipping). Each step is owned by a different service.
- **When distributed ACID transactions are not available** — Which is almost always in microservices. 2PC (two-phase commit) is a distributed systems antipattern due to coordinator single point of failure.
- **When compensating actions are well-defined** — Every step that can fail needs a compensating action (refund payment, release inventory reservation). If your domain doesn't support clean compensation, sagas are painful.

### When NOT to Use

- **Simple, short-lived transactions** — If everything happens in one database, use a local transaction. Sagas are for cross-service consistency only.
- **When you need true ACID guarantees** — Sagas give you eventual consistency. If you need atomicity and isolation, you need a different architecture (or a single service with a single database).

### Common Pitfalls

- **Missing compensations** — A saga step fails but there's no compensating transaction. Data ends up in an inconsistent state. Fix: define compensations before building the saga, not after.
- **Choreography spaghetti** — With many services and events, choreographed sagas become impossible to trace. Fix: switch to orchestration for complex workflows; use a workflow engine (Temporal, AWS Step Functions, Conductor).
- **Saga state loss** — The orchestrator crashes mid-saga. Fix: persist saga state to a durable store before each step; make the orchestrator recoverable.

---

## Strangler Fig Pattern

### What It Is

Inspired by the strangler fig tree (which grows around a host and eventually replaces it), this pattern migrates a legacy system incrementally. A facade/proxy routes requests to either the old system or the new system, based on which parts have been migrated. Over time, the legacy system is "strangled" as more and more traffic routes to the new implementation.

### When to Use

- **Migrating a legacy monolith to microservices or a modern stack** — Rewrite-in-place is risky and high-blast-radius. Strangler fig allows incremental migration with rollback capability.
- **When you cannot afford a big-bang rewrite** — The system must stay running during migration. Strangler fig gives you a safe migration path.
- **Domain by domain** — Migrate the lowest-risk, highest-value domains first. Prove the pattern, build confidence, migrate more.

### When NOT to Use

- **Systems with deeply entangled shared state** — If every module shares a single massive database with stored procedures, routing traffic to a new service while keeping the old system operational is a data consistency nightmare.
- **Short-lived projects** — If the legacy system will be retired in 6 months, a strangler fig may not be worth the infrastructure investment.

### Common Pitfalls

- **Facade becomes a bottleneck** — The routing layer adds latency and becomes a single point of failure. Fix: use a high-performance, stateless proxy (Nginx, Envoy); distribute it.
- **Dual-write complexity** — During migration, data may need to exist in both old and new stores. Fix: define which system is the source of truth for each domain and sync unidirectionally.
- **Never completing the migration** — The legacy system never fully dies. Fix: set migration deadlines, measure progress, decommission aggressively.

---

## Sidecar Pattern

### What It Is

A sidecar container runs alongside the main application container in the same pod/host, handling cross-cutting concerns: service discovery, observability, traffic management, security (mTLS), configuration. The main application is unaware of the sidecar; the sidecar intercepts traffic and augments behavior. Envoy proxy (used by Istio and Linkerd) is the canonical sidecar.

### When to Use

- **Polyglot microservices** — When you have services in multiple languages, implementing observability/tracing/mTLS in each language independently is expensive. A sidecar provides these capabilities uniformly.
- **Service mesh** — Istio, Linkerd, and Consul Connect all use sidecars to implement traffic management, mutual TLS, and telemetry.
- **Gradual infrastructure upgrades** — Add observability or security to existing services without code changes.

### When NOT to Use

- **Low-resource environments** — Sidecars add memory and CPU overhead (Envoy uses ~50MB+ per instance). In environments with tight resource constraints or many small services, this adds up.
- **Simple deployments** — If you have 3 services and don't need a service mesh, the sidecar pattern adds operational complexity for minimal gain.

### Common Pitfalls

- **Latency overhead** — Traffic through a sidecar adds 1-5ms per hop. For latency-sensitive services, this matters. Measure before deploying broadly.
- **Debugging complexity** — mTLS and traffic manipulation by the sidecar can make debugging network issues harder. Fix: establish clear observability practices before enabling complex sidecar features.

---

## Circuit Breaker Pattern

### What It Is

Prevents cascading failures in distributed systems. When a downstream service starts failing, the circuit breaker "opens" and short-circuits requests (returning an error or fallback immediately) rather than allowing callers to queue up waiting for timeouts. After a cooldown period, the circuit "half-opens" — a small number of requests probe the downstream service. If they succeed, the circuit closes.

States: Closed (normal operation) → Open (failing fast) → Half-Open (testing recovery).

Libraries: Hystrix (deprecated, Netflix), Resilience4j (Java), Polly (.NET), go-resilience, built into Envoy/Istio.

### When to Use

- **Any service that calls external dependencies** — Databases, third-party APIs, downstream microservices. If it can be slow or unavailable, protect it with a circuit breaker.
- **High-traffic systems** — A slow downstream service without a circuit breaker can exhaust thread pools and crash the caller. Circuit breakers prevent this cascade.
- **When fallback behavior is possible** — Circuit breakers work best when you can define a meaningful fallback (serve cached data, return a default, degrade gracefully).

### When NOT to Use

- **Calls where failure should propagate immediately** — Some operations are critical paths where there is no meaningful fallback. Force the error to the surface.
- **Internal same-process calls** — Circuit breakers are for network calls. Don't apply this to in-process function calls.

### Common Pitfalls

- **Misconfigured thresholds** — Too sensitive (opens on transient errors), too lenient (never opens). Fix: tune thresholds based on real error rate baselines in production.
- **No fallback strategy** — Circuit breaker opens, caller gets an error, user sees a crash. Fix: always define fallback behavior before implementing the circuit breaker.
- **Hiding systematic failures** — A permanently open circuit breaker masks a broken integration. Fix: alert on circuit breaker state changes; don't let open circuits stay open silently.

---

## Bulkhead Pattern

### What It Is

Inspired by ship hull compartments (if one compartment floods, the ship doesn't sink), bulkheads isolate resources so that a failure in one area doesn't consume resources needed by another. In practice: separate thread pools, connection pools, or rate limits for different downstream dependencies.

Example: Your checkout service calls three services — inventory, payment, and shipping. Without bulkheads, a slow shipping API can exhaust the shared thread pool and starve inventory and payment calls. With bulkheads, each downstream has its own thread pool with an independent limit.

### When to Use

- **Services with multiple downstream dependencies of different criticality** — Isolate critical-path dependencies from nice-to-have ones.
- **Preventing noisy neighbors** — When one tenant or workload type could consume all shared resources.
- **Paired with circuit breakers** — Bulkheads and circuit breakers are complementary. Bulkheads limit blast radius; circuit breakers prevent cascades.

### When NOT to Use

- **Simple services with one downstream** — Bulkheads only matter when resource contention between dependencies is a real risk.
- **Over-partitioned systems** — Dozens of tiny thread pools creates tuning overhead without proportional benefit. Reserve for the most critical resource-isolation requirements.

### Common Pitfalls

- **Under-sizing pools** — Too-small thread pools cause legitimate requests to fail under normal load. Fix: size based on observed concurrency, not guesses. Monitor pool saturation.
- **Forgetting connection pools** — Thread pools are the most visible bulkhead, but database connection pools matter just as much. Isolate critical-path DB connections from batch operations.
