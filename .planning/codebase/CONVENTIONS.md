# Coding Conventions

**Analysis Date:** 2026-04-11

## Naming Patterns

**Files:**
- kebab-case for all TypeScript files: `src/commands/init.ts`, `src/adapters/codex.ts`, `src/utils/skill-loader.ts`
- Test files use `.test.ts` suffix: `src/adapters/codex.test.ts`, `src/adapters/cursor.test.ts`
- Index files: `src/adapters/index.ts`, `src/runners/index.ts` re-export main functions

**Functions:**
- camelCase for function names: `exportToCodex()`, `loadAgentManifest()`, `parseSkillMd()`, `buildComplianceSection()`
- Private functions prefixed with underscore only when truly internal to module, otherwise use regular camelCase
- Handler functions use verb-action pattern: `buildInstructions()`, `buildConfig()`, `collectAllowedTools()`, `buildSubagentConfig()`

**Variables:**
- camelCase for all variables: `agentDir`, `manifest`, `tmpFiles`, `promptFile`, `allowedTools`, `schemaResult`
- Constants use UPPER_SNAKE_CASE: `MINIMAL_AGENT_YAML`, `STANDARD_AGENT_YAML`, `STANDARD_SOUL_MD`, `STANDARD_RULES_MD`
- Single letter loop variables acceptable: `i`, `e` (in error handlers)

**Types:**
- PascalCase for interfaces: `AgentManifest`, `InitOptions`, `ExportOptions`, `CodexExport`, `SkillFrontmatter`, `ParsedSkill`, `SkillMetadata`, `ValidationResult`
- Interfaces prefixed with capital letter, not `I-` prefix convention
- Type properties use snake_case to match YAML/JSON schemas: `spec_version`, `human_in_the_loop`, `pii_handling`, `max_tokens`, `allowed_tools`
- Union/literal types use lowercase: `mode: 'auto' | 'manual'`, `pii_handling: 'redact' | 'prohibit'`

## Code Style

**Formatting:**
- No linting tool configured (no .eslintrc, no prettier config)
- TypeScript compiler runs in strict mode: `"strict": true` in `tsconfig.json`
- Target: ES2022 with Node16 module resolution
- Auto-formatting not enforced in source

**Linting:**
- No linter configured
- Strict TypeScript enforced via tsconfig: strict type checking enabled
- Build step runs tsc to validate types

## Import Organization

**Order:**
1. Built-in Node.js modules: `import { readFileSync } from 'node:fs';`
2. Third-party packages: `import yaml from 'js-yaml';`, `import chalk from 'chalk';`
3. Relative imports from utils: `import { loadAgentManifest } from '../utils/loader.js';`
4. Relative imports from adapters: `import { buildComplianceSection } from './shared.js';`
5. Type imports: Included inline with regular imports

**Path Aliases:**
- No path aliases configured
- All imports use explicit relative paths: `./`, `../`
- Full file extensions required in imports: `.js` extension even for TypeScript files

**Example from `src/commands/export.ts`:**
```typescript
import { Command } from 'commander';
import { resolve } from 'node:path';
import { error, heading, info, success } from '../utils/format.js';
import {
  exportToSystemPrompt,
  exportToClaudeCode,
  // ...
} from '../adapters/index.js';
```

## Error Handling

**Patterns:**
- Try-catch blocks in command handlers wrap async/sync operations
- Errors logged using `error()` utility function from `src/utils/format.ts`
- Process exit with status code: `process.exit(1)` on error
- Set exit code: `process.exitCode = result.status ?? 0`
- Silent catches for non-critical operations: `catch { /* skip */ }`

**Example from `src/commands/export.ts`:**
```typescript
try {
  // operation
  result = exportToCodex(dir);
} catch (e) {
  error((e as Error).message);
  process.exit(1);
}
```

