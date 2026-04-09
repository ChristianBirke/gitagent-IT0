# Cloud Cost Optimization

Cloud bills are architecture decisions. Every component, configuration choice, and scaling policy translates directly to monthly spend. This document covers the strategies, hidden costs, and monitoring practices for keeping costs in line with value delivered.

---

## Right-Sizing Compute

### The Problem

Over-provisioning is endemic. Teams pick "safe" instance sizes, then never revisit. A typical cloud environment runs at 10-20% average CPU utilization. You're paying for 80-90% of capacity you're not using.

### How to Approach It

**Start with metrics, not guesses.** Look at actual CPU, memory, and network utilization at P95 and P99, not averages. Averages hide spikes; you need to see peak utilization to right-size safely.

**Right-size in two steps:**
1. First right-size memory (often easier to measure accurately)
2. Then right-size CPU (more variable due to spikes)

**Use Graviton/Ampere (ARM) instances.** AWS Graviton3 delivers 20-40% better price-performance than comparable x86 instances (AWS benchmarks). Most workloads — web servers, APIs, containerized applications — run unchanged on ARM. Check your critical dependencies for ARM compatibility first.

**Managed database right-sizing:** RDS and Aurora instances are frequently oversized. Use Performance Insights and CloudWatch to identify actual utilization. Switching from db.r5.4xlarge to db.r5.2xlarge saves ~$400/month per instance. Do this carefully — test under realistic load before production.

### Tools

- AWS: Cost Explorer Resource Optimization, AWS Compute Optimizer, Trusted Advisor
- GCP: Recommender (Idle Resource Recommendations)
- Azure: Azure Advisor
- Third-party: Spot.io, CloudHealth, Datadog Cost Management

---

## Reserved vs. Spot vs. On-Demand

### On-Demand

Full price, no commitment, start/stop anytime. Use for:
- Unpredictable, short-lived workloads
- Development and test environments (with auto-stop schedules)
- Workloads you haven't characterized yet

**Avoid on-demand for:** Long-running, predictable production workloads. You're paying a 40-60% premium for flexibility you're not using.

### Reserved Capacity

Commit to 1 or 3 years, get 30-60% discount vs. on-demand. Three types:

- **Standard Reserved Instances:** Highest discount (up to 60%), least flexible. Locked to instance family, OS, region.
- **Convertible Reserved Instances:** Lower discount (~45%), can exchange for different family/OS. Better for teams where workloads evolve.
- **Savings Plans (AWS):** Commit to a dollar amount of compute usage per hour, not specific instance types. Most flexible, ~60% discount on EC2. The right default for most AWS users.

**Rule of thumb:** Reserve/commit whatever you can confidently predict running 24/7 for 12+ months. Layer spot on top for burst.

### Spot Instances

Spare cloud provider capacity, 60-90% discount vs. on-demand. Can be reclaimed with 2-minute notice (AWS) or 30 seconds (GCP preemptible).

**Good fit:**
- Stateless workloads (web tier, API layer with multiple instances)
- Batch jobs and data processing (use checkpointing for long jobs)
- CI/CD build runners
- Kubernetes node groups for non-critical pods

**Bad fit:**
- Stateful workloads without external state management
- Single-instance services
- Workloads with strict latency SLAs that can't absorb a restart

**Spot interruption handling:** Configure graceful shutdown hooks. Use AWS Auto Scaling mixed instances policy to blend spot and on-demand. Use Spot Instance Advisor to pick instance types with low interruption frequency.

---

## Serverless Economics

### When Serverless Wins

Serverless (Lambda, Cloud Functions, Cloud Run) excels for:
- **Bursty, unpredictable traffic** — You pay only for actual invocations. A function that runs 1,000 times/day is vastly cheaper than an always-on server.
- **Event-driven processing** — S3 event triggers, SNS/SQS consumers, scheduled jobs.
- **Idle-heavy workloads** — Internal tools, batch processors, notification services that run minutes per day.

### When Serverless Gets Expensive

At sustained high throughput, serverless can be 2-5x more expensive than reserved EC2/containers:

- **Lambda pricing:** $0.0000166667 per GB-second + $0.20 per 1M requests. At 1,000 requests/second with 128MB functions running 100ms, you pay ~$1,440/month. An equivalent EC2 Savings Plan might cost $300/month.
- **Cold start costs:** Cold starts add 100-1,000ms latency. For latency-sensitive applications, you need provisioned concurrency (~$0.0000646 per GB-second), which partially eliminates the cost advantage.
- **VPC cold starts:** Lambda functions in a VPC have historically had slow cold starts (mitigated in 2019 with hyperplane ENIs, but still a factor to monitor).

**Break-even analysis:** Run the numbers at your expected request rate. Serverless typically wins below ~100 req/sec sustained; container/VM typically wins above ~500 req/sec sustained. The exact crossover depends on function duration and memory.

---

## Data Transfer Costs

Data transfer is the hidden cost that surprises teams most. Cloud providers charge generously for ingress (usually free) and punitively for egress.

### AWS Data Transfer Pricing (representative, verify current pricing)

- **Egress to Internet:** ~$0.09/GB (first 10TB/month), ~$0.085/GB (next 40TB)
- **Cross-region transfer:** ~$0.02/GB each way
- **Cross-AZ transfer within VPC:** $0.01/GB each way — this one surprises teams most
- **Same-AZ transfer:** Free
- **CloudFront egress:** ~$0.0085/GB (much cheaper than direct egress)

