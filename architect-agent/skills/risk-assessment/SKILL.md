---
name: risk-assessment
description: "Identify and rate technical, operational, and organizational risks for an architecture decision. Use when the user says 'what could go wrong', 'what are the risks', 'risk assessment', or before finalizing a major decision."
license: MIT
metadata:
  author: vincentelbotte
  version: "1.0.0"
  category: consulting
---

# Risk Assessment

## Instructions

When assessing risks:

1. **Identify risks** — Scan across three categories:
   - **Technical** — Performance bottlenecks, single points of failure, data loss scenarios, integration failures
   - **Operational** — On-call burden, deployment complexity, debugging difficulty, monitoring gaps
   - **Organizational** — Skill gaps, vendor lock-in, bus factor, compliance exposure
2. **Rate each risk** — Severity (1-5) x Likelihood (1-5) = Risk Score (1-25)
   - **Severity:** 1=negligible, 2=minor, 3=moderate, 4=major, 5=catastrophic
   - **Likelihood:** 1=rare, 2=unlikely, 3=possible, 4=likely, 5=almost certain
3. **Propose mitigations** — For every risk scored 9+, provide a specific mitigation strategy.
4. **Prioritize** — Sort by risk score descending. Focus attention on the top 5.

## Output Format

```
## Risk Assessment: [System/Decision]

### Risk Register

| # | Risk | Category | Severity | Likelihood | Score | Mitigation |
|---|------|----------|----------|------------|-------|------------|
| 1 | [Description] | Technical | 4 | 4 | 16 | [Specific mitigation] |
| 2 | [Description] | Operational | 3 | 5 | 15 | [Specific mitigation] |
| 3 | [Description] | Organizational | 5 | 2 | 10 | [Specific mitigation] |

### Top Risks Summary

1. **[Highest risk]** — [Why this matters and what to do about it]
2. **[Second highest]** — [Why this matters and what to do about it]
3. **[Third highest]** — [Why this matters and what to do about it]

### Overall Risk Profile

**Risk level:** Low | Medium | High | Critical
[1-2 sentences on overall assessment and whether to proceed]
```

## What This Skill Is NOT

- Not a blocker — risks are information, not stop signs. The goal is informed decisions, not risk avoidance.
- Not exhaustive — focus on the risks that actually matter, not every theoretical failure mode
