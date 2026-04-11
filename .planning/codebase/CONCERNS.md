# Codebase Concerns

**Analysis Date:** 2026-04-11

## Tech Debt

**Bare catch blocks silently swallowing errors:**
- Issue: Multiple catch handlers ignore errors without logging, making debugging difficult
- Files:
  - `src/utils/git-cache.ts:58` — `rmSync()` cleanup errors ignored
  - `src/runners/openclaw.ts:91,128` — Workspace cleanup silently fails
  - `src/runners/openai.ts:41` — Temp file deletion ignored
  - `src/runners/gemini.ts:115` — Workspace cleanup ignored
  - `src/runners/crewai.ts:34` — Temp file cleanup silently fails
  - `src/runners/claude.ts:106` — File cleanup errors ignored
  - `src/runners/nanobot.ts:67` — Config cleanup silently fails
  - `src/commands/import.ts:278,355,423` — Malformed config silently skipped
  - `src/adapters/gemini.ts:375` — Hook config failures ignored
  - `src/adapters/openclaw.ts:313,339` — Tool/sub-agent parsing failures silently skipped
  - `src/adapters/gemini.ts:280` — Malformed tools silently skipped
  - `src/adapters/opencode.ts:124` — Tool parsing failures ignored
  - `src/adapters/copilot.ts:182` — Tool definitions silently skipped
  - `src/adapters/codex.ts:129` — Malformed tools ignored
  - `src/adapters/nanobot.ts:149` — Generic silent skip
- Impact: Lost diagnostic information, harder to debug production issues, potential data loss if cleanup fails
- Fix approach: Add error logging to all catch blocks. At minimum, use `process.env.DEBUG` to enable verbose output. Consider categorizing errors (fatal vs. recoverable).

**Untyped error handling:**
- Issue: Error assertions and casts lack proper typing
- Files:
  - `src/commands/validate.ts:33` — `e: any` without validation
  - `src/adapters/gemini.ts:292` — `Record<string, any>` return type
  - `src/commands/skills.ts:20` — `as unknown as Record<string, unknown>` workaround for module resolution
  - `src/commands/validate.ts:6-7` — Type coercion for Ajv (esm/cjs mismatch)
- Impact: Runtime type errors possible, IDE can't warn about incorrect property access
- Fix approach: Create proper type definitions for ESM/CJS interop. Use typed error handling utilities.

**ESM/CJS interop workarounds:**
- Issue: Using `as unknown as typeof` casts to work around module format mismatches
- Files:
  - `src/commands/validate.ts:6-7` — Ajv import workaround
  - `src/commands/skills.ts:20` — Registry type cast
- Impact: Fragile, bypasses type checking, difficult to upgrade dependencies
- Fix approach: Create an adapter module `src/utils/esm-interop.ts` with proper import wrappers.

## Known Bugs

**Import command section parsing is fragile:**
- Symptoms: Section headers may not split correctly if markdown contains special characters or inconsistent heading levels
- Files: `src/commands/import.ts:498-503` — Simple regex-based section parsing
- Trigger: Importing agent with markdown containing edge-case heading styles (e.g., setext-style underlines, atypical spacing)
- Workaround: Manually split SOUL.md and RULES.md after import if parsing fails
- Fix approach: Use a proper markdown AST parser instead of regex splitting (e.g., `remark` or similar).

**Model constraint handling doesn't validate consistency:**
- Symptoms: Agents may have contradictory or incompatible model constraints
- Files: `src/utils/loader.ts:11-24` — AgentManifest model constraints are loosely typed
- Trigger: Setting `max_tokens: 4096` with `temperature: 0.01` on a model that doesn't support it
- Impact: Exports may generate invalid configurations for target adapters
- Fix approach: Add a validation layer in `validateAgentYaml()` to check model constraints against a known compatibility matrix.

**Temp directory cleanup failures go unnoticed:**
- Symptoms: Temp workspaces accumulate in system tmp, consuming disk space
- Files: All runner files use `rmSync()` with `/* ignore */` catch
- Trigger: If process is killed during runner execution, or if file permissions prevent deletion
- Impact: Disk space leakage over time, potential system slowdown
- Fix approach: Implement a cleanup service that registers temp directories and periodically purges old ones.

## Security Considerations

**Command injection risk in shell script execution:**
- Risk: Tool names derived from YAML aren't escaped when building shell commands
- Files:
  - `src/adapters/gemini.ts:354-356` — Building `bash` command dynamically
  - `src/runners/openclaw.ts:98` — Session ID built from manifest data
- Current mitigation: Using `spawnSync()` with array args avoids shell interpretation in most cases
- Recommendations:
  - Validate tool/script names against whitelist pattern `^[a-z0-9_-]+$`
  - Never pass unsanitized manifest data directly to shell commands
  - Document shell command injection prevention in SECURITY.md

