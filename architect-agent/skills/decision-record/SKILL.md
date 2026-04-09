---
name: decision-record
description: "Generate an Architecture Decision Record (ADR) documenting a technology or design choice. Use when the user says 'document this decision', 'write an ADR', 'record that we chose', or after a comparison/evaluation concludes."
license: MIT
metadata:
  author: vincentelbotte
  version: "1.0.0"
  category: documentation
---

# Decision Record

## Instructions

When documenting an architecture decision:

1. **Gather context** — What prompted this decision? What constraints exist? Draw from memory and current conversation.
2. **List options** — Include all options that were seriously considered, with pros and cons for each.
3. **State the decision** — Clear, unambiguous statement of what was chosen.
4. **Document consequences** — Both positive and negative. What does this enable? What does it prevent? What new constraints does it create?
5. **Set review date** — When should this decision be revisited?

## Output Format

```
# ADR-[NNN]: [Title]

**Status:** Accepted | Proposed | Deprecated | Superseded by ADR-[NNN]
**Date:** [YYYY-MM-DD]
**Decision makers:** [Who was involved]

## Context

[What is the issue? What forces are at play? What constraints exist?
2-3 paragraphs providing full context so future readers understand why
this decision was made.]

## Options Considered

### Option 1: [Name]
- **Pros:** [list]
- **Cons:** [list]
- **Cost estimate:** [if relevant]

### Option 2: [Name]
- **Pros:** [list]
- **Cons:** [list]
- **Cost estimate:** [if relevant]

### Option 3: [Name]
- **Pros:** [list]
- **Cons:** [list]
- **Cost estimate:** [if relevant]

## Decision

[Clear statement: "We will use [X] for [purpose]."]

[1-2 paragraphs explaining the rationale — why this option over the others.]

## Consequences

### Positive
- [What this enables]

### Negative
- [What this costs or prevents]

### Risks
- [Risks introduced by this decision]

## Review Date

[When to revisit: date or trigger condition, e.g., "when traffic exceeds 10k RPS"]
```

## What This Skill Is NOT

- Not a comparison tool — use comparison-matrix for evaluation, this is for recording the outcome
- Not a rubber stamp — the ADR should honestly document trade-offs, not justify a predetermined choice
