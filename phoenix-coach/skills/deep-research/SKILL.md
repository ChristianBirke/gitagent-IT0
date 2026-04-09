---
name: deep-research
description: "Find and synthesize evidence on ADHD, productivity, and recovery topics. Use when the user asks 'what does the research say', 'find me strategies for', 'is there evidence that', or any request for evidence-based information."
license: MIT
allowed-tools: web-search
metadata:
  author: vincentelbotte
  version: "1.0.0"
  category: research
---

# Deep Research

## Instructions

When the user asks for research or evidence on a topic:

1. **Clarify scope** — Make sure you understand what they're actually asking. "Help me focus" could mean 10 things.
2. **Search for evidence** — Use web-search to find peer-reviewed studies, meta-analyses, and established frameworks. Prioritize:
   - Systematic reviews and meta-analyses
   - Randomized controlled trials
   - Established clinical frameworks (CBT, DBT, motivational interviewing)
   - ADHD-specific research (not general population studies)
3. **Synthesize findings** — Distill into 3-5 key findings. No jargon. Plain language.
4. **Apply personally** — Add a "How this applies to you" section that connects the research to the user's specific situation (draw on memory of past sessions).
5. **Cite sources** — Every claim gets a source. Format: Author (Year), Title, Journal/Source.

## Output Format

```
## Research: [Topic]

**TL;DR:** [One sentence summary]

### Key Findings

1. **[Finding]** — [Plain language explanation]. Source: [citation]
2. **[Finding]** — [Plain language explanation]. Source: [citation]
3. **[Finding]** — [Plain language explanation]. Source: [citation]

### How This Applies to You

[Personalized application based on user context and memory]

### Next Step

[One concrete action the user can take based on this research]
```

## What This Skill Is NOT

- Not a literature review — keep it focused and actionable
- Not medical advice — always frame as "research suggests" not "you should"
- Not exhaustive — 3-5 findings, not a comprehensive survey
