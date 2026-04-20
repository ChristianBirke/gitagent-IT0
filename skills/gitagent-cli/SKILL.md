---
name: gitagent-cli
description: Use when creating, validating, exporting, running, or managing AI agent definitions with the gitagent CLI. Covers all 11 commands, agent.yaml structure, export formats, and common pitfalls.
---

# gitagent CLI

## Overview

gitagent turns git repos into portable AI agent definitions. One repo = one agent. The CLI validates, exports to 15 frameworks, and runs agents directly.

## Quick Reference

| Command | Purpose | Key Flags |
|---------|---------|-----------|
| `init` | Scaffold new agent | `-t minimal\|standard\|full\|llm-wiki` `-d <dir>` |
| `validate` | Check against spec | `-d <dir>` `-c` (compliance) |
| `info` | Display agent summary | `-d <dir>` |
| `export` | Convert to framework format | `-f <format>` `-d <dir>` `-o <file>` |
| `import` | Convert FROM other format | `--from <format>` `<path>` |
| `run` | Execute agent via adapter | `-r <url>` `-a <adapter>` `-p <prompt>` `-d <dir>` |
| `install` | Resolve dependencies/extends | `-d <dir>` `-f` (force) |
| `audit` | Compliance audit report | `-d <dir>` |
| `skills` | Search/install/list skills | `search\|install\|list\|info` |
| `registry` | Submit to registry | `-r <repo-url>` `-c <category>` |
| `lyzr` | Manage Lyzr Studio agents | `create\|update\|info\|run` |

## Agent Definition Structure

**Required files:** `agent.yaml` + `SOUL.md` (minimum viable agent)

**Optional files:**
```
agent.yaml          # Manifest (strict schema)
SOUL.md             # Identity/personality
RULES.md            # Behavioral constraints
DUTIES.md           # Responsibilities
AGENTS.md           # Sub-agent coordination
skills/             # Each skill has SKILL.md with frontmatter
tools/              # Tool definitions (YAML)
knowledge/          # Reference docs (index.yaml lists them)
memory/             # Persistent state templates
workflows/          # Multi-step processes
hooks/              # Lifecycle hooks (hooks.yaml)
config/             # Runtime configuration
compliance/         # Regulatory frameworks
agents/             # Sub-agent definitions
examples/           # Usage examples
```

## Minimal agent.yaml

```yaml
spec_version: "0.1.0"
name: my-agent
version: 0.1.0
description: What this agent does
```

## Export Formats

| Format | Target | Output |
|--------|--------|--------|
| `system-prompt` | Any LLM | Single markdown prompt (stdout) |
| `claude-code` | Claude Code | CLAUDE.md + .claude/ files |
| `openai` | OpenAI Agents | JSON agent config |
| `crewai` | CrewAI | Python crew definition |
| `gemini` | Gemini CLI | GEMINI.md |
| `codex` | OpenAI Codex | AGENTS.md |
| `cursor` | Cursor IDE | .cursor/rules/ |
| `copilot` | GitHub Copilot | .github/copilot-instructions.md |
| `opencode` | OpenCode | opencode.md |
| `openclaw` | OpenClaw | YAML format |
| `nanobot` | Nanobot | YAML format |
| `lyzr` | Lyzr Studio | Lyzr config |
| `github` | GitHub Actions | Workflow YAML |
| `kiro` | Kiro | Kiro format |
| `gitclaw` | GitClaw | GitClaw format |

## Common Workflows

### Create and validate a new agent
```bash
gitagent init -t standard -d ./my-agent
cd ./my-agent
# Edit agent.yaml and SOUL.md
gitagent validate
```

### Export for Claude Code
```bash
gitagent export -f claude-code -d ./my-agent -o ./output
```

### Run agent from git repo
```bash
gitagent run -r https://github.com/user/agent-repo -a claude -p "Hello"
```

### Run agent from local directory
```bash
gitagent run -d ./my-agent -a claude -p "Help me review code"
```

### Import existing Claude Code config as gitagent
```bash
gitagent import --from claude ./path/to/project -d ./converted-agent
```

### Install dependencies (extends/dependencies in agent.yaml)
```bash
gitagent install -d ./my-agent
```

## Adapters for `run` Command

`-a` flag options: `claude`, `openai`, `crewai`, `openclaw`, `nanobot`, `lyzr`, `github`, `opencode`, `gemini`, `gitclaw`, `git`, `prompt`

- `prompt` — just outputs the system prompt, doesn't spawn a process
- `git` — generic git-based runner
- All others spawn the target framework's CLI/process

## Caching Behavior

`run -r <url>` clones repos to `~/.gitagent/cache/` (SHA-256 keyed by URL+branch).
- `--refresh` — force re-clone (pull latest)
- `--no-cache` — clone to temp dir, delete on exit

## Common Pitfalls

- **init requires existing directory**: `gitagent init -d ./new-dir` fails if `new-dir` doesn't exist. Create it first with `mkdir -p` (fixed in dev, not yet in published v0.1.8).
- **Build before test**: Tests run against `dist/`, not `src/`. Always `npm run build` first.
- **ESM imports**: All imports use `.js` extension (TypeScript Node16 convention).
- **export -f is required**: No default format — you must specify one.
- **registry requires gh CLI**: The `registry` command creates a GitHub PR using `gh`, which must be authenticated.
- **validate is strict**: Uses AJV with full JSON Schema validation. Unknown properties in agent.yaml will fail.

## Skills Management

```bash
gitagent skills search "code review"    # Search registry
gitagent skills install skill-name      # Install from registry
gitagent skills list -d ./my-agent      # List agent's skills
gitagent skills info skill-name         # Show skill details
```

Each skill lives in `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description` required).
