---
name: comparison-matrix
description: "Side-by-side comparison of 2-4 technology options with weighted scoring. Use when the user says 'compare X vs Y', 'which should we use', 'help me choose between', or needs a structured decision between alternatives."
license: MIT
allowed-tools: web-search
metadata:
  author: vincentelbotte
  version: "1.0.0"
  category: decision-support
---

# Comparison Matrix

## Instructions

When comparing technology options:

1. **Identify the options** — What are we comparing? Confirm the list with the user.
2. **Define criteria** — Based on context, select 5-8 evaluation criteria. Default set:
   - **Performance** — Throughput, latency, scalability limits
   - **Cost** — Licensing, infrastructure, operational overhead
   - **Complexity** — Learning curve, deployment difficulty, debugging ease
   - **Maturity** — Production readiness, community size, documentation quality
   - **Ecosystem** — Integrations, tooling, managed service availability
   - **Team fit** — Does the team have experience? How steep is the ramp-up?
3. **Weight criteria** — Ask the user what matters most, or infer from context. Weights should total 100%.
4. **Score each option** — 1-5 scale per criterion. Cite evidence for scores.
5. **Calculate and recommend** — Weighted scores determine the recommendation. Explain the result.

## Output Format

```
## Comparison: [Option A] vs [Option B] vs [Option C]

**Context:** [What we're solving, key constraints]

### Decision Matrix

| Criteria | Weight | [Option A] | [Option B] | [Option C] |
|----------|--------|------------|------------|------------|
| Performance | 20% | 4 — [reason] | 3 — [reason] | 5 — [reason] |
| Cost | 25% | 3 — [reason] | 5 — [reason] | 2 — [reason] |
| Complexity | 20% | 4 — [reason] | 4 — [reason] | 2 — [reason] |
| Maturity | 15% | 5 — [reason] | 3 — [reason] | 4 — [reason] |
| Ecosystem | 10% | 4 — [reason] | 3 — [reason] | 5 — [reason] |
| Team Fit | 10% | 3 — [reason] | 4 — [reason] | 2 — [reason] |
| **Weighted** | **100%** | **3.75** | **3.85** | **3.30** |

### Recommendation

**[Option B]** — [Rationale explaining why the weighted score tells the right story, and any qualitative factors the numbers don't capture]

### Caveats

- [Important nuance the matrix doesn't capture]
- [Scenario where a different option would win]
```
