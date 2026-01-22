---
allowed-tools: Task, TaskOutput, Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: "[--template 'markdown']"
description: Generate and apply MR/PR description directly via gh or glab CLI (project)
skills: ["github-cli", "gitlab-cli"]
model: opus
context: fork
---

# MR/PR Description Creator

Generate MR/PR descriptions and apply directly using `gh` (GitHub) or `glab` (GitLab) CLI.

**Requires**: `gh` or `glab` CLI installed and authenticated.

## Related Skills

- `/github-cli <action>` — GitHub CLI wrapper
- `/gitlab-cli <action>` — GitLab CLI wrapper

## Arguments

- `--template "markdown"` - Custom template for description
- (none) - Uses default template

## Instructions

### Step 1: Detect Platform

```bash
git remote get-url origin 2>/dev/null
```

- `github.com` or `ghe.` → GitHub → use `gh`
- `gitlab` → GitLab → use `glab`
- Unclear → Ask user

### Step 2: Validate Environment

**GitHub:**
```bash
gh auth status
```

**GitLab:**
```bash
glab auth status
```

- If not installed: Report install link
- If not authenticated: Report auth command
- If on main/master: Report error (need feature branch)

### Step 3: Determine Action

```bash
# GitHub
gh pr view --json number -q '.number' 2>/dev/null

# GitLab
glab mr view --output json 2>/dev/null | jq -r '.iid'
```

- MR/PR exists → `update`
- No MR/PR → `create`

### Step 4: Gather Git Context

```bash
git log main..HEAD --oneline
git diff main...HEAD --stat
git rev-list --count main..HEAD
```

### Step 5: Launch Agent

Launch background agent with gathered context:

```
Generate MR/PR description:
Platform: <github or gitlab>
CLI: <gh or glab>
Action: <create or update>
Branch: <current> -> <base>
Template: <custom or "default">
Commits: <count>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:mr-description-creator-default"
run_in_background: true
prompt: "Generate MR/PR description:\nPlatform: <platform>\nCLI: <cli>\nAction: <action>\nBranch: <branch info>\nTemplate: <template>\nCommits: <count>"
```

Wait with TaskOutput (block: true).

### Step 6: Report Result

```
## MR/PR <CREATED/UPDATED>

**Platform**: <GitHub or GitLab>
**URL**: <url>
**Branch**: <current> -> <base>

View: <gh pr view --web OR glab mr view --web>
```

## Error Handling

| Scenario | Action |
|----------|--------|
| CLI not installed | Report install link |
| Not authenticated | Report auth command |
| Can't detect platform | Ask user |
| On main/master | Report error |
| No commits | Report error |

## Example Usage

```bash
/mr-description-creator
/mr-description-creator --template "## Summary\n{summary}\n## Changes\n{changes}"
```
