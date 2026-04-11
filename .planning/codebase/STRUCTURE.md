# Codebase Structure

**Analysis Date:** 2026-04-11

## Directory Layout

```
/Users/vincentelbotte/Documents/01-PROJECTS/16_GITAGENT/
├── src/                       # Source TypeScript code (8,292 LOC)
│   ├── index.ts              # CLI entry point (Commander program)
│   ├── adapters/             # Framework export adapters (11 + shared)
│   ├── runners/              # Framework execution engines (10 runners)
│   ├── commands/             # CLI command handlers (11 commands)
│   └── utils/                # Core utilities (loaders, validators, formatters)
├── dist/                     # Compiled JavaScript (build output)
├── spec/                     # JSON Schema specifications for validation
│   ├── SPECIFICATION.md      # Main spec document
│   └── schemas/              # JSON Schema files (agent-yaml, skill, tool, etc.)
├── examples/                 # Example agent configurations (8 examples)
├── patterns/                 # Architecture pattern illustrations (PNG diagrams)
├── architect-agent/          # Self-hosting agent for this codebase
├── phoenix-coach/            # Special-purpose coach agent
├── registry/                 # Agent registry/marketplace components
├── docs/                     # Documentation
├── .planning/                # GSD planning artifacts
├── package.json              # Node.js manifest (dependencies, scripts)
├── tsconfig.json             # TypeScript compiler config
├── README.md                 # Project documentation
├── LICENSE                   # MIT license
├── CONTRIBUTING.md           # Contribution guide
├── CODE_OF_CONDUCT.md        # Community code of conduct
└── .gitignore               # Git ignore rules
```

## Directory Purposes

**src/ (Source Code):**
- Purpose: All TypeScript source code for gitagent CLI framework
- Contains: Commands, adapters, runners, utilities, type definitions
- Key files: `index.ts` (entry), command handlers, adapter/runner implementations

**src/adapters/ (Framework Adapters):**
- Purpose: Transform agent definitions to framework-specific formats
- Contains: 11 adapters (claude-code, openai, crewai, openclaw, nanobot, lyzr, copilot, cursor, gemini, codex, github) + system-prompt generator + shared utilities
- Key files: `system-prompt.ts` (core narrative builder), `*.ts` (framework-specific exporters)

**src/runners/ (Execution Engines):**
- Purpose: Execute agents in target frameworks
- Contains: 10 runners for different frameworks + 1 git runner + 1 opencode runner
- Key files: `claude.ts` (Claude Code spawn), `openai.ts`, `crewai.ts`, etc.

**src/commands/ (CLI Commands):**
- Purpose: CLI command implementations
- Contains: init, validate, run, export, import, audit, skills, info, install, lyzr, registry
- Key files: Each `*.ts` file is one command; `init.ts` is largest (scaffolding templates)

**src/utils/ (Utilities):**
- Purpose: Reusable logic shared across commands, adapters, runners
- Contains: 8 modules
  - `loader.ts`: Load + parse `agent.yaml` manifests, interfaces for AgentManifest, ComplianceConfig
  - `skill-loader.ts`: Load + parse `SKILL.md` files with frontmatter extraction
  - `schemas.ts`: Load JSON schema files from spec/schemas/
  - `validator.ts`: Schema validation logic (AJV-based)
  - `format.ts`: Console output formatting (success, error, warn, info, heading)
  - `git-cache.ts`: Clone + cache git repos, resolve branches
  - `auth-provision.ts`: Load API keys from environment
  - `skill-discovery.ts`: Discover available skills in directory
  - `registry-provider.ts`: Query agent marketplace/registry

**dist/ (Build Output):**
- Purpose: Compiled JavaScript ready for npm distribution
- Contains: Transpiled `.js` files + `.d.ts` type definitions
- Generated: By `npm run build` (tsc compiler)
- Committed: No (in .gitignore)

