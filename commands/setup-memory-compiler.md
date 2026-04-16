---
name: setup-memory-compiler
description: Install the Claude Memory Compiler into the current project — sets up hooks, scripts, and knowledge base structure
---

You are setting up the Claude Memory Compiler in the user's current project. This system automatically captures conversations into daily logs, compiles them into a searchable knowledge base, and injects that knowledge back into future sessions.

## Setup Steps

### 1. Locate the source repo

Check if `claude-memory-compiler-walmart` is already cloned nearby:

```bash
# Check common locations
ls -d ../claude-memory-compiler-walmart 2>/dev/null || \
ls -d ~/IdeaProjects/claude-memory-compiler-walmart 2>/dev/null || \
echo "NOT_FOUND"
```

If not found, clone it to a temp directory:

```bash
TEMP_DIR=$(mktemp -d)
git clone https://gecgithub01.walmart.com/j0l0xg5/claude-memory-compiler-walmart.git "$TEMP_DIR/claude-memory-compiler-walmart"
```

Store the resolved path as `$SOURCE_DIR`.

### 2. Run setup.sh

From the **current project root** (not the cloned repo), run:

```bash
bash "$SOURCE_DIR/setup.sh"
```

This will:
- Copy hooks + scripts into `.claude-memory-compiler/`
- Install the `/compile-kb` slash command into `.wibey/commands/`
- Create `daily/`, `knowledge/`, `reports/` directories
- Merge hook config into `.claude/settings.json`
- Add `.claude-memory-compiler/` to `.gitignore`

### 3. Verify the installation

Run these checks and report results:

```bash
# Check directory structure
test -d .claude-memory-compiler/hooks && echo "hooks: OK" || echo "hooks: MISSING"
test -d .claude-memory-compiler/scripts && echo "scripts: OK" || echo "scripts: MISSING"
test -d .claude-memory-compiler/daily && echo "daily: OK" || echo "daily: MISSING"
test -d .claude-memory-compiler/knowledge/concepts && echo "knowledge: OK" || echo "knowledge: MISSING"

# Check hooks configured
test -f .claude/settings.json && echo "settings.json: OK" || echo "settings.json: MISSING"

# Check slash command installed
test -f .wibey/commands/compile-kb.md && echo "/compile-kb: OK" || echo "/compile-kb: MISSING"
```

### 4. Clean up

If you cloned to a temp directory in step 1, clean it up:

```bash
rm -rf "$TEMP_DIR"
```

### 5. Report to user

Tell the user:
- Setup is complete
- Start a **new** Wibey/Claude Code session to activate the hooks
- Conversations will be automatically captured to `.claude-memory-compiler/daily/`
- Use `/compile-kb` to compile daily logs into knowledge articles
- Check `.claude-memory-compiler/scripts/flush.log` if anything seems off
