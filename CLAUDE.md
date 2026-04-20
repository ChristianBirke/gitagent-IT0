# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

gitagent is a framework-agnostic, git-native standard for defining AI agents. A git repository becomes a portable agent definition — clone a repo, get an agent. The CLI validates, exports, imports, and runs agents across 14 adapters (claude-code, openai, crewai, openclaw, nanobot, lyzr, github, copilot, opencode, cursor, gemini, codex, system-prompt, plus a generic `git` runner).

Published as `@open-gitagent/gitagent` on npm (v0.1.8). Spec version: v0.1.0.

## Build & Development

```bash
npm run build        # tsc + chmod +x dist/index.js
npm run dev          # tsc --watch
npm start            # node dist/index.js
npm test             # node --test dist/**/*.test.js
```

Build before testing — tests run against `dist/`, not `src/`. Tests use Node.js built-in test runner (`node:test` + `node:assert/strict`).

To run a single test: `node --test dist/adapters/codex.test.js`

Test coverage is minimal — only `codex.test.ts` and `cursor.test.ts` exist. Most adapters/commands have no tests.

## Architecture

**Layered CLI with adapter pattern.** All source in `src/`, compiled to `dist/` as ESM (ES2022 target, Node16 module resolution).

### Data Flow

```
agent.yaml + SOUL.md + skills/ + knowledge/
  → loadAgentManifest() (src/utils/loader.ts)
  → AgentManifest interface
  → exportToSystemPrompt() (src/adapters/system-prompt.ts)
  → framework-specific adapter
  → output (files, stdout, or spawned process)
```

### Key Layers

- **Commands** (`src/commands/`) — 11 CLI commands registered via Commander in `src/index.ts`. Each file exports a `Command` object.
- **Adapters** (`src/adapters/`) — Transform `AgentManifest` → framework-specific format. Each adapter has `exportTo<Name>()` and optionally `exportTo<Name>String()`. Most re-exported from `src/adapters/index.ts`, but `lyzr.ts` and `github.ts` are imported directly where needed. `system-prompt.ts` is the core — composes SOUL.md + RULES.md + DUTIES.md + skills + knowledge + compliance into a single prompt. Other adapters build on this.
- **Runners** (`src/runners/`) — Execute agents by calling the adapter, then spawning the target framework's process.
- **Utils** (`src/utils/`) — `loader.ts` defines `AgentManifest` interface and parses `agent.yaml`. `skill-loader.ts` parses SKILL.md frontmatter. `schemas.ts` loads JSON schemas for AJV validation. `git-cache.ts` handles repo cloning/caching.

### Shared Compliance Logic

`src/adapters/shared.ts` has `buildComplianceSection()` — extracts compliance constraints from manifest into markdown. Used by adapters that emit markdown (claude-code, gemini, codex, copilot). The same logic is duplicated in `system-prompt.ts` — consolidation opportunity.

### Validation

`src/commands/validate.ts` (largest command, ~600 LOC) does:
1. Schema validation via AJV against `spec/schemas/agent-yaml.schema.json`
2. Cross-reference checks (skills/tools/agents directories exist and match manifest)
3. SKILL.md frontmatter validation against `spec/schemas/skill.schema.json`
4. Compliance-specific checks when `--compliance` flag used

### Agent Definition Structure

Only `agent.yaml` + `SOUL.md` are required. The manifest (`agent.yaml`) is the only file with a strict JSON schema. Everything else is optional: RULES.md, DUTIES.md, AGENTS.md, skills/, tools/, knowledge/, memory/, workflows/, hooks/, config/, compliance/, agents/ (sub-agents), examples/.

## Key Conventions

- ESM throughout — all imports use `.js` extension (TypeScript convention for Node16 module resolution)
- Adapters follow naming pattern: `exportTo<FrameworkName>(dir: string)` writes files, `exportTo<FrameworkName>String(dir: string)` returns string
- Tests colocated with source: `src/adapters/codex.test.ts` alongside `src/adapters/codex.ts`
- Error handling uses bare try/catch in many places — errors are often swallowed silently
- No linter configured
- The `architect-agent/`, `phoenix-coach/`, and `examples/` directories are example agents built with gitagent, not part of the CLI source

## Gotchas

