# Testing Patterns

**Analysis Date:** 2026-04-11

## Test Framework

**Runner:**
- Node.js built-in test runner (`node --test`)
- No external test framework required
- Available in Node >=18 (project requires `"engines": { "node": ">=18" }`)

**Configuration:**
- No `jest.config.js`, `vitest.config.ts`, or test config file
- Tests discovered automatically in `*.test.ts` and `*.spec.ts` files
- Run via `npm test` which executes: `node --test dist/**/*.test.js`

**Assertion Library:**
- Node.js built-in `assert/strict` module: `import assert from 'node:assert/strict';`
- Strict assertions enabled by default
- No external assertion library (Chai, Jest matchers, etc.)

**Run Commands:**
```bash
npm test                    # Run all tests (compiled dist/**/*.test.js)
npm run build && npm test   # Rebuild and test
npm run dev                 # Watch mode (builds TypeScript)
```

## Test File Organization

**Location:**
- Co-located with source code: `src/adapters/codex.test.ts` alongside `src/adapters/codex.ts`
- Test files import compiled JavaScript: `import { exportToCodex } from './codex.js';`

**Naming:**
- `.test.ts` suffix for test files: `codex.test.ts`, `cursor.test.ts`
- Test files compiled to `dist/adapters/codex.test.js` (same structure)

**Current Coverage:**
- Only two test files present: `src/adapters/codex.test.ts`, `src/adapters/cursor.test.ts`
- No tests for commands, runners, or utilities
- No test configuration enforcing coverage requirements

## Test Structure

**Suite Organization:**
```typescript
/**
 * Tests for the Codex CLI adapter (export + import).
 *
 * Uses Node.js built-in test runner (node --test).
 */
import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

import { exportToCodex, exportToCodexString } from './codex.js';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeAgentDir(opts: { ... }): string {
  // Factory to create test fixtures
}

// ---------------------------------------------------------------------------
// exportToCodex
// ---------------------------------------------------------------------------

describe('exportToCodex', () => {
  test('produces instructions and config objects', () => {
    // test
  });

  test('instructions include agent name and description', () => {
    // test
  });
});

// ---------------------------------------------------------------------------
// exportToCodexString
// ---------------------------------------------------------------------------

describe('exportToCodexString', () => {
  test('contains AGENTS.md and codex.json section headers', () => {
    // test
  });
});
```

**Section Organization:**
- Top comment block explains test purpose
- Helper functions at top of file (often before first test)
- Tests grouped by function under `describe()` blocks
- Horizontal divider comments between sections
- One assertion style per test (focused, single concern)

**Patterns:**

### Test Suite with describe():
```typescript
describe('exportToCodex', () => {
  test('produces instructions and config objects', () => {
    const dir = makeAgentDir({ name: 'my-agent' });
    const result = exportToCodex(dir);
    assert.ok(typeof result.instructions === 'string');
    assert.ok(typeof result.config === 'object');
  });

  test('instructions include agent name and description', () => {
    const dir = makeAgentDir({ name: 'demo-agent', description: 'Demo' });
    const { instructions } = exportToCodex(dir);
    assert.match(instructions, /demo-agent/);
    assert.match(instructions, /Demo description/);
  });
});
```

### Assertion Patterns:
- `assert.ok(condition)` - truthiness check
- `assert.equal(actual, expected)` - strict equality
- `assert.deepEqual(actual, expected)` - deep object comparison
- `assert.match(string, regex)` - regex pattern matching
- `assert.doesNotThrow(() => fn())` - exception checking
- `assert.throws(() => fn(), errorType)` - error assertion (when used)

## Mocking

**Framework:** No mocking library used (no sinon, jest.mock, vitest.mock)

