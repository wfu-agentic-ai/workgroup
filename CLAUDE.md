# WFU Agentic AI Workgroup

> Project instructions

## Workgroup overview

This is a faculty/staff workgroup at Wake Forest University focused on agentic AI tools in the CLI. It is **not** a credit-bearing course — there are no grades, no formal assessment, and membership is rolling (participants join and leave at any time).

- **Audience:** WFU faculty and staff with little or no CLI experience
- **Format:** Weekly in-person meetings + async web content
- **Facilitator:** Will Fleeson (Department of Psychology)
- **Deliverable:** A Quarto website deployed to GitHub Pages

## Learning goals

The workgroup moves participants from zero CLI knowledge toward independent use of agentic AI tools:

1. Navigate the file system and run commands in a terminal
2. Use Git and GitHub for version control and collaboration
3. Configure shell environments and dotfiles
4. Interact with Claude Code for agentic coding workflows
5. Access and configure APIs for AI services
6. Set up and use MCP servers for tool integration
7. Author reproducible documents with Markdown and Quarto

## Content guidelines

When writing tutorials, session notes, or resource pages:

- **Assume zero CLI knowledge.** Define terms on first use. Explain what commands do before showing them.
- **Progressive difficulty.** Early content covers basic navigation and file operations. Later content introduces Git, Claude Code, APIs, and MCPs.
- **Worked examples over abstractions.** Show a concrete task, walk through the steps, then generalize. Avoid leading with theory.
- **Copy-paste friendly.** Code blocks should be runnable as-is. Include expected output where helpful.
- **Platform awareness.** Most participants use macOS, but some use Windows. Tutorials should default to macOS examples and note Windows differences (e.g., PowerShell vs bash, path separators, installer commands) in callouts or inline when behavior diverges.
- **No jargon without context.** If a term is unavoidable, define it inline or link to the glossary.

## Technology stack

- **Shell:** bash (default macOS shell via Terminal.app or iTerm2)
- **Version control:** Git + GitHub
- **AI tools:** Claude Code (CLI), Anthropic API, MCP servers
- **Authoring:** Markdown, Quarto (`.qmd` files)
- **Deployment:** GitHub Pages via `quarto publish gh-pages`
- **Environment:** Nix flake for reproducible development setup

## Site structure

```
index.qmd          — Landing page (welcome, meeting info, getting started)
about.qmd          — Purpose, learning goals, format, facilitator
sessions/          — Session notes, one file per meeting (date-based)
  index.qmd        — Session log, reverse chronological
tutorials/         — Self-contained topic tutorials
  index.qmd        — Tutorial catalog with difficulty indicators
  cli-fundamentals.qmd
  working-with-paths.qmd
  shell-configuration.qmd
  git-fundamentals.qmd
  github-collaboration.qmd
  claude-code-intro.qmd
  apis-and-mcps.qmd
resources/         — Reference material
  index.qmd        — Resource hub
  cheatsheets.qmd
  tools.qmd
  troubleshooting.qmd
  glossary.qmd
```

### Adding a new session

Create `sessions/YYYY-MM-DD.qmd` with front matter:

```yaml
---
title: "Session title"
date: "YYYY-MM-DD"
description: "Brief summary of what was covered."
---
```

The listing on `sessions/index.qmd` picks up new session files automatically.

### Adding a new tutorial

Create `tutorials/topic-name.qmd` with front matter that includes `categories` (one of `"Getting started"`, `"Version control"`, or `"AI tools"`):

```yaml
---
title: "Tutorial title"
description: "Brief description of the tutorial."
date: "YYYY-MM-DD"
categories: ["Getting started"]
---
```

The listing on `tutorials/index.qmd` picks up new tutorial files automatically.

## Quarto conventions

- **Theme:** flatly (Bootstrap-based, clean and readable)
- **Code blocks:** Use `code-copy: true` and `code-tools: true` for interactive code
- **External links:** Open in new window (`link-external-newwindow: true`)
- **Front matter:** Every `.qmd` file needs `title` at minimum; tutorials should also have `description` and `date`
- **Callouts:** Use Quarto callouts (`.callout-note`, `.callout-tip`, `.callout-warning`) for asides and important information
- **Images:** Store in an `images/` subdirectory relative to the page that uses them

## Coding standards

Follow the conventions in the global `~/.claude/CLAUDE.md`:

- R: tidyverse, native pipe (`|>`), 2-space indent
- Python: data science stack, ruff, 4-space indent
- Bash: POSIX-compliant, 2-space indent
- Line limit: 80 characters (except Markdown)
- Naming: snake_case (functions/variables)
- Lists: Use `-` not `*` or `+`
- Conventional commits: `type(scope): message`

## Specs directory

The `specs/` directory contains planning, progress, and implementation documents for the workgroup. These files are excluded from the rendered site (via `.gitignore` and not being listed in `_quarto.yml`). They are internal project management documents.