**Validation errors:**
- Schema validation via AJV returns array of errors: `validate.errors?.map((e: any) => { ... })`
- Custom validation errors thrown as Error: `throw new Error('...')`
- Cross-module errors propagate upward, caught at command level

**Example from `src/utils/skill-loader.ts`:**
```typescript
if (!frontmatter.name || !frontmatter.description) {
  throw new Error(`SKILL.md at ${filePath} is missing required fields: name, description`);
}
```

## Logging

**Framework:** `console` with `chalk` color library from `src/utils/format.ts`

**Utilities in `src/utils/format.ts`:**
```typescript
export function success(msg: string): void  // Green ✓ prefix
export function error(msg: string): void    // Red ✗ prefix
export function warn(msg: string): void     // Yellow ! prefix
export function info(msg: string): void     // Blue i prefix
export function heading(msg: string): void  // Bold with newline
export function label(key: string, value: string): void  // Gray key: value format
export function divider(): void             // Horizontal line
```

**Patterns:**
- Commands use `heading()` to mark action start: `heading('Exporting agent')`
- Use `info()` for context and status: `info(`Format: ${options.format}`)`
- Use `success()` to confirm completion: `success(`Exported to ${output}`)`
- Use `error()` for failures (exits after): `error((e as Error).message)`
- Use `warn()` for non-fatal issues: `warn('Missing optional field')`
- Use `label()` for structured key-value output in reports

## Comments

**When to Comment:**
- JSDoc blocks on exported functions and public interfaces
- Inline comments for non-obvious logic, complex regex patterns, or surprising decisions
- Section dividers in tests: `// ---------------------------------------------------------------------------`
- Action documentation in command files: `// gitagent lyzr create`

**JSDoc/TSDoc:**
```typescript
/**
 * Export a gitagent to OpenAI Codex CLI format.
 *
 * Codex CLI (openai/codex) uses:
 *   - AGENTS.md              (custom agent instructions, project root)
 *   - codex.json             (model and provider configuration)
 *
 * Reference: https://github.com/openai/codex
 */
export interface CodexExport {
  /** Content for AGENTS.md */
  instructions: string;
  /** Content for codex.json */
  config: Record<string, unknown>;
}
```

**Single-line JSDoc for property documentation:**
```typescript
/** Default model when agent.yaml doesn't specify one */
const DEFAULT_MODEL = 'claude-3-5-sonnet-20241022';
```

## Function Design

**Size:** Functions typically 10-50 lines, complex operations broken into smaller helpers
- Main handler functions: 20-40 lines with delegation to helper functions
- Helper functions: 10-30 lines focused on single concern
- Complex validators broken into separate validation functions

**Parameters:**
- Simple parameters passed individually for 2-3 args
- Objects used for 4+ parameters: `opts: { name?: string; soul?: string; ... }`
- Configuration/options objects passed as second parameter

**Example from `src/adapters/codex.test.ts`:**
```typescript
function makeAgentDir(opts: {
  name?: string;
  description?: string;
  soul?: string;
  rules?: string;
  model?: string;
  skills?: Array<{ name: string; description: string; instructions: string }>;
}): string {
```

**Return Values:**
- Explicit return types required: `function foo(): string | null`
- Complex returns use interfaces: `function exportToCodex(): CodexExport`
- Void functions use `void` type when no return needed
- Early returns preferred for validation: `if (!valid) return null;`

## Module Design

**Exports:**
- Named exports for all public functions
- Default exports not used
- Re-export pattern in index files: `export { exportToCodex } from './codex.js';`

**Barrel Files:**
- Used in `src/adapters/index.ts` to aggregate adapter exports
- Used in `src/runners/index.ts` to aggregate runner functions
- Flat re-export structure without transformation

**Example from `src/adapters/index.ts` pattern:**
```typescript
export { exportToSystemPrompt } from './system-prompt.js';
export { exportToClaudeCode } from './claude-code.js';
// ... more exports
```

---

*Convention analysis: 2026-04-11*
