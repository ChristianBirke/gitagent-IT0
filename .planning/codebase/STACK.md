# Technology Stack

**Analysis Date:** 2026-04-11

## Languages

**Primary:**
- TypeScript 5.7.0 - All source code in `src/`
- Node.js 18+ - Runtime for CLI and programmatic usage

**Secondary:**
- JavaScript (ES2022) - Compiled output
- YAML - Agent manifests, configuration files
- JSON - Schema validation, CLI configuration

## Runtime

**Environment:**
- Node.js 18 or higher (specified in `package.json` engines field)
- CLI-first architecture via executable entry point: `./dist/index.js`

**Package Manager:**
- npm
- No lockfile committed (users manage via npm or yarn)

## Frameworks

**Core Framework:**
- Commander.js 12.1.0 - CLI argument parsing and command definition

**Type System:**
- TypeScript 5.7.0 - Strict type checking with ES2022 target

**Build:**
- TypeScript compiler (tsc) - Compiles src/ to dist/, emits declarations and source maps
- Command: `npm run build` compiles and makes executable with chmod +x

## Key Dependencies

**Critical:**
- `ajv` 8.17.1 - JSON Schema validation for agent manifests and configurations
- `ajv-formats` 3.0.1 - Extended format validation (email, uri, date, etc.)
- `commander` 12.1.0 - CLI framework and command parsing
- `inquirer` 9.3.7 - Interactive command-line UI (prompts, selections)
- `chalk` 5.3.0 - Terminal color output and styling
- `js-yaml` 4.1.0 - Parse and load YAML configuration files

**Development:**
- TypeScript compiler (devDependency) - Source compilation
- `@types/node` 22.10.0 - Node.js type definitions
- `@types/inquirer` 9.0.7 - Type definitions for inquirer
- `@types/js-yaml` 4.0.9 - Type definitions for yaml parsing

## Configuration

**Build Configuration:**
- `tsconfig.json` - TypeScript compiler options
  - Target: ES2022
  - Module: Node16 (ESM)
  - Output directory: `./dist`
  - Root directory: `./src`
  - Strict mode enabled
  - Source maps enabled
  - Declaration files emitted

**Entry Point Configuration:**
- `package.json` bin field: `gitagent` → `./dist/index.js`
- Shebang in dist/index.js (`#!/usr/bin/env node`) makes it executable

**Schema Validation:**
- `spec/schemas/` directory contains JSON Schema files
- Loaded at runtime via `src/utils/schemas.ts`
- Schemas for: agent.yaml, agent manifest, tools, etc.

## Platform Requirements

**Development:**
- Node.js 18+
- TypeScript 5.7.0
- npm or yarn for package management
- Bash/zsh for build scripts

**Production:**
- Node.js 18+ runtime
- No native dependencies
- Runs on macOS, Linux, Windows (with npm global or local install)

**CLI Distribution:**
- Published to npm as `@open-gitagent/gitagent`
- Can be installed globally: `npm install -g @open-gitagent/gitagent`
- Or run with npx: `npx @open-gitagent/gitagent <command>`

## Testing

**Framework:**
- Node.js built-in test runner (node --test)
- Command: `npm test` runs `node --test dist/**/*.test.js`
- Test files: `src/**/*.test.ts` compiled to `dist/**/*.test.js`

---

*Stack analysis: 2026-04-11*
