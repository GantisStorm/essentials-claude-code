---
name: gitlab-cli
description: GitLab CLI (glab) wrapper for MR status, issues, and repository operations
allowed-tools: Bash, Read, Glob
argument-hint: <action> [args]
---

GitLab CLI helper skill for common `glab` operations. Requires `glab` CLI installed and authenticated.

**Note**: For creating/updating MR descriptions, use `/mr-description-creator` instead.

## Actions

### MR Operations

**View MR status:**
```
/gitlab-cli mr status
```

**View MR in browser:**
```
/gitlab-cli mr view --web
```

**List MRs:**
```
/gitlab-cli mr list
```

**Merge MR:**
```
/gitlab-cli mr merge
```

### Issue Operations

**List issues:**
```
/gitlab-cli issue list
```

**Create issue:**
```
/gitlab-cli issue create
```

**View issue:**
```
/gitlab-cli issue view <number>
```

### CI/CD Operations

**View CI status:**
```
/gitlab-cli ci status
```

**View pipeline:**
```
/gitlab-cli ci view
```

**List jobs:**
```
/gitlab-cli job list
```

### Repository Operations

**View repo:**
```
/gitlab-cli repo view
```

## Instructions

### Step 1: Validate Environment

```bash
# Check glab is installed
glab --version

# Check glab is authenticated
glab auth status
```

If not installed, report: "Install glab CLI: https://gitlab.com/gitlab-org/cli"
If not authenticated, report: "Run: glab auth login"

### Step 2: Parse and Execute

Parse `$ARGUMENTS` and pass directly to `glab`:

```bash
glab $ARGUMENTS
```

### Step 3: Report Result

Show `glab` output directly to user.

## Examples

```bash
# View MR status
/gitlab-cli mr status

# View MR in browser
/gitlab-cli mr view --web

# List open MRs
/gitlab-cli mr list

# Merge current MR
/gitlab-cli mr merge

# List issues
/gitlab-cli issue list

# Create issue interactively
/gitlab-cli issue create

# View repo info
/gitlab-cli repo view

# View CI status
/gitlab-cli ci status

# View pipeline
/gitlab-cli ci view

# List jobs
/gitlab-cli job list

# API calls
/gitlab-cli api projects/:id/merge_requests

# Any glab command works
/gitlab-cli release list
/gitlab-cli label list
```

## Error Handling

| Scenario | Action |
|----------|--------|
| glab not installed | "Install glab: https://gitlab.com/gitlab-org/cli" |
| Not authenticated | "Run: glab auth login" |
| glab command fails | Show glab error output |
