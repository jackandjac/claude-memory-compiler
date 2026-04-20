---
name: compile-kb
description: Incrementally save knowledge from the current conversation — captures decisions, reasoning, patterns, dead ends, and meta-instructions. Run anytime, as often as needed.
---

You are a **deep knowledge compiler**. Your job is to extract knowledge — not just WHAT happened, but:

- **WHY** — the reasoning behind decisions, the trade-offs considered
- **HOW** — patterns learned, debugging techniques, reusable approaches
- **CONTEXT** — what was tried and rejected, dead ends explored
- **RULES** — meta-instructions, conventions, preferences that should persist

## Compilation Modes

This command supports two modes based on arguments:

### Mode 1: Incremental Save (DEFAULT — no arguments)

**Trigger:** `/compile-kb` with no arguments

**Source:** The current conversation in your context window — YOU are the source of truth.

This is the primary mode. The user can run this **anytime during a session** to checkpoint knowledge before a crash or compaction destroys it. Multiple invocations per session are expected and safe.

**Flow:**
1. Read the current knowledge state (index, existing articles, meta-instructions)
2. Read `knowledge/log.md` — check the **last compilation timestamp for today** to understand what's already been captured
3. Review the current conversation in your context, focusing on content **since the last compilation** (or the entire conversation if this is the first compilation today)
4. Extract new knowledge not already present in existing articles
5. Write/update knowledge articles
6. **Write a timestamped session summary to `daily/YYYY-MM-DD.md`** (this is the audit trail — the daily log is a SIDE EFFECT of compilation, not a prerequisite)
7. Update `index.md` and `log.md`

**Critical:** In this mode, the daily log is OUTPUT, not INPUT. You write TO it, you don't read FROM it. The conversation context is your source.

### Mode 2: Daily Log Compilation (with date argument)

**Trigger:** `/compile-kb 2026-04-15` or `/compile-kb --all`

**Source:** Daily log files in `.claude-memory-compiler/daily/`

This mode compiles from previously saved daily logs — useful for batch processing or recompiling old sessions.

**Flow:**
1. Read the daily log file(s)
2. Extract knowledge following the same rules as Mode 1
3. Update articles, index, and log

---

## Instructions (Mode 1: Incremental Save)

### Step 1. Read Current Knowledge State

- Read `.claude-memory-compiler/knowledge/index.md` (master catalog)
- Read `.claude-memory-compiler/knowledge/meta-instructions.md` if it exists
- Read `.claude-memory-compiler/knowledge/log.md` — find the last compilation entry for today to know what's already captured

### Step 2. Read Existing Articles That May Need Updating

Scan existing articles in `concepts/`, `decisions/`, `patterns/`, and `connections/` — read any that relate to topics discussed in the current conversation.

### Step 3. Ensure Directories Exist

```bash
mkdir -p .claude-memory-compiler/knowledge/{decisions,patterns}
mkdir -p .claude-memory-compiler/daily
```

### Step 4. Identify New Knowledge

Compare the current conversation against existing articles and the last compilation log entry.

**Ask yourself:** "What has been discussed since the last compilation (or session start) that is NOT already captured in the knowledge base?"

Skip anything that:
- Is already accurately captured in an existing article
- Is routine/trivial (file reads, tool calls, obvious clarifications)
- Was captured in a previous compilation during this same session

### Step 5. Deep Extraction

Extract ALL of the following from the new conversation content:

#### A. Decisions (highest priority — 0-3 per compilation)

**Signals to look for:**
- "We chose X over Y because..."
- "I tried X but it didn't work, so..."
- Trade-off discussions ("X is faster but Y is safer")
- Explicit rejections with reasoning
- Architecture or design choices
- Moments where alternatives were evaluated

**Create a `decisions/` article** for each significant decision. If a previous decision on the same topic exists, UPDATE it (mark old as superseded if replaced).

#### B. Patterns (0-3 per compilation)

**Signals to look for:**
- "When you see X, check Y first" (debugging heuristic)
- Reusable code patterns or architecture approaches
- "Don't do X because..." (anti-pattern)
- Workflow optimizations or shortcuts discovered
- Recurring problem → solution pairings

**Create a `patterns/` article** for each new pattern. UPDATE existing patterns with new evidence.

#### C. Concepts (0-7 per compilation)

Technical facts, configurations, API behaviors — **enhanced** with optional sections:
- **`## Reasoning`** — include when conversation shows WHY something works or was chosen
- **`## Alternatives & Dead Ends`** — include when conversation shows rejected approaches

UPDATE existing concept articles when possible. CREATE new ones for new topics.

#### D. Connections (0-2 per compilation)

Cross-cutting insights linking 2+ concepts.

#### E. Meta-Instructions (0-5 per compilation)

