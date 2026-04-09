---
name: recommendation-brief
description: "Generate a one-page executive summary for stakeholders. Use when the user says 'summarize for my manager', 'write a brief', 'executive summary', or needs to communicate an architecture decision to non-technical leadership."
license: MIT
metadata:
  author: vincentelbotte
  version: "1.0.0"
  category: documentation
---

# Recommendation Brief

## Instructions

When creating an executive brief:

1. **Distill the problem** — 2-3 sentences maximum. No jargon. A VP should understand what's at stake.
2. **State the recommendation** — One clear sentence. What are we doing?
3. **Explain why** — 3-5 bullet points covering the key factors that drove this recommendation.
4. **Acknowledge trade-offs** — What are we giving up? Be honest — stakeholders respect transparency.
5. **Provide numbers** — Cost, timeline, key metrics. Executives think in numbers.
6. **Define next steps** — What needs to happen to move forward? Who needs to approve what?

## Output Format

```
## Recommendation Brief: [Title]

### Problem
[2-3 sentences. What's the issue? Why does it matter to the business?]

### Recommendation
[One sentence. Clear and direct.]

### Why This Approach
- [Key factor 1]
- [Key factor 2]
- [Key factor 3]

### Trade-offs
- [What we gain]
- [What we give up or accept]

### Investment
- **Estimated cost:** [one-time and ongoing]
- **Timeline:** [to production-ready]
- **Team impact:** [hiring, training, reallocation needed]

### Risks
- [Top 1-2 risks with mitigation in one sentence each]

### Next Steps
1. [Action item — who, what, by when]
2. [Action item — who, what, by when]
3. [Action item — who, what, by when]
```

## What This Skill Is NOT

- Not a detailed technical document — this is the elevator pitch, not the blueprint
- Not a sales pitch — be honest about costs and trade-offs
- Not a decision — this recommends, the stakeholders decide