### Cross-AZ Transfer: The Silent Budget Killer

In a typical multi-AZ deployment, your load balancer routes requests to instances in different AZs, which then query databases in other AZs. Every hop across AZ boundaries costs $0.01/GB each way. At scale, this adds up fast.

**Example:** An application processing 10TB of data per month across AZs pays $100/month in cross-AZ transfer alone, on top of compute costs. At 100TB/month: $1,000/month.

**Mitigations:**
- Use AZ-aware routing in your service mesh (Istio locality load balancing, AWS Target Group AZ routing)
- Place read replicas in each AZ and route reads locally
- Use VPC endpoints for AWS service access (eliminates NAT gateway charges for S3, DynamoDB, etc.)

### NAT Gateway Costs

NAT Gateways charge $0.045/hour (~$32/month) per gateway **plus** $0.045/GB of data processed. A single NAT gateway processing 1TB/month costs $77. Two gateways (for HA) in a high-traffic environment processing 10TB/month: $930/month.

**Mitigation:**
- Use VPC endpoints for AWS services (S3, DynamoDB, ECR, SQS, SNS) — eliminates NAT gateway traffic for those services
- Use NAT Instances (cheaper but more operational overhead) for non-critical environments
- Aggregate outbound traffic through fewer, larger NAT gateways rather than one-per-AZ-per-service

---

## Storage Tiers

### Object Storage (S3, GCS, Azure Blob)

| Tier | Use Case | Retrieval | Cost (S3 approximate) |
|------|----------|-----------|----------------------|
| Standard | Active data, frequent access | Immediate | ~$0.023/GB/month |
| Infrequent Access | Monthly access, backups | Immediate | ~$0.0125/GB/month |
| Glacier Instant Retrieval | Quarterly access | Milliseconds | ~$0.004/GB/month |
| Glacier Flexible Retrieval | Yearly access | Minutes to hours | ~$0.0036/GB/month |
| Glacier Deep Archive | Long-term archival | 12+ hours | ~$0.00099/GB/month |

**S3 Lifecycle Policies** automate tier transitions. Typical pattern: Standard → IA after 30 days → Glacier after 90 days → Deep Archive after 365 days. Run the cost calculator with your actual access patterns before committing — retrieval fees can exceed storage savings for frequently accessed archives.

**S3 Intelligent-Tiering** automatically moves objects between access tiers based on access patterns. Monitoring fee: $0.0025 per 1,000 objects. Worth it for large datasets with unknown access patterns; not worth it for millions of small objects.

### Database Storage

- **EBS GP3:** $0.08/GB/month (de-coupled IOPS — pay for storage and IOPS separately). Default choice.
- **EBS IO2:** $0.125/GB/month + $0.065/provisioned IOPS/month. For high-IOPS workloads only.
- **RDS storage autoscaling:** Enable it. Running out of storage causes downtime. Set the maximum to something reasonable.

---

## Hidden Costs

### CloudWatch Logs

CloudWatch Logs charges for ingestion ($0.50/GB), storage ($0.03/GB/month), and queries ($0.005 per GB scanned). A high-traffic application logging 100GB/day generates $1,500/month in log ingestion alone.

**Mitigation:**
- Set log retention policies (30-90 days for most applications)
- Filter noisy log sources before ingestion using Lambda or Kinesis Firehose
- Use log sampling for high-volume, low-signal logs
- Consider shipping to cheaper storage (S3 via Kinesis Firehose) for long-term retention

### Route 53 DNS Queries

$0.40 per million queries for standard routing, $0.60-$0.80 for latency/geo/weighted routing. Usually negligible but can surprise at scale.

### Elastic IP Addresses

Free when attached to a running instance. $0.005/hour (~$3.60/month) when not attached. Audit regularly for unattached EIPs — a sign of resources that weren't cleaned up.

### Load Balancer Hours

ALBs and NLBs charge per hour ($0.008/hour for ALB = ~$5.76/month) plus per LCU (Load Balancer Capacity Unit). A heavily utilized ALB can cost hundreds per month. Don't create per-service load balancers in microservices architectures — use a single ALB with path-based routing.

---

## Cost Monitoring and Alerting

### Fundamentals

- **Enable AWS Cost Anomaly Detection** (free) — alerts on unusual spending patterns before they become big bills
- **Tag everything** — Environment, team, service, project. Without tags, you can't attribute costs or identify waste
- **Set billing alerts** — CloudWatch billing alarms at 80% and 100% of budget
- **Weekly cost reviews** — Assign a rotation for reviewing Cost Explorer weekly. Costs that go unreviewed for a month turn into surprises

### FinOps Practice

For organizations spending >$50K/month on cloud, formalize FinOps:
- **Allocate costs to teams** — Showback (visibility) or chargeback (actual allocation). Visibility alone drives behavior change.
- **Define cost-per-unit metrics** — Cost per request, cost per active user, cost per GB processed. These metrics connect engineering decisions to business value.
- **Review Reserved/Savings Plan coverage** — Target 70-80% coverage for predictable workloads. 100% is too rigid; 50% means you're overpaying on the remainder.
