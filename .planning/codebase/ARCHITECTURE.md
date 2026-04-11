# Architecture

**Analysis Date:** 2026-04-11

## Pattern Overview

**Overall:** Adapter-Based CLI Framework with Framework-Agnostic Agent Definition Standard

**Key Characteristics:**
- **CLI-driven**: Commander.js-based command dispatcher that coordinates multiple subsystems
- **Adapter pattern**: Pluggable adapters transform a common agent definition into framework-specific formats
- **Schema-driven validation**: JSON Schema validation at the core validates all configuration against specifications
- **Layered composition**: Agents can extend, contain sub-agents, skills, and tools in a recursive, hierarchical structure
- **Git-native**: All agent definitions are files in version control; git becomes the agent repository

## Layers

**Presentation Layer (Commands):**
- Purpose: Expose CLI commands to users
- Location: `src/commands/`
- Contains: 11 command modules (init, validate, run, export, import, audit, skills, info, install, lyzr, registry)
- Depends on: Utils layer (loader, validators, formatters), Adapters layer, Runners layer
- Used by: Terminal/CLI users via `gitagent` command

**Adapter Layer (Framework Integration):**
- Purpose: Translate agent definitions from gitagent spec → framework-specific formats
- Location: `src/adapters/`
- Contains: System prompt generator + 11 framework adapters (claude-code, openai, crewai, openclaw, nanobot, lyzr, copilot, cursor, gemini, codex, github)
- Depends on: Utils layer (loader, skill-loader)
- Used by: Run command, Export command, various runners

**Runner Layer (Execution):**
- Purpose: Execute agents in their target environment
- Location: `src/runners/`
- Contains: 10 runners (claude, openai, crewai, openclaw, nanobot, lyzr, github, git, opencode, gemini)
- Depends on: Adapter layer (system-prompt exporter), Utils layer (loaders)
- Used by: Run command to spawn agent processes

**Utils Layer (Core Logic):**
- Purpose: Provide reusable logic for loading, validating, transforming agent definitions
- Location: `src/utils/`
- Contains: 8 utility modules covering loaders, validators, skill discovery, auth provisioning, git caching, formatting
- Depends on: External packages only (ajv, js-yaml, commander, chalk, inquirer)
- Used by: Commands, Adapters, Runners

**Schema Layer (Specifications):**
- Purpose: Define JSON Schemas that validate all agent configuration
- Location: `spec/schemas/`
- Contains: 10 JSON schema files (agent-yaml, skill, tool, knowledge, memory, hook, config, marketplace, compliance, etc.)
- Depends on: JSON Schema standard
- Used by: Utils validators (via ajv), documentation

## Data Flow

**Agent Discovery and Validation:**

1. User invokes `gitagent validate --dir <path>` or `gitagent run --dir <path>`
2. `validateCommand` or `runCommand` in `src/commands/` receives request
3. `agentDirExists()` checks for `agent.yaml` in directory
4. `loadAgentManifest()` from `src/utils/loader.ts` reads and parses YAML manifest
5. `validateSchema()` validates manifest against `agent-yaml.schema.json` using AJV
6. For each referenced skill in `manifest.skills`, `src/utils/skill-loader.ts` loads SKILL.md files
7. Returns `ParsedSkill` with frontmatter + instructions
8. Cross-reference checks ensure all skills, tools, agents mentioned in manifest exist on disk

**Agent Execution Flow:**

1. User invokes `gitagent run --repo <url> --adapter claude`
2. `runCommand` resolves repo via `resolveRepo()` (clone or use cache)
3. `loadAgentManifest()` loads agent manifest
4. Based on adapter choice, route to appropriate runner (`runWithClaude()`, `runWithOpenAI()`, etc.)
5. Runner calls `exportToSystemPrompt()` from `src/adapters/system-prompt.ts`
6. System prompt generator composes all narrative parts:
   - Agent identity (`agent.yaml` name/version/description)
   - Soul (`SOUL.md`)
   - Rules (`RULES.md`, `DUTIES.md`)
   - Skills (all `SKILL.md` files, frontmatter + instructions)
   - Knowledge (documents marked `always_load` in `knowledge/index.yaml`)
   - Compliance constraints (formatted from `compliance` section of manifest)
7. Framework adapter transforms system prompt → framework-specific format (e.g., Claude Code settings JSON)
8. Runner spawns process in target environment with system prompt pre-loaded

**Agent Export Flow:**

1. User invokes `gitagent export --dir <path> --format <framework> --output <file>`
2. `exportCommand` loads manifest and validates
3. Routes to adapter function (e.g., `exportToOpenAI()`, `exportToCrewAI()`)
4. Adapter generates framework-specific configuration object or JSON string
5. Writes to output file

**Import/Scaffolding Flow:**

