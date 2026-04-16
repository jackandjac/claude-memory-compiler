---
name: compile-kb
description: Compile daily conversation logs into structured knowledge base articles
---

You are a knowledge compiler. Your job is to read daily conversation logs and extract knowledge into structured wiki articles.

## Instructions

1. **Read the schema**: Read `.claude-memory-compiler/AGENTS.md` for the full article format specification.

2. **Read the current index**: Read `.claude-memory-compiler/knowledge/index.md` to understand what articles already exist.

3. **Find uncompiled daily logs**: List files in `.claude-memory-compiler/daily/` and compare against the index to find logs that haven't been compiled yet. If no argument is provided, compile ALL uncompiled logs. If a specific date is provided (e.g., `/compile-kb 2026-04-15`), compile only that day's log.

4. **Read existing articles**: Read any existing articles in `.claude-memory-compiler/knowledge/concepts/` and `.claude-memory-compiler/knowledge/connections/` that may need updating.

5. **For each daily log to compile**:
   - Read the daily log file
   - Extract 3-7 distinct concepts worth their own article
   - For each concept:
     - If an existing article covers this topic: UPDATE it with new information, add the daily log as a source
     - If it's a new topic: CREATE a new article in `knowledge/concepts/`
   - If the log reveals non-obvious connections between 2+ existing concepts: CREATE a `connections/` article
   - Use the exact article format from AGENTS.md (YAML frontmatter + sections)
   - Use `[[concepts/slug]]` wikilinks to link related concepts
   - Write in encyclopedia style — neutral, factual, comprehensive

6. **Update structural files**:
   - UPDATE `.claude-memory-compiler/knowledge/index.md` with new/modified entries
   - APPEND to `.claude-memory-compiler/knowledge/log.md` with a timestamped build entry

## Article Quality Standards

- Every article MUST have complete YAML frontmatter (title, sources, created, updated)
- Every article MUST link to at least 2 other articles via `[[wikilinks]]`
- Key Points section: 3-5 bullet points
- Details section: 2+ paragraphs
- Related Concepts section: 2+ entries
- Sources section: cite daily logs with specific claims extracted
- File naming: lowercase, hyphens for spaces (e.g., `bq-merge-deduplication.md`)

## Important

- Prefer UPDATING existing articles over creating near-duplicates
- Skip routine/trivial content (file reads, tool calls, obvious clarifications)
- Focus on decisions, patterns, gotchas, architecture insights, and lessons learned
- Every article should be self-contained and useful without reading the source daily log
