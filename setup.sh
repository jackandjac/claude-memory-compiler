#!/bin/bash
# ============================================================================
# Claude Memory Compiler — Setup Script (Walmart Edition)
#
# Installs the memory compiler into any project directory.
# Run from inside the target project:
#
#   bash /path/to/claude-memory-compiler-walmart/setup.sh
#
# Or clone the repo first, then:
#
#   cd your-project
#   bash ../claude-memory-compiler-walmart/setup.sh
#
# What it does:
#   1. Copies hooks + scripts into .claude-memory-compiler/ in your project
#   2. Creates daily/, knowledge/, reports/ directories
#   3. Merges hook config into your .claude/settings.json
#   4. Adds .claude-memory-compiler/ to your .gitignore
# ============================================================================

set -euo pipefail

# ── Resolve paths ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(pwd)"
TARGET_DIR="$PROJECT_DIR/.claude-memory-compiler"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Claude Memory Compiler — Walmart Edition Setup         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "  Source:  $SCRIPT_DIR"
echo "  Target:  $TARGET_DIR"
echo ""

# ── Find Python 3.12+ ────────────────────────────────────────────────────
PYTHON=""
for candidate in python3.13 python3.12 python3; do
    if command -v "$candidate" &>/dev/null; then
        version=$("$candidate" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0.0")
        major=$(echo "$version" | cut -d. -f1)
        minor=$(echo "$version" | cut -d. -f2)
        if [ "$major" -ge 3 ] && [ "$minor" -ge 12 ]; then
            PYTHON="$(command -v "$candidate")"
            echo "  Python:  $PYTHON (v$version)"
            break
        fi
    fi
done

# Also check common Homebrew path on macOS
if [ -z "$PYTHON" ] && [ -x /opt/homebrew/bin/python3.13 ]; then
    PYTHON="/opt/homebrew/bin/python3.13"
    echo "  Python:  $PYTHON"
elif [ -z "$PYTHON" ] && [ -x /opt/homebrew/bin/python3.12 ]; then
    PYTHON="/opt/homebrew/bin/python3.12"
    echo "  Python:  $PYTHON"
fi

if [ -z "$PYTHON" ]; then
    echo ""
    echo "  ❌ ERROR: Python 3.12+ not found."
    echo "  The hooks require Python 3.12 or later."
    echo "  Check: python3.13 --version  or  /opt/homebrew/bin/python3.13 --version"
    exit 1
fi

echo ""

# ── Step 1: Copy files ───────────────────────────────────────────────────
echo "▸ Copying files..."
mkdir -p "$TARGET_DIR"/{hooks,scripts,knowledge/{concepts,connections,qa},daily,reports}

cp "$SCRIPT_DIR"/hooks/session-start.py  "$TARGET_DIR"/hooks/
cp "$SCRIPT_DIR"/hooks/session-end.py    "$TARGET_DIR"/hooks/
cp "$SCRIPT_DIR"/hooks/pre-compact.py    "$TARGET_DIR"/hooks/
cp "$SCRIPT_DIR"/scripts/flush.py        "$TARGET_DIR"/scripts/
cp "$SCRIPT_DIR"/scripts/config.py       "$TARGET_DIR"/scripts/
cp "$SCRIPT_DIR"/scripts/utils.py        "$TARGET_DIR"/scripts/
cp "$SCRIPT_DIR"/scripts/compile.py      "$TARGET_DIR"/scripts/
cp "$SCRIPT_DIR"/scripts/query.py        "$TARGET_DIR"/scripts/
cp "$SCRIPT_DIR"/scripts/lint.py         "$TARGET_DIR"/scripts/
cp "$SCRIPT_DIR"/AGENTS.md               "$TARGET_DIR"/

# Bootstrap knowledge base structural files (only if they don't exist)
if [ ! -f "$TARGET_DIR/knowledge/index.md" ]; then
    cp "$SCRIPT_DIR"/knowledge/index.md "$TARGET_DIR"/knowledge/
fi
if [ ! -f "$TARGET_DIR/knowledge/log.md" ]; then
    cp "$SCRIPT_DIR"/knowledge/log.md "$TARGET_DIR"/knowledge/
fi

echo "  ✓ Files copied to $TARGET_DIR"

# ── Step 1b: Install /compile-kb slash command ───────────────────────────
echo "▸ Installing /compile-kb slash command..."
COMMANDS_DIR="$PROJECT_DIR/.wibey/commands"
mkdir -p "$COMMANDS_DIR"

if [ -f "$SCRIPT_DIR/commands/compile-kb.md" ]; then
    cp "$SCRIPT_DIR/commands/compile-kb.md" "$COMMANDS_DIR/"
    echo "  ✓ /compile-kb command installed (use it to compile daily logs → knowledge articles)"
else
    echo "  ⚠ commands/compile-kb.md not found in source — skipping"
fi

# ── Step 2: Merge hooks into .claude/settings.json ───────────────────────
echo "▸ Configuring hooks..."
SETTINGS_DIR="$PROJECT_DIR/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
mkdir -p "$SETTINGS_DIR"

# The three hooks to add
HOOK_JSON=$(cat <<HOOKS_EOF
{
  "SessionStart": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "$PYTHON .claude-memory-compiler/hooks/session-start.py",
          "timeout": 15
        }
      ]
    }
  ],
  "PreCompact": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "$PYTHON .claude-memory-compiler/hooks/pre-compact.py",
          "timeout": 10
        }
      ]
    }
  ],
  "SessionEnd": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "$PYTHON .claude-memory-compiler/hooks/session-end.py",
          "timeout": 10
        }
      ]
    }
  ]
}
HOOKS_EOF
)