- **AJV ESM import workaround:** AJV and ajv-formats don't export cleanly under Node16 ESM. The codebase uses `import _Ajv from 'ajv'` then `const Ajv = _Ajv as unknown as typeof _Ajv.default` — follow this pattern when adding AJV usage.
- **Version string in `src/index.ts`** is hardcoded to `0.1.0` and doesn't match `package.json` (`0.1.8`).
- **Git cache:** Cloned agent repos are cached at `~/.gitagent/cache/` (keyed by SHA-256 of URL+branch). The `--refresh` and `--no-cache` flags on `run` control this.
- **Registry:** `registry` command creates a PR against `open-gitagent/registry` on GitHub — requires `gh` CLI authenticated.

## Schemas

10 JSON Schema files in `spec/schemas/` validate agent definitions. The primary schema is `agent-yaml.schema.json`. Others cover skills, tools, knowledge, memory, hooks, config, compliance, workflows, and marketplace entries.

---

## Handoff: Session 1 — 2026-04-20

### TL;DR

**Project**: gitagent — git-native AI agent definition standard with CLI for validation, export, and execution across 14 frameworks.

**Status**: CLAUDE.md created, codebase documented, git worktree structure initialized for dev workflow.

**Immediate Next Step**: Begin development work in the `DEV-IT-0` or `DEV-IT-1` worktree.

### Accomplishments

1. **Created CLAUDE.md** — Analyzed the full codebase (commands, adapters, runners, utils, schemas) and wrote project-level documentation covering build commands, architecture, data flow, conventions, and gotchas (AJV ESM workaround, stale version string, git cache location, registry `gh` dependency).

2. **Committed and pushed all pending work** — 85 files (codebase mapping docs, example agent docs, gitagent-helper agent, service blueprint HTMLs, planning config) committed as `6358b9a` and pushed to `origin/main` (35 total commits).

3. **Set up git worktree structure** for development:

| Worktree | Path | Branch | Based on |
|----------|------|--------|----------|
| Main | `16_GITAGENT/` | `main` | — |
| DEV-IT-0 | `16_GITAGENT-DEV-IT-0/` | `DEV-IT-0` | `DEV` |
| DEV-IT-1 | `16_GITAGENT-DEV-IT-1/` | `DEV-IT-1` | `DEV-IT-0` |

### Branch Structure

```
main (6358b9a) — pushed to origin
└── DEV (same commit, no worktree)
    └── DEV-IT-0 (worktree at ../16_GITAGENT-DEV-IT-0/)
        └── DEV-IT-1 (worktree at ../16_GITAGENT-DEV-IT-1/)
```

`DEV` exists as a branch but has no worktree — it serves as the base for the iteration branches.

### Technical Decisions

| Decision | Rationale |
|----------|-----------|
| Worktrees placed as sibling dirs (`16_GITAGENT-DEV-IT-*`) | Keeps project root clean, consistent with existing `01-PROJECTS/` layout |
| `DEV` branch without worktree | Acts as stable integration branch; worktrees are for active iteration |
| CLAUDE.md includes "Gotchas" section | Documents non-obvious pitfalls (AJV ESM, stale version, registry gh dep) that waste time if discovered ad-hoc |

### How to Continue

```bash
# Switch to a dev worktree
cd /Users/vincentelbotte/Documents/01-PROJECTS/16_GITAGENT-DEV-IT-0

# Build and test
npm run build && npm test

# List worktrees from any worktree
git worktree list

# Merge iteration work back
git checkout DEV && git merge DEV-IT-0
```

### Known Issues

- [ ] `src/index.ts` version hardcoded to `0.1.0` (should match `package.json` `0.1.8`)
- [ ] `lyzr.ts` and `github.ts` not re-exported from `src/adapters/index.ts` (inconsistent with other adapters)
- [ ] Compliance logic duplicated between `shared.ts` and `system-prompt.ts`
- [ ] Test coverage minimal (2 test files out of ~15 adapters)

### Session Metadata

- **Date**: 2026-04-20
- **Working Directory**: `/Users/vincentelbotte/Documents/01-PROJECTS/16_GITAGENT`
- **Agent Model**: Claude Opus 4.6 (1M context)
- **Key Files Modified**: `CLAUDE.md`, `.gitignore`, `architect-agent/memory/memory.md` + 82 new files
