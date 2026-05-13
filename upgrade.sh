#!/bin/bash
# ============================================================================
# Claude Memory Compiler 2.0 — Upgrade Script
#
# Upgrades an existing .claude-memory-compiler installation with:
#   - knowledge/decisions/    (WHY — decision records with rejected alternatives)
#   - knowledge/patterns/     (HOW — reusable approaches and anti-patterns)
#   - knowledge/meta-instructions.md (RULES — living doc of conventions)
#   - Updated index.md format (sectioned by article type)
#   - Enhanced /compile-kb slash command
#
# Run from inside a project that already has .claude-memory-compiler/ installed:
#
#   bash /path/to/claude-memory-compiler/upgrade.sh
#
# Safe to run multiple times — won't overwrite existing content.
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(pwd)"
TARGET_DIR="$PROJECT_DIR/.claude-memory-compiler"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Claude Memory Compiler 2.0 — Upgrade                   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── Check existing installation ──────────────────────────────────────────
if [ ! -d "$TARGET_DIR" ]; then
    echo "  ❌ ERROR: No .claude-memory-compiler/ found in current directory."
    echo "  Run the original setup.sh first, then run this upgrade."
    exit 1
fi

echo "  Found: $TARGET_DIR"
echo ""

# ── Step 1: Create new knowledge directories ─────────────────────────────
echo "▸ Creating new knowledge directories..."

mkdir -p "$TARGET_DIR/knowledge/decisions"
echo "  ✓ knowledge/decisions/"

mkdir -p "$TARGET_DIR/knowledge/patterns"
echo "  ✓ knowledge/patterns/"

# ── Step 2: Bootstrap meta-instructions.md ───────────────────────────────
echo "▸ Setting up meta-instructions..."

if [ ! -f "$TARGET_DIR/knowledge/meta-instructions.md" ]; then
    cp "$SCRIPT_DIR/knowledge-templates/meta-instructions.md" "$TARGET_DIR/knowledge/meta-instructions.md"
    echo "  ✓ Created knowledge/meta-instructions.md"
else
    echo "  ⚠ knowledge/meta-instructions.md already exists — skipping (won't overwrite)"
fi

# ── Step 3: Upgrade index.md format ──────────────────────────────────────
echo "▸ Checking index.md format..."

INDEX_FILE="$TARGET_DIR/knowledge/index.md"
if [ -f "$INDEX_FILE" ]; then
    if grep -q "## Decisions" "$INDEX_FILE" 2>/dev/null; then
        echo "  ✓ index.md already has sectioned format"
    else
        # Check if index has any existing entries
        ENTRY_COUNT=$(grep -c "^\|" "$INDEX_FILE" 2>/dev/null || echo "0")
        if [ "$ENTRY_COUNT" -le 2 ]; then
            # Empty or header-only — safe to replace
            cp "$SCRIPT_DIR/knowledge-templates/index.md" "$INDEX_FILE"
            echo "  ✓ Upgraded index.md to sectioned format (was empty)"
        else
            # Has existing entries — migrate them into Concepts section
            echo "  ⚠ index.md has existing entries — migrating to sectioned format..."

            # Back up the original
            cp "$INDEX_FILE" "${INDEX_FILE}.bak"

            # Extract existing table rows (skip header lines)
            EXISTING_ROWS=$(grep "^\| \[\[" "$INDEX_FILE" 2>/dev/null || echo "")

            # Write new sectioned format with existing entries under Concepts
            cat > "$INDEX_FILE" << 'INDEXEOF'
# Knowledge Base Index

## Concepts

| Article | Summary | Compiled From | Updated |
|---------|---------|---------------|---------|
INDEXEOF

            if [ -n "$EXISTING_ROWS" ]; then
                echo "$EXISTING_ROWS" >> "$INDEX_FILE"
            fi

            cat >> "$INDEX_FILE" << 'INDEXEOF'

## Decisions

| Article | Summary | Compiled From | Updated |
|---------|---------|---------------|---------|

## Patterns

| Article | Summary | Compiled From | Updated |
|---------|---------|---------------|---------|

## Connections

| Article | Summary | Compiled From | Updated |
|---------|---------|---------------|---------|
INDEXEOF
            echo "  ✓ Migrated index.md to sectioned format (backup: index.md.bak)"
        fi
    fi
else
    cp "$SCRIPT_DIR/knowledge-templates/index.md" "$INDEX_FILE"
    echo "  ✓ Created index.md with sectioned format"
fi

# ── Step 4: Upgrade /compile-kb slash command ────────────────────────────
echo "▸ Upgrading /compile-kb command..."

COMMANDS_DIR="$PROJECT_DIR/.claude/commands"
mkdir -p "$COMMANDS_DIR"

if [ -f "$COMMANDS_DIR/compile-kb.md" ]; then
    # Back up existing command
    cp "$COMMANDS_DIR/compile-kb.md" "$COMMANDS_DIR/compile-kb.md.v1.bak"
    echo "  ✓ Backed up existing /compile-kb → compile-kb.md.v1.bak"
fi

cp "$SCRIPT_DIR/commands/compile-kb.md" "$COMMANDS_DIR/compile-kb.md"
echo "  ✓ Installed enhanced /compile-kb command (v2.0)"

# ── Done ─────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅ Upgrade complete!                                    ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║  New knowledge types:                                    ║"
echo "║                                                          ║"
echo "║  decisions/          WHY — choices + rejected alternatives║"
echo "║  patterns/           HOW — reusable techniques           ║"
echo "║  meta-instructions   RULES — living conventions doc      ║"
echo "║                                                          ║"
echo "║  Enhanced /compile-kb now:                                 ║"
echo "║  • Saves incrementally — run anytime, as often as needed ║"
echo "║  • Compiles from conversation context (no daily log dep) ║"
echo "║  • Writes daily log as side effect (audit trail)         ║"
echo "║  • Extracts decision records with reasoning chains       ║"
echo "║  • Captures dead ends and rejected approaches            ║"
echo "║  • Discovers patterns and anti-patterns                  ║"
echo "║  • Accumulates meta-instructions across sessions         ║"
echo "║  • Enhances concepts with Reasoning & Dead Ends sections ║"
echo "║                                                          ║"
echo "║  Usage:                                                  ║"
echo "║    /compile-kb            incremental save (from convo)  ║"
echo "║    /compile-kb 2026-04-15 compile a specific daily log   ║"
echo "║    /compile-kb --all      compile all uncompiled logs    ║"
echo "║                                                          ║"
echo "║  Run /compile-kb in your next Claude Code session.       ║"
echo "╚══════════════════════════════════════════════════════════╝"
