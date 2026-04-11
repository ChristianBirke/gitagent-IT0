# External Integrations

**Analysis Date:** 2026-04-11

## APIs & External Services

**LLM Providers:**
- Claude/Anthropic API
  - SDK/Client: Native fetch (builtin)
  - Auth: `ANTHROPIC_API_KEY` or `ANTHROPIC_OAUTH_TOKEN`
  - Usage: `src/runners/claude.ts` - Spawns Claude Code CLI
  - Export adapter: `src/adapters/claude-code.ts`

- OpenAI API
  - SDK/Client: Native fetch (builtin)
  - Auth: `OPENAI_API_KEY`
  - Usage: `src/runners/openai.ts` - Generates Python code and spawns python3
  - Export adapter: `src/adapters/openai.ts` - Generates OpenAI Agents SDK Python
  - Supports multiple OpenAI models (GPT-4, o1, o3, o4 variants)

- GitHub Models API
  - Endpoint: `https://models.github.ai/inference` (OpenAI-compatible chat completions)
  - Auth: `GITHUB_TOKEN` or `GH_TOKEN` (requires "models:read" scope)
  - Usage: `src/runners/github.ts` - Streams responses with Server-Sent Events
  - Export adapter: `src/adapters/github.ts` - Generates OpenAI-compatible payload
  - Supports multi-vendor models: openai/*, anthropic/*, meta/*, mistralai/*, google/*, deepseek/*, cohere/*

- Gemini (Google)
  - Export adapter: `src/adapters/gemini.ts`
  - Planned integration

- DeepSeek
  - Model mapping in `src/runners/github.ts` and `src/adapters/github.ts`

**Agent/Framework Platforms:**
- OpenClaw (Anthropic Agent Framework)
  - Auth: `ANTHROPIC_API_KEY`
  - Config: `~/.openclaw/agents/main/agent/auth-profiles.json` (auto-created)
  - Usage: `src/runners/openclaw.ts` - Spawns openclaw CLI
  - Export adapter: `src/adapters/openclaw.ts`
  - Auto-provision: `src/utils/auth-provision.ts` ensureOpenClawAuth()

- Nanobot
  - Auth: `ANTHROPIC_API_KEY`
  - Config: `~/.nanobot/config.json` (auto-created)
  - Export adapter: `src/adapters/nanobot.ts`
  - Auto-provision: `src/utils/auth-provision.ts` ensureNanobotAuth()

- Lyzr Studio
  - Endpoint: `https://agent-prod.studio.lyzr.ai` (v3 REST API)
  - Auth: `LYZR_API_KEY` (via x-api-key header)
  - Usage: `src/runners/lyzr.ts` - REST API client (fetch)
  - Operations:
    - POST `/v3/agents/template/single-task` - Create agent
    - GET `/v3/agents/{agentId}` - Fetch existing agent
    - PUT `/v3/agents/template/single-task/{agentId}` - Update agent
  - Export adapter: `src/adapters/lyzr.ts`

- CrewAI
  - Export adapter: `src/adapters/crewai.ts`
  - Python-based agent framework

- OpenCode (sst/opencode)
  - Usage: `src/runners/opencode.ts` - Spawns opencode CLI
  - Creates workspace with AGENTS.md + opencode.json
  - Export adapter: `src/adapters/opencode.ts`
  - Supports interactive and single-shot modes

- Copilot (GitHub)
  - Export adapter: `src/adapters/copilot.ts`

- Cursor
  - Export adapter: `src/adapters/cursor.ts`
  - Custom rules (.mdc format)

- Codex (OpenAI deprecated)
  - Export adapter: `src/adapters/codex.ts`
  - Reference: https://github.com/openai/codex

**Code Editor/IDE Integrations:**
- Claude Code (Anthropic IDE)
  - Runner: `src/runners/claude.ts` - Spawns claude CLI with system prompt
  - Maps gitagent hooks to Claude Code settings
  - Maps sub-agents to Claude Code agents via --agents JSON
  - Supports skill directories via --add-dir
  - Command mapping: on_session_start → SessionStart, pre_tool_use → PreToolUse, etc.

## Data Storage

**Databases:**
- None integrated - File-based configuration only

**File Storage:**
- Local filesystem only
  - Agent definitions: `./<agent>/agent.yaml`
  - Skills: `./<agent>/skills/*.md`
  - Tools: `./<agent>/tools/*.yaml`
  - Knowledge: `./<agent>/knowledge/**/*`
  - Sub-agents: `./<agent>/agents/<name>/`
  - Hooks: `./<agent>/hooks/hooks.yaml`

**Caching:**
- Git cache: `src/utils/git-cache.ts` - In-memory caching of git operations
- Registry cache: Local filesystem temp directories for downloaded skills

## Authentication & Identity

**Auth Providers:**

1. **API Key Providers:**
   - Anthropic: `ANTHROPIC_API_KEY` or `ANTHROPIC_OAUTH_TOKEN`
   - OpenAI: `OPENAI_API_KEY`
   - Lyzr: `LYZR_API_KEY`
   - GitHub: `GITHUB_TOKEN` or `GH_TOKEN`

2. **Auth Functions (src/utils/auth-provision.ts):**
   - `resolveAnthropicKey()` - Returns API key or OAuth token
   - `resolveOpenAIKey()` - Returns OpenAI API key
   - `ensureOpenClawAuth()` - Auto-creates ~/.openclaw/agents/main/agent/auth-profiles.json
   - `ensureNanobotAuth()` - Auto-creates ~/.nanobot/config.json
   - `ensureLyzrAuth()` - Validates LYZR_API_KEY
   - `ensureGitHubAuth()` - Validates GITHUB_TOKEN or GH_TOKEN
   - `resolveGitHubToken()` - Returns token from env

## Monitoring & Observability

**Error Tracking:**
- None integrated

**Logs:**
- Console output via `src/utils/format.js`:
  - `info()` - Informational messages
  - `success()` - Success messages
  - `error()` - Error messages
  - `warn()` - Warning messages
  - `label()` - Key-value output
  - `heading()` - Section headers
  - `divider()` - Visual separators
- Colored output via chalk 5.3.0

## CI/CD & Deployment

**Hosting:**
- npm registry - Published as `@open-gitagent/gitagent`
- GitHub Releases - Source code

**CI Pipeline:**
- GitHub Actions (inferred from keywords, not configured in repo)

**Build Pipeline:**
- Pre-publish: `npm run build` - TypeScript compilation
- Entry: `gitagent` command (globally available after npm install -g)

## Environment Configuration

**Required env vars:**
- None required (all optional for specific runners)
- Conditional by runner:
  - Claude: Claude Code CLI must be installed
  - OpenAI: `OPENAI_API_KEY`
  - GitHub Models: `GITHUB_TOKEN` or `GH_TOKEN`
  - Lyzr: `LYZR_API_KEY`
  - OpenClaw: `ANTHROPIC_API_KEY`
  - Nanobot: `ANTHROPIC_API_KEY`

**Secrets location:**
- Environment variables only - no .env file support
- No config file-based secrets (intentional security design)

## Skill Registry

**SkillsMP Marketplace:**
- Endpoint: `https://api.skillsmp.com` (default, configurable)
- Client: `src/utils/registry-provider.ts` SkillsMPProvider class
- Operations:
  - GET `/v1/skills/search?q=<query>&limit=<n>&offset=<n>` - Search skills
  - GET `/v1/skills/<skillName>` - Fetch skill package
- Auth: None (public API)

**GitHub Skills Registry:**
- Endpoint: `https://api.github.com` (REST API v3)
- Client: `src/utils/registry-provider.ts` GitHubProvider class
- Operations:
  - GET `/search/code?q=<skillmd_query>` - Search skill repositories
  - GET `/repos/{owner}/{repo}/contents/{skillMdPath}` - Fetch SKILL.md
  - Git clone: `git clone --depth=1 https://github.com/{owner}/{repo}.git`
- Auth: Optional `GITHUB_TOKEN` for higher rate limits

**Local File Registry:**
- Client: `src/utils/registry-provider.ts` LocalProvider class
- Reads skills from local filesystem paths

## Webhooks & Callbacks

**Incoming:**
- None implemented

**Outgoing:**
- Lyzr API operations include agent state updates (indirect webhooks via agent_id)
- No explicit webhook endpoints exposed

---

*Integration audit: 2026-04-11*