if [ -f "$SETTINGS_FILE" ]; then
    # Merge new hooks into existing settings.json using Python
    "$PYTHON" -c "
import json, sys

with open('$SETTINGS_FILE', 'r') as f:
    settings = json.load(f)

new_hooks = json.loads('''$HOOK_JSON''')

hooks = settings.setdefault('hooks', {})
for key, value in new_hooks.items():
    if key not in hooks:
        hooks[key] = value
    else:
        print(f'  ⚠ Hook \"{key}\" already exists in settings.json — skipping (won'\''t overwrite)')

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print('  ✓ Hooks merged into existing .claude/settings.json')
"
else
    # Create new settings.json
    "$PYTHON" -c "
import json

new_hooks = json.loads('''$HOOK_JSON''')
settings = {'hooks': new_hooks}

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print('  ✓ Created .claude/settings.json with hooks')
"
fi

# ── Step 3: Update .gitignore ────────────────────────────────────────────
echo "▸ Updating .gitignore..."
GITIGNORE="$PROJECT_DIR/.gitignore"

if [ -f "$GITIGNORE" ]; then
    if grep -q "claude-memory-compiler" "$GITIGNORE" 2>/dev/null; then
        echo "  ✓ .gitignore already has claude-memory-compiler entry"
    else
        echo "" >> "$GITIGNORE"
        echo "# Claude memory compiler (conversation logs + knowledge base)" >> "$GITIGNORE"
        echo ".claude-memory-compiler/" >> "$GITIGNORE"
        echo "  ✓ Added .claude-memory-compiler/ to .gitignore"
    fi
else
    echo "# Claude memory compiler (conversation logs + knowledge base)" > "$GITIGNORE"
    echo ".claude-memory-compiler/" >> "$GITIGNORE"
    echo "  ✓ Created .gitignore with .claude-memory-compiler/ entry"
fi

# ── Done ─────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅ Setup complete!                                      ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║  What happens now:                                       ║"
echo "║                                                          ║"
echo "║  • SessionStart: Injects knowledge base into context     ║"
echo "║  • SessionEnd:   Captures conversation → daily log       ║"
echo "║  • PreCompact:   Saves context before auto-compaction    ║"
echo "║                                                          ║"
echo "║  Daily logs:  .claude-memory-compiler/daily/             ║"
echo "║  Knowledge:   .claude-memory-compiler/knowledge/         ║"
echo "║  Debug log:   .claude-memory-compiler/scripts/flush.log  ║"
echo "║                                                          ║"
echo "║  Start a new Wibey/Claude Code session to activate.      ║"
echo "╚══════════════════════════════════════════════════════════╝"