**Signals to look for:**
- "Always do X before Y"
- "Never use X when..."
- "I prefer X over Y"
- "Our convention is..."
- "When debugging X, first check..."
- Hook/automation rules
- Instructions for how AI assistants should behave
- Project-specific conventions

**MERGE** new rules into `knowledge/meta-instructions.md` — never replace the whole file.

### Step 6. Write Daily Log Entry (Audit Trail)

**APPEND** a timestamped entry to `.claude-memory-compiler/daily/YYYY-MM-DD.md`:

```markdown
### Compilation (HH:MM) - [Brief summary of what was captured]

**Session context:** [What the user was working on]

**Knowledge extracted:**
- [Created/Updated] [[type/article-slug]] — [one-line summary]
- [Created/Updated] [[type/article-slug]] — [one-line summary]
- ...

**Key exchanges since last save:**
- [Brief summary of significant discussion points]
- [Decisions made, problems solved, dead ends hit]

**Meta-instructions captured:**
- [Any new rules/conventions extracted, or "none"]
```

This daily log entry serves as:
1. **Audit trail** — proof of what was compiled and when
2. **Crash recovery** — if the session dies after this compilation, this entry survives
3. **Source reference** — articles can cite `daily/YYYY-MM-DD.md` as their source

### Step 7. Update Structural Files

- UPDATE `.claude-memory-compiler/knowledge/index.md` with all new/modified entries (sectioned format)
- APPEND to `.claude-memory-compiler/knowledge/log.md`:

```markdown
## [YYYY-MM-DDTHH:MM:SS] compile | Incremental save (conversation)
- Source: current session (incremental)
- Articles created: [[type/slug]], ...
- Articles updated: [[type/slug]], ...
- Meta-instructions: [N new rules added / no changes]
```

---

## Instructions (Mode 2: Daily Log Compilation)

Follow the same extraction rules as Mode 1, but:
- **Source** is the daily log file(s), not the conversation
- Find uncompiled logs by comparing `daily/` files against `knowledge/log.md` entries
- Date argument → compile only that day
- `--all` → compile all uncompiled logs
- Log entry format:

```markdown
## [YYYY-MM-DDTHH:MM:SS] compile | Daily Log YYYY-MM-DD
- Source: daily/YYYY-MM-DD.md
- Articles created: [[type/slug]], ...
- Articles updated: [[type/slug]], ...
```

---

## Knowledge Types Reference

| Type | Directory | What to Capture |
|------|-----------|----------------|
| **Concepts** | `knowledge/concepts/` | Technical facts, configurations, API behaviors |
| **Decisions** | `knowledge/decisions/` | Choices between alternatives with full rationale |
| **Patterns** | `knowledge/patterns/` | Reusable approaches, anti-patterns, debugging heuristics |
| **Connections** | `knowledge/connections/` | Non-obvious links between 2+ concepts |
| **Meta-Instructions** | `knowledge/meta-instructions.md` | Living doc of behavioral rules, conventions, preferences |

---

## Article Formats

### Decision Record (`knowledge/decisions/slug.md`)

```markdown
---
title: "Decision: [Short Description]"
status: accepted
tags: [domain, topic]
sources:
  - "daily/YYYY-MM-DD.md"
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Decision: [Short Description]

## Context

[What situation or problem prompted this decision? What constraints existed?]

## Decision

[What was decided. Be specific and concrete.]

## Alternatives Considered

- **[Alternative A]**: [Description]. Rejected because [specific reason with evidence].
- **[Alternative B]**: [Description]. Rejected because [specific reason with evidence].

## Dead Ends Explored

[If approaches were actually tried and failed, document what happened:]
- Tried [approach]: [what went wrong, error messages, unexpected behavior]

## Consequences

- [Positive consequence]
- [Trade-off accepted]
- [Follow-up work required, if any]

## Related

- [[concepts/related-concept]] - Technical details
- [[patterns/related-pattern]] - Pattern that emerged

## Sources

- [[daily/YYYY-MM-DD.md]] - Full discussion context
```

### Pattern Article (`knowledge/patterns/slug.md`)

```markdown
---
title: "Pattern: [Name]"
type: pattern | anti-pattern | debugging-technique | workflow
tags: [domain, topic]
sources:
  - "daily/YYYY-MM-DD.md"
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Pattern: [Name]

## Problem

[What recurring problem does this pattern solve?]

## Solution

[The approach — concrete steps, code snippets if relevant]

## When to Use

- [Condition 1]
- [Condition 2]

## When NOT to Use

- [Counter-indication with reason]

## Examples

[Concrete examples from conversations — real scenarios, not hypothetical]

## Related

- [[concepts/related]] - Underlying concept
- [[decisions/related]] - Decision that established this pattern

## Sources

- [[daily/YYYY-MM-DD.md]] - Where this pattern was discovered/applied
```

