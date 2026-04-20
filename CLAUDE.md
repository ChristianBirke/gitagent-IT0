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