**Test Isolation Pattern:**
- Tests use temporary directories for all file I/O
- Factory functions (`makeAgentDir()`) create fresh test fixtures per test
- No shared state between tests

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
  const dir = mkdtempSync(join(tmpdir(), 'gitagent-codex-test-'));

  const modelBlock = opts.model
    ? `model:\n  preferred: ${opts.model}\n`
    : '';

  writeFileSync(
    join(dir, 'agent.yaml'),
    `spec_version: '0.1.0'\nname: ${opts.name ?? 'test-agent'}\n...`,
    'utf-8',
  );

  if (opts.soul !== undefined) {
    writeFileSync(join(dir, 'SOUL.md'), opts.soul, 'utf-8');
  }

  // ... more setup

  return dir;
}
```

**What to Mock:**
- External API calls (not present in test files yet)
- File system interactions (avoided by using temporary directories instead)
- Subprocess spawning (not tested)

**What NOT to Mock:**
- File system operations (use temp directories via `mkdtempSync`)
- YAML parsing (actual parsing tested)
- Agent manifest loading (actual loading tested)
- Schema validation (actual validation tested)

## Fixtures and Factories

**Test Data Pattern:**
- Factory function per adapter test file: `makeAgentDir(opts)`
- Creates minimal but complete test agent directory structure
- Options object allows parameterization for different test cases
- Default values for optional fields

**Example from `src/adapters/cursor.test.ts`:**
```typescript
function makeAgentDir(opts: {
  name?: string;
  description?: string;
  soul?: string;
  rules?: string;
  skills?: Array<{ name: string; description: string; instructions: string; globs?: string }>;
}): string {
  const dir = mkdtempSync(join(tmpdir(), 'gitagent-cursor-test-'));

  const manifest = {
    spec_version: '0.1.0',
    name: opts.name ?? 'test-agent',
    version: '0.1.0',
    description: opts.description ?? 'A test agent',
  };

  writeFileSync(
    join(dir, 'agent.yaml'),
    `spec_version: '0.1.0'\nname: ${manifest.name}\nversion: '0.1.0'\ndescription: '${manifest.description}'\n`,
    'utf-8',
  );

  if (opts.skills) {
    for (const skill of opts.skills) {
      const skillDir = join(dir, 'skills', skill.name);
      mkdirSync(skillDir, { recursive: true });
      const metadataLine = skill.globs ? `metadata:\n  globs: ${skill.globs}\n` : '';
      writeFileSync(
        join(skillDir, 'SKILL.md'),
        `---\nname: ${skill.name}\ndescription: '${skill.description}'\n${metadataLine}---\n\n${skill.instructions}\n`,
        'utf-8',
      );
    }
  }

  return dir;
}
```

**Location:**
- Factory functions defined at top of test file before test suites
- Helpers are local to each test file (not shared)
- Temporary directories created via Node's `os.tmpdir()`

## Coverage

**Requirements:** None enforced
- No coverage thresholds configured
- No coverage reporting tools (Istanbul, c8, etc.)
- No coverage targets mentioned in docs

**Measurement:**
- No coverage reporting script in package.json
- Can be run manually: `node --test --coverage` (if Node supports it)

## Test Types

**Unit Tests:**
- Focus on adapter export/import functions: `exportToCodex()`, `exportToCursorString()`, `parseMdcFile()`
- Test individual concern per test
- Use temp directories and factory fixtures
- Validate behavior against expected inputs/outputs

**Integration Tests:**
- Not present in codebase
- Would test full workflow: init → validate → export → run

**E2E Tests:**
- Not present
- Not configured

## Common Patterns

### Async Testing:
- No async tests present
- All tests are synchronous
- File I/O uses synchronous methods: `writeFileSync()`, `readFileSync()`, `mkdtempSync()`

### Error Testing:
```typescript
test('throws on missing frontmatter', () => {
  const content = `Just plain markdown, no frontmatter.`;
  const result = parseMdcFile(content);
  assert.deepEqual(result.frontmatter, {});
  assert.equal(result.body, content);
});
```

**Pattern:**
- Use factory to set up error condition
- Call function
- Assert expected result (often lenient/graceful handling)
- No `assert.throws()` usage in current tests
- Error handling tested via expected behavior, not exception throwing

### Setup/Teardown:
- No setup/teardown hooks used (no `beforeEach`, `afterEach`)
- Temporary directories cleaned up by OS after test process exits
- Each test completely independent via factory pattern

### Regex Matching:
```typescript
test('instructions include SOUL.md content', () => {
  const dir = makeAgentDir({ soul: '# Soul\n\nBe helpful and precise.' });
  const { instructions } = exportToCodex(dir);
  assert.match(instructions, /Be helpful and precise/);
});
```

**Pattern:**
- Use `assert.match(string, regex)` for substring presence
- Case-sensitive by default
- No regex flags except when needed

### JSON Validation:
```typescript
test('codex.json section is valid JSON', () => {
  const dir = makeAgentDir({ model: 'gpt-4o' });
  const result = exportToCodexString(dir);
  const jsonStart = result.indexOf('# === codex.json ===\n') + '# === codex.json ===\n'.length;
  const jsonStr = result.slice(jsonStart).trim();
  assert.doesNotThrow(() => JSON.parse(jsonStr));
  const parsed = JSON.parse(jsonStr);
  assert.equal(parsed.model, 'gpt-4o');
});
```

**Pattern:**
- Extract JSON from output string
- Validate with `assert.doesNotThrow()`
- Parse and validate structure with assertions

---

*Testing analysis: 2026-04-11*
