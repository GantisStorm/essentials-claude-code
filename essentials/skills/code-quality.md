# Code Quality - CLI Commands

Commands for maintaining code quality in this Python project using Ruff and Pyright.

## Quick Command (Run After Every Edit)

```bash
# Auto-fix linting + format + type check
.venv/bin/ruff check . --fix && .venv/bin/ruff format . && .venv/bin/pyright
```

This command:
- Fixes import order and style issues
- Formats code consistently
- Checks for type errors

## Individual Commands

### Linting

```bash
# Check for issues
.venv/bin/ruff check .
.venv/bin/ruff check agent/
.venv/bin/ruff check tui/

# Auto-fix issues
.venv/bin/ruff check . --fix
.venv/bin/ruff check agent/ --fix

# Verify clean (no fixes)
.venv/bin/ruff check .
```

### Formatting

```bash
# Format all files
.venv/bin/ruff format .

# Format specific directory
.venv/bin/ruff format agent/
.venv/bin/ruff format tui/
```

**What ruff format does:**
- Breaks long lines (120 char limit)
- Fixes indentation/spacing
- Enforces double quotes
- Adds/removes trailing commas

### Type Checking

```bash
# Check all files
.venv/bin/pyright

# Check specific file
.venv/bin/pyright agent/agent.py
.venv/bin/pyright tui/app.py
```

## Targeted Rule Checking

Check for specific types of issues:

```bash
# Find unused imports (F401), variables (F841), arguments (ARG)
.venv/bin/ruff check . --select F401,F841,ARG

# Auto-fix unused imports
.venv/bin/ruff check . --select F401 --fix

# Check import sorting only
.venv/bin/ruff check . --select I --fix

# Check for common bugs (flake8-bugbear)
.venv/bin/ruff check . --select B

# Check naming conventions
.venv/bin/ruff check . --select N
```

**Useful when:**
- Cleaning up unused code
- Fixing import organization
- Focusing on specific code quality issues

## Dead Code Detection

Detect and remove unused code to keep the codebase clean and maintainable.

### Quick Dead Code Scan

```bash
# Find all dead code (unused imports, variables, arguments)
.venv/bin/ruff check . --select F401,F841,ARG

# Auto-fix safely removable dead code (unused imports only)
.venv/bin/ruff check . --select F401 --fix
```

### Ruff Dead Code Rules

| Rule | Description | Safe to Auto-Fix? |
|------|-------------|-------------------|
| F401 | Unused imports | Yes |
| F841 | Unused local variables | Review first |
| ARG001 | Unused function arguments | Review first |
| ARG002 | Unused method arguments | Review first |
| ARG003 | Unused class method arguments | Review first |
| ARG004 | Unused static method arguments | Review first |
| ARG005 | Unused lambda arguments | Review first |

### When to Use --fix

**Safe to auto-fix:**
- `F401` (unused imports): Always safe, removes clutter

**Review before fixing:**
- `F841` (unused variables): May indicate incomplete implementation or debugging code left behind
- `ARG*` (unused arguments): May be required for API compatibility, callbacks, or future use

```bash
# Preview what --fix would change (recommended before fixing F841/ARG)
.venv/bin/ruff check . --select F841,ARG --fix --diff

# Fix only after reviewing the diff
.venv/bin/ruff check . --select F841 --fix
```

### Interpreting Findings

**Unused imports (F401):**
- Usually safe to remove
- Exception: imports used for type hints in `TYPE_CHECKING` blocks

**Unused variables (F841):**
- Check if the variable was meant to be used but wasn't
- Look for typos in variable names
- May indicate incomplete refactoring

**Unused arguments (ARG):**
- Required by interface/callback signature? Add `# noqa: ARG001` or prefix with `_`
- Truly unused? Consider removing if you control the API

```bash
# Suppress warning for intentionally unused argument
def callback(event, _context):  # _prefix indicates intentionally unused
    process(event)
```

### Optional: Vulture for Deeper Analysis

Vulture finds unreachable code that Ruff may miss (unused functions, classes, methods):

```bash
# Install vulture (if not already installed)
pip install vulture

# Run vulture on the codebase
vulture agent/ tui/ common/

# With confidence threshold (higher = fewer false positives)
vulture agent/ tui/ common/ --min-confidence 80
```