1. User invokes `gitagent init --template <standard|full|minimal>`
2. `initCommand` creates directory structure with template files
3. Creates `agent.yaml` manifest
4. Creates narrative files (`SOUL.md`, `RULES.md`, `AGENTS.md`)
5. For full template: adds `compliance/`, `hooks/`, `memory/`, `workflows/` directories
6. All files follow spec to be immediately valid

**State Management:**

- **Manifest**: Loaded once per command execution from `agent.yaml`, passed through layers via function parameters
- **Skills**: Loaded on-demand via `loadAllSkills()`, cached in memory during single execution
- **Git state**: Cached via `resolveRepo()` to avoid re-cloning same repo in same session
- **Runtime state**: `.gitagent/` directory (git-ignored) stores temporary state, caches

## Key Abstractions

**Agent Manifest (AgentManifest interface):**
- Purpose: Canonical representation of agent configuration
- Examples: `src/utils/loader.ts` lines 5-67
- Pattern: TypeScript interface describing all top-level fields (name, version, description, model, skills, tools, delegation, compliance, etc.); loader.ts ensures consistency

**Skill Definition (ParsedSkill interface):**
- Purpose: Standardized skill format with YAML frontmatter + markdown instructions
- Examples: `src/utils/skill-loader.ts` lines 18-26
- Pattern: SKILL.md files with `---frontmatter---\n\n# Instructions` structure; frontmatter follows agentskills.io spec exactly

**Compliance Config (ComplianceConfig interface):**
- Purpose: Nested YAML structure encoding regulatory requirements (FINRA, Fed, SEC)
- Examples: `src/utils/loader.ts` lines 69-150 (ComplianceConfig interface)
- Pattern: Hierarchical configuration for supervision, recordkeeping, model risk, data governance, segregation of duties, vendor management, communications

**Framework Adapter (adapter function pattern):**
- Purpose: Transform agent definition → framework format
- Examples: `exportToSystemPrompt()`, `exportToOpenAI()`, `exportToCrewAI()`, etc. in `src/adapters/`
- Pattern: Pure functions that read agent directory, construct framework-specific JSON/object, return serializable output

**Schema Validation (ajv + JSON Schema):**
- Purpose: Validate all YAML input against specs before processing
- Examples: `validateSchema()` in `src/commands/validate.ts` lines 24-38
- Pattern: AJV with allErrors=true captures all violations; called before any deep processing

## Entry Points

**CLI Entry:**
- Location: `src/index.ts`
- Triggers: Node.js execution via `gitagent` binary (defined in package.json `bin`)
- Responsibilities: Import all command modules, create Commander program, add commands, parse argv

**Commands (11 entry points):**
- **init**: `src/commands/init.ts` — Scaffold new agent repository with templates
- **validate**: `src/commands/validate.ts` — Validate manifest + check referential integrity
- **run**: `src/commands/run.ts` — Load + execute agent with selected adapter
- **export**: `src/commands/export.ts` — Export agent definition to framework format (file)
- **import**: `src/commands/import.ts` — Import framework-native config into gitagent format
- **audit**: `src/commands/audit.ts` — Check compliance requirements, security, segregation of duties
- **skills**: `src/commands/skills.ts` — List, discover, manage skills
- **info**: `src/commands/info.ts` — Display agent metadata
- **install**: `src/commands/install.ts` — Install agent into local cache or publish
- **lyzr**: `src/commands/lyzr.ts` — Integration with Lyzr framework
- **registry**: `src/commands/registry.ts` — Query/manage agent registry

## Error Handling

**Strategy:** Exit-code-based with formatted console output

**Patterns:**
- Schema validation errors: Collected with path + message, displayed as bulleted list, exit code 1
- File not found errors: Descriptive message with expected path, exit code 1
- Referential integrity errors: "Referenced skill 'X' not found at skills/X/" style messages
- Warnings (non-blocking): Displayed in yellow but execution continues
- Success messages: Green checkmarks with action taken
- Errors: Red X with description

**Implementation**: `src/utils/format.ts` provides `success()`, `error()`, `warn()`, `info()`, `heading()`, `divider()` wrappers around chalk.js for consistent formatting

## Cross-Cutting Concerns

**Logging:** Uses chalk.js for colored terminal output only; no file-based logging in core CLI (compliance logging is application-defined via hooks)

**Validation:** AJV-based schema validation at manifest load time, cross-reference checks (skill/tool/agent existence), progressive disclosure pattern (metadata-only vs full load)

**Authentication:** `src/utils/auth-provision.ts` handles API key loading from environment variables and `.env` files; no secrets committed to repo

**Git Caching:** `src/utils/git-cache.ts` avoids re-cloning same repo in one session; temp directories cleaned on exit unless `--cache` flag used

**Skill Discovery:** Progressive disclosure via `loadSkillMetadata()` for lightweight listing vs `loadSkillFull()` for active use (reduces context window impact)

---

*Architecture analysis: 2026-04-11*
