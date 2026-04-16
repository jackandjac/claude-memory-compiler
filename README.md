# Claude Memory Compiler — Walmart Edition

Automatically captures your Wibey/Claude Code conversations into daily logs, compiles them into a searchable knowledge base, and injects that knowledge back into future sessions.

Adapted from [coleam00/claude-memory-compiler](https://github.com/coleam00/claude-memory-compiler) (Karpathy's LLM Knowledge Base architecture) for the Walmart network — **no external downloads, no pip installs, no uv, pure Python 3.12+ stdlib**.

## How It Works

```
┌──────────────────────────────────────────────────────────────┐
│  Session Start                                                │
│  Hook reads knowledge/index.md + latest daily log            │
│  → Injects as context so Claude "remembers" past sessions    │
├──────────────────────────────────────────────────────────────┤
│  During Session                                               │
│  You work normally. PreCompact hook fires before              │
│  auto-compaction to capture context that would be lost.       │
├──────────────────────────────────────────────────────────────┤
│  Session End                                                  │
│  Hook extracts conversation transcript                        │
│  → flush.py appends structured context to daily/YYYY-MM-DD.md│
├──────────────────────────────────────────────────────────────┤
│  Compilation (via /compile-kb command)                        │
│  daily/ logs → Wibey compiler → knowledge/ articles          │
│  Structured, cross-referenced, searchable knowledge base     │
└──────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Python 3.12+ (check: `python3.13 --version` or `/opt/homebrew/bin/python3.13 --version`)
- Wibey CLI or Claude Code

### Install into Your Project

```bash
# Clone this repo (one-time, from GEC GitHub)
git clone https://gecgithub01.walmart.com/j0l0xg5/claude-memory-compiler-walmart.git

# Go to your project
cd /path/to/your-project

# Run setup
bash /path/to/claude-memory-compiler-walmart/setup.sh
```

The setup script:
1. Copies hooks + scripts into `.claude-memory-compiler/` in your project
2. Installs the `/compile-kb` slash command into `.wibey/commands/`
3. Creates the `daily/`, `knowledge/`, `reports/` directory structure
4. Merges hook config into your `.claude/settings.json` (preserves existing hooks)
5. Adds `.claude-memory-compiler/` to your `.gitignore`

### Start Using It

Just start a new Wibey session. The hooks activate automatically:
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
│   │   ├── index.md                # Master catalog (read first)
│   │   ├── log.md                  # Build log
│   │   ├── concepts/               # Atomic knowledge articles
│   │   ├── connections/            # Cross-cutting insights
│   │   └── qa/                     # Filed Q&A
│   └── reports/                    # Lint reports
├── .claude/
│   └── settings.json               # ← hooks configured here
└── .gitignore                      # ← .claude-memory-compiler/ excluded
```

## Compilation (Daily Logs → Knowledge Base)

The automatic capture pipeline (hooks → flush.py → daily log) works with pure Python and requires zero external dependencies. The **compilation step** (daily logs → structured knowledge articles) uses the `/compile-kb` Wibey slash command — no VPN disconnect, no pip installs, no external tools needed.

### Option 1: `/compile-kb` Slash Command (Recommended)

The setup script automatically installs a `/compile-kb` slash command into your project. Just run it in any Wibey session:

```
/compile-kb
```

This tells Wibey to:
1. Read the `AGENTS.md` schema for knowledge article structure
2. Scan `daily/` logs for unprocessed entries
3. Extract concepts, decisions, patterns, and Q&A
4. Create/update knowledge articles in `knowledge/concepts/`, `knowledge/connections/`, `knowledge/qa/`
5. Update `knowledge/index.md` (master catalog) and `knowledge/log.md` (build log)

All compilation happens in-session using Wibey's built-in Read/Write/Edit tools — no external dependencies.

### Option 2: Ask Wibey Directly

You can also just ask Wibey in plain English:

```
Compile my daily logs into knowledge articles. Read .claude-memory-compiler/AGENTS.md
for the schema, then process any new entries in .claude-memory-compiler/daily/.
```

### Option 3: Skip Compilation

The daily logs alone are valuable. SessionStart injects the latest daily log into context, so Claude already "remembers" recent sessions even without compilation.

## Walmart Network Adaptations

| Original | Walmart Edition | Why |
|----------|----------------|-----|
| `uv run python` | `/opt/homebrew/bin/python3.13` | Can't install uv via curl (network blocked) |
| `claude-agent-sdk` in flush.py | Pure Python stdlib | Can't pip install from PyPI (whl blocked) |
| `pip install` dependencies | Zero dependencies | All hooks + flush use stdlib only |
| Background LLM flush | Direct transcript append | No agent SDK → no LLM summarization in flush |

The hooks auto-detect Python 3.12+ from PATH or `/opt/homebrew/bin/`.

## Troubleshooting

### Hooks not firing?
- Check `.claude/settings.json` has the `SessionStart`, `SessionEnd`, `PreCompact` entries
- Check the Python path: `which python3.13` or `/opt/homebrew/bin/python3.13 --version`
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
