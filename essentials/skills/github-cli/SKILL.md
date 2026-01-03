---
name: github-cli
description: GitHub CLI (gh) wrapper for PR status, issues, and repository operations
allowed-tools: Bash, Read, Glob
argument-hint: <action> [args]
---

GitHub CLI helper skill for common `gh` operations. Requires `gh` CLI installed and authenticated.

**Note**: For creating/updating PR descriptions, use `/mr-description-creator` instead.

## Actions

### PR Operations

**View PR status:**
```
/github-cli pr status
```

**View PR checks:**
```
/github-cli pr checks
```

**Merge PR:**
```
/github-cli pr merge
```

**View PR in browser:**
```
/github-cli pr view --web
```

**List PRs:**
```
/github-cli pr list
```

### Issue Operations

**List issues:**
```
/github-cli issue list
```

**Create issue:**
```
/github-cli issue create
```

**View issue:**
```
/github-cli issue view <number>
```

### Repository Operations

**View repo:**
```
/github-cli repo view
```

## Instructions

### Step 1: Validate Environment

```bash
# Check gh is installed
gh --version

# Check gh is authenticated
gh auth status
```

If not installed, report: "Install gh CLI: https://cli.github.com"
If not authenticated, report: "Run: gh auth login"

### Step 2: Parse and Execute

Parse `$ARGUMENTS` and pass directly to `gh`:

```bash
gh $ARGUMENTS
```

### Step 3: Report Result

Show `gh` output directly to user.

## Examples

```bash
# View PR status
/github-cli pr status

# View PR checks (CI status)
/github-cli pr checks

# Merge current PR
/github-cli pr merge

# List open PRs
/github-cli pr list

# View PR in browser
/github-cli pr view --web

# List issues
/github-cli issue list

# Create issue interactively
/github-cli issue create

# View repo info
/github-cli repo view

# API calls
/github-cli api repos/{owner}/{repo}/pulls

# Any gh command works
/github-cli release list
/github-cli workflow list
```

## Error Handling

| Scenario | Action |
|----------|--------|
| gh not installed | "Install gh: https://cli.github.com" |
| Not authenticated | "Run: gh auth login" |
| gh command fails | Show gh error output |