**spec/ (Specifications):**
- Purpose: Formal JSON Schema specifications for all configuration types
- Contains: 10 JSON schema files
  - `agent-yaml.schema.json`: Validates `agent.yaml` manifests
  - `skill.schema.json`: Validates SKILL.md frontmatter
  - `tool.schema.json`: Validates tool definitions
  - `knowledge.schema.json`: Validates knowledge index
  - `memory.schema.json`: Validates memory configuration
  - `hook.schema.json`: Validates hook definitions
  - `config.schema.json`: Validates runtime config
  - `marketplace.schema.json`: Validates marketplace metadata
  - Others: compliance, regulatory frameworks
- Key files: `SPECIFICATION.md` (narrative spec), all `.schema.json`

**examples/ (Example Configurations):**
- Purpose: Reference agent configurations demonstrating gitagent patterns
- Contains: 8 example agents (minimal, standard, full, compliance-heavy, etc.)
- Usage: Templates for users, reference implementations, E2E test fixtures

**patterns/ (Architecture Patterns):**
- Purpose: Visual documentation of architectural patterns
- Contains: PNG diagrams showing human-in-the-loop, SOD, memory, versioning, forking, CI/CD, audit trails, monorepo, etc.
- Usage: README.md references these to explain design

**architect-agent/ (Self-Hosting Agent):**
- Purpose: Agent that understands and can reason about gitagent codebase
- Contains: agent.yaml, SOUL.md, skills/, tools/, knowledge/ for this repository
- Usage: Demonstrates gitagent's self-referential capabilities

**phoenix-coach/ (Specialized Agent):**
- Purpose: Coach/mentor agent for learning and development
- Contains: Agent definition for coaching interactions
- Usage: Example of domain-specific agent

**registry/ (Marketplace):**
- Purpose: Agent registry/discovery service
- Contains: Registry schema, marketplace utilities
- Usage: Discovering + installing published agents

**docs/ (Documentation):**
- Purpose: Extended documentation beyond README
- Contains: Guides, architecture diagrams, API reference
- Usage: Detailed user documentation

**.planning/ (GSD Planning):**
- Purpose: GSD orchestrator output artifacts
- Contains: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, CONCERNS.md, STACK.md, INTEGRATIONS.md (this file set)
- Usage: Planning phases, context for Claude agents

## Key File Locations

**Entry Points:**
- `src/index.ts`: CLI entrypoint, creates Commander program with all commands
- `dist/index.js`: Compiled entry point (from src/index.ts), referenced in package.json `bin` field

**Configuration:**
- `package.json`: Declares `bin: { gitagent: "./dist/index.js" }`, dependencies, scripts
- `tsconfig.json`: TypeScript compiler options (target: ES2022, module: Node16)
- `spec/schemas/*.json`: JSON Schema definitions for validation

**Core Logic:**
- `src/utils/loader.ts`: AgentManifest interface + YAML parsing
- `src/utils/skill-loader.ts`: SKILL.md parsing + frontmatter extraction
- `src/adapters/system-prompt.ts`: Core narrative builder (composes SOUL.md + RULES.md + skills + knowledge into system prompt)
- `src/commands/validate.ts`: Full validation logic (manifest schema + referential integrity + compliance checks)

**Testing:**
- `src/adapters/cursor.test.ts`: Cursor adapter tests
- `src/adapters/codex.test.ts`: Codex adapter tests
- Run via: `npm run test` (Node.js test runner on `dist/**/*.test.js`)

**Type Definitions:**
- Interfaces defined in-file (not separate .d.ts):
  - `AgentManifest` in `src/utils/loader.ts`
  - `ComplianceConfig` in `src/utils/loader.ts`
  - `ParsedSkill` in `src/utils/skill-loader.ts`
  - `SkillFrontmatter` in `src/utils/skill-loader.ts`

## Naming Conventions

**Files:**
- Commands: kebab-case (`init.ts`, `validate.ts`, `run.ts`)
- Adapters: framework-name.ts (`claude-code.ts`, `openai.ts`, `crewai.ts`)
- Utilities: functionality-name.ts (`skill-loader.ts`, `git-cache.ts`, `auth-provision.ts`)
- Tests: `*.test.ts` suffix (e.g., `cursor.test.ts`)
- Schemas: hyphenated names (`agent-yaml.schema.json`, `hook-io.schema.json`)

