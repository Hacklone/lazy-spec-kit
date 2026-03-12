<p align="center">
  <img src="media/logo.webp" alt="LazySpecKit" width="200">
</p>

<h1 align="center">LazySpecKit ⚡</h1>

<p align="center">
  <strong>The complete AI development workflow — not just automation, but architecture awareness, multi-agent review & auto-fix, and zero babysitting.</strong><br>
  Write your spec. LazySpecKit handles everything else: planning, implementation, validation, and a seven-agent review that finds AND fixes issues automatically.
</p>

<p align="center">
  <a href="#install"><img src="https://img.shields.io/badge/Install-blue" alt="Install"></a>
  <a href="#quick-start"><img src="https://img.shields.io/badge/Quick%20Start-blue" alt="Quick Start"></a>
  <a href="https://hacklone.github.io/lazy-spec-kit/"><img src="https://img.shields.io/badge/docs-GitHub%20Pages-blue" alt="Documentation"></a>
  <a href="https://github.com/Hacklone/lazy-spec-kit/actions/workflows/test.yml"><img src="https://github.com/Hacklone/lazy-spec-kit/actions/workflows/test.yml/badge.svg" alt="Tests"></a>
  <a href="https://github.com/Hacklone/lazy-spec-kit/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT License"></a>
</p>

---

## Why LazySpecKit?

