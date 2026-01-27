---
allowed-tools: Task, Bash, Read, AskUserQuestion
argument-hint: <description>
description: Enhance rough prompt ideas into detailed, effective prompts (project)
model: opus
context: fork
---

# Prompt Creator

Transform rough, vibe-y prompt ideas into detailed, effective prompts tuned to your codebase.

**Supports 4 prompt types:**
- **Slash Commands** — User-invoked commands
- **Subagents** — Background worker agents
- **Feature Requests** — Well-formatted input for `/plan-creator`
- **Bug Reports** — Well-formatted input for `/bug-plan-creator`

## Arguments

Takes any rough prompt description:
- `"a prompt that reviews code for security"` → Slash command or subagent
- `"help me debug stuff"` → Slash command or subagent
- `"feature: add user authentication with OAuth"` → Feature request for /plan-creator
- `"bug: login fails when user has no profile"` → Bug description for /bug-plan-creator
- `"bug: ./logs/error.log API timeout"` → Analyzes logs, creates clean bug description

## Instructions

### Step 1: Generate Output Path

```bash
HASH=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 5)
```

Path: `.claude/prompts/{slug}-{hash5}.md`

### Step 2: Launch Agent

Launch `prompt-creator-default` agent:

```
Enhance this rough prompt idea into a detailed, effective prompt.

Description: <user input>
Output file: <generated path>

Research the codebase for context, then write the enhanced prompt.
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:prompt-creator-default"
prompt: "Enhance this rough prompt idea into a detailed, effective prompt.\n\nDescription: <user input>\nOutput file: <generated path>\n\nResearch the codebase for context, then write the enhanced prompt."
```

### Step 3: Report Result

```
Prompt created: <file path>

Ready to use. For edits, ask the main agent to modify the file.
```

## Example Usage

```bash
# Create slash commands or subagents
/prompt-creator "a prompt that reviews PRs for security issues"
/prompt-creator "help me analyze pentesting results"

# Create feature requests for /plan-creator
/prompt-creator "feature: add user authentication with JWT and refresh tokens"
/prompt-creator "feature: implement real-time notifications with WebSockets"
# Then: /plan-creator <paste feature request>

# Create bug descriptions for /bug-plan-creator
/prompt-creator "bug: API returns 500 when user profile is null"
/prompt-creator "bug: ./logs/error.log connection timeout on database"
# Then: /bug-plan-creator "<paste bug description>" ./logs/error.log
```