### Enhanced Concept Article (`knowledge/concepts/slug.md`)

```markdown
---
title: "Concept Name"
aliases: [alternate-name]
tags: [domain, topic]
sources:
  - "daily/YYYY-MM-DD.md"
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Concept Name

[2-4 sentence core explanation]

## Key Points

- [3-5 self-contained bullet points]

## Details

[2+ paragraphs, encyclopedia-style]

## Reasoning

[WHY this approach/technology/pattern works. What problem it solves. Include only when the conversation reveals the reasoning — do not fabricate.]

## Alternatives & Dead Ends

[What else was considered or tried. Include only when the conversation discusses alternatives.]
- **[Alternative A]**: Rejected because [reason]
- **[Approach tried]**: Failed because [what happened]

## Related Concepts

- [[concepts/related]] - How it connects
- [[decisions/related-decision]] - Decision that led here
- [[patterns/related-pattern]] - Pattern using this concept

## Sources

- [[daily/YYYY-MM-DD.md]] - Specific context
```

### Meta-Instructions (`knowledge/meta-instructions.md`)

This is a **living document**. MERGE new rules — never replace the file.

```markdown
# Meta-Instructions

> Behavioral rules, conventions, and preferences extracted from conversations.
> Updated incrementally by /compile-kb. Each rule cites its source.

## Coding Conventions

- [Rule]: [reason] _(from daily/YYYY-MM-DD.md)_

## Tool & Workflow Rules

- [Rule]: [reason] _(from daily/YYYY-MM-DD.md)_

## Project Conventions

- [Rule]: [reason] _(from daily/YYYY-MM-DD.md)_

## Debugging Heuristics

- [Rule]: [reason] _(from daily/YYYY-MM-DD.md)_

## User Preferences

- [Preference]: [context] _(from daily/YYYY-MM-DD.md)_

## AI Assistant Instructions

- [Instruction]: [reason] _(from daily/YYYY-MM-DD.md)_
```

**MERGE rules:**
- Read the existing file FIRST
- Add new rules under the appropriate category
- If a new rule CONTRADICTS an existing one: update the existing rule, note the change and date
- Always include the source daily log reference
- Do NOT remove existing rules unless explicitly contradicted by newer information

---

## Index Format

Use sectioned format in `knowledge/index.md`:

```markdown
# Knowledge Base Index

## Concepts

| Article | Summary | Compiled From | Updated |
|---------|---------|---------------|---------|

## Decisions

| Article | Summary | Compiled From | Updated |
|---------|---------|---------------|---------|

## Patterns

| Article | Summary | Compiled From | Updated |
|---------|---------|---------------|---------|

## Connections

| Article | Summary | Compiled From | Updated |
|---------|---------|---------------|---------|
```

If the existing index uses the old flat format, migrate it to this sectioned format while preserving all existing entries.

---

## Extraction Priority

Extract in this order of value:

1. **Decisions with rejected alternatives** — Highest value. The reasoning chain and rejected paths prevent future re-exploration of dead ends.
2. **Dead ends and failures** — "Tried X, failed because Y" is MORE valuable than "Used X successfully" because it prevents wasted effort.
3. **Meta-instructions** — Behavioral rules that compound across every future session.
4. **Patterns** — Reusable approaches worth remembering.
5. **Concepts** — Factual knowledge (the existing default).

---

## Quality Standards

- Every article MUST have complete YAML frontmatter (title, sources, created, updated)
- Every article MUST link to at least 2 other articles via `[[wikilinks]]`
- Decision records MUST list at least 2 alternatives with specific rejection reasons
- Pattern articles MUST include both "When to Use" and "When NOT to Use"
- Meta-instructions MUST include the source daily log reference
- File naming: lowercase, hyphens for spaces (e.g., `chose-merge-over-insert.md`)
- Concept `## Reasoning` and `## Alternatives & Dead Ends` sections: include ONLY when the conversation actually contains this information — never fabricate
- Prefer UPDATING existing articles over creating near-duplicates
- Skip routine/trivial content (file reads, tool calls, obvious clarifications)
- On incremental saves: ONLY extract knowledge not already captured — check existing articles first

## Critical Reminders

- **Run early, run often.** Every `/compile-kb` is a checkpoint. If the session crashes after, the knowledge survives.
- The daily log is a SIDE EFFECT of compilation in incremental mode — not a prerequisite
- The MOST VALUABLE knowledge is in **failures and rejections** — extract those first
- Dead ends save future sessions from re-exploring the same paths
- Meta-instructions compound: one rule captured today saves time in every future session
- Every article must be self-contained and useful without reading the source daily log
- When updating existing articles, ADD information — don't overwrite what's already there
- Multiple compilations per session are safe — the system is idempotent by design
