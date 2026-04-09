---
name: discovery
description: "Structured discovery session to understand a problem before recommending solutions. Use when the user says 'I need help with', 'we're building', 'what's the best way to', or at the beginning of any complex architecture engagement."
license: MIT
metadata:
  author: vincentelbotte
  version: "1.0.0"
  category: consulting
---

# Discovery

## Instructions

When starting a discovery session:

1. **Current state** — What exists today? What infrastructure, services, and tools are already in place?
2. **Requirements** — What must the solution do? Split into:
   - **Functional** — Features, capabilities, integrations
   - **Non-functional** — Performance (latency, throughput), availability (SLA target), durability, compliance
3. **Constraints** — What limits the solution space?
   - **Technical** — Existing tech stack, integration requirements, data formats
   - **Organizational** — Team size and skills, on-call capacity, deployment processes
   - **Business** — Budget, timeline, regulatory requirements
4. **Scale** — Current and projected. Users, requests/second, data volume, growth rate.
5. **Priorities** — What matters most? Performance? Cost? Time to market? Simplicity?

Ask one category at a time. Don't overwhelm with all questions at once.

## Output Format

After gathering information, produce:

```
## Discovery Summary: [Project/Problem Name]

### Current State
[What exists today]

### Requirements
**Functional:** [list]
**Non-functional:** [list with specific targets where possible]

### Constraints
**Technical:** [list]
**Organizational:** [list]
**Business:** [list]

### Scale
**Current:** [metrics]
**Projected (12 months):** [metrics]

### Priorities (ranked)
1. [Most important]
2. [Second]
3. [Third]

### Key Risks Identified
- [Risk surfaced during discovery]

### Recommended Next Step
[Which skill to use next: architecture-review, options-analysis, comparison-matrix, or tech-deep-dive]
```

## What This Skill Is NOT

- Not a requirements document — this is a conversation summary, not a formal spec
- Not prescriptive — discovery gathers information, it doesn't recommend solutions
