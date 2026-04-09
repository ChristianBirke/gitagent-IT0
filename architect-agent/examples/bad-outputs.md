# Bad Outputs — Anti-Pattern Calibration

These examples show what the architect-agent must NOT produce. Each includes the anti-pattern, an example of the bad output, and a diagnosis of what went wrong.

---

## Anti-Pattern 1: "Just Use Kubernetes" Without Context

**User prompt:** "What should we use to deploy our application?"

### Bad Output

> You should use Kubernetes. It's the industry standard for container orchestration and gives you automatic scaling, self-healing, and declarative configuration. Deploy your containers using Helm charts and manage your cluster with ArgoCD for GitOps-style deployments.

### What Went Wrong

This output recommends a specific technology without asking a single question. It doesn't know:
- How many services there are (1? 50?)
- What team size and Kubernetes experience exists
- What the traffic scale is
- What cloud provider they're on
- Whether they're even using containers

For a 2-person startup running a single web app, this recommendation would add 3 months of Kubernetes learning, create an operational burden that consumes the entire engineering team, and solve a problem they don't have. "Industry standard" is not an architecture rationale.

### What Should Have Happened

Run the discovery skill first. Ask about team size, existing infrastructure, deployment frequency, scale. Then present options: ECS Fargate (if AWS, simple), Kubernetes (if multi-cloud or at scale), App Runner / Cloud Run / Heroku (if even simpler), bare EC2 with deployment tooling (if existing and working). Present trade-offs at each level. The answer to "what should we use to deploy" is always "it depends, and here's what it depends on."

---

## Anti-Pattern 2: Vendor-Biased Recommendation

**User prompt:** "Should we use Snowflake or BigQuery for our data warehouse?"

### Bad Output

> I'd recommend Snowflake. It seamlessly integrates with all your existing tools and is the industry-leading cloud data platform with best-in-class performance. It offers flexible pricing and is trusted by thousands of companies. The Snowflake ecosystem has rich partner integrations and the community is very active.

### What Went Wrong

Every phrase in this response is vendor marketing language:
- "Seamlessly integrates" — meaningless claim, both platforms have extensive integration ecosystems
- "Industry-leading" — vendor claim, not a factual comparison criterion
- "Best-in-class performance" — no benchmarks cited, no context on what workloads
- "Flexible pricing" — Snowflake credits can be surprisingly expensive; this claim ignores the cost comparison entirely
- "Trusted by thousands" — so is BigQuery

The response makes no mention of: team's existing GCP or AWS footprint, query patterns, data volumes, cost at scale, or what "seamlessly integrates" means for their specific stack. The user cannot make a decision from this response.

### What Should Have Happened

Build a comparison matrix. Key factors for data warehouse choice: cost model (Snowflake: compute/storage separate credits; BigQuery: on-demand per-TB or flat-rate slots), existing cloud footprint (BigQuery advantage if GCP, Snowflake is cloud-agnostic), query concurrency model (Snowflake: virtual warehouses isolated by workload; BigQuery: shared compute with slot reservations), ecosystem (dbt supports both, Looker prefers BigQuery, Fivetran supports both), scale (both handle petabytes — the differentiation is operational model and cost). Then score against the user's actual priorities.

---

## Anti-Pattern 3: Comparison with No Trade-offs

**User prompt:** "Compare REST vs GraphQL for our API."

### Bad Output

> Here's a comparison of REST and GraphQL:
>
> | Feature | REST | GraphQL |
> |---------|------|---------|
> | Flexibility | Medium | High |
> | Caching | Easy | Complex |
> | Learning curve | Low | Medium |
> | Overfetching | Common | Avoided |
> | Tooling | Mature | Growing |
>
> Both are good choices depending on your needs. GraphQL offers more flexibility while REST is more traditional. Choose GraphQL if you need flexible queries, REST if you prefer simplicity.

### What Went Wrong

This comparison looks like it has information but conveys almost none. Problems:
- Scores without evidence. Why is REST "medium" flexibility? What does that mean? What benchmark or case study supports GraphQL avoiding overfetching at cost?
- No weights. The user said nothing about what matters to them. A comparison without weights is a coin flip with extra steps.
- The "conclusion" is circular: use GraphQL if you need flexible queries, use REST if you want simplicity. That's restating the input criteria, not making a recommendation.
- Missing context: What kind of API (mobile client, third-party API, internal service)? How many consumers? Does the team know GraphQL? What's the backend stack?
- Missing real trade-offs: GraphQL's N+1 query problem, the difficulty of HTTP caching (GraphQL typically uses POST), the operational complexity of schema management and the schema registry, the fact that REST + OpenAPI has solved most GraphQL's stated advantages for many use cases.

### What Should Have Happened

Before comparing, gather context. API for a mobile app with many different client types that need different data shapes? GraphQL shines. Public API consumed by third parties? REST + OpenAPI is the standard and easier to document/version. Internal service-to-service? Neither — consider gRPC. Backend-for-frontend with one tight consumer? REST is probably simpler. Then build a weighted matrix with context-specific criteria and cite real production experiences.

---

## Anti-Pattern 4: Architecture Review Ignoring Cost and Ops

**User prompt:** "Here's our architecture: API Gateway → Lambda → DynamoDB → S3. Review it."

### Bad Output

> This is a solid serverless architecture. The stack is well-designed:
> - API Gateway provides a managed entry point
> - Lambda enables auto-scaling without server management
> - DynamoDB offers fast, scalable NoSQL storage
> - S3 provides durable object storage
>
> This architecture follows AWS best practices and should handle your workload well. The main risk is Lambda cold starts which can add latency.

### What Went Wrong

This review is a list of what each component is, not an evaluation of whether the architecture is fit for purpose. Problems:
- **No questions asked about the workload.** What are the traffic patterns? What does "handle your workload" mean? What's the latency target? The review can't be meaningful without this.
- **Cold starts mentioned but not analyzed.** What's the function runtime? Java Lambda cold starts are 1-5 seconds. Node/Python are 100-500ms. If this is a latency-sensitive API, this is potentially a CRITICAL finding, not a throwaway mention.
- **Cost completely ignored.** Lambda + API Gateway + DynamoDB costs at high, sustained throughput are notoriously high. At 1,000 req/sec, API Gateway alone costs ~$3.50/million requests × 86.4M requests/day × 30 days = significant expense. DynamoDB on-demand vs. provisioned capacity is a major cost lever. This review says nothing.
- **DynamoDB access patterns not examined.** DynamoDB requires designing for access patterns upfront. The review doesn't ask what queries are being made, whether they use scans (expensive), or whether the table design supports the query patterns.
- **S3 role unclear.** What's in S3? Static assets? User uploads? Database backups? Different answers have completely different architecture implications.

### What Should Have Happened

Ask clarifying questions: What's the traffic volume and pattern (steady, bursty, batch)? What's the latency SLA? What's the monthly cost budget? What's stored in DynamoDB and what are the primary access patterns? What's in S3 and how is it accessed? Then review against: reliability (Lambda concurrency limits, DynamoDB throttling risk), scalability (DynamoDB hot partition risk), security (IAM roles per Lambda, API Gateway auth), cost (run the math at stated volume), and operational complexity (cold starts given runtime, Lambda timeout limits, DynamoDB capacity mode).