**Potential path traversal in skill loading:**
- Risk: Skill directories could be symlinks pointing outside agent directory
- Files:
  - `src/utils/skill-discovery.ts:67` — Loads `SKILL.md` without path validation
  - `src/utils/skill-loader.ts:41` — Resolves parent directory naively
- Current mitigation: `readdirSync()` with `withFileTypes` limits direct attacks
- Recommendations:
  - Resolve canonical paths and verify they're within agent boundaries
  - Add `realpath()` check in `loadSkillMetadata()` and `loadSkillFull()`

**No validation of YAML external references:**
- Risk: `yaml.load()` could execute arbitrary code if YAML contains unsafe tags
- Files: Every adapter and util that calls `yaml.load()`
- Current mitigation: Node.js `js-yaml` defaults to safe mode (no function tags)
- Recommendations:
  - Explicitly pass `{safe: true}` to all `yaml.load()` calls for defense-in-depth
  - Document YAML parsing safety in architecture docs

## Performance Bottlenecks

**Synchronous file I/O blocks entire process:**
- Problem: All file operations use `readFileSync()`, blocking event loop
- Files:
  - `src/commands/validate.ts` — Validates all skills sequentially
  - `src/utils/skill-discovery.ts:61` — `readdirSync()` on every path
  - `src/utils/skill-loader.ts:75-76` — Reads entire SKILL.md to parse frontmatter
