<p align="center">
  <img src="media/logo.webp" alt="LazySpecKit" width="200">
</p>

<h1 align="center">LazySpecKit ⚡</h1>

<p align="center">
  <strong>SpecKit without babysitting — plus multi-agent review & auto-fix.</strong><br>
  Write your spec. Answer clarification questions. Everything else — including a multi-perspective review that finds AND fixes issues — runs automatically.
</p>

<p align="center">
  <a href="#install"><img src="https://img.shields.io/badge/Install-blue?style=flat-square" alt="Install"></a>
  <a href="#quick-start"><img src="https://img.shields.io/badge/Quick%20Start-blue?style=flat-square" alt="Quick Start"></a>
  <a href="https://hacklone.github.io/lazy-spec-kit/"><img src="https://img.shields.io/badge/Docs-blue?style=flat-square" alt="Documentation"></a>
  <a href="https://github.com/Hacklone/lazy-spec-kit/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License"></a>
</p>

---

LazySpecKit goes beyond wrapping [GitHub SpecKit](https://github.com/github/spec-kit). It orchestrates the entire workflow — from constitution setup through implementation and validation — and then launches its own **Review & Refine** phase: four specialized AI agents, each approaching the code from a different perspective (architecture, code quality, spec compliance, tests), that don't just *review* but **automatically fix** the issues they find. You focus on *what* to build; LazySpecKit handles *how* and iterates until the result is solid.

```
/LazySpecKit Add OAuth login with GitHub and Google. Store users in Postgres. Add tests.
```

> Sit back, enjoy a coffee ☕, and let LazySpecKit handle the rest — including a multi-agent review that fixes what it finds.

---

## Table of Contents

- [Install](#install)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Review & Refine — What Makes LazySpecKit Different](#review--refine--what-makes-lazyspeckit-different)
- [CLI Reference](#cli-reference)
- [Supported AI Agents](#supported-ai-agents)
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

Optionally disable the post-implementation multi-agent review & refinement:

```
/LazySpecKit --review=off <your spec here>
```

That's it. LazySpecKit takes over from there — implementation, validation, and (by default) a multi-agent review that fixes issues automatically.

---

## How It Works

When you run `/LazySpecKit <spec>`, it orchestrates the full SpecKit lifecycle automatically:

| Phase | What happens | User input needed? |
|-------|-------------|-------------------|
| **Constitution** | Checks for an existing constitution; asks you to provide one if missing | Only if missing |
| **Specify** | Runs `/speckit.specify` with your spec text | No |
| **Clarify** | Presents clarification questions | **Yes — answer once** |
| **Plan** | Generates implementation plan | No |
| **Tasks** | Breaks plan into sequential tasks | No |
| **Quality Gates** | Runs `/speckit.checklist` + `/speckit.analyze`, auto-fixes spec issues | No |
| **Implement** | Executes tasks in a fresh session | No |
| **Validate** | Runs detected lint / typecheck / tests / build | No |
| **Review & Refine** | Four AI agents review from different perspectives — architecture, quality, spec compliance, tests — and **auto-fix** findings (up to 3 loops) | No |
| **Final Validation** | Full validation suite re-run to guarantee green before completion | No |

**You only interact during Constitution (if missing) and Clarify.** Everything else — including multi-agent review and automatic code refinement — is fully automated.

If something goes wrong, LazySpecKit retries up to 3 times, then stops with a clear blocker message — it never silently continues in a broken state.

---

## Review & Refine — What Makes LazySpecKit Different

SpecKit stops after implementation and validation. **LazySpecKit keeps going.**

This isn't a single-pass code review. After SpecKit's work is done, LazySpecKit spawns **four independent AI agents** — each with fresh context and a distinct perspective — that **review the code AND fix what they find**:

| Agent | Perspective | What it catches & fixes |
|-------|-------------|------------------------|
| **Architecture Reviewer** | System design | Poor structure, tangled dependencies, wrong abstraction boundaries |
| **Code Quality Reviewer** | Engineering craft | Bad idioms, missing error handling, duplication, readability issues |
| **Spec Compliance Reviewer** | Requirements | Missing or incorrectly implemented spec requirements |
| **Test Reviewer** | QA | Gaps in coverage, fragile tests, missing edge cases |

### Review, fix, verify — automatically

1. All four agents analyze the changes from their perspective and produce findings (Critical / High / Medium / Low).
2. LazySpecKit **automatically fixes** all Critical and High issues, plus low-effort Medium ones — this is refinement, not just reporting.
3. Validation (lint / typecheck / tests / build) re-runs to confirm the fixes didn't break anything.
4. The agents review again — up to **3 loops total** — until no Critical or High findings remain.
5. A **final validation gate** ensures everything is green before completion.

If a finding can't be resolved safely, LazySpecKit stops and tells you exactly what needs attention — it never ships broken code.

### Why this matters

- **Multiple perspectives** — Four agents catch different classes of problems that a single reviewer would miss.
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

> **Bottom line:** With plain SpecKit, you implement and hope for the best. With LazySpecKit, four agents — each with a different perspective — review your code, fix what's wrong, and verify the result. You get reviewed, refined, validated code without lifting a finger.

---

## CLI Reference

### `lazyspeckit init`

Initializes SpecKit and installs LazySpecKit prompts into a repository.
All flags are passed through to `specify init`.

```bash
lazyspeckit init --here --ai copilot
lazyspeckit init ./my-repo --ai claude
```

### `lazyspeckit upgrade`

Upgrades everything in a repository:
- SpecKit CLI (`specify-cli`)
- SpecKit project files (slash commands / templates)
- LazySpecKit prompts

Auto-detects which AI agents are configured. If both VS Code and Claude are present, it upgrades both. You can also target one explicitly with `--ai`.

SpecKit upgrade failures are non-fatal — LazySpecKit prompts are always updated even if SpecKit has issues.

```bash
# Auto-detect (upgrades all detected agents)
lazyspeckit upgrade --here

# Explicit
lazyspeckit upgrade --here --ai copilot
lazyspeckit upgrade ./my-repo --ai claude
```

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

### `lazyspeckit --help`

Shows all commands and examples.

---

## Supported AI Agents

| Agent | Flag | Prompt location |
|-------|------|----------------|
| VS Code Copilot | `--ai copilot` | `.github/prompts/LazySpecKit.prompt.md` |
| Claude Code | `--ai claude` | `.claude/commands/LazySpecKit.md` |

Both prompts are installed from the same source. If your repo has both `.vscode`/`.github/prompts` and `.claude` directories, `upgrade` handles both automatically.

**VS Code users:** If `/LazySpecKit` doesn't appear after init or upgrade, run **Developer: Reload Window** (`Cmd+Shift+P` → "Reload Window").

**Claude Code users:** Restart your session or reopen the repository.

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
LAZYSPECKIT_REF=v0.6.1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Hacklone/lazy-spec-kit/v0.6.1/install.sh)"

# Self-update to a specific version
LAZYSPECKIT_REF=v0.6.1 lazyspeckit self-update
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

### What does LazySpecKit respect from my repo?

LazySpecKit respects `agents.md` governance files. A root-level `agents.md` applies to the entire repo; nested ones apply to their directory and subdirectories. These rules are enforced across all phases.

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
```

---

## License

MIT