LazySpecKit is the complete spec-driven development workflow. Built on [GitHub SpecKit](https://github.com/github/spec-kit), it adds architecture awareness, auto-clarification, multi-agent review with auto-fix, governance, and fully automated execution — everything you need out of the box:

| | SpecKit alone | LazySpecKit |
|---|---|---|
| **Workflow automation** | Manual slash commands between phases | Fully automated end-to-end |
| **Architecture awareness** | None | Selectively loads architecture docs — ensures specs reuse existing services, libraries, and respect service boundaries |
| **Clarification** | Always manual | `--auto-clarify` — agent answers its own questions when confident |
| **Post-implementation review** | None | Seven AI agents review from different perspectives |
| **Auto-fix** | None | Reviewers fix Critical/High issues automatically |
| **Governance** | None | Scoped `agents.md` files enforce conventions per directory |
| **Architecture docs** | None | Auto-generated from codebase, kept evergreen across runs |

LazySpecKit uses SpecKit as its foundation for structured spec processing, then adds full automation, architecture context, and its own **Review & Refine** phase: seven specialized AI agents, each approaching the code from a different perspective (architecture, code quality, security, performance, spec compliance, accessibility, tests), that don't just *review* but **automatically fix** the issues they find. Five of these reviewers are sourced from [Agency](https://github.com/msitarzewski/agency-agents) — a curated collection of specialized AI agent definitions — and downloaded automatically during setup.

```
/LazySpecKit Add OAuth login with GitHub and Google. Store users in Postgres. Add tests.
```

Want the fully hands-off experience? Add `--auto-clarify`:

```
/LazySpecKit --auto-clarify Add OAuth login with GitHub and Google. Store users in Postgres. Add tests.
```

> Sit back, enjoy a coffee ☕, and let LazySpecKit handle the rest — including a multi-agent review that fixes what it finds.

---

## Table of Contents

- [Install](#install)
- [Quick Start](#quick-start)
- [What is SpecKit?](#what-is-speckit)
- [What is a Constitution?](#what-is-a-constitution)
- [How It Works](#how-it-works)
- [Architecture Context Awareness](#architecture-context-awareness)
- [Auto-Clarify — True Hands-Off Mode](#auto-clarify--true-hands-off-mode)
- [Review & Refine](#review--refine)
- [Custom Reviewers](#custom-reviewers)
- [Agency Integration](#agency-integration)
- [Supported AI Agents](#supported-ai-agents)
- [CLI Reference](#cli-reference)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Uninstall](#uninstall)
- [License](#license)

---

## Install

**Requirements:** `bash` + `curl` (or `wget`). Works on macOS, Linux, and Windows (Git Bash).

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Hacklone/lazy-spec-kit/main/install.sh)"
```

This installs the `lazyspeckit` CLI to `~/.local/bin` (or `~/bin` on Windows Git Bash).

---

## Quick Start

**1. Initialize your project** (one-time setup):

```bash
# For VS Code Copilot
lazyspeckit init --here --ai copilot

# For Claude Code
lazyspeckit init --here --ai claude
```

**2. Use the prompt** in your AI assistant:

```
/LazySpecKit <your spec here>
```

For the ultimate hands-off experience — auto-answer clarification questions + multi-agent review:

```
/LazySpecKit --auto-clarify <your spec here>
```

Optionally disable the post-implementation multi-agent review & refinement:

```
/LazySpecKit --review=off <your spec here>
```

Combine both for maximum automation, no review:

```
/LazySpecKit --auto-clarify --review=off <your spec here>
```

That's it. LazySpecKit takes over from there — implementation, validation, and (by default) a multi-agent review that fixes issues automatically.

---

## What is SpecKit?

[GitHub SpecKit](https://github.com/github/spec-kit) is a structured workflow for AI-assisted development. Instead of giving an AI agent a vague prompt and hoping for the best, SpecKit turns a natural-language spec into a formal plan, generates tasks, validates spec quality, implements code, and runs validation — all through slash commands (`/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, etc.).

LazySpecKit uses SpecKit as its structured spec processing engine and adds full lifecycle automation, architecture awareness, multi-agent review with auto-fix, governance enforcement, and automatic architecture documentation on top. You don't need to run each slash command manually; LazySpecKit handles the entire workflow from spec to reviewed, validated code.

---

## What is a Constitution?

A **constitution** is a short document that tells SpecKit about your project — its tech stack, conventions, and preferences. It's created once per project (on first run) and ensures that every generated plan, task, and code change aligns with how your project actually works.

### What to include

Pick what applies to your project:

- **Tech stack** — languages, frameworks, databases, infrastructure
- **Code style** — naming conventions, file/folder structure, patterns (e.g., "use repository pattern", "prefer functional components")
- **Testing** — framework, coverage expectations, test file conventions
- **Build & tooling** — package manager, bundler, linter, CI requirements
- **Constraints** — security policies, performance targets, accessibility, compliance
- **Domain context** — brief description of what the project does

### Example constitution

```
- TypeScript + React 19 frontend, Node.js + Express backend
- PostgreSQL with Prisma ORM
- Vitest for unit tests, Playwright for E2E
- pnpm workspaces monorepo
- All API routes require auth middleware
- Follow existing patterns in src/
```

### When is it created?

The first time you run `/LazySpecKit` in a project without an existing constitution, it will ask you to provide one. Paste your constitution text, and LazySpecKit passes it to SpecKit's `/speckit.constitution` command. After that, it's saved in your project and reused for every future run.

If your project already has a constitution (e.g., from a previous SpecKit setup), LazySpecKit detects it automatically and skips this step.

---

## How It Works

When you run `/LazySpecKit <spec>`, it orchestrates the full SpecKit lifecycle automatically:

| Phase | What happens | User input needed? |
|-------|-------------|-------------------|
| **Constitution** | Checks for an existing [constitution](#what-is-a-constitution); asks you to provide one if missing | Only if missing |
| **Architecture Context** | Loads 3 compact root files from `.docs/architecture/`, then selectively loads only relevant service/app/library docs. If none exist, **auto-generates from codebase**. Scales to large monorepos | No |
| **Specify** | Runs `/speckit.specify` with your spec text | No |
| **Clarify** | Presents clarification questions (architecture-informed recommendations) | **Yes — answer once** (or use `--auto-clarify`) |
| **Spec Summary** | Prints a concise summary of what will be built | No |
| **Plan** | Generates implementation plan aligned with architecture principles | No |
| **Tasks** | Breaks plan into sequential tasks | No |
| **Quality Gates** | Runs `/speckit.checklist` + `/speckit.analyze` with multi-perspective checks (architecture, security, performance, UX), auto-fixes spec issues | No |
| **Governance** | Creates scoped `agents.md` governance files if missing (root + immediate subdirectories) | No |
| **Implement** | Executes tasks in order, following `agents.md` rules | No |
| **Validate** | Runs detected lint / typecheck / tests / build | No |
| **Review & Refine** | Seven AI agents review from different perspectives — architecture, quality, security, performance, spec compliance, accessibility, tests — and **auto-fix** findings (up to 6 loops, configurable via `--max-review-loops`) | No |
| **Final Validation** | Full validation suite re-run to guarantee green before completion | No |
| **Architecture Update** | Updates architecture docs to reflect new services, apps, libraries, and decisions | No |

**You only interact during Constitution (if missing) and Clarify.** With `--auto-clarify`, even Clarify becomes automatic for high/medium-confidence questions — you're only asked about genuinely ambiguous items. Everything else — including multi-agent review and automatic code refinement — is fully automated.

If something goes wrong, LazySpecKit retries up to 3 times, then stops with a clear blocker message — it never silently continues in a broken state.

---

## Architecture Context Awareness

LazySpecKit includes built-in architecture context awareness. When your project has architecture documentation in `.docs/architecture/`, every spec benefits from knowledge of your existing system — services, apps, libraries, principles, and integration patterns.

### Why it matters

Without architecture context, AI agents treat each spec in isolation. They might:
- Recreate logic that already exists in a shared library
- Violate service boundaries
- Introduce patterns inconsistent with your codebase
- Build one-off solutions instead of reusable components

With architecture context, LazySpecKit ensures new specs **reuse existing libraries and services**, **respect service boundaries**, and **create reusable components** — just like a human architect would.

### Designed for scale

Architecture docs are structured for **selective loading**. Only 3 small root files are always loaded — agents then use the routing table to load only the component docs relevant to the current task. This keeps context focused even in huge monorepos with dozens of components. Components can be organized flat or grouped by domain — the structure adapts to your project.

### How it works

1. **`lazyspeckit init`** creates `.docs/architecture/` with templates and examples
2. **Phase 1 (Architecture Context)** loads 3 compact root files (`index.md`, `summary.md`, `principles.md`) — or **auto-generates them from codebase analysis** if none exist
3. **Phase 2 (Selective Loading)** matches spec keywords against the `index.md` routing table and loads only relevant component docs
4. **Plan & Quality Gates** validate alignment with architecture principles
5. **Review & Refine** — the architecture reviewer checks for violations against loaded context
6. **Phase 9 (Architecture Update)** updates the docs to reflect what was built — keeping them evergreen

### Architecture documentation structure

```
.docs/architecture/
├── index.md              # Context router — keyword-to-path routing table (always loaded)
├── summary.md            # System overview — compact, constant-size (always loaded)
├── principles.md         # Architecture rules enforced during planning (always loaded)
├── components/           # All project components — organized however suits your project
│   ├── example/          # Template — replace with your own components
│   │   ├── overview.md
│   │   ├── modules.md
│   │   ├── api.md
│   │   └── ui.md
│   ├── auth/             # Flat component (small repos)
│   │   ├── overview.md
│   │   ├── modules.md
│   │   └── api.md
│   └── payments/         # Domain group (monorepos)
│       ├── payment-api/
│       │   ├── overview.md
│       │   └── api.md
│       └── payment-ui/
│           ├── overview.md
│           └── ui.md
├── integrations/         # External system integrations
│   └── stripe.md
└── decisions/            # Architecture Decision Records (ADRs)
    └── ADR-001-example.md
```

### Key files

| File | Purpose | When it's loaded |
|------|---------|-----------------|
| `index.md` | Routing table — maps keywords to doc paths for each component | Always — agent scans for relevant entries |
| `summary.md` | System purpose, architecture style, tech stack, cross-cutting concerns | Always — compact system-level overview |
| `principles.md` | Architecture rules — service boundaries, dependency direction, reusability | Always — enforced during planning and review |
| `components/<name>/overview.md` | Component entry point — purpose, interfaces, data, dependencies | Selectively — only when spec matches keywords |
| `components/<name>/modules.md` | Internal module breakdown — boundaries, responsibilities, key paths | On demand — when task touches component internals |
| `components/<name>/api.md` | Detailed interfaces — REST, gRPC, CLI, events, schemas | On demand — when task involves interface changes |
| `components/<name>/ui.md` | Screens, pages, or commands — user-facing entry point breakdown | On demand — when task touches specific screens/commands |

### Setup

Architecture docs are created automatically during `lazyspeckit init`. To add them to an existing project:

```bash
lazyspeckit architecture:init --here
```

To skip architecture docs during init:

```bash
lazyspeckit init --here --ai copilot --no-architecture
```

> **Note:** Even without `architecture:init`, LazySpecKit auto-generates architecture docs from your codebase on first run (Phase 1). Templates from `architecture:init` provide a head start, but are not required.

### Checking documentation health

Run `architecture:check` to scan your project and validate documentation status:

```bash
lazyspeckit architecture:check --here
```

This reports documented services, apps, libraries, integrations, and decisions — and suggests project directories that lack documentation. It runs automatically during `lazyspeckit upgrade` and `lazyspeckit doctor`.

### Architecture update phase

After implementation and review, LazySpecKit automatically updates the architecture docs:
- Updates service, app, and library docs with new capabilities and dependencies
- Creates new docs for newly introduced services, apps, or libraries
- Adds entries to the `index.md` routing table for new docs
- Records Architecture Decision Records (ADRs) for significant decisions

This keeps architecture documentation evergreen without manual effort.

---

## Auto-Clarify — True Hands-Off Mode

SpecKit's clarification phase normally requires you to answer questions before proceeding. With `--auto-clarify`, **LazySpecKit answers them for you.**

```
/LazySpecKit --auto-clarify Add a REST API for user management with CRUD endpoints and tests.
```

### How it works

Every clarification question comes with a **Recommendation** and a **Confidence** level (High / Medium / Low):

- **High & Medium confidence** — LazySpecKit auto-selects the recommended answer and keeps moving. No pause.
- **Low confidence** — The question is genuinely ambiguous. Only these are presented to you, in a structured format, for a single quick reply.

If every question is High or Medium confidence, **you never interact at all.** Spec in, finished code out.

### Structured answers

Whether auto-clarified or manual, all clarification questions use a clean A/B/C/D format with explicit recommendations:

```
1) Should auth tokens be JWT or opaque?
   A) JWT
   B) Opaque tokens
   C) Both (configurable)
   D) Other: <free text>

   Recommendation: A — JWT is standard for stateless APIs
   Confidence: High
```

You can always answer manually in one message: `1: A  2: B  3: Other: <text>`

### When to use it

| Scenario | Recommended command |
|----------|--------------------|
| **Maximum hands-off** — trust the agent's judgment | `/LazySpecKit --auto-clarify <spec>` |
| **Full control** — answer every question yourself | `/LazySpecKit <spec>` |
| **Hands-off, skip review** — fastest possible run | `/LazySpecKit --auto-clarify --review=off <spec>` |
| **Fewer review loops** — faster review convergence | `/LazySpecKit --max-review-loops=3 <spec>` |
> **Bottom line:** `--auto-clarify` makes LazySpecKit the ultimate hands-off workflow. Write your spec, walk away, come back to reviewed and refined code.

---

## Review & Refine — What Makes LazySpecKit Different

Most tools stop after implementation and validation. **LazySpecKit keeps going.**

This isn't a single-pass code review. After implementation, LazySpecKit spawns **seven independent AI agents** — each with fresh context and a distinct perspective — that **review the code AND fix what they find**:

| Agent | Perspective | What it catches & fixes |
|-------|-------------|------------------------|
| **Architecture Reviewer** | System design | Poor structure, tangled dependencies, wrong abstraction boundaries |
| **Code Quality Reviewer** | Engineering craft | Bad idioms, missing error handling, duplication, readability issues |
| **Security Reviewer** | Application security | Injection vulnerabilities, missing auth checks, credential leaks, input validation gaps |
| **Performance Reviewer** | Runtime efficiency | N+1 queries, missing indexes, redundant computation, memory leaks |
| **Spec Compliance Reviewer** | Requirements | Missing or incorrectly implemented spec requirements |
| **Accessibility Reviewer** | Accessibility & inclusion | Missing ARIA attributes, color contrast, keyboard navigation, screen reader support |
| **Test Reviewer** | QA | Gaps in coverage, fragile tests, missing edge cases |

### Review, fix, verify — automatically

1. All seven agents analyze the changes — in parallel — from their perspective and produce findings (Critical / High / Medium / Low).
2. LazySpecKit **automatically fixes** all Critical and High issues, plus low-effort Medium ones — this is refinement, not just reporting.
3. Validation (lint / typecheck / tests / build) re-runs to confirm the fixes didn't break anything.
4. The agents review again — up to **6 loops** by default (configurable with `--max-review-loops=N`) — until no Critical or High findings remain.
5. A **final validation gate** ensures everything is green before completion.

If a finding can't be resolved safely, LazySpecKit stops and tells you exactly what needs attention — it never ships broken code.

### Why this matters

- **Multiple perspectives** — Seven agents catch different classes of problems that a single reviewer would miss.
- **Parallel execution** — All reviewers run simultaneously when the environment supports it (e.g., Claude Code), or sequentially otherwise (e.g., VS Code Copilot).
- **Not just review, but refinement** — Issues are fixed in place, not dumped on you as a TODO list.
- **Iterative convergence** — Fix loops continue until the agents agree the code is clean.
- **Safe by design** — Every fix is re-validated; regressions are caught and reverted.

### Control it

Review & Refine is **enabled by default**. To skip it:

```
/LazySpecKit --review=off <your spec>
```

To explicitly enable (the default):

```
/LazySpecKit --review=on <your spec>
```

To limit review iterations:

```
/LazySpecKit --max-review-loops=3 <your spec>
```

> **Bottom line:** With plain SpecKit, you implement and hope for the best. With LazySpecKit, seven agents — each with a different perspective — review your code in parallel, fix what's wrong, and verify the result. You get reviewed, refined, validated code without lifting a finger.

---

## Custom Reviewers

When you run `lazyspeckit init` or `lazyspeckit upgrade`, seven default reviewer skill files are installed into your project:

```
.lazyspeckit/reviewers/
├── accessibility.md       # Accessibility & inclusion (from Agency)
├── architecture.md        # System design (from Agency)
├── code-quality.md        # Engineering craft
├── performance.md         # Runtime efficiency (from Agency)
├── security.md            # Application security (from Agency)
├── spec-compliance.md     # Requirements coverage (from Agency)
└── test.md                # QA & test quality
```

Five of these reviewers are downloaded from the [Agency](https://github.com/msitarzewski/agency-agents) repository — a curated collection of specialized AI agent definitions. The remaining two (`code-quality.md`, `test.md`) are LazySpecKit originals.

Each file defines one reviewer agent that participates in the Review & Refine phase. You can **edit any default** to tune its behavior, or **add new `.md` files** to create additional reviewers.

### Skill file format

```markdown
---
name: Security Reviewer
perspective: Application security and vulnerability prevention
---

Focus on:
- Input validation and sanitization
- Authentication and authorization boundaries
- Secret handling (no hardcoded credentials)
- SQL injection, XSS, CSRF, path traversal
- Dependency vulnerabilities (known CVEs)

Severity guide:
- Critical: exploitable vulnerability, credential leak
- High: missing auth check, unsanitized user input
- Medium: missing rate limiting, overly permissive CORS
- Low: informational security best practices
```

**Required frontmatter:**
- `name` — Reviewer display name
- `perspective` — One-line description of the review angle

**Body:** Freeform instructions — what to look for, what to flag, severity guidance, domain rules. This becomes the reviewer's system prompt.

### Adding new reviewers

Drop a new `.md` file into `.lazyspeckit/reviewers/` with a unique `name`. It runs as an additional reviewer alongside the defaults. There is no limit on how many you can add.

---

## Agency Integration

LazySpecKit uses [Agency](https://github.com/msitarzewski/agency-agents) — a curated collection of specialized AI agent definitions — as the **default source** for five of its seven reviewers. During `init` and `upgrade`, these reviewer files are downloaded directly from the Agency GitHub repository. No local Agency installation is required.

If you *do* have Agency installed locally (`~/.claude/agents/` or `~/.github/agents/`), LazySpecKit auto-detects it during `init` and **symlinks** the matching agents instead — so updates to your local Agency installation flow into LazySpecKit automatically.

### Agent-to-reviewer mapping

| Agency agent | LazySpecKit reviewer |
|---|---|
| `testing/testing-reality-checker.md` | `spec-compliance.md` |
| `engineering/engineering-security-engineer.md` | `security.md` |
| `testing/testing-performance-benchmarker.md` | `performance.md` |
| `testing/testing-accessibility-auditor.md` | `accessibility.md` |
| `engineering/engineering-backend-architect.md` | `architecture.md` |

The remaining two reviewers (`code-quality.md`, `test.md`) are LazySpecKit originals with no Agency equivalent.

### Default behavior — download from Agency repo

Running `init` or `upgrade` downloads the five mapped reviewers from the Agency GitHub repository and injects a no-interaction header so they work as review-only agents:

```bash
lazyspeckit init --here --ai copilot
```

This requires no local Agency installation — reviewer content is fetched from `https://github.com/msitarzewski/agency-agents`.

### Local Agency override

If Agency is installed locally, LazySpecKit auto-detects it and symlinks the matching agents as reviewers instead of downloading them. Updates to your local Agency installation are reflected automatically.

Override the detection path with `--agency-path`:

```bash
lazyspeckit init --here --ai copilot --agency-path ~/my-agents
```

To skip local Agency auto-detection (downloaded defaults are still used):

```bash
lazyspeckit init --here --ai copilot --no-agency
```

### Add individual Agency agents

Use `add-reviewer` to import a specific Agency agent as a reviewer at any time:

```bash
# Import the accessibility auditor
lazyspeckit add-reviewer --from-agency testing/testing-accessibility-auditor.md

# Import with a custom name
lazyspeckit add-reviewer --from-agency testing-reality-checker --as my-spec-checker.md
```

The agent file is **copied** (not symlinked) with the no-interaction enforcement header injected after its YAML frontmatter. This makes it safe to further customize without affecting the upstream Agency agent.

### How it works

- **`init` / `upgrade`** download Agency reviewers from the GitHub repo by default. A no-interaction header is injected after the YAML frontmatter so the agents produce findings only.
- If a **local Agency installation** is detected, `init` creates **symlinks** instead — the local agent files become the single source of truth.
- **`add-reviewer --from-agency`** creates a **copy** with the no-interaction header injected — safe to edit independently.
- Both approaches work on macOS, Linux, and Windows. On platforms where symlinks aren't supported, LazySpecKit falls back to copying with a warning.
- Existing user-customized reviewers (files you've edited manually) are never overwritten.
- Use `--no-agency` during `init` to skip local Agency symlink overlay (downloaded defaults are still installed).

---

## Supported AI Agents

All agents use the `--ai` flag. Use `--ai all` to install for every supported agent at once. `upgrade` auto-detects installed agents from the directory structure.

| Agent | Flag | Prompt location | Notes |
|-------|------|----------------|-------|
| VS Code Copilot | `--ai copilot` | `.github/prompts/LazySpecKit.prompt.md` | If `/LazySpecKit` doesn't appear, run **Developer: Reload Window** |
| Claude Code | `--ai claude` | `.claude/commands/LazySpecKit.md` | Restart your session or reopen the repo if the command doesn't appear |
| Cursor | `--ai cursor` | `.cursor/rules/lazyspeckit.mdc` | MDC format with YAML frontmatter (`alwaysApply: false`) |
| OpenCode | `--ai opencode` | `.opencode/agent/LazySpecKit.md` | Standard Markdown agent file |

Copilot and Claude are **primary agents** — they drive the full SpecKit lifecycle (specify, plan, implement, validate). Cursor and OpenCode receive the same prompt file so you can use `/LazySpecKit` there too, but SpecKit project setup (`specify init`) is tied to Copilot or Claude.


---

## CLI Reference

### `lazyspeckit init`

Initializes SpecKit and installs LazySpecKit prompts into a repository.
All flags are passed through to `specify init`.

```bash
lazyspeckit init --here --ai copilot
lazyspeckit init ./my-repo --ai claude
```

With [Agency](https://github.com/msitarzewski/agency-agents) installed locally, reviewers are automatically symlinked from your Agency installation instead of using the downloaded defaults (see [Agency Integration](#agency-integration)):

```bash
lazyspeckit init --here --ai copilot --agency-path ~/my-agents
```

To skip local Agency auto-detection (downloaded defaults are still used):

```bash
lazyspeckit init --here --ai copilot --no-agency
```

To skip architecture documentation setup:

```bash
lazyspeckit init --here --ai copilot --no-architecture
```

Additional agents (Cursor, OpenCode) can be added with repeatable `--ai` flags:

```bash
# Also install for Cursor
lazyspeckit init --here --ai copilot --ai cursor

# Also install for OpenCode
lazyspeckit init --here --ai copilot --ai opencode

# Install for all supported agents at once
lazyspeckit init --here --ai all

# Combine any agents
lazyspeckit init --here --ai copilot --ai cursor --ai opencode
```

### `lazyspeckit upgrade`

Upgrades everything in a repository:
- SpecKit CLI (`specify-cli`)
- SpecKit project files (slash commands / templates)
- LazySpecKit prompts
- Reviewer skill files (Agency-sourced and LazySpecKit originals)

Auto-detects which AI agents are configured. If both VS Code and Claude are present, it upgrades both. You can also target one explicitly with `--ai`.

If a local Agency installation is detected, matching reviewers are symlinked. Otherwise, the latest Agency reviewer files are downloaded from the Agency repository.

SpecKit upgrade failures are non-fatal — LazySpecKit prompts and reviewers are always updated even if SpecKit has issues.

```bash
# Auto-detect (upgrades all detected agents)
lazyspeckit upgrade --here

# Explicit
lazyspeckit upgrade --here --ai copilot
lazyspeckit upgrade ./my-repo --ai claude

# Also upgrade a specific extra agent
lazyspeckit upgrade --here --ai copilot --ai cursor
```

`upgrade` auto-detects installed agents: if a `.cursor/` or `.opencode/` directory exists in the repo, the corresponding prompt is updated automatically.

### `lazyspeckit doctor`

Shows diagnostics: versions, tools, SpecKit init status, prompt file presence. Makes no changes.

```bash
lazyspeckit doctor --here
```

### `lazyspeckit self-update`

Updates the `lazyspeckit` CLI itself and the SpecKit CLI.

```bash
lazyspeckit self-update
```

### `lazyspeckit version`

Shows local and remote CLI versions.

```bash
lazyspeckit version
```

### `lazyspeckit add-reviewer`

Adds an [Agency](https://github.com/msitarzewski/agency-agents) agent as a LazySpecKit reviewer. The agent file is copied into `.lazyspeckit/reviewers/` with the no-interaction enforcement header injected automatically.

```bash
# Add by full path
lazyspeckit add-reviewer --from-agency testing/testing-reality-checker.md

# Add by basename (auto-discovered)
lazyspeckit add-reviewer --from-agency testing-performance-benchmarker

# Override the installed reviewer name
lazyspeckit add-reviewer --from-agency testing-reality-checker --as spec-checker.md

# Custom Agency install location
lazyspeckit add-reviewer --from-agency engineering-security-engineer --agency-path ~/agents

# Overwrite an existing reviewer
lazyspeckit add-reviewer --from-agency testing-reality-checker --force
```

| Flag | Description |
|------|-------------|
| `--from-agency <name>` | Agency agent name or path (e.g., `testing/testing-reality-checker.md`) |
| `--as <name>` | Override the installed reviewer filename |
| `--agency-path <dir>` | Override Agency install location (default: `~/.claude/agents/` or `~/.github/agents/`) |
| `--force` | Overwrite an existing reviewer |

### `lazyspeckit --help`

Shows all commands and examples.

### `lazyspeckit architecture:init`

Creates `.docs/architecture/` with core template files, example service/app/library docs, and directory structure. Never overwrites existing files.

```bash
lazyspeckit architecture:init --here
lazyspeckit architecture:init ./my-repo
```

### `lazyspeckit architecture:check`

Scans the project and reports architecture documentation status — documented services, apps, libraries, integrations, and decisions. Suggests project directories that lack documentation.

```bash
lazyspeckit architecture:check --here
```

Runs automatically during `lazyspeckit upgrade` and `lazyspeckit doctor` if architecture docs exist.

> **Note:** `architecture:sync` is accepted as an alias for backward compatibility.

### `lazyspeckit architecture:show`

Displays architecture documentation status — core files, services, apps, libraries, integrations, and decisions with document counts.

```bash
lazyspeckit architecture:show --here
```

---

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LAZYSPECKIT_REF` | `main` | Pin downloads to a specific branch, tag, or commit SHA |
| `DEBUG` | `0` | Set to `1` to enable bash trace output |
| `NO_COLOR` | *(unset)* | Set to `1` to disable colored output |
| `BIN_DIR` | `~/.local/bin` | Override install location (`install.sh` only) |

**Pin to a specific release:**

```bash
# Install a specific version
LAZYSPECKIT_REF=v0.8.4 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Hacklone/lazy-spec-kit/v0.8.4/install.sh)"

# Self-update to a specific version
LAZYSPECKIT_REF=v0.8.4 lazyspeckit self-update
```

---

## Troubleshooting

### `lazyspeckit: command not found`

The install directory isn't on your `PATH`. Add this to `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then restart your terminal. On Windows Git Bash, the default install directory is `~/bin`.

### `/LazySpecKit` doesn't appear in VS Code

Run **Developer: Reload Window** (`Cmd+Shift+P` or `Ctrl+Shift+P` → type "Reload Window").

### `/LazySpecKit` doesn't appear in Claude Code

Restart your Claude Code session or reopen the repository folder.

### `uv` or `uvx` not found

LazySpecKit installs [uv](https://docs.astral.sh/uv/) automatically on first run. If auto-install fails:

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
winget install --id Astral.Uv -e
```

### Windows: `winget` not found from Git Bash

Package managers like `winget` aren't available inside Git Bash. Run the install command in **PowerShell** instead, then restart Git Bash.

### Something else is broken

Run diagnostics:

```bash
lazyspeckit doctor --here
```

For full debug output:

```bash
DEBUG=1 lazyspeckit doctor --here
```

---

## FAQ

### What is a constitution and what should I put in it?

A constitution is a short project description that tells SpecKit about your tech stack, coding conventions, testing setup, and constraints. It's created once per project (on first run) and reused for every future spec. See [What is a Constitution?](#what-is-a-constitution) for details and examples.

### Why does `upgrade` run `specify init --force`?

That's how SpecKit refreshes its project files (slash commands, templates). LazySpecKit automatically backs up and restores your constitution and custom templates before and after the init.

### What does LazySpecKit back up during upgrade?

- `.specify/memory/constitution.md` — your constitution
- `.specify/templates/` — your custom templates

These are restored after `specify init --force` completes.

### Can I use LazySpecKit with both Copilot and Claude in the same repo?

Yes. `lazyspeckit init` and `lazyspeckit upgrade` install prompts for both agents. The prompt content is identical — only the file location differs.

### Does LazySpecKit modify my source code?

The CLI only manages SpecKit configuration files and LazySpecKit prompt files. It never touches your source code. The `/LazySpecKit` prompt *does* generate and modify source code as part of the SpecKit implementation phase — that's the whole point.

### What does `--auto-clarify` do?

It lets the agent auto-select recommended answers for clarification questions when it's confident (High or Medium). Only genuinely ambiguous (Low confidence) questions are presented to you. If all questions are High/Medium, you never interact at all — spec in, finished code out.

### Is `--auto-clarify` safe?

Yes. Each recommendation includes a confidence level. High-confidence answers follow clear best practices or strong repo signals. Medium answers reflect reasonable trade-offs. Only Low-confidence (genuinely ambiguous) items are escalated to you. You can always override by answering manually instead.

### What does `--max-review-loops` do?

It controls how many review/fix iterations the Review & Refine phase will run (default: 6). Lower values like `--max-review-loops=2` give faster runs with fewer refinement passes. Higher values allow more thorough convergence.

### Where are run audit logs?

After each run, LazySpecKit writes a JSON audit log to `.lazyspeckit/runs/<timestamp>.json`. It records which phases ran, how many tasks were generated, review findings and fixes, validation results, and the final outcome. Useful for debugging, retrospectives, and tracking how the tool performs over time.

### What does LazySpecKit respect from my repo?

LazySpecKit respects `agents.md` governance files. A root-level `agents.md` applies to the entire repo; nested ones apply to their directory and subdirectories. These rules are enforced across all phases. During implementation, LazySpecKit also **creates** scoped `agents.md` files if they're missing — at the root and for immediate subdirectories that contain generated code — so future runs (and other AI agents) benefit from documented project conventions.

### What is `.docs/architecture/` and do I need it?

`.docs/architecture/` contains your project's architecture documentation — services, apps, libraries, principles, and integration patterns. It's created automatically during `lazyspeckit init` and enables architecture-aware spec generation. Without it, LazySpecKit still works but treats each spec in isolation. With it, specs reuse existing services, respect service boundaries, and create reusable components. See [Architecture Context Awareness](#architecture-context-awareness).

### How do I skip architecture documentation?

Use `--no-architecture` during init:

```bash
lazyspeckit init --here --ai copilot --no-architecture
```

Or add `--no-architecture` to the `/LazySpecKit` prompt invocation to skip architecture context loading and the architecture update phase for a specific run.

### How do architecture docs stay up to date?

LazySpecKit automatically updates architecture docs at the end of every run (Phase 9 — Architecture Update). New services, apps, libraries, and integration points are reflected in the docs. Architecture Decision Records (ADRs) are created for significant decisions. Running `lazyspeckit architecture:check` or `lazyspeckit upgrade` also checks for gaps.

### What is Agency and how does it integrate with LazySpecKit?

[Agency](https://github.com/msitarzewski/agency-agents) is a curated collection of specialized AI agent definitions. LazySpecKit uses Agency as the **default source** for five of its seven reviewers — they are downloaded from the Agency GitHub repository during `init` and `upgrade`. No local Agency installation is required. If you *do* have Agency installed locally, `init` auto-detects it and symlinks the matching agents instead, so local updates flow in automatically. Use `lazyspeckit add-reviewer --from-agency` to import additional agents. See [Agency Integration](#agency-integration) for details.

### How is LazySpecKit different from OpenSpec?

Both tools care about spec-driven development — but they solve different problems.

**OpenSpec** focuses on structured, versioned specification workflows. It helps teams define, validate, and manage changes through explicit spec artifacts and proposal flows.

**LazySpecKit** focuses on automated execution and convergence to green.

Here is the practical difference:

| Feature | OpenSpec | LazySpecKit |
|----------|----------|-------------|
| Spec management & proposal workflow | ✔️ | Inherits from SpecKit |
| Structured validation of specs | ✔️ | ✔️ (via `/speckit.analyze` + auto-fix) |
| Fully automated end-to-end lifecycle | ❌ | ✔️ |
| Deterministic phase gates (must pass before next phase) | ❌ | ✔️ |
| Auto-clarify with recommendation + confidence | ❌ | ✔️ |
| Hands-off mode (`--auto-clarify`) | ❌ | ✔️ |
| Multi-agent autonomous review loop | ❌ | ✔️ (7 agents, parallel) |
| Auto-fix review findings | ❌ | ✔️ |
| Security & performance review | ❌ | ✔️ (dedicated agents) |
| Configurable review iterations (`--max-review-loops`) | ❌ | ✔️ |
| Run audit log | ❌ | ✔️ (`.lazyspeckit/runs/`) |
| Guaranteed final validation before completion | ❌ | ✔️ |

**In short:**

- **OpenSpec** is about making specs explicit and collaborative.
- **LazySpecKit** is about taking a spec and autonomously driving it to validated, reviewed, green code — without babysitting.

They are complementary philosophies, but LazySpecKit’s differentiator is automation depth and post-implementation refinement.

---

## Uninstall

**Remove the CLI:**

```bash
# macOS / Linux (default location)
rm ~/.local/bin/lazyspeckit

# Windows Git Bash (default location)
rm ~/bin/lazyspeckit
```

**Remove prompts from a repo:**

```bash
rm .github/prompts/LazySpecKit.prompt.md
rm .claude/commands/LazySpecKit.md
rm .cursor/rules/lazyspeckit.mdc
rm .opencode/agent/LazySpecKit.md
```

---

## License

MIT