- Cause: Synchronous Node.js APIs prioritized for simplicity in CLI context
- Impact: Large skill repositories (50+ skills) will hang for seconds
- Improvement path:
  - For CLI: acceptable (short-lived processes)
  - If exported as library: migrate to `fs.promises` or `fs/promises` with parallel loading
  - Implement lazy loading for skill metadata (don't load full content until needed)

**All skills loaded into memory during discovery:**
- Problem: `discoverAndLoadSkills()` loads every skill's full content, regardless of whether it's used
- Files: `src/utils/skill-discovery.ts:91-105`
- Cause: No filtering before loading
- Impact: Agents with 100+ skills could consume significant memory
- Improvement path:
  - Split metadata discovery (fast, ~100 tokens per skill) from full loading
  - Use progressive disclosure pattern already started (metadata vs. full)
  - Load only requested skills on demand

**Git clone operations not cached during imports:**
- Problem: Each import operation that references an external agent clones from git
- Files: `src/utils/git-cache.ts` — Cache exists but may not be used in import path
- Cause: Import operations may not leverage `resolveRepo()` caching
- Impact: Same repo cloned multiple times during import if multiple references exist
- Improvement path: Verify import command uses cache. Consider pre-warming cache.

## Fragile Areas

**Complex compliance validation logic:**
- Files: `src/commands/validate.ts:117-360` — 240+ lines of compliance checks
- Why fragile:
  - Deeply nested conditions for FINRA/Federal Reserve/SEC/CFPB frameworks
  - Each framework adds new error/warning branches
  - New compliance requirement requires modifying central validator
  - Multiple places check same compliance field (e.g., `c.supervision`)
- Safe modification:
  - Extract framework validators into separate functions (one per framework)
  - Use a rule engine instead of nested if statements
  - Add framework-specific test fixtures
  - Test coverage: Currently only `cursor.test.ts` and `codex.test.ts` exist; no validate tests

**Adapter export logic scattered across multiple functions:**
- Files: Each adapter (openclaw, gemini, copilot, etc.) repeats similar patterns:
  - Build system prompt from SOUL.md + RULES.md
  - Load skills
  - Build tool definitions
  - Map compliance constraints
  - Generate output
- Why fragile:
  - Copy-paste leads to inconsistencies (e.g., some adapters handle hooks, others don't)
  - Changes to shared logic must be replicated across 12+ adapters
  - Hard to spot when an adapter drifts from spec
- Safe modification:
  - Extract `buildSystemPrompt()` and tool-building logic to shared module
  - Create base adapter class with common patterns
  - Add adapter parity tests

**Import command has multiple code paths:**
- Files: `src/commands/import.ts:1-566` — Handles 6 different import formats
- Why fragile:
  - Each format (Claude, Cursor, Codex, OpenCode, Gemini, OpenClaw) has similar but not identical logic
  - Section parsing logic (`parseSections()`) used inconsistently
  - Model field extraction varies by format
- Safe modification:
  - Create importers directory with one file per format
  - Implement `Importer` interface with `parse()`, `extractModel()`, `extractSections()`
  - Use strategy pattern for format detection

**Test coverage is extremely minimal:**
- Files: Only 2 test files exist:
  - `src/adapters/cursor.test.ts` — 230 lines, tests cursor export/import
  - `src/adapters/codex.test.ts` — 180 lines, tests codex export
- What's not tested:
  - Validate command (all compliance checks untested)
  - Import from 4 other formats (Claude, Codex, OpenCode, Gemini not tested)
  - Any runner functions
  - Skill discovery and loading
  - Git cache functionality
  - Registry operations
  - Error handling paths
- Impact: Regressions can be deployed without detection. Compliance validation especially risky.
- Priority: HIGH — Add test suites for validate, import, and runners

## Scaling Limits

**No pagination or streaming for large skill repositories:**
- Current capacity: Single agent can reference unlimited skills, all loaded into memory
- Limit: 500+ skills would cause noticeable memory usage and discovery slowdown
- Scaling path:
  - Implement skill pagination in registry
  - Stream skill metadata instead of loading all at once
  - Add skill lazy-loading with on-demand full content fetch

**Git cache directory unbounded growth:**
- Current capacity: `~/.gitagent/cache/` accumulates cloned repos with no cleanup
- Limit: After 100+ external agent imports, cache could reach gigabytes
- Scaling path:
  - Implement cache eviction (LRU or TTL)
  - Add `gitagent cache clear` command
  - Document cache location and recommend periodic cleanup

**Compliance validation scales linearly with rule count:**
- Current capacity: Single validator loop handles all frameworks and rules sequentially
- Limit: Adding more compliance frameworks will linearly increase validation time
- Scaling path:
  - Pre-compile framework rules
  - Parallelize framework validation
  - Consider rule compilation/caching

## Dependencies at Risk

**js-yaml without version pinning details:**
- Risk: `js-yaml` is known to have had parsing vulnerabilities in the past
- Impact: Malicious YAML files could exploit vulnerabilities
- Current mitigation: Defaults to safe mode; no custom tag handlers
- Migration plan: Keep version up-to-date, consider `yaml` package as alternative (stricter)

**Commander.js tight integration:**
- Risk: CLI commands tightly couple to Commander.js patterns
- Impact: Difficult to refactor CLI structure or export as library
- Migration plan: Consider wrapper layer abstracting CLI framework

**Ajv ESM/CJS interop:**
- Risk: Type casting workaround is brittle, may break with Ajv upgrades
- Impact: Validation could silently fail if import behavior changes
- Migration plan: Create proper ESM wrapper, add explicit tests for schema validation

## Missing Critical Features

**No dry-run or preview mode for adapters:**
- Problem: Running `gitagent run` actually executes the agent; can't preview config without running
- Blocks: Testing agent configs before deployment, diff viewing
- Impact: Users must run agents to verify they work
- Priority: MEDIUM — Add `--dry-run` flag to all runners

**No agent schema evolution/migration support:**
- Problem: If `agent.yaml` spec changes, old agents aren't automatically updated
- Blocks: Forward compatibility, breaking changes
- Impact: Older agents may become invalid as spec evolves
- Priority: MEDIUM — Add `agent.yaml` schema versioning and migration logic

**No support for agent templates:**
- Problem: `gitagent init` offers limited templates (minimal, standard, full)
- Blocks: Creating agents from custom templates, org-specific structures
- Impact: Teams must manually copy boilerplate
- Priority: LOW — Add template inheritance and custom template support

**No built-in agent composition/inheritance:**
- Problem: Agents can reference sub-agents but can't inherit their properties
- Blocks: Reducing duplication in agent hierarchies
- Impact: Copy-paste of SOUL.md, RULES.md across related agents
- Priority: LOW — Add `extends:` support in agent.yaml

## Test Coverage Gaps

**Untested: Validate command compliance checks:**
- What's not tested: All FINRA, Federal Reserve, SEC, CFPB framework validation
- Files: `src/commands/validate.ts:117-360`
- Risk: Compliance violations could be missed in deployment
- Priority: CRITICAL

**Untested: Import command (4 of 6 formats):**
- What's not tested: Claude, Codex (partially), OpenCode, Gemini, OpenClaw imports
- Files: `src/commands/import.ts`
- Risk: Import failures only discovered by users
- Priority: HIGH

**Untested: All runner functions:**
- What's not tested: `runWithOpenAI()`, `runWithGemini()`, `runWithCursor()`, etc.
- Files: All `src/runners/*.ts`
- Risk: Runtime errors in agent execution
- Priority: HIGH

**Untested: Skill discovery and loading:**
- What's not tested: Multi-source discovery, deduplication, malformed SKILL.md handling
- Files: `src/utils/skill-discovery.ts`, `src/utils/skill-loader.ts`
- Risk: Agents silently skip skills due to parsing errors
- Priority: MEDIUM

**Untested: Error handling paths:**
- What's not tested: All try-catch blocks, validation failures, missing files
- Impact: Unknown behavior when things fail
- Priority: MEDIUM

---

*Concerns audit: 2026-04-11*
