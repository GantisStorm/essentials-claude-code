---
allowed-tools: Task, TaskOutput, Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: "[--template 'markdown']"
description: Generate and apply MR/PR description directly via gh or glab CLI (project)
model: opus
skills: ["github-cli", "gitlab-cli"]
---

# MR/PR Description Creator

Generate professional merge request (MR) or pull request (PR) descriptions and apply them directly using `gh` (GitHub) or `glab` (GitLab) CLI - auto-detected based on repository remote.

**IMPORTANT**: Requires `gh` or `glab` CLI installed and authenticated. No file created - description applied directly.

## Related Skills

For manual CLI operations, use the helper skills:
- `/github-cli <action>` — GitHub CLI wrapper (e.g., `/github-cli pr status`)
- `/gitlab-cli <action>` — GitLab CLI wrapper (e.g., `/gitlab-cli mr status`)

## Arguments

Optional:
- `--template "markdown"` - Custom markdown template for the MR/PR description output format
- (none) - Uses default template

## Instructions

### Step 1: Detect Platform

```bash
# Get remote URL
git remote get-url origin 2>/dev/null

# Check for GitHub or GitLab
# GitHub: github.com, ghe.* (GitHub Enterprise)
# GitLab: gitlab.com, gitlab.* (self-hosted GitLab)
```

**Platform Detection Logic:**
- If remote contains `github.com` or `ghe.` → GitHub → use `gh`
- If remote contains `gitlab` → GitLab → use `glab`
- If unclear → Ask user which platform

### Step 2: Validate Environment

**For GitHub (gh):**
```bash
gh auth status
```
- If not installed: "Install gh: https://cli.github.com"
- If not authenticated: "Run: gh auth login"

**For GitLab (glab):**
```bash
glab auth status
```
- If not installed: "Install glab: https://gitlab.com/gitlab-org/cli"
- If not authenticated: "Run: glab auth login"

**Common checks:**
```bash
# Verify git repo
git status

# Get current branch
git rev-parse --abbrev-ref HEAD

# Auto-detect base branch
git branch --list main master | head -n 1
```

**Validation:**
- If CLI not installed: Report error with install link
- If not authenticated: Report error, suggest auth command
- If not git repo: Report error
- If on main/master: Report error (need feature branch)

### Step 3: Determine Action & Parse Arguments

**Parse --template argument:**
```bash
# Check if $ARGUMENTS contains --template
# Extract the markdown template content between quotes if present
```

**For GitHub:**
```bash
gh pr view --json number -q '.number' 2>/dev/null
```

**For GitLab:**
```bash
glab mr view --output json 2>/dev/null | jq -r '.iid'
```

**Action Logic (auto-detect):**
- If MR/PR exists → `update`
- If no MR/PR exists → `create`

### Step 4: Gather Git Context

```bash
# Get commits (use detected base branch)
git log main..HEAD --oneline

# Get file changes
git diff main...HEAD --stat
git diff main...HEAD --name-status

# Get commit count
git rev-list --count main..HEAD

# Check changelog
cat CHANGELOG.md 2>/dev/null | head -50 || echo "No changelog"
```

### Step 5: Launch Agent

Launch `mr-description-creator-default` in background:

```
Generate MR/PR description and apply via CLI.

Platform: <github or gitlab>
CLI: <gh or glab>
Action: <create or update> (auto-detected)
Current Branch: <branch>
Base Branch: <main or master>

## Custom Template

<If --template provided, include the template content here>
<If no template, write: "No custom template - use default template">

## Git Context

Commits: <count>
<commit list>

File Changes:
- Added: <count>
- Modified: <count>
- Deleted: <count>

## Process

1. GIT CHANGE ANALYSIS
2. TEMPLATE SELECTION (custom or default)
3. REGRESSION ANALYSIS - Breaking changes
4. COMMIT CATEGORIZATION - feat, fix, etc.
5. MR/PR DESCRIPTION GENERATION
6. MULTI-PASS VALIDATION
7. APPLY VIA CLI

Return:
PLATFORM: <github or gitlab>
ACTION: <create or update>
MR_NUMBER: <number>
MR_URL: <url>
COMMITS_ANALYZED: <count>
FILES_CHANGED: <count>
BREAKING_CHANGES: <count>
STATUS: <CREATED or UPDATED>
```