**Directories:**
- Lowercase, plural: `adapters/`, `runners/`, `commands/`, `utils/`, `schemas/`
- Feature directories: lowercase: `skills/`, `tools/`, `knowledge/`, `hooks/`, `compliance/`, `workflows/`, `memory/`, `agents/`, `examples/`

**Functions/Interfaces:**
- Camel case: `loadAgentManifest()`, `loadAllSkills()`, `exportToOpenAI()`, `runWithClaude()`
- Interfaces: PascalCase: `AgentManifest`, `ComplianceConfig`, `ParsedSkill`, `SkillFrontmatter`, `RunOptions`
- Type unions: `string | null`, `boolean | undefined`

**Command modules:**
- Each exports a single Command object named `{action}Command`: `initCommand`, `validateCommand`, `runCommand`, `exportCommand`
- Options interfaces named `{Action}Options`: `InitOptions`, `ValidateOptions`, `RunOptions`

## Where to Add New Code

**New CLI Command:**
1. Create `src/commands/{command-name}.ts`
2. Define `{name}Options` interface with all option definitions
3. Create exported `{name}Command = new Command('{name}')` with `.option()` and `.action()` calls
4. Import command in `src/index.ts` with `import { {name}Command } from './commands/{name}.js'`
5. Add to program with `program.addCommand({name}Command)`
6. Test via `npm run build && npm start {name} --help`

**New Framework Adapter:**
1. Create `src/adapters/{framework-name}.ts`
2. Implement `export{FrameworkName}()` function that:
   - Takes agentDir as parameter
   - Calls `loadAgentManifest()` and other loaders
   - Calls `exportToSystemPrompt()` for narrative
   - Transforms into framework-specific format
   - Returns framework-native object or JSON string
3. Export function from `src/adapters/index.ts`
4. Create corresponding runner: `src/runners/{framework-name}.ts` that spawns the framework with config
5. Import runner in `src/commands/run.ts` and add case to switch statement

**New Framework Runner:**
1. Create `src/runners/{framework-name}.ts`
2. Implement `runWith{FrameworkName}()` function that:
   - Takes agentDir, manifest, options
   - Uses adapter to transform manifest → framework format
   - Calls `spawnSync()` or equivalent to execute framework
   - Handles temp file cleanup
3. Handle tool allowlists, model constraints, permission modes from manifest
4. Export from runners module

**New Utility Function:**
1. Add to appropriate file in `src/utils/` or create new file if distinct concern
2. Keep utilities pure and side-effect free where possible
3. Use consistent error handling (throw descriptive Error, let caller handle)
4. Export from utils barrel if applicable

**New Schema:**
1. Create `spec/schemas/{schema-name}.schema.json`
2. Follow JSON Schema draft 2020-12 conventions
3. Add corresponding interface in `src/utils/loader.ts` if it's a top-level agent config type
4. Load schema in `src/utils/schemas.ts` via `loadSchema(name)`
5. Validate in appropriate command via `validateSchema(data, 'schema-name')`

**New Validation Rule:**
1. Add logic to appropriate validation function in `src/commands/validate.ts`
2. Append errors/warnings to `ValidationResult` object
3. For cross-file validation (e.g., skill existence), check both file existence AND content validity
4. Use consistent error message format: `"context: specific problem"`

## Special Directories

**node_modules/:**
- Purpose: Npm dependencies
- Generated: By `npm install`
- Committed: Yes (unusual; typically gitignored, but this repo commits dependencies for context-mode stability)
- Key packages: ajv, chalk, commander, inquirer, js-yaml, @types/*

**.planning/codebase/:**
- Purpose: GSD codebase documentation
- Generated: By GSD mapper tools
- Committed: Yes
- Contents: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, CONCERNS.md, STACK.md, INTEGRATIONS.md

**dist/:**
- Purpose: Compiled JavaScript from TypeScript
- Generated: By `npm run build` (tsc)
- Committed: No (.gitignore)
- Build output includes `.js` files and `.d.ts` type declaration files

**.gitagent/ (in agent directories):**
- Purpose: Runtime state directory (git-ignored)
- Generated: At runtime by gitagent when executing agents
- Committed: No (added to .gitignore by init command)
- Contents: Temporary files, caches, logs

---

*Structure analysis: 2026-04-11*
