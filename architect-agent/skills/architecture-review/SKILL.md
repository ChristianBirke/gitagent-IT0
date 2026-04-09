---
name: architecture-review
description: "Evaluate an existing or proposed architecture for risks, bottlenecks, and improvement opportunities. Use when the user says 'review this architecture', 'what are the risks', 'where are the bottlenecks', or describes a system design for feedback."
license: MIT
metadata:
  author: vincentelbotte
  version: "1.0.0"
  category: evaluation
---

# Architecture Review

## Instructions

When reviewing an architecture:

1. **Understand the system** — Ask clarifying questions if needed: what does it do, what scale, what SLAs, what team maintains it?
2. **Evaluate across dimensions** — Check each of these systematically:
   - **Reliability** — Single points of failure, failover mechanisms, data durability
   - **Scalability** — Horizontal vs vertical, bottlenecks, stateful components
   - **Security** — Authentication, authorization, data encryption, network boundaries
   - **Cost** — Over-provisioned resources, data transfer costs, managed service pricing
   - **Operational complexity** — Deployment complexity, observability, debugging difficulty, on-call burden
   - **Maintainability** — Coupling between components, blast radius of changes, team cognitive load
3. **Prioritize findings** — Not everything is critical. Rank by impact and likelihood.
4. **Recommend** — For each finding, suggest a specific improvement.

## Output Format

```
## Architecture Review: [System Name]

**Summary:** [2-3 sentence overall assessment]

### Findings

#### CRITICAL
- **[Finding]** — [Description]. Impact: [what happens if this fails]. Recommendation: [specific fix].

#### HIGH
- **[Finding]** — [Description]. Impact: [consequence]. Recommendation: [specific fix].

#### MEDIUM
- **[Finding]** — [Description]. Recommendation: [specific fix].

#### LOW
- **[Finding]** — [Description]. Recommendation: [specific fix].

### Strengths
- [What's working well — acknowledge good design decisions]

### Overall Assessment
[Is this architecture fit for purpose? What's the biggest risk? What should be addressed first?]
```

## What This Skill Is NOT

- Not a code review — focus on architecture, not implementation details
- Not exhaustive — focus on the highest-impact findings, not every possible concern
- Not academic — prioritize practical risks over theoretical ones
