# Claude Memory Compiler

Automatically captures your Claude Code conversations into daily logs, compiles them into a searchable knowledge base, and injects that knowledge back into future sessions.

Based on [coleam00/claude-memory-compiler](https://github.com/coleam00/claude-memory-compiler) (Karpathy's LLM Knowledge Base architecture). **No external downloads, no pip installs, no uv — pure Python 3.12+ stdlib for all hooks.**

## How It Works

```
┌──────────────────────────────────────────────────────────────┐
│  Session Start                                                │
│  Hook reads knowledge/index.md + meta-instructions +         │
│  latest daily log → Injects as context so Claude "remembers" │
├──────────────────────────────────────────────────────────────┤
│  During Session                                               │
│  You work normally. PreCompact hook fires before              │
│  auto-compaction to capture context that would be lost.       │
│  Run /compile-kb anytime to checkpoint knowledge.             │
├──────────────────────────────────────────────────────────────┤
│  Session End                                                  │
│  Hook extracts conversation transcript                        │
│  → flush.py appends structured context to daily/YYYY-MM-DD.md│
├──────────────────────────────────────────────────────────────┤
│  Compilation (via /compile-kb command)                        │
│  Extracts: concepts, decisions, patterns, dead ends,         │
│  meta-instructions → knowledge/ articles                     │
│  Run early, run often — every call is a checkpoint.          │
└──────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Python 3.12+ (check: `python3.13 --version`)
- Claude Code

### Option 1: Ask Claude Code (Recommended)

Open Claude Code in your project and paste this prompt:

```
Clone https://github.com/jackandjac/claude-memory-compiler.git to a temp
directory, then run its setup.sh from my project root. This sets up Claude Code hooks so my
conversations automatically get captured into daily logs, compiled into a knowledge base, and
injected back into future sessions. Read the AGENTS.md for the full technical reference.
```

Claude Code will clone the repo, run setup, and configure everything for you.

### Option 2: Slash Command (One Command)

If you have the `/setup-memory-compiler` command installed, just type:

```
/setup-memory-compiler
```

### Option 3: Manual Setup

```bash
# Clone this repo (one-time)
git clone https://github.com/jackandjac/claude-memory-compiler.git

# Go to your project
cd /path/to/your-project

# Run setup
bash /path/to/claude-memory-compiler/setup.sh
```

All three options do the same thing — the setup script:
1. Copies hooks + scripts into `.claude-memory-compiler/` in your project
2. Installs the `/compile-kb` slash command into `.claude/commands/`
3. Creates the full directory structure (`daily/`, `knowledge/concepts/`, `knowledge/decisions/`, `knowledge/patterns/`, `knowledge/connections/`, `knowledge/qa/`, `reports/`)
4. Bootstraps `knowledge/index.md`, `knowledge/log.md`, and `knowledge/meta-instructions.md`
5. Merges hook config into your `.claude/settings.json` (preserves existing hooks)
6. Adds `.claude-memory-compiler/` to your `.gitignore`

### Start Using It

Just start a new Claude Code session. The hooks activate automatically:
- **SessionStart** — knowledge base injected into context
- **PreCompact** — conversation captured before auto-compaction
- **SessionEnd** — conversation captured to daily log

Check it's working:
```bash
# After a session ends, check the daily log
cat .claude-memory-compiler/daily/$(date +%Y-%m-%d).md

# Check the debug log
cat .claude-memory-compiler/scripts/flush.log
```

## Directory Structure

```
your-project/
├── .claude-memory-compiler/        # ← all memory compiler files live here
│   ├── AGENTS.md                   # Schema reference (for LLM compilation)
│   ├── hooks/
│   │   ├── session-start.py        # Injects KB context at session start
│   │   ├── session-end.py          # Captures transcript at session end
│   │   └── pre-compact.py          # Captures before auto-compaction
│   ├── scripts/
│   │   ├── flush.py                # Appends conversation to daily log
│   │   ├── compile.py              # Compiles daily logs → knowledge articles
│   │   ├── query.py                # Query the knowledge base
│   │   ├── lint.py                 # Health checks
│   │   ├── config.py               # Path constants
│   │   └── utils.py                # Shared helpers
│   ├── daily/                      # Auto-populated conversation logs
│   │   ├── 2026-04-15.md
│   │   └── ...
│   ├── knowledge/                  # Compiled knowledge base
│   │   ├── index.md                # Master catalog (sectioned by type)
│   │   ├── log.md                  # Build log
│   │   ├── meta-instructions.md    # Living doc of conventions & rules
│   │   ├── concepts/               # WHAT — technical facts & configs
│   │   ├── decisions/              # WHY — choices + rejected alternatives
│   │   ├── patterns/               # HOW — reusable approaches & anti-patterns
│   │   ├── connections/            # Cross-cutting insights
│   │   └── qa/                     # Filed Q&A
│   └── reports/                    # Lint reports
├── .claude/
│   ├── commands/
│   │   └── compile-kb.md           # ← /compile-kb slash command
│   └── settings.json               # ← hooks configured here
└── .gitignore                      # ← .claude-memory-compiler/ excluded
```

## Compilation (`/compile-kb`)

The automatic capture pipeline (hooks → flush.py → daily log) works with pure Python and requires zero external dependencies. The **compilation step** uses the `/compile-kb` Claude Code slash command.

### Incremental Save (Default)

Run anytime during a session to checkpoint knowledge:

```
/compile-kb
```

This extracts knowledge directly from the **current conversation** — not from daily logs. The daily log entry is written as a side effect (audit trail). Run early, run often — every call is a safe checkpoint. Multiple invocations per session are idempotent.

**What it extracts (in priority order):**
1. **Decisions** — choices between alternatives, with full rationale and rejected paths
2. **Dead ends** — what was tried and failed (prevents re-exploration)
3. **Meta-instructions** — conventions, preferences, rules that persist across sessions
4. **Patterns** — reusable approaches, anti-patterns, debugging heuristics
5. **Concepts** — technical facts, configs, API behaviors (enhanced with Reasoning & Dead Ends sections)

### Daily Log Compilation (with date argument)

Compile from previously saved daily logs — useful for batch processing or recompiling old sessions:

```
/compile-kb 2026-04-15       # compile a specific day
/compile-kb --all            # compile all uncompiled logs
```

### Skip Compilation

The daily logs alone are valuable. SessionStart injects the latest daily log into context, so Claude already "remembers" recent sessions even without compilation.

## Knowledge Types

| Type | Directory | What Gets Captured |
|------|-----------|-------------------|
| **Concepts** | `knowledge/concepts/` | Technical facts, configurations, API behaviors |
| **Decisions** | `knowledge/decisions/` | Choices between alternatives with full rationale |
| **Patterns** | `knowledge/patterns/` | Reusable approaches, anti-patterns, debugging heuristics |
| **Connections** | `knowledge/connections/` | Non-obvious links between 2+ concepts |
| **Meta-Instructions** | `knowledge/meta-instructions.md` | Living doc of conventions, preferences, behavioral rules |

## Upgrading from v1

If you already have a v1 installation (before the `decisions/`, `patterns/`, and `meta-instructions` additions), run the upgrade script from your project root:

```bash
bash /path/to/claude-memory-compiler/upgrade.sh
```

The upgrade:
- Creates `knowledge/decisions/` and `knowledge/patterns/` directories
- Bootstraps `knowledge/meta-instructions.md`
- Migrates `index.md` to the new sectioned format (preserves existing entries)
- Installs the enhanced `/compile-kb` v2 command (backs up the old one)

Safe to run multiple times — won't overwrite existing content.

## Troubleshooting

### Hooks not firing?
- Check `.claude/settings.json` has the `SessionStart`, `SessionEnd`, `PreCompact` entries
- Check the Python path: `which python3.13`
- Start a **new** session (hooks only activate on new sessions)

### Daily logs empty?
- Check flush.log: `cat .claude-memory-compiler/scripts/flush.log`
- Common: "SKIP: transcript missing" means the transcript path wasn't passed by Claude Code

### Python not found?
- The setup script searches for `python3.13`, `python3.12`, `python3` in PATH
- Falls back to `/opt/homebrew/bin/python3.13` on macOS
- If neither works, install Python 3.12+ and re-run setup

## Credits

Based on [coleam00/claude-memory-compiler](https://github.com/coleam00/claude-memory-compiler), inspired by [Andrej Karpathy's LLM Knowledge Base](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) architecture.