Use `subagent_type: "mr-description-creator-default"` and `run_in_background: true`.

### Step 6: Report Result

```
===============================================================
<MR or PR> <CREATED/UPDATED>
===============================================================

Platform: <GitHub or GitLab>
<MR or PR>: #<number>
URL: <url>
Branch: <current> -> <base>

Analysis:
- Commits: <count>
- Files changed: <count>
- Breaking changes: <count>

===============================================================
NEXT STEPS
===============================================================

View: <gh pr view --web OR glab mr view --web>

===============================================================
```

## Workflow Diagram

```
/mr-description-creator [--template "markdown"]
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 1: DETECT PLATFORM                                       │
│                                                               │
│  • Parse git remote URL                                       │
│  • Detect: GitHub (gh) or GitLab (glab)                       │
│  • Ask user if ambiguous                                      │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 2: VALIDATE PREREQUISITES                                │
│                                                               │
│  • Check CLI installed (gh/glab)                              │
│  • Check authentication status                                │
│  • Verify git repository                                      │
│  • Ensure not on main/master branch                           │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 3: AUTO-DETECT ACTION                                    │
│                                                               │
│  • Check if MR/PR exists for current branch                   │
│  • Action: CREATE (new) or UPDATE (existing)                  │
│  • Parse --template argument if provided                      │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 4: GATHER GIT CONTEXT                                    │
│                                                               │
│  • git log (commits on branch)                                │
│  • git diff (changes vs base branch)                          │
│  • Current branch name                                        │
│  • Base branch (main/master/develop)                          │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 5: LAUNCH AGENT                                          │
│                                                               │
│  Agent: mr-description-creator-default                        │
│  Mode: run_in_background: true                                │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASES:                                           │  │
│  │                                                         │  │
│  │  1. ANALYZE CHANGES                                     │  │
│  │     • Parse commit messages                             │  │
│  │     • Categorize changes (feat/fix/refactor/docs)       │  │
│  │     • Identify affected components                      │  │
│  │                                                         │  │
│  │  2. GENERATE DESCRIPTION                                │  │
│  │     • Title from primary change                         │  │
│  │     • Summary section                                   │  │
│  │     • Changes breakdown                                 │  │
│  │     • Testing notes                                     │  │
│  │                                                         │  │
│  │  3. APPLY VIA CLI                                       │  │
│  │     • gh pr create/edit OR glab mr create/update        │  │
│  │     • Use custom template if --template provided        │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 6: REPORT RESULT                                         │
│                                                               │
│  Output:                                                      │
│  • Action taken: CREATED or UPDATED                           │
│  • MR/PR URL                                                  │
│  • View command: gh pr view --web / glab mr view --web        │
└───────────────────────────────────────────────────────────────┘
```

## Error Handling

| Scenario | Action |
|----------|--------|
| gh not installed | "Install gh: https://cli.github.com" |
| glab not installed | "Install glab: https://gitlab.com/gitlab-org/cli" |
| Not authenticated | "Run: gh auth login" or "Run: glab auth login" |
| Can't detect platform | Ask user which platform to use |
| Not git repo | Report error |
| On main/master | Report error, suggest feature branch |
| No commits | Report error, suggest making commits |
| Invalid --template format | Report error, show correct format |
| CLI command fails | Report CLI error output |

## Example Usage

```bash
# Auto-detect platform and action (creates if no MR/PR exists, updates if exists)
/mr-description-creator

# Use custom template for MR/PR description
/mr-description-creator --template "## Summary
{summary}

## Changes
{changes}

## Testing
{testing}"

# View result (GitHub)
gh pr view --web

# View result (GitLab)
glab mr view --web
```
