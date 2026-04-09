---
name: options-analysis
description: "Present 3 viable architecture options at different investment levels (lean/balanced/premium). Use when the user says 'what are our options', 'give me choices', or after a discovery session is complete."
license: MIT
metadata:
  author: vincentelbotte
  version: "1.0.0"
  category: consulting
---

# Options Analysis

## Instructions

When presenting options:

1. **Review context** — Check memory for discovery summary, known constraints, and priorities.
2. **Design 3 options** — Each must be genuinely viable. They differ in investment level, not quality:
   - **Lean** — Minimum viable architecture. Lowest cost and complexity. Trade-off: may not scale or may require rework later.
   - **Balanced** — Good fit for most scenarios. Moderate investment. Best trade-off between capability and complexity.
   - **Premium** — Future-proof, highly scalable, comprehensive. Highest investment. Trade-off: more complex, slower to deliver.
3. **Be honest about trade-offs** — Don't make the lean option look bad to sell the premium. Each option has genuine advantages.
4. **Recommend one** — Based on the user's stated priorities and constraints.

## Output Format

```
## Options Analysis: [Problem/Project]

**Context:** [1-2 sentences summarizing the problem and key constraints]

### Option 1: Lean — [Name]
**Description:** [What this looks like]
**Key components:** [list]
**Estimated cost:** [monthly/annual]
**Complexity:** Low | Medium | High
**Time to implement:** [estimate with confidence level]
**Trade-offs:**
- (+) [advantage]
- (-) [disadvantage]
**Best for:** [when to choose this]

### Option 2: Balanced — [Name]
**Description:** [What this looks like]
**Key components:** [list]
**Estimated cost:** [monthly/annual]
**Complexity:** Low | Medium | High
**Time to implement:** [estimate with confidence level]
**Trade-offs:**
- (+) [advantage]
- (-) [disadvantage]
**Best for:** [when to choose this]

### Option 3: Premium — [Name]
**Description:** [What this looks like]
**Key components:** [list]
**Estimated cost:** [monthly/annual]
**Complexity:** Low | Medium | High
**Time to implement:** [estimate with confidence level]
**Trade-offs:**
- (+) [advantage]
- (-) [disadvantage]
**Best for:** [when to choose this]

### Recommendation

**[Option N]** — [Rationale tied to user's priorities and constraints]
```
