---
name: tech-deep-dive
description: "Deep research on a specific technology, pattern, or service. Use when the user asks 'tell me about', 'what's the deal with', 'should we use', 'deep dive on', or any request for in-depth technical analysis."
license: MIT
allowed-tools: web-search
metadata:
  author: vincentelbotte
  version: "1.0.0"
  category: research
---

# Tech Deep Dive

## Instructions

When the user asks for a deep dive on a technology:

1. **Clarify scope** — What specifically do they want to know? "Tell me about Kafka" could mean architecture, use cases, operations, or comparison with alternatives.
2. **Research** — Use web-search to find official documentation, benchmarks, case studies, and real-world adoption stories. Prioritize:
   - Official documentation and architecture guides
   - Published benchmarks and performance data
   - Production case studies from companies at relevant scale
   - Known limitations and failure modes
3. **Analyze** — Synthesize findings into a structured analysis.
4. **Contextualize** — Connect findings to the user's situation using memory of past decisions and known constraints.

## Output Format

```
## Deep Dive: [Technology/Pattern]

**TL;DR:** [One sentence — what it is and when to use it]

### Overview
[2-3 paragraphs: what it is, how it works at a high level, where it fits in the ecosystem]

### Strengths
1. **[Strength]** — [Explanation with evidence/citation]
2. **[Strength]** — [Explanation with evidence/citation]
3. **[Strength]** — [Explanation with evidence/citation]

### Weaknesses
1. **[Weakness]** — [Explanation with evidence/citation]
2. **[Weakness]** — [Explanation with evidence/citation]
3. **[Weakness]** — [Explanation with evidence/citation]

### Real-World Adoption
- [Company/project] uses it for [use case] at [scale]. Source: [citation]
- [Company/project] uses it for [use case] at [scale]. Source: [citation]

### When to Use This
- [Specific scenario where this is the right choice]
- [Specific scenario where this is the right choice]

### When NOT to Use This
- [Specific scenario where this is wrong — and what to use instead]
- [Specific scenario where this is wrong — and what to use instead]

### Cost & Operational Considerations
[Managed service pricing, self-hosted requirements, operational complexity, team skill requirements]

### Recommendation
[Contextual recommendation based on user's situation]

### Sources
- [Citation 1]
- [Citation 2]
```