**Vulture findings require manual review** - it reports potential dead code but may have false positives for:
- Dynamically called functions
- Plugin/hook systems
- Test fixtures
- CLI entry points

### Dead Code Detection Workflow

1. **Regular maintenance:**
   ```bash
   .venv/bin/ruff check . --select F401 --fix  # Safe auto-fix
   ```

2. **Before major refactoring:**
   ```bash
   .venv/bin/ruff check . --select F401,F841,ARG  # Full scan
   vulture agent/ tui/ common/ --min-confidence 80  # Deep analysis
   ```

3. **After removing features:**
   ```bash
   # Find orphaned code from removed features
   .venv/bin/ruff check . --select F401,F841,ARG
   vulture agent/ tui/ common/
   ```

## Preview Changes (Diff Mode)

See what would change without modifying files:

```bash
# Show diff of all auto-fixes
.venv/bin/ruff check . --fix --diff

# Preview formatting changes
.venv/bin/ruff format . --diff

# Check specific file changes
.venv/bin/ruff check agent/hitl.py --fix --diff
```

**Use this to:**
- Review changes before applying
- Understand what tools will modify
- Safely explore fixes

## Before Committing

```bash
# Complete pre-commit workflow
.venv/bin/ruff check . --fix && \
.venv/bin/ruff format . && \
.venv/bin/ruff check . && \
.venv/bin/pyright
```

If all checks pass, then commit:
```bash
git add .
git commit -m "Your message"
```

## Understanding Output

### Ruff Output

**Clean:**
```
All checks passed!
```

**Issues found:**
```
agent/agent.py:136:5: SIM108 Use ternary operator instead of if-else-block
Found 4 errors (3 fixable).
```
- Line format: `file:line:col: CODE Description`
- `3 fixable` = can auto-fix with `--fix`

**Auto-fixed:**
```
Found 55 errors (55 fixed).
```

### Pyright Output

Shows type errors that must be fixed:
- Missing type annotations
- None type errors
- Import errors
- Type mismatches

## Configuration Files

**Ruff:** `ruff.toml`
- Line length: 120
- Linting rules enabled
- CLI only (no IDE extension)

**Pyright:** `pyrightconfig.json`
- Type checking rules
- Used by both IDE and CLI

**Pylint:** `.pylintrc`
- IDE warnings only
- Configured to match Ruff (120 char)
- Not required for commits

### Enabled Rule Categories

Based on `ruff.toml`, these rule sets are active:

- **E/W** - pycodestyle (PEP 8 style violations)
- **F** - Pyflakes (unused imports, variables, undefined names)
- **I** - isort (import sorting/organization)
- **N** - pep8-naming (naming conventions)
- **UP** - pyupgrade (modernize Python syntax)
- **B** - flake8-bugbear (likely bugs and design problems)
- **C4** - flake8-comprehensions (better list/dict comprehensions)
- **SIM** - flake8-simplify (code simplification suggestions)

See all rules: https://docs.astral.sh/ruff/rules/

## Troubleshooting

### "Command not found: ruff"
```bash
# Use full path to venv
.venv/bin/ruff check .
```

### "Import could not be resolved"
Reload IDE (Cmd+Shift+P → "Reload Window")

### Type errors
Fix by:
- Adding type annotations
- Checking for None before accessing
- Using `hasattr()` for attribute checks
- Adding type guards

### Long line warnings from Pylint
```bash
# Auto-fix with ruff format
.venv/bin/ruff format .
```

## Quick Status Check

```bash
# Check if tools are available
which .venv/bin/ruff
which .venv/bin/pyright

# Verify versions
.venv/bin/ruff --version
.venv/bin/pyright --version
```

## Configuration Reference

All configuration files are in project root:
- `ruff.toml` - Ruff configuration
- `pyrightconfig.json` - Pyright configuration
- `.pylintrc` - Pylint configuration

**Important:** Don't modify these unless you know what you're doing - they affect the entire team.

## Pro Tips

1. Run the quick command after every code edit
2. Fix issues immediately, don't let them pile up
3. Read error messages - they explain what's wrong
4. Use `--fix` liberally - it's safe
5. Review changes with `git diff` before committing

## Reference

- **Ruff docs:** https://docs.astral.sh/ruff/
- **Ruff rules:** https://docs.astral.sh/ruff/rules/
- **Pyright docs:** https://github.com/microsoft/pyright
